namespace GMSOFT.InventoryHealthCheck.Test;

using GMSOFT.InventoryHealthCheck;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.TestLibraries.Utilities;

codeunit 50104 "GSO IR Analysis Run Tests"
{
    // The analysis run log: what a run records, failed runs, location filters, totals and deletion.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        TestHelper: Codeunit "GSO IR Test Helper";

    [Test]
    procedure CompletedRunRecordsFiltersUserAndTimes()
    var
        Location: Record Location;
        Item: Record Item;
        AnalysisRun: Record "GSO IR Analysis Run";
        RunNo: Integer;
    begin
        // [SCENARIO] A completed run logs its filters, the user and when it ran.
        // [GIVEN] A balanced bin location
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [THEN] The run is completed and logs the filters, the user and the times
        AnalysisRun.Get(RunNo);
        Assert.AreEqual(AnalysisRun.Status::Completed, AnalysisRun.Status, AnalysisRun."Error Message");
        Assert.AreEqual(Location.Code, AnalysisRun."Location Filter", 'Location filter');
        Assert.AreEqual(Item."No.", AnalysisRun."Item Filter", 'Item filter');
        Assert.AreEqual(UpperCase(UserId()), AnalysisRun."User ID", 'User ID');
        Assert.AreNotEqual(0DT, AnalysisRun."Started At", 'Started at');
        Assert.IsTrue(AnalysisRun."Finished At" >= AnalysisRun."Started At", 'The run cannot finish before it starts.');
        Assert.AreEqual('', AnalysisRun."Error Message", 'A completed run has no error message.');
    end;

    [Test]
    procedure LongItemFilterIsUsedInFull()
    var
        Location: Record Location;
        Item: Record Item;
        AnalysisRun: Record "GSO IR Analysis Run";
        ItemFilter: Text;
        Counter: Integer;
        RunNo: Integer;
    begin
        // [SCENARIO] An item filter longer than the run log keeps still checks every item in it.
        // [GIVEN] An item with a difference, listed after more than 250 characters of other item numbers
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        repeat
            Counter += 1;
            ItemFilter += 'NOITEM' + Format(Counter, 0, 9) + '|';
        until StrLen(ItemFilter) > MaxStrLen(AnalysisRun."Item Filter");
        ItemFilter += Item."No.";

        // [WHEN] The analysis runs with the long filter
        RunNo := TestHelper.RunAnalysis(Location.Code, ItemFilter);

        // [THEN] The item at the end is checked, and the log keeps the start of the filter
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R1), 'The item at the end of the long filter must be checked.');
        AnalysisRun.Get(RunNo);
        Assert.AreEqual(AnalysisRun.Status::Completed, AnalysisRun.Status, AnalysisRun."Error Message");
        Assert.AreEqual(CopyStr(ItemFilter, 1, MaxStrLen(AnalysisRun."Item Filter")), AnalysisRun."Item Filter", 'The log keeps the first 250 characters.');
    end;

    [Test]
    procedure FilterOnOtherItemFieldsSelectsOnlyMatchingItems()
    var
        Location: Record Location;
        Item: Record Item;
        OtherItem: Record Item;
        ItemCategory: Record "Item Category";
        Finding: Record "GSO IR Finding";
        AnalysisMgt: Codeunit "GSO IR Analysis Mgt";
        RunNo: Integer;
    begin
        // [SCENARIO] A request page filter on another item field (Item Category Code) limits the analysis to those items.
        // [GIVEN] Two items with the same difference; only the first has item category X
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        LibraryInventory.CreateItemCategory(ItemCategory);
        TestHelper.CreateItem(Item);
        Item."Item Category Code" := ItemCategory.Code;
        Item.Modify(false);
        TestHelper.CreateItem(OtherItem);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        TestHelper.InsertItemLedgerEntry(OtherItem, Location.Code, 10, WorkDate(), '');

        // [WHEN] The analysis runs for the location and the items of category X
        Location.SetRange(Code, Location.Code);
        Item.Reset();
        Item.SetRange("Item Category Code", ItemCategory.Code);
        RunNo := AnalysisMgt.RunAnalysisForSelection(Location, Item);

        // [THEN] Only the item of category X is reported
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R1), 'Only the item in the category must be checked.');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R1, Finding);
        Assert.AreEqual(Item."No.", Finding."Item No.", 'The item outside the category must not be checked.');
    end;

    [Test]
    procedure FilterThatMatchesNothingStops()
    var
        Location: Record Location;
        Item: Record Item;
        ItemCategory: Record "Item Category";
        AnalysisMgt: Codeunit "GSO IR Analysis Mgt";
    begin
        // [SCENARIO] A filter that selects no item must not silently run on every item.
        // [GIVEN] An item category without items
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        LibraryInventory.CreateItemCategory(ItemCategory);
        Location.SetRange(Code, Location.Code);
        Item.SetRange("Item Category Code", ItemCategory.Code);

        // [WHEN] The analysis runs for that category
        asserterror AnalysisMgt.RunAnalysisForSelection(Location, Item);

        // [THEN] It stops with an error
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure FailedRunIsLoggedAndRolledBack()
    var
        Location: Record Location;
        Item: Record Item;
        AnalysisRun: Record "GSO IR Analysis Run";
        FailingSubscriber: Codeunit "GSO IR Failing Subscriber";
        RunNo: Integer;
    begin
        // [SCENARIO] An error during the analysis marks the run as failed and keeps no partial findings.
        // [GIVEN] A difference that gives a finding, and a subscriber that fails when the finding is written
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        BindSubscription(FailingSubscriber);

        // [WHEN] The analysis runs
        RunNo := TestHelper.RunAnalysis(Location, Item);
        UnbindSubscription(FailingSubscriber);

        // [THEN] The run is failed, logs the error and has no findings
        AnalysisRun.Get(RunNo);
        Assert.AreEqual(AnalysisRun.Status::Failed, AnalysisRun.Status, 'Status');
        Assert.AreEqual(FailingSubscriber.FailureText(), AnalysisRun."Error Message", 'Error message');
        Assert.AreNotEqual(0DT, AnalysisRun."Finished At", 'A failed run is finished too.');
        Assert.AreEqual(0, TestHelper.CountAllFindings(RunNo), 'The findings of a failed run are rolled back.');
    end;

    [Test]
    procedure FailedRunFailsBackgroundCallerAndStaysLogged()
    var
        Location: Record Location;
        Item: Record Item;
        AnalysisRun: Record "GSO IR Analysis Run";
        AnalysisMgt: Codeunit "GSO IR Analysis Mgt";
        FailingSubscriber: Codeunit "GSO IR Failing Subscriber";
        RunNo: Integer;
    begin
        // [SCENARIO] A background caller (job queue) gets an error for a failed analysis, and the run stays logged as failed.
        // [GIVEN] An analysis that fails when it writes its first finding
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        BindSubscription(FailingSubscriber);
        RunNo := TestHelper.RunAnalysis(Location, Item);
        UnbindSubscription(FailingSubscriber);

        // [WHEN] The background caller checks the result
        asserterror AnalysisMgt.CheckRunSucceeded(RunNo);

        // [THEN] It fails with the analysis error, and the failed run is still in the log
        Assert.ExpectedError(FailingSubscriber.FailureText());
        AnalysisRun.Get(RunNo);
        Assert.AreEqual(AnalysisRun.Status::Failed, AnalysisRun.Status, 'The failed run must stay logged after the error.');
    end;

    [Test]
    procedure CompletedRunPassesBackgroundCheck()
    var
        Location: Record Location;
        Item: Record Item;
        AnalysisMgt: Codeunit "GSO IR Analysis Mgt";
        RunNo: Integer;
    begin
        // [SCENARIO] A completed analysis, even with findings, is a success for a background caller.
        // [GIVEN] A completed run with an R1 finding
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        RunNo := TestHelper.RunAnalysis(Location, Item);

        // [WHEN] The background caller checks the result
        AnalysisMgt.CheckRunSucceeded(RunNo);

        // [THEN] No error is raised
        Assert.AreEqual(1, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R1), 'Findings do not make the run fail.');
    end;

    [Test]
    procedure RunCountsFindingsBySeverity()
    var
        Location: Record Location;
        Item: Record Item;
        OtherItem: Record Item;
        AnalysisRun: Record "GSO IR Analysis Run";
        RunNo: Integer;
    begin
        // [SCENARIO] The run totals count the findings per severity.
        // [GIVEN] Directed location. Item: item ledger 10; STOCK-1 13, STOCK-2 -1, adjustment bin -2 today
        //         (R3 info, R4 warning). Other item: item ledger 5, no warehouse entries (R1 critical).
        TestHelper.SetMaxPendingAdjustmentAge(30);
        TestHelper.CreateBinLocation(Location, true);
        TestHelper.CreateItem(Item);
        TestHelper.CreateItem(OtherItem);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 13, Today(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.SecondBinCode(), -1, Today(), '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.AdjustmentBinCode(), -2, Today(), '');
        TestHelper.InsertItemLedgerEntry(OtherItem, Location.Code, 5, WorkDate(), '');

        // [WHEN] The analysis runs for both items
        RunNo := TestHelper.RunAnalysis(Location.Code, StrSubstNo('%1|%2', Item."No.", OtherItem."No."));

        // [THEN] One critical, one warning, one info
        AnalysisRun.Get(RunNo);
        AnalysisRun.CalcFields("No. of Findings", "No. of Critical", "No. of Warnings", "No. of Info");
        Assert.AreEqual(1, AnalysisRun."No. of Critical", 'Critical');
        Assert.AreEqual(1, AnalysisRun."No. of Warnings", 'Warnings');
        Assert.AreEqual(1, AnalysisRun."No. of Info", 'Info');
        Assert.AreEqual(3, AnalysisRun."No. of Findings", 'Findings');
    end;

    [Test]
    procedure SeveralLocationsInOneRun()
    var
        Location: Record Location;
        OtherLocation: Record Location;
        Item: Record Item;
        AnalysisRun: Record "GSO IR Analysis Run";
        RunNo: Integer;
    begin
        // [SCENARIO] A location filter with two locations checks both.
        // [GIVEN] Two bin locations, each with item ledger 10 and no warehouse entries
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateBinLocation(OtherLocation, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        TestHelper.InsertItemLedgerEntry(Item, OtherLocation.Code, 10, WorkDate(), '');

        // [WHEN] The analysis runs for both locations
        RunNo := TestHelper.RunAnalysis(StrSubstNo('%1|%2', Location.Code, OtherLocation.Code), Item."No.");

        // [THEN] Two locations analysed and one R1 per location
        AnalysisRun.Get(RunNo);
        Assert.AreEqual(2, AnalysisRun."Locations Analysed", 'Locations analysed');
        Assert.AreEqual(2, TestHelper.CountFindings(RunNo, Enum::"GSO IR Rule"::R1), 'Expected one R1 finding per location.');
    end;

    [Test]
    procedure EmptyLocationFilterUsesSetup()
    var
        Location: Record Location;
        OtherLocation: Record Location;
        Item: Record Item;
        AnalysisRun: Record "GSO IR Analysis Run";
        Finding: Record "GSO IR Finding";
        RunNo: Integer;
    begin
        // [SCENARIO] Without a location filter, the run uses the location filter from the setup.
        // [GIVEN] Two locations with a difference; the setup filter names only the second
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateBinLocation(OtherLocation, false);
        TestHelper.SetLocationFilter(OtherLocation.Code);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        TestHelper.InsertItemLedgerEntry(Item, OtherLocation.Code, 10, WorkDate(), '');

        // [WHEN] The analysis runs without a location filter
        RunNo := TestHelper.RunAnalysis('', Item."No.");

        // [THEN] Only the second location is checked and the run logs the setup filter
        AnalysisRun.Get(RunNo);
        Assert.AreEqual(OtherLocation.Code, AnalysisRun."Location Filter", 'The run logs the filter it used.');
        Assert.AreEqual(1, AnalysisRun."Locations Analysed", 'Locations analysed');
        TestHelper.GetFinding(RunNo, Enum::"GSO IR Rule"::R1, Finding);
        Assert.AreEqual(OtherLocation.Code, Finding."Location Code", 'Location code');
        Assert.AreEqual(1, TestHelper.CountAllFindings(RunNo), 'Only the setup location is checked.');
    end;

    [Test]
    procedure DeletingRunDeletesOnlyItsFindings()
    var
        Location: Record Location;
        Item: Record Item;
        AnalysisRun: Record "GSO IR Analysis Run";
        FirstRunNo: Integer;
        SecondRunNo: Integer;
    begin
        // [SCENARIO] Deleting a run deletes its findings and leaves other runs alone.
        // [GIVEN] Two runs with one R1 finding each
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 10, WorkDate(), '');
        FirstRunNo := TestHelper.RunAnalysis(Location, Item);
        SecondRunNo := TestHelper.RunAnalysis(Location, Item);

        // [WHEN] The first run is deleted
        AnalysisRun.Get(FirstRunNo);
        AnalysisRun.Delete(true);

        // [THEN] Its findings are gone; the second run keeps its finding
        Assert.AreEqual(0, TestHelper.CountAllFindings(FirstRunNo), 'The findings of the deleted run must be deleted.');
        Assert.AreEqual(1, TestHelper.CountAllFindings(SecondRunNo), 'Other runs keep their findings.');
    end;
}
