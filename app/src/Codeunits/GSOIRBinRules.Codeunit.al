namespace GMSOFT.InventoryHealthCheck;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Structure;

codeunit 73031490 "GSO IR Bin Rules"
{
    // Rules on the warehouse side of one location:
    //   R3  adjustment bin balance <> 0 per unit of measure and item tracking (pending warehouse adjustment, directed locations)
    //   R4  negative bin content (beyond the tolerance)
    //   R5  unit of measure problems that block Calculate Warehouse Adjustment
    //   R6  quantity in a bin that is missing or has no bin code; info for a bin blocked for outbound movement
    //   R8  warehouse physical inventory journal open while the adjustment bin is not zero
    //   R9  quantity in a bin whose Bin Content record is missing
    // All totals come from queries with SUM; nothing here writes to a ledger table.
    Access = Internal;

    var
        Setup: Record "GSO IR Setup";
        FindingMgt: Codeunit "GSO IR Finding Mgt";
        NoAdjustmentBinCauseTxt: Label 'The location uses directed put-away and pick but has no adjustment bin, so warehouse adjustments cannot be posted to the item ledger.';
        PendingAdjustmentCauseTxt: Label 'A warehouse adjustment of %1 is registered in the adjustment bin but not yet posted to the item ledger.', Comment = '%1 = quantity';
        NegativeBinContentCauseTxt: Label 'The bin content is negative. Quantity was taken from the bin that the warehouse entries never put into it.';
        NoBinCodeCauseTxt: Label 'Warehouse entries without a bin code hold quantity at a location where bins are mandatory.';
        MissingBinCauseTxt: Label 'The bin does not exist at this location. It was deleted or renamed while it held quantity.';
        BlockedBinCauseTxt: Label 'The bin holds quantity but is blocked for %1 movement.', Comment = '%1 = inbound, outbound or all';
        BaseQtyMismatchCauseTxt: Label 'Quantity x Qty. per Unit of Measure (%1) does not equal Qty. (Base) (%2) in the warehouse entries.', Comment = '%1 = calculated base quantity, %2 = base quantity';
        MissingUnitOfMeasureCauseTxt: Label 'The warehouse entries use a unit of measure that the item no longer has.';
        ChangedQtyPerUoMCauseTxt: Label 'The warehouse entries use %1 base units per unit, but the item unit of measure now has %2. Calculate Warehouse Adjustment can fail or post wrong quantities.', Comment = '%1 = old quantity per unit, %2 = current quantity per unit';
        MissingBinContentCauseTxt: Label 'The warehouse entries hold quantity in this bin, but the bin content line for the item, variant and unit of measure is missing. The quantity is not shown in Bin Contents and is not offered for picks.';
        OpenPhysInventoryCauseTxt: Label 'Warehouse physical inventory journal %1 has lines for this location while the adjustment bin still holds pending adjustments.', Comment = '%1 = journal template name';

    procedure CheckLocation(RunNo: Integer; Location: Record Location; ItemFilter: Text)
    begin
        Setup.GetRecordOnce();

        if Location."Directed Put-away and Pick" then
            if Location."Adjustment Bin Code" = '' then
                InsertLocationFinding(RunNo, Location, Enum::"GSO IR Rule"::R3, NoAdjustmentBinCauseTxt)
            else
                if CheckAdjustmentBin(RunNo, Location, ItemFilter) then
                    CheckOpenPhysInventory(RunNo, Location);

        CheckBinContents(RunNo, Location, ItemFilter);
        CheckUnitsOfMeasure(RunNo, Location, ItemFilter);
    end;

    local procedure CheckAdjustmentBin(RunNo: Integer; Location: Record Location; ItemFilter: Text) HasPendingAdjustment: Boolean
    var
        WhseTrackingTotals: Query "GSO IR Whse Tracking Totals";
    begin
        // One balance per item, variant, unit of measure and lot/serial/package: Calculate Warehouse
        // Adjustment posts each of these groups, so opposite balances must not cancel each other out.
        WhseTrackingTotals.SetRange(LocationCode, Location.Code);
        WhseTrackingTotals.SetRange(BinCode, Location."Adjustment Bin Code");
        if ItemFilter <> '' then
            WhseTrackingTotals.SetFilter(ItemNo, ItemFilter);
        WhseTrackingTotals.SetFilter(SumQtyBase, '<>0');
        WhseTrackingTotals.Open();
        while WhseTrackingTotals.Read() do
            if Abs(WhseTrackingTotals.SumQtyBase) > Setup."Tolerance (Base)" then begin
                InsertPendingAdjustmentFinding(RunNo, Location, WhseTrackingTotals);
                HasPendingAdjustment := true;
            end;
        WhseTrackingTotals.Close();
    end;

    local procedure InsertPendingAdjustmentFinding(RunNo: Integer; Location: Record Location; var WhseTrackingTotals: Query "GSO IR Whse Tracking Totals")
    var
        Finding: Record "GSO IR Finding";
        Balance: Decimal;
    begin
        Balance := WhseTrackingTotals.SumQtyBase;
        FindingMgt.InitFinding(Finding, RunNo, Finding.Rule::R3, Finding.Severity::Info, Location.Code,
            WhseTrackingTotals.ItemNo, WhseTrackingTotals.VariantCode);
        Finding."Bin Code" := Location."Adjustment Bin Code";
        Finding."Unit of Measure Code" := WhseTrackingTotals.UnitOfMeasureCode;
        Finding."Lot No." := WhseTrackingTotals.LotNo;
        Finding."Serial No." := WhseTrackingTotals.SerialNo;
        Finding."Package No." := WhseTrackingTotals.PackageNo;
        Finding."Warehouse Qty. (Base)" := Balance;
        // The quantity that Calculate Warehouse Adjustment will post to the item ledger.
        Finding."Difference (Base)" := -Balance;
        Finding."Probable Cause" := CopyStr(StrSubstNo(PendingAdjustmentCauseTxt, -Balance), 1, MaxStrLen(Finding."Probable Cause"));
        // The age of a pending adjustment decides its severity, so the date is always looked up.
        Finding."First Date" := FindingMgt.FindFirstWarehouseDate(Finding, -Balance, Setup."Tolerance (Base)");
        if (Finding."First Date" <> 0D) and (Today() - Finding."First Date" > Setup."Max. Pending Adj. Age (Days)") then
            Finding.Severity := Finding.Severity::Warning;
        FindingMgt.InsertFinding(Finding);
    end;

    local procedure CheckOpenPhysInventory(RunNo: Integer; Location: Record Location)
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        WarehouseJournalTemplate.SetRange(Type, WarehouseJournalTemplate.Type::"Physical Inventory");
        if WarehouseJournalTemplate.FindSet() then
            repeat
                WarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalTemplate.Name);
                WarehouseJournalLine.SetRange("Location Code", Location.Code);
                if not WarehouseJournalLine.IsEmpty() then
                    InsertLocationFinding(RunNo, Location, Enum::"GSO IR Rule"::R8, StrSubstNo(OpenPhysInventoryCauseTxt, WarehouseJournalTemplate.Name));
            until WarehouseJournalTemplate.Next() = 0;
    end;

    local procedure CheckBinContents(RunNo: Integer; Location: Record Location; ItemFilter: Text)
    var
        WhseBinTotals: Query "GSO IR Whse Bin Totals";
        BinState: Dictionary of [Code[20], Integer];
        BlockedFor: Dictionary of [Code[20], Text];
    begin
        WhseBinTotals.SetRange(LocationCode, Location.Code);
        if Location."Adjustment Bin Code" <> '' then
            WhseBinTotals.SetFilter(BinCode, '<>%1', Location."Adjustment Bin Code");
        if ItemFilter <> '' then
            WhseBinTotals.SetFilter(ItemNo, ItemFilter);
        WhseBinTotals.SetFilter(SumQtyBase, '<>0');
        WhseBinTotals.Open();
        while WhseBinTotals.Read() do begin
            // Rounding residues within the tolerance are not negative bin content.
            if WhseBinTotals.SumQtyBase < -Setup."Tolerance (Base)" then
                InsertBinFinding(RunNo, Location.Code, Enum::"GSO IR Rule"::R4, Enum::"GSO IR Severity"::Warning, NegativeBinContentCauseTxt, WhseBinTotals);
            if CheckBinIsValid(RunNo, Location.Code, WhseBinTotals, BinState, BlockedFor) then
                CheckBinContentExists(RunNo, Location.Code, WhseBinTotals);
        end;
        WhseBinTotals.Close();
    end;

    /// <summary>
    /// R9: the bin holds quantity but its Bin Content record is missing. Bin Content quantities are
    /// calculated from the warehouse entries, so the ledgers still agree, but the stock is not shown
    /// in Bin Contents and picks do not find it. Each query row is one Bin Content key.
    /// </summary>
    local procedure CheckBinContentExists(RunNo: Integer; LocationCode: Code[10]; var WhseBinTotals: Query "GSO IR Whse Bin Totals")
    var
        BinContent: Record "Bin Content";
    begin
        if Abs(WhseBinTotals.SumQtyBase) <= Setup."Tolerance (Base)" then
            exit;
        BinContent.SetLoadFields("Location Code");
        if not BinContent.Get(LocationCode, WhseBinTotals.BinCode, WhseBinTotals.ItemNo, WhseBinTotals.VariantCode, WhseBinTotals.UnitOfMeasureCode) then
            InsertBinFinding(RunNo, LocationCode, Enum::"GSO IR Rule"::R9, Enum::"GSO IR Severity"::Warning, MissingBinContentCauseTxt, WhseBinTotals);
    end;

    /// <summary>
    /// R6: quantity without a bin code, in a bin that does not exist, or in a bin blocked for outbound
    /// movement. A bin blocked for inbound only is a normal place for stock. A bin blocked for outbound
    /// or all movement usually holds stock on purpose (quarantine), so that is info, not a warning.
    /// </summary>
    /// <returns>True when the bin exists, so that its bin content can be checked.</returns>
    local procedure CheckBinIsValid(RunNo: Integer; LocationCode: Code[10]; var WhseBinTotals: Query "GSO IR Whse Bin Totals"; var BinState: Dictionary of [Code[20], Integer]; var BlockedFor: Dictionary of [Code[20], Text]): Boolean
    begin
        if WhseBinTotals.BinCode = '' then begin
            InsertBinFinding(RunNo, LocationCode, Enum::"GSO IR Rule"::R6, Enum::"GSO IR Severity"::Warning, NoBinCodeCauseTxt, WhseBinTotals);
            exit(false);
        end;

        case GetBinState(LocationCode, WhseBinTotals.BinCode, BinState, BlockedFor) of
            1:
                begin
                    InsertBinFinding(RunNo, LocationCode, Enum::"GSO IR Rule"::R6, Enum::"GSO IR Severity"::Warning, MissingBinCauseTxt, WhseBinTotals);
                    exit(false);
                end;
            2:
                InsertBinFinding(RunNo, LocationCode, Enum::"GSO IR Rule"::R6, Enum::"GSO IR Severity"::Info,
                    StrSubstNo(BlockedBinCauseTxt, BlockedFor.Get(WhseBinTotals.BinCode)), WhseBinTotals);
        end;
        exit(true);
    end;

    /// <summary>
    /// Returns 0 for a bin that can be picked from, 1 for a bin that does not exist, 2 for a bin blocked
    /// for outbound or all movement (BlockedFor then holds the Block Movement text). Each bin is read once per location.
    /// </summary>
    local procedure GetBinState(LocationCode: Code[10]; BinCode: Code[20]; var BinState: Dictionary of [Code[20], Integer]; var BlockedFor: Dictionary of [Code[20], Text]) State: Integer
    var
        Bin: Record Bin;
    begin
        if BinState.Get(BinCode, State) then
            exit(State);

        Bin.SetLoadFields("Block Movement");
        if not Bin.Get(LocationCode, BinCode) then
            State := 1
        else
            if Bin."Block Movement" in [Bin."Block Movement"::Outbound, Bin."Block Movement"::All] then begin
                State := 2;
                BlockedFor.Add(BinCode, Format(Bin."Block Movement"));
            end;
        BinState.Add(BinCode, State);
    end;

    local procedure InsertBinFinding(RunNo: Integer; LocationCode: Code[10]; Rule: Enum "GSO IR Rule"; Severity: Enum "GSO IR Severity"; CauseText: Text; var WhseBinTotals: Query "GSO IR Whse Bin Totals")
    var
        Finding: Record "GSO IR Finding";
    begin
        InitBinFinding(Finding, RunNo, Rule, Severity, LocationCode, WhseBinTotals);
        Finding."Probable Cause" := CopyStr(CauseText, 1, MaxStrLen(Finding."Probable Cause"));
        FindingMgt.InsertFinding(Finding);
    end;

    local procedure CheckUnitsOfMeasure(RunNo: Integer; Location: Record Location; ItemFilter: Text)
    var
        Finding: Record "GSO IR Finding";
        WhseUoMTotals: Query "GSO IR Whse UoM Totals";
        CalculatedBaseQty: Decimal;
        CauseText: Text;
    begin
        WhseUoMTotals.SetRange(LocationCode, Location.Code);
        if ItemFilter <> '' then
            WhseUoMTotals.SetFilter(ItemNo, ItemFilter);
        WhseUoMTotals.Open();
        while WhseUoMTotals.Read() do
            if (WhseUoMTotals.SumQuantity <> 0) or (WhseUoMTotals.SumQtyBase <> 0) then begin
                CauseText := GetUnitOfMeasureProblem(WhseUoMTotals, CalculatedBaseQty);
                if CauseText <> '' then begin
                    FindingMgt.InitFinding(Finding, RunNo, Finding.Rule::R5, Finding.Severity::Warning, Location.Code,
                        WhseUoMTotals.ItemNo, WhseUoMTotals.VariantCode);
                    Finding."Unit of Measure Code" := WhseUoMTotals.UnitOfMeasureCode;
                    Finding."Qty. per Unit of Measure" := WhseUoMTotals.QtyPerUnitOfMeasure;
                    Finding."Warehouse Qty. (Base)" := WhseUoMTotals.SumQtyBase;
                    Finding."Difference (Base)" := CalculatedBaseQty - WhseUoMTotals.SumQtyBase;
                    Finding."Probable Cause" := CopyStr(CauseText, 1, MaxStrLen(Finding."Probable Cause"));
                    FindingMgt.InsertFinding(Finding);
                end;
            end;
        WhseUoMTotals.Close();
    end;

    /// <summary>Returns why the unit of measure of this group is a problem, or '' when it is fine.</summary>
    local procedure GetUnitOfMeasureProblem(var WhseUoMTotals: Query "GSO IR Whse UoM Totals"; var CalculatedBaseQty: Decimal): Text
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        RoundingTolerance: Decimal;
    begin
        // Qty. (Base) is rounded on every entry, so allow the rounding of each entry.
        RoundingTolerance := 0.00001 * WhseUoMTotals.NoOfEntries;
        if RoundingTolerance < Setup."Tolerance (Base)" then
            RoundingTolerance := Setup."Tolerance (Base)";
        CalculatedBaseQty := WhseUoMTotals.SumQuantity * WhseUoMTotals.QtyPerUnitOfMeasure;
        if Abs(CalculatedBaseQty - WhseUoMTotals.SumQtyBase) > RoundingTolerance then
            exit(StrSubstNo(BaseQtyMismatchCauseTxt, CalculatedBaseQty, WhseUoMTotals.SumQtyBase));

        ItemUnitOfMeasure.SetLoadFields("Qty. per Unit of Measure");
        if not ItemUnitOfMeasure.Get(WhseUoMTotals.ItemNo, WhseUoMTotals.UnitOfMeasureCode) then
            exit(MissingUnitOfMeasureCauseTxt);
        if ItemUnitOfMeasure."Qty. per Unit of Measure" <> WhseUoMTotals.QtyPerUnitOfMeasure then
            exit(StrSubstNo(ChangedQtyPerUoMCauseTxt, WhseUoMTotals.QtyPerUnitOfMeasure, ItemUnitOfMeasure."Qty. per Unit of Measure"));
        exit('');
    end;

    local procedure InitBinFinding(var Finding: Record "GSO IR Finding"; RunNo: Integer; Rule: Enum "GSO IR Rule"; Severity: Enum "GSO IR Severity"; LocationCode: Code[10]; var WhseBinTotals: Query "GSO IR Whse Bin Totals")
    begin
        FindingMgt.InitFinding(Finding, RunNo, Rule, Severity, LocationCode, WhseBinTotals.ItemNo, WhseBinTotals.VariantCode);
        Finding."Bin Code" := WhseBinTotals.BinCode;
        Finding."Unit of Measure Code" := WhseBinTotals.UnitOfMeasureCode;
        Finding."Warehouse Qty. (Base)" := WhseBinTotals.SumQtyBase;
    end;

    local procedure InsertLocationFinding(RunNo: Integer; Location: Record Location; Rule: Enum "GSO IR Rule"; CauseText: Text)
    var
        Finding: Record "GSO IR Finding";
    begin
        FindingMgt.InitFinding(Finding, RunNo, Rule, Finding.Severity::Warning, Location.Code, '', '');
        Finding."Probable Cause" := CopyStr(CauseText, 1, MaxStrLen(Finding."Probable Cause"));
        FindingMgt.InsertFinding(Finding);
    end;
}
