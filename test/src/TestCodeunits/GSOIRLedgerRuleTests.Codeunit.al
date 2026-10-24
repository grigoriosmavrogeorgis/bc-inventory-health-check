namespace GMSOFT.InventoryHealthCheck.Test;

using GMSOFT.InventoryHealthCheck;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.TestLibraries.Utilities;

codeunit 50752 "GSO IR Ledger Rule Tests"
{
    // Edge cases of the item ledger rules (R1, R2, R7) that "GSO IR Analysis Tests" does not cover:
    // tolerance, warehouse surplus, variants, serial and package numbers, and the First Date switch.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        TestHelper: Codeunit "GSO IR Test Helper";

    [Test]
    procedure DifferenceWithinToleranceIsNotReported()
    var
        Location: Record Location;
        Item: Record Item;
        RunNo: Integer;
    begin
        // [SCENARIO] A difference that is not larger than the tolerance gives no finding.
        // [GIVEN] Tolerance 0.5, item ledger 10, warehouse 9.6
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.SetTolerance(0.5);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 9.6, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] No finding
        Assert.AreEqual(0, TestHelper.CountAllFindings(RunNo), 'A difference within the tolerance must not be reported.');
    end;

    [Test]
    procedure DifferenceAboveToleranceIsReported()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] A difference larger than the tolerance is still reported in full.
        // [GIVEN] Tolerance 1, item ledger 10, warehouse 8
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.SetTolerance(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 8, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One R1 finding with the whole difference of 2
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R1), 'Expected one R1 finding.');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R1, Finding);
        Assert.AreEqual(2, Finding."Difference (Base)", 'The tolerance must not be subtracted from the difference.');
    end;

    [Test]
    procedure WarehouseWithoutItemLedgerGivesR1()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] The bins hold quantity that the item ledger does not have: R1 with a negative difference.
        // [GIVEN] No item ledger entries, warehouse 4
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 4, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One critical R1 finding: item ledger 0, warehouse 4, difference -4
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R1, Finding);
        Assert.AreEqual(Finding.Severity::Critical, Finding.Severity, 'R1 must be critical.');
        Assert.AreEqual(0, Finding."Item Ledger Qty. (Base)", 'Item ledger quantity');
        Assert.AreEqual(4, Finding."Warehouse Qty. (Base)", 'Warehouse quantity');
        Assert.AreEqual(-4, Finding."Difference (Base)", 'Difference');
        Assert.AreNotEqual('', Finding."Probable Cause", 'The finding must explain the probable cause.');
    end;

    [Test]
    procedure DifferenceIsReportedPerVariant()
    var
        Location: Record Location;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] Only the variant with the difference is reported, with its variant code.
        // [GIVEN] Without variant: item ledger 5, warehouse 5; variant V: item ledger 5, warehouse 3
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 5, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 5, WorkDate(), '');
        TestHelper.InsertTrackedItemLedgerEntry(Item, Location.Code, ItemVariant.Code, 5, WorkDate(), '', '', '');
        TestHelper.InsertTrackedWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), ItemVariant.Code, 3, WorkDate(), '', '', '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One R1 finding for the variant, with a difference of 2, and no R2 for the same variant
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R1), 'Expected one R1 finding.');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R1, Finding);
        Assert.AreEqual(ItemVariant.Code, Finding."Variant Code", 'Variant code');
        Assert.AreEqual(2, Finding."Difference (Base)", 'Difference');
        Assert.AreEqual(0, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R2), 'An unbalanced variant is reported by R1 only.');
    end;

    [Test]
    procedure SerialNoMismatchGivesR2()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] The item total agrees but the serial numbers differ: R2 per serial number.
        // [GIVEN] Item ledger SN1 and SN2; warehouse SN1 and SN3
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateTrackedItem(Item, true, true, true);
        TestHelper.InsertTrackedItemLedgerEntry(Item, Location.Code, '', 1, WorkDate(), '', 'SN1', '');
        TestHelper.InsertTrackedItemLedgerEntry(Item, Location.Code, '', 1, WorkDate(), '', 'SN2', '');
        TestHelper.InsertTrackedWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), '', 1, WorkDate(), '', 'SN1', '');
        TestHelper.InsertTrackedWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), '', 1, WorkDate(), '', 'SN3', '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] No R1; R2 for SN2 (item ledger only) and SN3 (warehouse only)
        Assert.AreEqual(0, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R1), 'The item total agrees.');
        Assert.AreEqual(2, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R2), 'Expected one R2 finding per serial number.');

        Finding.SetRange("Serial No.", 'SN2');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R2, Finding);
        Assert.AreEqual('', Finding."Lot No.", 'Lot No.');
        Assert.AreEqual('', Finding."Package No.", 'Package No.');
        Assert.AreEqual(1, Finding."Difference (Base)", 'SN2 exists in the item ledger only.');

        Finding.SetRange("Serial No.", 'SN3');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R2, Finding);
        Assert.AreEqual(-1, Finding."Difference (Base)", 'SN3 exists in the warehouse only.');
    end;

    [Test]
    procedure PackageNoMismatchGivesR2()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] The item total agrees but the package numbers differ: R2 per package.
        // [GIVEN] Item ledger PKG1 5 and PKG2 5; warehouse PKG1 7 and PKG2 3
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateTrackedItem(Item, true, true, true);
        TestHelper.InsertTrackedItemLedgerEntry(Item, Location.Code, '', 5, WorkDate(), '', '', 'PKG1');
        TestHelper.InsertTrackedItemLedgerEntry(Item, Location.Code, '', 5, WorkDate(), '', '', 'PKG2');
        TestHelper.InsertTrackedWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), '', 7, WorkDate(), '', '', 'PKG1');
        TestHelper.InsertTrackedWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), '', 3, WorkDate(), '', '', 'PKG2');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] Two R2 findings; PKG2 has item ledger 5, warehouse 3, difference 2
        Assert.AreEqual(2, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R2), 'Expected one R2 finding per package.');
        Finding.SetRange("Package No.", 'PKG2');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R2, Finding);
        Assert.AreEqual('', Finding."Serial No.", 'Serial No.');
        Assert.AreEqual(5, Finding."Item Ledger Qty. (Base)", 'Item ledger quantity');
        Assert.AreEqual(3, Finding."Warehouse Qty. (Base)", 'Warehouse quantity');
        Assert.AreEqual(2, Finding."Difference (Base)", 'Difference');
    end;

    [Test]
    procedure TrackingDifferenceOnUnbalancedItemGivesR1Only()
    var
        Location: Record Location;
        Item: Record Item;
        RunNo: Integer;
    begin
        // [SCENARIO] When the item total already differs, the lot difference is not reported again as R2.
        // [GIVEN] Item ledger LOT1 5, warehouse LOT1 3
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateTrackedItem(Item, true, true, true);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 5, WorkDate(), 'LOT1');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 3, WorkDate(), 'LOT1');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] One R1 and no R2
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R1), 'Expected one R1 finding.');
        Assert.AreEqual(0, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R2), 'R2 must not repeat an R1 difference.');
    end;

    [Test]
    procedure LotsWithoutWarehouseTrackingAreNotR2()
    var
        Location: Record Location;
        Item: Record Item;
        RunNo: Integer;
    begin
        // [SCENARIO] A lot-tracked item without Lot Warehouse Tracking has no lots on its warehouse entries; that is not R2.
        // [GIVEN] Item tracking code without warehouse tracking; item ledger LOT1 5 and LOT2 5; warehouse 10 without lot
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateTrackedItem(Item, false, false, false);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 5, WorkDate(), 'LOT1');
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 5, WorkDate(), 'LOT2');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 10, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] No findings at all
        Assert.AreEqual(0, TestHelper.CountAllFindings(RunNo), 'Lots that the warehouse does not track must not be compared.');
    end;

    [Test]
    procedure TrackingDifferenceHasFirstDate()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] An R2 finding carries the date on which the lot difference appeared.
        // [GIVEN] LOT1 5 and LOT2 5 agree three days ago; yesterday the warehouse moved 2 from LOT2 to LOT1
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateTrackedItem(Item, true, true, true);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 5, WorkDate() - 3, 'LOT1');
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 5, WorkDate() - 3, 'LOT2');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 5, WorkDate() - 3, 'LOT1');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 5, WorkDate() - 3, 'LOT2');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 2, WorkDate() - 1, 'LOT1');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), -2, WorkDate() - 1, 'LOT2');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] The R2 finding for LOT1 is dated yesterday
        Finding.SetRange("Lot No.", 'LOT1');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R2, Finding);
        Assert.AreEqual(-2, Finding."Difference (Base)", 'Difference of LOT1');
        Assert.AreEqual(WorkDate() - 1, Finding."First Date", 'First date of the lot difference');
    end;

    [Test]
    procedure KnownApplicationIssueRunsInItalian()
    var
        Location: Record Location;
        Item: Record Item;
        AnalysisRun: Record "GSO IR Analysis Run";
        RunNo: Integer;
        OldLanguage: Integer;
    begin
        // [SCENARIO] A translated cause longer than the field must not fail the run (the Italian R7 text was 279 characters).
        // [GIVEN] Inventory 0 with an open inbound and an open outbound entry; the user works in Italian
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 5, WorkDate(), '');
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, -5, WorkDate(), '');
        OldLanguage := GlobalLanguage();
        GlobalLanguage(1040);

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);
        GlobalLanguage(OldLanguage);

        // [THEN] The run completes with the R7 finding
        AnalysisRun.Get(RunNo);
        Assert.AreEqual(AnalysisRun.Status::Completed, AnalysisRun.Status, AnalysisRun."Error Message");
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R7), 'Expected the known application issue.');
    end;

    [Test]
    procedure FirstDateIsEmptyWhenSwitchedOff()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] With Find First Date off, R1 findings carry no first date.
        // [GIVEN] Find First Date off; item ledger 10 posted 4 days ago, no warehouse entries
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.SetFindFirstDate(false);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate() - 4, '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] The R1 finding has no first date
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R1, Finding);
        Assert.AreEqual(0D, Finding."First Date", 'First date must be empty when the setup switches it off.');
    end;

    [Test]
    procedure ClosedEntriesGiveNoFindings()
    var
        Location: Record Location;
        Item: Record Item;
        RunNo: Integer;
    begin
        // [SCENARIO] Fully applied (closed) entries with zero inventory are not R7.
        // [GIVEN] +5 and -5 in the item ledger, both closed (remaining quantity 0)
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 5, 0, WorkDate(), '');
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, -5, 0, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] No findings
        Assert.AreEqual(0, TestHelper.CountAllFindings(RunNo), 'Closed entries must not be reported.');
    end;

    [Test]
    procedure InventoryWithoutOpenEntriesGivesR7()
    var
        Location: Record Location;
        Item: Record Item;
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] Inventory whose entries are all closed is R7: the open entries must add up to the inventory.
        // [GIVEN] Item ledger +10 but closed (remaining quantity 0), warehouse 10
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, 0, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 10, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] No R1, one R7: remaining quantity 0 against inventory 10
        Assert.AreEqual(0, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R1), 'Item ledger and warehouse agree.');
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R7), 'Inventory without open entries must be R7.');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R7, Finding);
        Assert.AreEqual(10, Finding."Item Ledger Qty. (Base)", 'Inventory');
        Assert.AreEqual(-10, Finding."Difference (Base)", 'Remaining quantity minus inventory');
    end;

    [Test]
    procedure OpenInboundEntryOnlyIsNotR7()
    var
        Location: Record Location;
        Item: Record Item;
        RunNo: Integer;
    begin
        // [SCENARIO] Open inbound entries that match the inventory are normal stock, not R7.
        // [GIVEN] Two open inbound entries of 3 and 4 with matching warehouse quantity
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 3, WorkDate(), '');
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 4, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 7, WorkDate(), '');

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] No R7
        Assert.AreEqual(0, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R7), 'Open stock that matches the inventory is not R7.');
    end;
}
