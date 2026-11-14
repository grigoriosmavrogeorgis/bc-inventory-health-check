namespace GMSOFT.InventoryHealthCheck.Test;

using GMSOFT.InventoryHealthCheck;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using System.TestLibraries.Utilities;

codeunit 50107 "GSO IR Page Tests"
{
    // The user-facing pages: review actions and drill-downs on Findings, the Analysis Runs
    // navigation and the setup card.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        TestHelper: Codeunit "GSO IR Test Helper";
        CapturedFilters: Dictionary of [Text, Text];
        CapturedHyperlink: Text;

    [Test]
    procedure MarkAsReviewedSetsStatus()
    var
        Finding: Record "GSO IR Finding";
        FindingsPage: TestPage "GSO IR Findings";
    begin
        // [SCENARIO] Mark as Reviewed sets the status and records who did it.
        // [GIVEN] A new finding
        TestHelper.CreateFinding(Finding, 0, Enum::"GSO IR Rule"::R1);

        // [WHEN] Mark as Reviewed is used on the Findings page
        FindingsPage.OpenEdit();
        FindingsPage.GoToRecord(Finding);
        FindingsPage.MarkReviewed.Invoke();
        FindingsPage.Close();

        // [THEN] The finding is reviewed by the current user
        Finding.Get(Finding."Entry No.");
        Assert.AreEqual(Finding.Status::Reviewed, Finding.Status, 'Status');
        Assert.AreEqual(UpperCase(UserId()), Finding."Status Changed By", 'Status changed by');
    end;

    [Test]
    procedure CloseSetsStatus()
    var
        Finding: Record "GSO IR Finding";
        FindingsPage: TestPage "GSO IR Findings";
    begin
        // [SCENARIO] Close sets the status to Closed.
        // [GIVEN] A new finding
        TestHelper.CreateFinding(Finding, 0, Enum::"GSO IR Rule"::R1);

        // [WHEN] Close is used on the Findings page
        FindingsPage.OpenEdit();
        FindingsPage.GoToRecord(Finding);
        FindingsPage.CloseFinding.Invoke();
        FindingsPage.Close();

        // [THEN] The finding is closed
        Finding.Get(Finding."Entry No.");
        Assert.AreEqual(Finding.Status::Closed, Finding.Status, 'Status');
    end;

    [Test]
    [HandlerFunctions('ItemLedgerEntriesHandler')]
    procedure ItemLedgerEntriesDrillDownUsesFindingFilters()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        FindingsPage: TestPage "GSO IR Findings";
        RunNo: Integer;
    begin
        // [SCENARIO] The item ledger drill-down filters on the item, location and serial number of the finding.
        // [GIVEN] An R2 finding for serial number SN2
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateTrackedItem(Item, true, true, true);
        TestHelper.InsertTrackedItemLedgerEntry(Item, Location.Code, '', 1, WorkDate(), '', 'SN1', '');
        TestHelper.InsertTrackedItemLedgerEntry(Item, Location.Code, '', 1, WorkDate(), '', 'SN2', '');
        TestHelper.InsertTrackedWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), '', 1, WorkDate(), '', 'SN1', '');
        TestHelper.InsertTrackedWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), '', 1, WorkDate(), '', 'SN3', '');
        RunNo := TestHelper.RunAnalysis(Location, Item);
        Finding.SetRange("Serial No.", 'SN2');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R2, Finding);

        // [WHEN] Item Ledger Entries is opened from the finding
        FindingsPage.OpenView();
        FindingsPage.GoToRecord(Finding);
        FindingsPage.ItemLedgerEntries.Invoke();

        // [THEN] The entries are filtered on the finding
        Assert.AreEqual(Item."No.", CapturedFilters.Get('Item No.'), 'Item No. filter');
        Assert.AreEqual(Location.Code, CapturedFilters.Get('Location Code'), 'Location Code filter');
        Assert.AreEqual('SN2', CapturedFilters.Get('Serial No.'), 'Serial No. filter');
        Assert.AreEqual('''''', CapturedFilters.Get('Lot No.'), 'The finding is for entries without a lot number, not for every lot.');
    end;

    [Test]
    [HandlerFunctions('WarehouseEntriesHandler')]
    procedure UnitOfMeasureDrillDownUsesConversionFactor()
    var
        Location: Record Location;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Finding: Record "GSO IR Finding";
        FindingsPage: TestPage "GSO IR Findings";
        RunNo: Integer;
    begin
        // [SCENARIO] An R5 finding for entries with an old conversion factor opens only the entries with that factor.
        // [GIVEN] Unit BOX now has 12 per unit, but a warehouse entry used 10 per unit
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 12);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), ItemUnitOfMeasure.Code, 10, 1, 10, WorkDate(), '');
        RunNo := TestHelper.RunAnalysis(Location, Item);
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R5, Finding);

        // [WHEN] Warehouse Entries is opened from the finding
        FindingsPage.OpenView();
        FindingsPage.GoToRecord(Finding);
        FindingsPage.WarehouseEntries.Invoke();

        // [THEN] The entries are filtered on the old conversion factor
        Assert.AreEqual(10, Finding."Qty. per Unit of Measure", 'The finding keeps the conversion factor of its entries.');
        Assert.AreEqual('10', CapturedFilters.Get('Qty. per Unit of Measure'), 'Qty. per Unit of Measure filter');
    end;

    [Test]
    [HandlerFunctions('WarehouseEntriesHandler')]
    procedure UnitOfMeasureDrillDownWithoutFactorKeepsAllFactors()
    var
        Finding: Record "GSO IR Finding";
        FindingsPage: TestPage "GSO IR Findings";
    begin
        // [SCENARIO] An R5 finding created before the factor was stored (factor 0) must not open an empty list.
        // [GIVEN] An R5 finding without Qty. per Unit of Measure
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateFinding(Finding, 0, Enum::"GSO IR Rule"::R5);

        // [WHEN] Warehouse Entries is opened from the finding
        FindingsPage.OpenView();
        FindingsPage.GoToRecord(Finding);
        FindingsPage.WarehouseEntries.Invoke();

        // [THEN] There is no filter on the conversion factor
        Assert.AreEqual('', CapturedFilters.Get('Qty. per Unit of Measure'), 'No conversion factor filter for an old finding');
    end;

    [Test]
    [HandlerFunctions('HyperlinkHandler')]
    procedure GetHelpOpensGMSOFTPage()
    var
        Finding: Record "GSO IR Finding";
        FindingsPage: TestPage "GSO IR Findings";
    begin
        // [SCENARIO] Get Help from GMSOFT opens the app's web page; nothing about the finding is in the link.
        // [GIVEN] A finding
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateFinding(Finding, 0, Enum::"GSO IR Rule"::R1);

        // [WHEN] Get Help from GMSOFT is invoked
        FindingsPage.OpenView();
        FindingsPage.GoToRecord(Finding);
        FindingsPage.GetHelp.Invoke();

        // [THEN] The GMSOFT page of the app opens
        Assert.AreEqual('https://gmsoftdynamics.com/apps/free/inventory-health-check/', CapturedHyperlink, 'Get Help link');
    end;

    [Test]
    [HandlerFunctions('WarehouseEntriesHandler')]
    procedure WarehouseEntriesDrillDownWithoutBinShowsEntriesWithoutBin()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        FindingsPage: TestPage "GSO IR Findings";
        RunNo: Integer;
    begin
        // [SCENARIO] The drill-down of an R6 finding for entries without a bin code shows only those entries.
        // [GIVEN] Item ledger 4, warehouse 4 without a bin code
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 4, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, '', 4, WorkDate(), '');
        RunNo := TestHelper.RunAnalysis(Location, Item);
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R6, Finding);

        // [WHEN] Warehouse Entries is opened from the finding
        FindingsPage.OpenView();
        FindingsPage.GoToRecord(Finding);
        FindingsPage.WarehouseEntries.Invoke();

        // [THEN] The bin code filter is blank, not removed
        Assert.AreEqual('''''', CapturedFilters.Get('Bin Code'), 'A blank bin code must show the entries without a bin, not every bin.');
    end;

    [Test]
    [HandlerFunctions('WarehouseEntriesHandler')]
    procedure WarehouseEntriesDrillDownUsesBin()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        FindingsPage: TestPage "GSO IR Findings";
        RunNo: Integer;
    begin
        // [SCENARIO] The warehouse entries drill-down of a bin finding filters on that bin.
        // [GIVEN] An R4 finding on STOCK-2
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 7, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 10, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.SecondBinCode(), -3, WorkDate(), '');
        RunNo := TestHelper.RunAnalysis(Location, Item);
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R4, Finding);

        // [WHEN] Warehouse Entries is opened from the finding
        FindingsPage.OpenView();
        FindingsPage.GoToRecord(Finding);
        FindingsPage.WarehouseEntries.Invoke();

        // [THEN] The entries are filtered on the item, location and bin
        Assert.AreEqual(Item."No.", CapturedFilters.Get('Item No.'), 'Item No. filter');
        Assert.AreEqual(Location.Code, CapturedFilters.Get('Location Code'), 'Location Code filter');
        Assert.AreEqual(TestHelper.SecondBinCode(), CapturedFilters.Get('Bin Code'), 'Bin Code filter');
    end;

    [Test]
    [HandlerFunctions('BinContentsHandler')]
    procedure BinContentsDrillDownUsesBin()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        WarehouseEmployee: Record "Warehouse Employee";
        FindingsPage: TestPage "GSO IR Findings";
        RunNo: Integer;
    begin
        // [SCENARIO] The bin contents drill-down filters on the location, item and bin of the finding.
        // [GIVEN] An R4 finding on STOCK-2, and the user is a warehouse employee there (Bin Contents requires it)
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 7, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 10, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.SecondBinCode(), -3, WorkDate(), '');
        RunNo := TestHelper.RunAnalysis(Location, Item);
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R4, Finding);

        // [WHEN] Bin Contents is opened from the finding
        FindingsPage.OpenView();
        FindingsPage.GoToRecord(Finding);
        FindingsPage.BinContents.Invoke();

        // [THEN] The bin contents are filtered on the finding
        Assert.AreEqual(Location.Code, CapturedFilters.Get('Location Code'), 'Location Code filter');
        Assert.AreEqual(Item."No.", CapturedFilters.Get('Item No.'), 'Item No. filter');
        Assert.AreEqual(TestHelper.SecondBinCode(), CapturedFilters.Get('Bin Code'), 'Bin Code filter');
    end;

    [Test]
    [HandlerFunctions('FindingsHandler')]
    procedure AnalysisRunsOpensFindingsOfTheRun()
    var
        Location: Record Location;
        Item: Record Item;
        AnalysisRun: Record "GSO IR Analysis Run";
        AnalysisRunsPage: TestPage "GSO IR Analysis Runs";
        RunNo: Integer;
    begin
        // [SCENARIO] Findings on the Analysis Runs page shows only the findings of the selected run.
        // [GIVEN] A run
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        RunNo := TestHelper.RunAnalysis(Location, Item);
        AnalysisRun.Get(RunNo);

        // [WHEN] Findings is opened from the run
        AnalysisRunsPage.OpenView();
        AnalysisRunsPage.GoToRecord(AnalysisRun);
        AnalysisRunsPage.Findings.Invoke();

        // [THEN] The findings are filtered on the run
        Assert.AreEqual(Format(RunNo), CapturedFilters.Get('Run No.'), 'Run No. filter');
    end;

    [Test]
    procedure SetupPageCreatesSetup()
    var
        Setup: Record "GSO IR Setup";
        SetupPage: TestPage "GSO IR Setup";
    begin
        // [SCENARIO] Opening the setup page for the first time creates the setup with defaults.
        // [GIVEN] No setup record
        Setup.DeleteAll(false);

        // [WHEN] The setup page is opened
        SetupPage.OpenEdit();
        SetupPage.Close();

        // [THEN] The setup exists
        Assert.IsTrue(Setup.Get(), 'Opening the setup page must create the setup.');
        Assert.AreEqual(1, Setup."Max. Pending Adj. Age (Days)", 'Max. pending adjustment age');
    end;

    [PageHandler]
    procedure ItemLedgerEntriesHandler(var ItemLedgerEntries: TestPage "Item Ledger Entries")
    begin
        Clear(CapturedFilters);
        CapturedFilters.Add('Item No.', ItemLedgerEntries.Filter.GetFilter("Item No."));
        CapturedFilters.Add('Location Code', ItemLedgerEntries.Filter.GetFilter("Location Code"));
        CapturedFilters.Add('Serial No.', ItemLedgerEntries.Filter.GetFilter("Serial No."));
        CapturedFilters.Add('Lot No.', ItemLedgerEntries.Filter.GetFilter("Lot No."));
    end;

    [PageHandler]
    procedure WarehouseEntriesHandler(var WarehouseEntries: TestPage "Warehouse Entries")
    begin
        Clear(CapturedFilters);
        CapturedFilters.Add('Item No.', WarehouseEntries.Filter.GetFilter("Item No."));
        CapturedFilters.Add('Location Code', WarehouseEntries.Filter.GetFilter("Location Code"));
        CapturedFilters.Add('Bin Code', WarehouseEntries.Filter.GetFilter("Bin Code"));
        CapturedFilters.Add('Qty. per Unit of Measure', WarehouseEntries.Filter.GetFilter("Qty. per Unit of Measure"));
    end;

    [HyperlinkHandler]
    procedure HyperlinkHandler(Message: Text[1024])
    begin
        CapturedHyperlink := Message;
    end;

    [PageHandler]
    procedure BinContentsHandler(var BinContents: TestPage "Bin Contents")
    begin
        Clear(CapturedFilters);
        CapturedFilters.Add('Location Code', BinContents.Filter.GetFilter("Location Code"));
        CapturedFilters.Add('Item No.', BinContents.Filter.GetFilter("Item No."));
        CapturedFilters.Add('Bin Code', BinContents.Filter.GetFilter("Bin Code"));
    end;

    [PageHandler]
    procedure FindingsHandler(var Findings: TestPage "GSO IR Findings")
    begin
        Clear(CapturedFilters);
        CapturedFilters.Add('Run No.', Findings.Filter.GetFilter("Run No."));
    end;
}
