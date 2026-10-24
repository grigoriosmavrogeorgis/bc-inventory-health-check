namespace GMSOFT.InventoryHealthCheck.Test;

using GMSOFT.InventoryHealthCheck;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.TestLibraries.Utilities;

codeunit 50758 "GSO IR Report Tests"
{
    // Report "GSO IR Run Analysis": passes its filters to the analysis and tells the user the result.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TestHelper: Codeunit "GSO IR Test Helper";
        LastMessage: Text;
        FindingsRunFilter: Text;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ReportWithoutFindingsSaysEverythingAgrees()
    var
        Location: Record Location;
        Item: Record Item;
        AnalysisRun: Record "GSO IR Analysis Run";
    begin
        // [SCENARIO] The report runs the analysis with its filters and reports that everything agrees.
        // [GIVEN] A balanced bin location
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 10, WorkDate(), '');

        // [WHEN] The report runs for the location and item
        RunReport(Location, Item);

        // [THEN] A run with the report filters exists, and the message says one location agrees
        FindLastRun(AnalysisRun);
        Assert.AreEqual(Location.Code, AnalysisRun."Location Filter", 'Location filter');
        Assert.AreEqual(Item."No.", AnalysisRun."Item Filter", 'Item filter');
        Assert.IsTrue(LastMessage.Contains('1 location(s) checked'), LastMessage);
        Assert.IsTrue(LastMessage.Contains('agree'), LastMessage);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,FindingsHandler')]
    procedure ReportWithFindingsOpensFindings()
    var
        Location: Record Location;
        Item: Record Item;
        AnalysisRun: Record "GSO IR Analysis Run";
    begin
        // [SCENARIO] With findings, the report shows the totals and opens the findings of the run.
        // [GIVEN] Item ledger 10 and no warehouse entries (one critical R1)
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');

        // [WHEN] The report runs
        RunReport(Location, Item);

        // [THEN] The message gives the totals and the Findings page opens on the run
        FindLastRun(AnalysisRun);
        Assert.IsTrue(LastMessage.Contains('1 critical'), LastMessage);
        Assert.AreEqual(Format(AnalysisRun."No."), FindingsRunFilter, 'The Findings page must show the findings of this run.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ReportShowsFailure()
    var
        Location: Record Location;
        Item: Record Item;
        FailingSubscriber: Codeunit "GSO IR Failing Subscriber";
    begin
        // [SCENARIO] When the analysis fails, the report shows the error instead of the findings.
        // [GIVEN] A difference and a subscriber that fails when the finding is written
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        BindSubscription(FailingSubscriber);

        // [WHEN] The report runs
        RunReport(Location, Item);
        UnbindSubscription(FailingSubscriber);

        // [THEN] The message names the failure
        Assert.IsTrue(LastMessage.Contains('failed'), LastMessage);
        Assert.IsTrue(LastMessage.Contains(FailingSubscriber.FailureText()), LastMessage);
    end;

    local procedure RunReport(Location: Record Location; Item: Record Item)
    var
        LocationFilter: Record Location;
        ItemFilter: Record Item;
        RunAnalysis: Report "GSO IR Run Analysis";
    begin
        LastMessage := '';
        FindingsRunFilter := '';
        LocationFilter.SetRange(Code, Location.Code);
        ItemFilter.SetRange("No.", Item."No.");
        RunAnalysis.SetTableView(LocationFilter);
        RunAnalysis.SetTableView(ItemFilter);
        RunAnalysis.UseRequestPage(false);
        RunAnalysis.Run();
    end;

    local procedure FindLastRun(var AnalysisRun: Record "GSO IR Analysis Run")
    begin
        AnalysisRun.FindLast();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        LastMessage := Message;
    end;

    [PageHandler]
    procedure FindingsHandler(var Findings: TestPage "GSO IR Findings")
    begin
        FindingsRunFilter := Findings.Filter.GetFilter("Run No.");
    end;
}
