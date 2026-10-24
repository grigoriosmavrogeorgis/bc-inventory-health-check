namespace GMSOFT.InventoryHealthCheck.Test;

using GMSOFT.InventoryHealthCheck;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.TestLibraries.Utilities;

codeunit 50750 "GSO IR Analysis Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        TestHelper: Codeunit "GSO IR Test Helper";

    [Test]
    procedure BalancedBinLocationHasNoFindings()
    var
        Location: Record Location;
        Item: Record Item;
        RunNo: Integer;
    begin
        // [SCENARIO] Normal postings in a bin location give no findings.
        // [GIVEN] A bin location where the item ledger and the bins hold 10
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 10, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] The run completes without findings
        AssertRunCompleted(RunNo);
        Assert.AreEqual(0, TestHelper.CountAllFindings(RunNo), 'A balanced location must not give findings.');
    end;

    [Test]
    procedure MissingWarehouseQuantityGivesR1()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] The item ledger holds more than the bins: R1, critical.
        // [GIVEN] Item ledger 10, warehouse 7
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 7, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One critical R1 finding with a difference of 3
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R1), 'Expected one R1 finding.');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R1, Finding);
        Assert.AreEqual(Finding.Severity::Critical, Finding.Severity, 'R1 must be critical.');
        Assert.AreEqual(10, Finding."Item Ledger Qty. (Base)", 'Item ledger quantity');
        Assert.AreEqual(7, Finding."Warehouse Qty. (Base)", 'Warehouse quantity');
        Assert.AreEqual(3, Finding."Difference (Base)", 'Difference');
        Assert.AreNotEqual('', Finding.Advice, 'The finding must carry advice.');
    end;

    [Test]
    procedure FirstDateOfDifferenceIsFound()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] The first date points to the day the difference appeared.
        // [GIVEN] Balanced 10 days ago, then 5 posted to the item ledger 4 days ago without a warehouse entry
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate() - 10, '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 10, WorkDate() - 10, '');
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 5, WorkDate() - 4, '');
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, -2, WorkDate() - 1, '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), -2, WorkDate() - 1, '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] The R1 finding has the date 4 days ago
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R1, Finding);
        Assert.AreEqual(WorkDate() - 4, Finding."First Date", 'First date of the difference');
    end;

    [Test]
    procedure PendingAdjustmentGivesR3NotR1()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] A registered warehouse journal without Calculate Warehouse Adjustment is pending, not corruption.
        // [GIVEN] Directed location: item ledger 10, bin 12, adjustment bin -2 (warehouse total 10)
        TestHelper.SetMaxPendingAdjustmentAge(30);
        TestHelper.CreateBinLocation(Location, true);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 10, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 2, Today(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.AdjustmentBinCode(), -2, Today(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] No R1, one R3 info finding that will post +2 to the item ledger
        Assert.AreEqual(0, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R1), 'The adjustment bin is part of the warehouse total.');
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R3), 'Expected one R3 finding.');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R3, Finding);
        Assert.AreEqual(Finding.Severity::Info, Finding.Severity, 'A recent pending adjustment is info.');
        Assert.AreEqual(TestHelper.AdjustmentBinCode(), Finding."Bin Code", 'Bin code');
        Assert.AreEqual(-2, Finding."Warehouse Qty. (Base)", 'Adjustment bin balance');
        Assert.AreEqual(2, Finding."Difference (Base)", 'Quantity to post to the item ledger');
        Assert.AreEqual(Today(), Finding."First Date", 'First date of the pending adjustment');
    end;

    [Test]
    procedure OldPendingAdjustmentIsWarning()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] A pending adjustment older than the allowed age is a warning.
        // [GIVEN] Maximum age 1 day, adjustment registered 10 days ago
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, true);
        TestHelper.CreateItem(Item);
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 3, Today() - 10, '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.AdjustmentBinCode(), -3, Today() - 10, '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] The R3 finding is a warning
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R3, Finding);
        Assert.AreEqual(Finding.Severity::Warning, Finding.Severity, 'An old pending adjustment is a warning.');
    end;

    [Test]
    procedure DirectedLocationWithoutAdjustmentBinGivesR3()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] Microsoft requires an adjustment bin for every directed location.
        // [GIVEN] A directed location without adjustment bin
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, true);
        Location."Adjustment Bin Code" := '';
        Location.Modify(false);
        TestHelper.CreateItem(Item);

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One location-level R3 warning
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R3, Finding);
        Assert.AreEqual('', Finding."Item No.", 'The finding is for the location, not an item.');
        Assert.AreEqual(Finding.Severity::Warning, Finding.Severity, 'Severity');
    end;

    [Test]
    procedure LotMismatchGivesR2()
    var
        Location: Record Location;
        Item: Record Item;
        RunNo: Integer;
    begin
        // [SCENARIO] The item total agrees but the lots differ: R2, not R1.
        // [GIVEN] Item ledger LOT1 5 and LOT2 5; warehouse LOT1 7 and LOT2 3
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateTrackedItem(Item, true, true, true);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 5, WorkDate(), 'LOT1');
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 5, WorkDate(), 'LOT2');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 7, WorkDate(), 'LOT1');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 3, WorkDate(), 'LOT2');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] Two R2 findings and no R1
        Assert.AreEqual(0, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R1), 'The item total agrees.');
        Assert.AreEqual(2, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R2), 'Expected one R2 finding per lot.');
    end;

    [Test]
    procedure NegativeBinContentGivesR4()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] A bin with negative content gives R4.
        // [GIVEN] Item ledger 7; bin 1 holds 10, bin 2 holds -3
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 7, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 10, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.SecondBinCode(), -3, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One R4 finding on bin 2 and no R1
        Assert.AreEqual(0, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R1), 'The totals agree.');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R4, Finding);
        Assert.AreEqual(TestHelper.SecondBinCode(), Finding."Bin Code", 'Bin code');
        Assert.AreEqual(-3, Finding."Warehouse Qty. (Base)", 'Bin content');
    end;

    [Test]
    procedure ChangedQtyPerUnitOfMeasureGivesR5()
    var
        Location: Record Location;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RunNo: Integer;
    begin
        // [SCENARIO] Warehouse entries use an old Qty. per Unit of Measure: R5.
        // [GIVEN] The item unit of measure has 12 per unit now; the warehouse entry used 10
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 12);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), ItemUnitOfMeasure.Code, 10, 1, 10, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One R5 finding
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R5), 'Expected one R5 finding.');
    end;

    [Test]
    procedure BaseQuantityMismatchGivesR5()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] Quantity x Qty. per Unit of Measure <> Qty. (Base): R5 (the old NAV report 50193 case).
        // [GIVEN] A warehouse entry with Quantity 4 at 1 per unit but Qty. (Base) 5
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 5, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), Item."Base Unit of Measure", 1, 4, 5, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One R5 finding with a difference of -1
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R5, Finding);
        Assert.AreEqual(-1, Finding."Difference (Base)", 'Calculated minus registered base quantity');
    end;

    [Test]
    procedure QuantityInMissingBinGivesR6()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] Quantity in a bin that does not exist: R6.
        // [GIVEN] Warehouse quantity in bin GHOST, which has no bin record
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 4, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, 'GHOST', 4, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One R6 finding on bin GHOST
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R6, Finding);
        Assert.AreEqual('GHOST', Finding."Bin Code", 'Bin code');
    end;

    [Test]
    procedure KnownItemApplicationIssueGivesR7()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] Inventory 0 with open inbound and outbound entries (Microsoft known issue): R7.
        // [GIVEN] An open positive entry of 5 and an open negative entry of -5
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 5, 5, WorkDate(), '');
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, -5, -5, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One critical R7 finding and no R1
        Assert.AreEqual(0, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R1), 'Inventory and warehouse are both zero.');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R7, Finding);
        Assert.AreEqual(Finding.Severity::Critical, Finding.Severity, 'R7 must be critical.');
    end;

    [Test]
    procedure RemainingQuantityMismatchGivesR7()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] The remaining quantity of open entries differs from the inventory: R7.
        // [GIVEN] Inventory 10, but the open entry has a remaining quantity of 8
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, 8, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 10, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One R7 finding with a difference of -2
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R7, Finding);
        Assert.AreEqual(-2, Finding."Difference (Base)", 'Remaining minus inventory');
    end;

    [Test]
    procedure PhysInventoryWithPendingAdjustmentGivesR8()
    var
        Location: Record Location;
        Item: Record Item;
        RunNo: Integer;
    begin
        // [SCENARIO] Counting while the adjustment bin is not zero: R8.
        // [GIVEN] A pending adjustment and an open warehouse physical inventory journal line
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, true);
        TestHelper.CreateItem(Item);
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 1, Today(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.AdjustmentBinCode(), -1, Today(), '');
        TestHelper.InsertWhsePhysInventoryLine(Location.Code);

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One R8 finding
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R8), 'Expected one R8 finding.');
    end;

    [Test]
    procedure LocationWithoutBinsIsNotChecked()
    var
        Location: Record Location;
        Item: Record Item;
        AnalysisRun: Record "GSO IR Analysis Run";
        RunNo: Integer;
    begin
        // [SCENARIO] Locations without Bin Mandatory have no warehouse entries and are skipped.
        // [GIVEN] A location without bins with item ledger quantity
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateLocationWithoutBins(Location);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] No location is analysed and there are no findings
        AnalysisRun.Get(RunNo);
        Assert.AreEqual(0, AnalysisRun."Locations Analysed", 'Locations analysed');
        Assert.AreEqual(0, TestHelper.CountAllFindings(RunNo), 'No findings expected.');
    end;

    [Test]
    procedure ItemFilterLimitsTheAnalysis()
    var
        Location: Record Location;
        Item: Record Item;
        OtherItem: Record Item;
        RunNo: Integer;
    begin
        // [SCENARIO] Only items in the item filter are checked.
        // [GIVEN] Two items with a difference
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.CreateItem(OtherItem);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        TestHelper.InsertItemLedgerEntry(OtherItem, Location.Code, 10, WorkDate(), '');

        // [WHEN] The analysis runs for the first item
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] Only the first item is reported
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R1), 'Only the filtered item is checked.');
    end;

    local procedure AssertRunCompleted(RunNo: Integer)
    var
        AnalysisRun: Record "GSO IR Analysis Run";
    begin
        AnalysisRun.Get(RunNo);
        Assert.AreEqual(AnalysisRun.Status::Completed, AnalysisRun.Status, AnalysisRun."Error Message");
        Assert.AreEqual(1, AnalysisRun."Locations Analysed", 'Locations analysed');
    end;
}
