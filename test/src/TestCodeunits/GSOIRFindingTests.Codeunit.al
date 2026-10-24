namespace GMSOFT.InventoryHealthCheck.Test;

using GMSOFT.InventoryHealthCheck;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.TestLibraries.Utilities;

codeunit 50755 "GSO IR Finding Tests"
{
    // The finding record and "GSO IR Finding Mgt": defaults on insert, status history,
    // advice per rule, the first-date search and the total helpers.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TestHelper: Codeunit "GSO IR Test Helper";
        FindingMgt: Codeunit "GSO IR Finding Mgt";
        NoAdviceMsg: Label 'Rule %1 has no advice.', Comment = '%1 = rule', Locked = true;
        RepeatedAdviceMsg: Label 'Rule %1 repeats the advice of another rule.', Comment = '%1 = rule', Locked = true;

    [Test]
    procedure InsertFindingSetsDefaults()
    var
        Finding: Record "GSO IR Finding";
    begin
        // [SCENARIO] A new finding always starts as New, with a creation time and the advice of its rule.
        // [GIVEN] A finding prepared with status Closed and no advice
        FindingMgt.InitFinding(Finding, 0, Enum::"GSO IR Rule"::R4, Enum::"GSO IR Severity"::Warning, '', '', '');
        Finding.Status := Finding.Status::Closed;

        // [WHEN] It is inserted
        FindingMgt.InsertFinding(Finding);

        // [THEN] Status New, creation time and R4 advice are set
        Finding.Get(Finding."Entry No.");
        Assert.AreEqual(Finding.Status::New, Finding.Status, 'Status');
        Assert.AreNotEqual(0DT, Finding."Created At", 'Created at');
        Assert.AreEqual(FindingMgt.GetAdvice(Enum::"GSO IR Rule"::R4), Finding.Advice, 'Advice');
    end;

    [Test]
    procedure InsertFindingKeepsGivenAdvice()
    var
        Finding: Record "GSO IR Finding";
    begin
        // [SCENARIO] Advice that the rule already set is not replaced by the default advice.
        // [GIVEN] A finding with its own advice
        FindingMgt.InitFinding(Finding, 0, Enum::"GSO IR Rule"::R1, Enum::"GSO IR Severity"::Critical, '', '', '');
        Finding.Advice := 'Own advice';

        // [WHEN] It is inserted
        FindingMgt.InsertFinding(Finding);

        // [THEN] The advice is kept
        Finding.Get(Finding."Entry No.");
        Assert.AreEqual('Own advice', Finding.Advice, 'Advice');
    end;

    [Test]
    procedure StatusChangeRecordsUserAndTime()
    var
        Finding: Record "GSO IR Finding";
    begin
        // [SCENARIO] Changing the status records who changed it and when.
        // [GIVEN] A new finding
        TestHelper.CreateFinding(Finding, 0, Enum::"GSO IR Rule"::R1);

        // [WHEN] The status is set to Reviewed
        Finding.Validate(Status, Finding.Status::Reviewed);

        // [THEN] User and time are recorded
        Assert.AreEqual(UpperCase(UserId()), Finding."Status Changed By", 'Status changed by');
        Assert.AreNotEqual(0DT, Finding."Status Changed At", 'Status changed at');
    end;

    [Test]
    procedure SameStatusDoesNotRecordChange()
    var
        Finding: Record "GSO IR Finding";
    begin
        // [SCENARIO] Validating the same status again is not a change.
        // [GIVEN] A new finding
        TestHelper.CreateFinding(Finding, 0, Enum::"GSO IR Rule"::R1);

        // [WHEN] The status is validated as New again
        Finding.Validate(Status, Finding.Status::New);

        // [THEN] Nothing is recorded
        Assert.AreEqual('', Finding."Status Changed By", 'Status changed by');
        Assert.AreEqual(0DT, Finding."Status Changed At", 'Status changed at');
    end;

    [Test]
    procedure EveryRuleHasItsOwnAdvice()
    var
        Advices: List of [Text];
        Advice: Text;
        RuleValue: Integer;
    begin
        // [SCENARIO] Every rule R1..R8 has advice, and no two rules share the same advice.
        // [WHEN] The advice of every rule is read
        foreach RuleValue in Enum::"GSO IR Rule".Ordinals() do
            if RuleValue <> Enum::"GSO IR Rule"::" ".AsInteger() then begin
                Advice := FindingMgt.GetAdvice(Enum::"GSO IR Rule".FromInteger(RuleValue));

                // [THEN] It is filled in and unique
                Assert.AreNotEqual('', Advice, StrSubstNo(NoAdviceMsg, Enum::"GSO IR Rule".FromInteger(RuleValue)));
                Assert.IsFalse(Advices.Contains(Advice), StrSubstNo(RepeatedAdviceMsg, Enum::"GSO IR Rule".FromInteger(RuleValue)));
                Advices.Add(Advice);
            end;
        Assert.AreEqual(8, Advices.Count(), 'Expected advice for eight rules.');
        Assert.AreEqual('', FindingMgt.GetAdvice(Enum::"GSO IR Rule"::" "), 'A blank rule has no advice.');
    end;

    [Test]
    procedure FirstDateIsTheDayTheDifferenceAppeared()
    var
        Location: Record Location;
        Item: Record Item;
    begin
        // [SCENARIO] The search walks back until the difference disappears.
        // [GIVEN] Item ledger 5 and warehouse 5 ten days ago, then item ledger 3 two days ago (difference 3)
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 5, WorkDate() - 10, '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), 5, WorkDate() - 10, '');
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 3, WorkDate() - 2, '');

        // [WHEN] / [THEN] The first date is two days ago
        Assert.AreEqual(WorkDate() - 2, FindingMgt.FindFirstDate(Item."No.", '', Location.Code, '', true, 3, 0), 'First date');
    end;

    [Test]
    procedure FirstDateIsOldestDateWhenDifferenceNeverDisappears()
    var
        Location: Record Location;
        Item: Record Item;
    begin
        // [SCENARIO] If the difference exists since the first entry, the oldest entry date is returned.
        // [GIVEN] Entries ten and two days ago, and a difference larger than all of them
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 5, WorkDate() - 10, '');
        TestHelper.InsertItemLedgerEntry(Item, Location.Code, 3, WorkDate() - 2, '');

        // [WHEN] / [THEN] The oldest date is returned
        Assert.AreEqual(WorkDate() - 10, FindingMgt.FindFirstDate(Item."No.", '', Location.Code, '', true, 100, 0), 'Oldest date');
    end;

    [Test]
    procedure FirstDateInOneBinIgnoresOtherBins()
    var
        Location: Record Location;
        Item: Record Item;
    begin
        // [SCENARIO] With a bin code, only the warehouse entries of that bin are walked back.
        // [GIVEN] STOCK-1 -2 three days ago; STOCK-2 -5 yesterday
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.StockBinCode(), -2, WorkDate() - 3, '');
        TestHelper.InsertWarehouseEntry(Item, Location.Code, TestHelper.SecondBinCode(), -5, WorkDate() - 1, '');

        // [WHEN] / [THEN] The STOCK-1 balance of -2 appeared three days ago
        Assert.AreEqual(WorkDate() - 3, FindingMgt.FindFirstDate(Item."No.", '', Location.Code, TestHelper.StockBinCode(), false, 2, 0), 'First date in STOCK-1');
    end;

    [Test]
    procedure FirstDateWithoutEntriesIsEmpty()
    var
        Location: Record Location;
        Item: Record Item;
    begin
        // [SCENARIO] Without entries there is no date to find.
        TestHelper.CreateBinLocation(Location, false);
        TestHelper.CreateItem(Item);

        Assert.AreEqual(0D, FindingMgt.FindFirstDate(Item."No.", '', Location.Code, '', true, 1, 0), 'No entries, no date');
    end;

    [Test]
    procedure TotalsAddUpPerKey()
    var
        Totals: Dictionary of [Text, Decimal];
    begin
        // [SCENARIO] AddToTotal sums per key; GetTotal returns 0 for an unknown key.
        FindingMgt.AddToTotal(Totals, FindingMgt.ItemKey('A', ''), 2);
        FindingMgt.AddToTotal(Totals, FindingMgt.ItemKey('A', ''), 3.5);
        FindingMgt.AddToTotal(Totals, FindingMgt.ItemKey('A', 'V1'), 1);

        Assert.AreEqual(5.5, FindingMgt.GetTotal(Totals, FindingMgt.ItemKey('A', '')), 'Total of A');
        Assert.AreEqual(1, FindingMgt.GetTotal(Totals, FindingMgt.ItemKey('A', 'V1')), 'Total of A, variant V1');
        Assert.AreEqual(0, FindingMgt.GetTotal(Totals, FindingMgt.ItemKey('B', '')), 'Unknown key');
    end;
}
