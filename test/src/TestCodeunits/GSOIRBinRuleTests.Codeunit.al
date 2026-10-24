namespace GMSOFT.InventoryHealthCheck.Test;

using GMSOFT.InventoryHealthCheck;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.TestLibraries.Utilities;

codeunit 50753 "GSO IR Bin Rule Tests"
{
    // Edge cases of the warehouse rules (R3, R4, R5, R6, R8) that "GSO IR Analysis Tests" does not cover.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        TestHelper: Codeunit "GSO IR Test Helper";

    [Test]
    procedure QuantityWithoutBinCodeGivesR6()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] Warehouse entries without a bin code at a bin mandatory location: R6.
        // [GIVEN] Item ledger 4, warehouse 4 without a bin code
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 4, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, '', 4, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One R6 warning without a bin code
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R6), 'Expected one R6 finding.');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R6, Finding);
        Assert.AreEqual('', Finding."Bin Code", 'Bin code');
        Assert.AreEqual(4, Finding."Warehouse Qty. (Base)", 'Warehouse quantity');
        Assert.AreEqual(Finding.Severity::Warning, Finding.Severity, 'Severity');
    end;

    [Test]
    procedure QuantityInBlockedBinGivesR6()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] Quantity in a bin that is blocked for movement: R6.
        // [GIVEN] Item ledger 4, warehouse 4 in STOCK-1, and STOCK-1 blocked for all movement
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 4, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 4, WorkDate(), '');
        TestHelper.BlockBin(Location.Code, TestHelper.StockBinCode());

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One R6 info finding on the blocked bin (stock in a blocked bin is usually intended)
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R6), 'Expected one R6 finding.');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R6, Finding);
        Assert.AreEqual(TestHelper.StockBinCode(), Finding."Bin Code", 'Bin code');
        Assert.AreEqual(Finding.Severity::Info, Finding.Severity, 'Stock in a blocked bin is info.');
    end;

    [Test]
    procedure MissingBinContentGivesR9()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] Stock in a bin whose bin content line is missing: the ledgers agree, but the stock cannot be picked.
        // [GIVEN] Item ledger 4, warehouse 4 in STOCK-1, and the bin content line of STOCK-1 deleted
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 4, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 4, WorkDate(), '');
        TestHelper.DeleteBinContent(Location.Code, TestHelper.StockBinCode(), Item);

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One R9 warning for the bin and unit, and nothing else
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R9), 'Expected one R9 finding.');
        Assert.AreEqual(1, TestHelper.CountAllFindings(RunNo), 'Only the missing bin content is reported.');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R9, Finding);
        Assert.AreEqual(TestHelper.StockBinCode(), Finding."Bin Code", 'Bin code');
        Assert.AreEqual(Item."Base Unit of Measure", Finding."Unit of Measure Code", 'Unit of measure code');
        Assert.AreEqual(4, Finding."Warehouse Qty. (Base)", 'Warehouse quantity');
        Assert.AreEqual(Finding.Severity::Warning, Finding.Severity, 'Severity');
    end;

    [Test]
    procedure QuantityInBinBlockedForInboundIsNotReported()
    var
        Location: Record Location;
        Item: Record Item;
        RunNo: Integer;
    begin
        // [SCENARIO] A bin blocked for inbound movement only can still be picked from, so its stock is fine.
        // [GIVEN] Item ledger 4, warehouse 4 in STOCK-1, and STOCK-1 blocked for inbound movement
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 4, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 4, WorkDate(), '');
        TestHelper.BlockBinForInbound(Location.Code, TestHelper.StockBinCode());

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] No findings
        Assert.AreEqual(0, TestHelper.CountAllFindings(RunNo), 'A bin blocked for inbound only must not be reported.');
    end;

    [Test]
    procedure NegativeResidueWithinToleranceIsNotR4()
    var
        Location: Record Location;
        Item: Record Item;
        RunNo: Integer;
    begin
        // [SCENARIO] A rounding residue that is not larger than the tolerance is not negative bin content.
        // [GIVEN] Tolerance 0.001; STOCK-1 -0.0005 and STOCK-2 +0.0005, no item ledger quantity
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.SetTolerance(0.001);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), -0.0005, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.SecondBinCode(), 0.0005, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] No R4
        Assert.AreEqual(0, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R4), 'A residue within the tolerance is not R4.');
    end;

    [Test]
    procedure EmptyBlockedBinIsNotReported()
    var
        Location: Record Location;
        Item: Record Item;
        RunNo: Integer;
    begin
        // [SCENARIO] A blocked bin that holds nothing is fine.
        // [GIVEN] STOCK-1 received 4 and gave 4 away, and is blocked
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 4, 0, WorkDate(), '');
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, -4, 0, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 4, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), -4, WorkDate(), '');
        TestHelper.BlockBin(Location.Code, TestHelper.StockBinCode());

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] No findings
        Assert.AreEqual(0, TestHelper.CountAllFindings(RunNo), 'An empty blocked bin must not be reported.');
    end;

    [Test]
    procedure MissingUnitOfMeasureGivesR5()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] Warehouse entries use a unit of measure that the item no longer has: R5.
        // [GIVEN] A warehouse entry in unit GONE, which is not an item unit of measure
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 4, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 'GONE', 1, 4, 4, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One R5 finding for unit GONE
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R5), 'Expected one R5 finding.');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R5, Finding);
        Assert.AreEqual('GONE', Finding."Unit of Measure Code", 'Unit of measure code');
    end;

    [Test]
    procedure ToleranceAppliesToBaseQuantityCheck()
    var
        Location: Record Location;
        Item: Record Item;
        RunNo: Integer;
    begin
        // [SCENARIO] A base quantity difference within the tolerance is not R5.
        // [GIVEN] Tolerance 2; a warehouse entry with Quantity 4 at 1 per unit but Qty. (Base) 5
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.SetTolerance(2);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 5, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), Item."Base Unit of Measure", 1, 4, 5, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] No R5
        Assert.AreEqual(0, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R5), 'A difference within the tolerance is not R5.');
    end;

    [Test]
    procedure NegativeAdjustmentBinIsNotR4()
    var
        Location: Record Location;
        Item: Record Item;
        RunNo: Integer;
    begin
        // [SCENARIO] The adjustment bin is negative by design; it is R3, never R4 or R6.
        // [GIVEN] Directed location: STOCK-1 +2 and adjustment bin -2, registered today
        TestHelper.SetMaxPendingAdjustmentAge(30);
        TestHelper.CreateBinLocation(Location, true);
        TestHelper.CreateItem(Item);
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 2, Today(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.AdjustmentBinCode(), -2, Today(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One R3 and nothing else
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R3), 'Expected one R3 finding.');
        Assert.AreEqual(0, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R4), 'The adjustment bin is not a negative bin content.');
        Assert.AreEqual(0, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R6), 'The adjustment bin is a valid bin.');
        Assert.AreEqual(1, TestHelper.CountAllFindings(RunNo), 'Only the pending adjustment is reported.');
    end;

    [Test]
    procedure PostedAdjustmentIsNotPending()
    var
        Location: Record Location;
        Item: Record Item;
        RunNo: Integer;
    begin
        // [SCENARIO] After Calculate Warehouse Adjustment is posted, the adjustment bin is zero and nothing is reported.
        // [GIVEN] STOCK-1 +2 and adjustment bin -2, then the posted adjustment: item ledger +2 and adjustment bin +2
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, true);
        TestHelper.CreateItem(Item);
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 2, WorkDate() - 3, '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.AdjustmentBinCode(), -2, WorkDate() - 3, '');
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 2, WorkDate() - 2, '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.AdjustmentBinCode(), 2, WorkDate() - 2, '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] No findings
        Assert.AreEqual(0, TestHelper.CountAllFindings(RunNo), 'A posted adjustment leaves nothing to report.');
    end;

    [Test]
    procedure PendingAdjustmentAtMaximumAgeIsStillInfo()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] An adjustment exactly as old as the maximum age is still info; only older ones are warnings.
        // [GIVEN] Maximum age 5 days, adjustment registered 5 days ago
        TestHelper.SetMaxPendingAdjustmentAge(5);
        TestHelper.CreateBinLocation(Location, true);
        TestHelper.CreateItem(Item);
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 3, Today() - 5, '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.AdjustmentBinCode(), -3, Today() - 5, '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] The R3 finding is info and dated 5 days ago
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R3, Finding);
        Assert.AreEqual(Today() - 5, Finding."First Date", 'First date of the pending adjustment');
        Assert.AreEqual(Finding.Severity::Info, Finding.Severity, 'An adjustment at the maximum age is info.');
    end;

    [Test]
    procedure OppositePendingAdjustmentsPerLotAreReportedApart()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] Pending adjustments of two lots that cancel each other out are each R3, and R8 still sees them.
        // [GIVEN] Directed location with LOT2 in stock; a count found 5 of LOT1 and lost the 5 of LOT2,
        //         so the adjustment bin holds LOT1 -5 and LOT2 +5 (item total 0); a physical inventory journal is open
        TestHelper.SetMaxPendingAdjustmentAge(30);
        TestHelper.CreateBinLocation(Location, true);
        TestHelper.CreateTrackedItem(Item, true, true, true);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 5, WorkDate(), 'LOT2');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 5, WorkDate(), 'LOT2');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), -5, Today(), 'LOT2');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.AdjustmentBinCode(), 5, Today(), 'LOT2');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 5, Today(), 'LOT1');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.AdjustmentBinCode(), -5, Today(), 'LOT1');
        TestHelper.InsertWhsePhysInventoryLine(Location.Code);

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One R3 per lot, one R8, and no R1 or R2 (the warehouse totals include the adjustment bin)
        Assert.AreEqual(2, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R3), 'Expected one R3 finding per lot.');
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R8), 'The pending adjustments must still block counting.');
        Assert.AreEqual(0, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R1), 'No R1');
        Assert.AreEqual(0, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R2), 'No R2');
        Finding.SetRange("Lot No.", 'LOT1');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R3, Finding);
        Assert.AreEqual(-5, Finding."Warehouse Qty. (Base)", 'Adjustment bin balance of LOT1');
        Assert.AreEqual(5, Finding."Difference (Base)", 'Quantity of LOT1 to post to the item ledger');
        Assert.AreEqual(Today(), Finding."First Date", 'First date of the LOT1 adjustment');
    end;

    [Test]
    procedure OppositePendingAdjustmentsPerUnitOfMeasureAreReportedApart()
    var
        Location: Record Location;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] Pending adjustments in two units of measure that cancel each other out in the base unit are each R3.
        // [GIVEN] Directed location, unit BOX of 12; the adjustment bin holds +12 in the base unit and -1 BOX
        TestHelper.SetMaxPendingAdjustmentAge(30);
        TestHelper.CreateBinLocation(Location, true);
        TestHelper.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 12);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 12, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 12, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), -12, Today(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.AdjustmentBinCode(), 12, Today(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), ItemUnitOfMeasure.Code, 12, 1, 12, Today(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.AdjustmentBinCode(), ItemUnitOfMeasure.Code, 12, -1, -12, Today(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One R3 per unit of measure
        Assert.AreEqual(2, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R3), 'Expected one R3 finding per unit of measure.');
        Finding.SetRange("Unit of Measure Code", ItemUnitOfMeasure.Code);
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R3, Finding);
        Assert.AreEqual(-12, Finding."Warehouse Qty. (Base)", 'Adjustment bin balance of the box unit');
    end;

    [Test]
    procedure PhysInventoryWithoutPendingAdjustmentIsNotR8()
    var
        Location: Record Location;
        Item: Record Item;
        RunNo: Integer;
    begin
        // [SCENARIO] Counting is fine when the adjustment bin is zero.
        // [GIVEN] A balanced directed location and an open warehouse physical inventory journal line
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, true);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 1, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 1, WorkDate(), '');
        TestHelper.InsertWhsePhysInventoryLine(Location.Code);

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] No findings
        Assert.AreEqual(0, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R8), 'No pending adjustment, so no R8.');
        Assert.AreEqual(0, TestHelper.CountAllFindings(RunNo), 'No findings expected.');
    end;

    [Test]
    procedure NonDirectedLocationNeedsNoAdjustmentBin()
    var
        Location: Record Location;
        Item: Record Item;
        RunNo: Integer;
    begin
        // [SCENARIO] Only directed put-away and pick locations need an adjustment bin.
        // [GIVEN] A bin location without directed put-away and pick and without adjustment bin
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] No R3
        Assert.AreEqual(0, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R3), 'A bin location without directed put-away and pick needs no adjustment bin.');
    end;
}
