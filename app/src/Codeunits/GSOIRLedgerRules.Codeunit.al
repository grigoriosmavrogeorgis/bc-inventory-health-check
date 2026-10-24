namespace GMSOFT.InventoryHealthCheck;

using Microsoft.Inventory.Location;

codeunit 73033904 "GSO IR Ledger Rules"
{
    // Rules that compare the item ledger with the warehouse ledger of one location:
    //   R1  item ledger total <> warehouse total over all bins (incl. adjustment bin)
    //   R2  the same per lot / serial / package where the item total agrees, on the tracking the warehouse keeps
    //   R7  open item ledger entries that do not match the inventory (also inventory without open entries)
    // All totals come from queries with SUM; nothing here writes to a ledger table.
    Access = Internal;

    var
        Setup: Record "GSO IR Setup";
        FindingMgt: Codeunit "GSO IR Finding Mgt";
        ItemLedgerQty: Dictionary of [Text, Decimal];
        UnbalancedItems: Dictionary of [Text, Boolean];
        NoWarehouseQtyCauseTxt: Label 'Inventory exists in the item ledger but not in any bin. The location may have been switched to Bin Mandatory while it held stock, or entries were posted without a bin.';
        NoItemLedgerQtyCauseTxt: Label 'Bins hold quantity that the item ledger does not have. Warehouse entries were probably registered without the matching item posting.';
        TotalsDifferCauseTxt: Label 'The item ledger and the warehouse totals (all bins, including the adjustment bin) differ. No standard posting changes only one side.';
        TrackingDiffersCauseTxt: Label 'The item total agrees, but the quantity per lot, serial or package number differs between the item ledger and the warehouse entries.';
        RemainingDiffersCauseTxt: Label 'The remaining quantity of the open item ledger entries (%1) does not match the inventory (%2). The item application is damaged.', Comment = '%1 = remaining quantity, %2 = inventory';
        KnownApplicationIssueCauseTxt: Label 'Inventory is zero, but open inbound and outbound entries remain. This is the Microsoft known item application issue, often after posting without stock and then a credit memo or undo shipment.';

    procedure CheckLocation(RunNo: Integer; Location: Record Location; ItemFilter: Text)
    begin
        Setup.GetRecordOnce();
        Clear(ItemLedgerQty);
        Clear(UnbalancedItems);

        CheckItemLedgerVsWarehouse(RunNo, Location, ItemFilter);
        CheckItemTracking(RunNo, Location, ItemFilter);
        CheckOpenEntries(RunNo, Location, ItemFilter);
    end;

    local procedure CheckItemLedgerVsWarehouse(RunNo: Integer; Location: Record Location; ItemFilter: Text)
    var
        WarehouseQty: Dictionary of [Text, Decimal];
        KeyText: Text;
        ItemLedgerQuantity: Decimal;
        WarehouseQuantity: Decimal;
    begin
        // HAVING SUM <> 0 on both sides: a group missing on one side counts as zero.
        LoadItemLedgerTotals(Location.Code, ItemFilter);
        LoadWarehouseTotals(Location.Code, ItemFilter, WarehouseQty);

        foreach KeyText in ItemLedgerQty.Keys() do
            if not WarehouseQty.ContainsKey(KeyText) then
                WarehouseQty.Add(KeyText, 0);

        foreach KeyText in WarehouseQty.Keys() do begin
            ItemLedgerQuantity := FindingMgt.GetTotal(ItemLedgerQty, KeyText);
            WarehouseQuantity := FindingMgt.GetTotal(WarehouseQty, KeyText);
            if Abs(ItemLedgerQuantity - WarehouseQuantity) > Setup."Tolerance (Base)" then begin
                InsertItemLedgerVsWarehouseFinding(RunNo, Location.Code, KeyText, ItemLedgerQuantity, WarehouseQuantity);
                UnbalancedItems.Add(KeyText, true);
            end;
        end;
    end;

    local procedure LoadItemLedgerTotals(LocationCode: Code[10]; ItemFilter: Text)
    var
        ILETotals: Query "GSO IR ILE Totals";
    begin
        ILETotals.SetRange(LocationCode, LocationCode);
        if ItemFilter <> '' then
            ILETotals.SetFilter(ItemNo, ItemFilter);
        ILETotals.SetFilter(SumQuantity, '<>0');
        ILETotals.Open();
        while ILETotals.Read() do
            FindingMgt.AddToTotal(ItemLedgerQty, FindingMgt.ItemKey(ILETotals.ItemNo, ILETotals.VariantCode), ILETotals.SumQuantity);
        ILETotals.Close();
    end;

    local procedure LoadWarehouseTotals(LocationCode: Code[10]; ItemFilter: Text; var WarehouseQty: Dictionary of [Text, Decimal])
    var
        WhseTotals: Query "GSO IR Whse Totals";
    begin
        WhseTotals.SetRange(LocationCode, LocationCode);
        if ItemFilter <> '' then
            WhseTotals.SetFilter(ItemNo, ItemFilter);
        WhseTotals.SetFilter(SumQtyBase, '<>0');
        WhseTotals.Open();
        while WhseTotals.Read() do
            FindingMgt.AddToTotal(WarehouseQty, FindingMgt.ItemKey(WhseTotals.ItemNo, WhseTotals.VariantCode), WhseTotals.SumQtyBase);
        WhseTotals.Close();
    end;

    local procedure InsertItemLedgerVsWarehouseFinding(RunNo: Integer; LocationCode: Code[10]; KeyText: Text; ItemLedgerQuantity: Decimal; WarehouseQuantity: Decimal)
    var
        Finding: Record "GSO IR Finding";
        Parts: List of [Text];
    begin
        Parts := KeyText.Split(FindingMgt.KeySeparator());
        FindingMgt.InitFinding(Finding, RunNo, Finding.Rule::R1, Finding.Severity::Critical, LocationCode,
            CopyStr(Parts.Get(1), 1, MaxStrLen(Finding."Item No.")), CopyStr(Parts.Get(2), 1, MaxStrLen(Finding."Variant Code")));
        Finding."Item Ledger Qty. (Base)" := ItemLedgerQuantity;
        Finding."Warehouse Qty. (Base)" := WarehouseQuantity;
        Finding."Difference (Base)" := ItemLedgerQuantity - WarehouseQuantity;
        case true of
            WarehouseQuantity = 0:
                SetProbableCause(Finding, NoWarehouseQtyCauseTxt);
            ItemLedgerQuantity = 0:
                SetProbableCause(Finding, NoItemLedgerQtyCauseTxt);
            else
                SetProbableCause(Finding, TotalsDifferCauseTxt);
        end;
        if Setup."Find First Date" then
            Finding."First Date" := FindingMgt.FindFirstDate(Finding."Item No.", Finding."Variant Code", LocationCode, '', true,
                Finding."Difference (Base)", Setup."Tolerance (Base)");
        FindingMgt.InsertFinding(Finding);
    end;

    local procedure CheckItemTracking(RunNo: Integer; Location: Record Location; ItemFilter: Text)
    var
        ItemLedgerTrackingQty: Dictionary of [Text, Decimal];
        WarehouseTrackingQty: Dictionary of [Text, Decimal];
        KeyText: Text;
        ItemLedgerQuantity: Decimal;
        WarehouseQuantity: Decimal;
    begin
        LoadItemLedgerTrackingTotals(Location.Code, ItemFilter, ItemLedgerTrackingQty);
        LoadWarehouseTrackingTotals(Location.Code, ItemFilter, WarehouseTrackingQty);

        foreach KeyText in ItemLedgerTrackingQty.Keys() do
            if not WarehouseTrackingQty.ContainsKey(KeyText) then
                WarehouseTrackingQty.Add(KeyText, 0);

        foreach KeyText in WarehouseTrackingQty.Keys() do begin
            ItemLedgerQuantity := FindingMgt.GetTotal(ItemLedgerTrackingQty, KeyText);
            WarehouseQuantity := FindingMgt.GetTotal(WarehouseTrackingQty, KeyText);
            if Abs(ItemLedgerQuantity - WarehouseQuantity) > Setup."Tolerance (Base)" then
                InsertTrackingFinding(RunNo, Location.Code, KeyText, ItemLedgerQuantity, WarehouseQuantity);
        end;
    end;

    local procedure LoadItemLedgerTrackingTotals(LocationCode: Code[10]; ItemFilter: Text; var ItemLedgerTrackingQty: Dictionary of [Text, Decimal])
    var
        ILETrackingTotals: Query "GSO IR ILE Tracking Totals";
        LotNo: Code[50];
        SerialNo: Code[50];
        PackageNo: Code[50];
    begin
        // The warehouse keeps only the tracking that the item tracking code has Warehouse Tracking for;
        // the other numbers are blank on the warehouse entries, so they are left out on this side too.
        ILETrackingTotals.SetRange(LocationCode, LocationCode);
        if ItemFilter <> '' then
            ILETrackingTotals.SetFilter(ItemNo, ItemFilter);
        ILETrackingTotals.SetFilter(SumQuantity, '<>0');
        ILETrackingTotals.Open();
        while ILETrackingTotals.Read() do begin
            LotNo := ILETrackingTotals.LotNo;
            SerialNo := ILETrackingTotals.SerialNo;
            PackageNo := ILETrackingTotals.PackageNo;
            FindingMgt.KeepWarehouseTracking(ILETrackingTotals.ItemNo, LotNo, SerialNo, PackageNo);
            FindingMgt.AddToTotal(ItemLedgerTrackingQty,
                TrackingKey(ILETrackingTotals.ItemNo, ILETrackingTotals.VariantCode, LotNo, SerialNo, PackageNo),
                ILETrackingTotals.SumQuantity);
        end;
        ILETrackingTotals.Close();
    end;

    local procedure LoadWarehouseTrackingTotals(LocationCode: Code[10]; ItemFilter: Text; var WarehouseTrackingQty: Dictionary of [Text, Decimal])
    var
        WhseTrackingTotals: Query "GSO IR Whse Tracking Totals";
    begin
        WhseTrackingTotals.SetRange(LocationCode, LocationCode);
        if ItemFilter <> '' then
            WhseTrackingTotals.SetFilter(ItemNo, ItemFilter);
        WhseTrackingTotals.SetFilter(SumQtyBase, '<>0');
        WhseTrackingTotals.Open();
        while WhseTrackingTotals.Read() do
            FindingMgt.AddToTotal(WarehouseTrackingQty,
                TrackingKey(WhseTrackingTotals.ItemNo, WhseTrackingTotals.VariantCode, WhseTrackingTotals.LotNo, WhseTrackingTotals.SerialNo, WhseTrackingTotals.PackageNo),
                WhseTrackingTotals.SumQtyBase);
        WhseTrackingTotals.Close();
    end;

    local procedure InsertTrackingFinding(RunNo: Integer; LocationCode: Code[10]; KeyText: Text; ItemLedgerQuantity: Decimal; WarehouseQuantity: Decimal)
    var
        Finding: Record "GSO IR Finding";
        Parts: List of [Text];
    begin
        Parts := KeyText.Split(FindingMgt.KeySeparator());
        // Items whose total already differs are reported by R1 only.
        if UnbalancedItems.ContainsKey(FindingMgt.ItemKey(CopyStr(Parts.Get(1), 1, 20), CopyStr(Parts.Get(2), 1, 10))) then
            exit;

        FindingMgt.InitFinding(Finding, RunNo, Finding.Rule::R2, Finding.Severity::Critical, LocationCode,
            CopyStr(Parts.Get(1), 1, MaxStrLen(Finding."Item No.")), CopyStr(Parts.Get(2), 1, MaxStrLen(Finding."Variant Code")));
        Finding."Lot No." := CopyStr(Parts.Get(3), 1, MaxStrLen(Finding."Lot No."));
        Finding."Serial No." := CopyStr(Parts.Get(4), 1, MaxStrLen(Finding."Serial No."));
        Finding."Package No." := CopyStr(Parts.Get(5), 1, MaxStrLen(Finding."Package No."));
        Finding."Item Ledger Qty. (Base)" := ItemLedgerQuantity;
        Finding."Warehouse Qty. (Base)" := WarehouseQuantity;
        Finding."Difference (Base)" := ItemLedgerQuantity - WarehouseQuantity;
        SetProbableCause(Finding, TrackingDiffersCauseTxt);
        if Setup."Find First Date" then
            Finding."First Date" := FindingMgt.FindFirstTrackingDate(Finding, Finding."Difference (Base)", Setup."Tolerance (Base)");
        FindingMgt.InsertFinding(Finding);
    end;

    local procedure CheckOpenEntries(RunNo: Integer; Location: Record Location; ItemFilter: Text)
    var
        Finding: Record "GSO IR Finding";
        RemainingQty: Dictionary of [Text, Decimal];
        OpenInbound: Dictionary of [Text, Decimal];
        OpenOutbound: Dictionary of [Text, Decimal];
        KeyText: Text;
        Inventory: Decimal;
        Remaining: Decimal;
        Parts: List of [Text];
    begin
        LoadOpenEntries(Location.Code, ItemFilter, RemainingQty, OpenInbound, OpenOutbound);

        // The open entries must add up to the inventory, so inventory without any open entry is damaged too.
        foreach KeyText in ItemLedgerQty.Keys() do
            if not RemainingQty.ContainsKey(KeyText) then
                RemainingQty.Add(KeyText, 0);

        foreach KeyText in RemainingQty.Keys() do begin
            Inventory := FindingMgt.GetTotal(ItemLedgerQty, KeyText);
            Remaining := FindingMgt.GetTotal(RemainingQty, KeyText);
            Parts := KeyText.Split(FindingMgt.KeySeparator());
            FindingMgt.InitFinding(Finding, RunNo, Finding.Rule::R7, Finding.Severity::Critical, Location.Code,
                CopyStr(Parts.Get(1), 1, MaxStrLen(Finding."Item No.")), CopyStr(Parts.Get(2), 1, MaxStrLen(Finding."Variant Code")));
            Finding."Item Ledger Qty. (Base)" := Inventory;
            if Abs(Remaining - Inventory) > Setup."Tolerance (Base)" then begin
                Finding."Difference (Base)" := Remaining - Inventory;
                SetProbableCause(Finding, StrSubstNo(RemainingDiffersCauseTxt, Remaining, Inventory));
                FindingMgt.InsertFinding(Finding);
            end else
                if IsKnownApplicationIssue(Inventory, FindingMgt.GetTotal(OpenInbound, KeyText), FindingMgt.GetTotal(OpenOutbound, KeyText)) then begin
                    SetProbableCause(Finding, KnownApplicationIssueCauseTxt);
                    FindingMgt.InsertFinding(Finding);
                end;
        end;
    end;

    local procedure LoadOpenEntries(LocationCode: Code[10]; ItemFilter: Text; var RemainingQty: Dictionary of [Text, Decimal]; var OpenInbound: Dictionary of [Text, Decimal]; var OpenOutbound: Dictionary of [Text, Decimal])
    var
        ILEOpenEntries: Query "GSO IR ILE Open Entries";
        KeyText: Text;
    begin
        ILEOpenEntries.SetRange(LocationCode, LocationCode);
        if ItemFilter <> '' then
            ILEOpenEntries.SetFilter(ItemNo, ItemFilter);
        ILEOpenEntries.Open();
        while ILEOpenEntries.Read() do begin
            KeyText := FindingMgt.ItemKey(ILEOpenEntries.ItemNo, ILEOpenEntries.VariantCode);
            FindingMgt.AddToTotal(RemainingQty, KeyText, ILEOpenEntries.SumRemainingQuantity);
            if ILEOpenEntries.Positive then
                FindingMgt.AddToTotal(OpenInbound, KeyText, ILEOpenEntries.NoOfEntries)
            else
                FindingMgt.AddToTotal(OpenOutbound, KeyText, ILEOpenEntries.NoOfEntries);
        end;
        ILEOpenEntries.Close();
    end;

    local procedure IsKnownApplicationIssue(Inventory: Decimal; NoOfOpenInbound: Decimal; NoOfOpenOutbound: Decimal): Boolean
    begin
        exit((Inventory = 0) and (NoOfOpenInbound > 0) and (NoOfOpenOutbound > 0));
    end;

    /// <summary>A translated cause can be longer than the field; it is cut instead of failing the run.</summary>
    local procedure SetProbableCause(var Finding: Record "GSO IR Finding"; CauseText: Text)
    begin
        Finding."Probable Cause" := CopyStr(CauseText, 1, MaxStrLen(Finding."Probable Cause"));
    end;

    local procedure TrackingKey(ItemNo: Code[20]; VariantCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]; PackageNo: Code[50]): Text
    var
        Separator: Text;
    begin
        Separator := FindingMgt.KeySeparator();
        exit(ItemNo + Separator + VariantCode + Separator + LotNo + Separator + SerialNo + Separator + PackageNo);
    end;
}
