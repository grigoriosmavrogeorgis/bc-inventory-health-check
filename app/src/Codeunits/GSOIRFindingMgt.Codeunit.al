namespace GMSOFT.InventoryHealthCheck;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;

codeunit 73031488 "GSO IR Finding Mgt"
{
    // Creates findings, holds the advice texts per rule, finds the first date of a
    // difference and opens the standard entry pages for drill-down. Read-only on
    // all ledger tables: it only reads them through queries and opens pages.
    Access = Internal;
    Permissions = tabledata "GSO IR Finding" = ri;

    var
        R1AdviceTxt: Label 'Export the evidence and ask your partner. No standard posting changes only one side, so do not try to fix this with an item or warehouse journal.';
        R2AdviceTxt: Label 'Check the item tracking lines of the documents posted on the first date. No standard posting changes only one side, so ask your partner.';
        R3AdviceTxt: Label 'Run Calculate Warehouse Adjustment in the item journal and post it. Use Preview Posting first. Microsoft recommends posting warehouse adjustments regularly.';
        R4AdviceTxt: Label 'Check the warehouse entries of the bin, then move or reclassify quantity into the bin with a movement or a warehouse reclassification journal.';
        R5AdviceTxt: Label 'Correct the unit of measure before you run Calculate Warehouse Adjustment. Do not change Qty. per Unit of Measure while the unit is used in bins.';
        R6AdviceTxt: Label 'Move the quantity to a valid bin with a movement or a warehouse reclassification journal before you block or delete the bin.';
        R7AdviceTxt: Label 'Known issue: post a positive adjustment with Applies-from Entry and a negative adjustment of the same quantity with Applies-to Entry (Microsoft workaround). Otherwise ask your partner.';
        R8AdviceTxt: Label 'Run Calculate Warehouse Adjustment and post it before you count. Microsoft: synchronize item ledger and warehouse data before you count physical inventory.';
        R9AdviceTxt: Label 'Create the bin content line for this bin, item, variant and unit of measure on the Bin Contents page. Its quantity is calculated from the warehouse entries, so no posting is needed.';
        GetHelpUrlTxt: Label 'https://gmsoftdynamics.com/apps/free/inventory-health-check/', Locked = true;
        GetHelpFeatureTxt: Label 'Get Help', Locked = true;
        WarehouseTrackingCache: Dictionary of [Code[20], Integer];

    procedure InsertFinding(var Finding: Record "GSO IR Finding")
    begin
        Finding."Entry No." := 0;
        Finding.Status := Finding.Status::New;
        Finding."Created At" := CurrentDateTime();
        if Finding.Advice = '' then
            Finding.Advice := GetAdvice(Finding.Rule);
        Finding.Insert(true);
    end;

    procedure InitFinding(var Finding: Record "GSO IR Finding"; RunNo: Integer; Rule: Enum "GSO IR Rule"; Severity: Enum "GSO IR Severity"; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        Finding.Init();
        Finding."Run No." := RunNo;
        Finding.Rule := Rule;
        Finding.Severity := Severity;
        Finding."Location Code" := LocationCode;
        Finding."Item No." := ItemNo;
        Finding."Variant Code" := VariantCode;
    end;

    procedure GetAdvice(Rule: Enum "GSO IR Rule"): Text[250]
    var
        Advice: Text;
    begin
        case Rule of
            Rule::R1, Rule::R2, Rule::R7:
                Advice := GetLedgerRuleAdvice(Rule);
            Rule::R3, Rule::R4, Rule::R5, Rule::R6, Rule::R8, Rule::R9:
                Advice := GetBinRuleAdvice(Rule);
        end;
        // A translated advice can be longer than the field; it is cut instead of failing the run.
        exit(CopyStr(Advice, 1, 250));
    end;

    /// <summary>Advice for the rules of "GSO IR Ledger Rules".</summary>
    local procedure GetLedgerRuleAdvice(Rule: Enum "GSO IR Rule"): Text
    begin
        case Rule of
            Rule::R1:
                exit(R1AdviceTxt);
            Rule::R2:
                exit(R2AdviceTxt);
            Rule::R7:
                exit(R7AdviceTxt);
        end;
        exit('');
    end;

    /// <summary>Advice for the rules of "GSO IR Bin Rules".</summary>
    local procedure GetBinRuleAdvice(Rule: Enum "GSO IR Rule"): Text
    begin
        case Rule of
            Rule::R3:
                exit(R3AdviceTxt);
            Rule::R4:
                exit(R4AdviceTxt);
            Rule::R5:
                exit(R5AdviceTxt);
            Rule::R6:
                exit(R6AdviceTxt);
            Rule::R8:
                exit(R8AdviceTxt);
            Rule::R9:
                exit(R9AdviceTxt);
        end;
        exit('');
    end;

    /// <summary>
    /// Opens the GMSOFT web page, where the user can ask for help with a finding. Nothing about the
    /// finding leaves the tenant; telemetry logs only that the action was used and for which rule.
    /// </summary>
    procedure OpenGetHelp(Finding: Record "GSO IR Finding")
    var
        Telemetry: Codeunit "GSO IR Telemetry";
    begin
        Telemetry.FeatureUsed(GetHelpFeatureTxt, Format(Finding.Rule.AsInteger(), 0, 9));
        Hyperlink(GetHelpUrlTxt);
    end;

    /// <summary>
    /// Walks the item ledger and warehouse quantities back day by day, starting from the
    /// current difference (item ledger minus warehouse), and returns the date on which the
    /// difference last was within the tolerance, i.e. the date the difference appeared.
    /// With BinCode the warehouse side is limited to that bin. Without IncludeItemLedger
    /// only the warehouse side is used (for example for the adjustment bin balance).
    /// Returns the oldest date found if the difference exists since the first entry.
    /// </summary>
    procedure FindFirstDate(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; IncludeItemLedger: Boolean; CurrentDifference: Decimal; Tolerance: Decimal): Date
    var
        ILEDaily: Query "GSO IR ILE Daily";
        WhseDaily: Query "GSO IR Whse Daily";
    begin
        SetWarehouseDayFilters(WhseDaily, ItemNo, VariantCode, LocationCode, BinCode);
        SetItemLedgerDayFilters(ILEDaily, ItemNo, VariantCode, LocationCode);
        exit(WalkBackDays(ILEDaily, IncludeItemLedger, WhseDaily, CurrentDifference, Tolerance));
    end;

    /// <summary>
    /// FindFirstDate on the warehouse side of one finding group: the bin, unit of measure and lot,
    /// serial and package number of the finding, blank values included. Used for the adjustment
    /// bin balances (R3), which are checked per group.
    /// </summary>
    procedure FindFirstWarehouseDate(Finding: Record "GSO IR Finding"; CurrentDifference: Decimal; Tolerance: Decimal): Date
    var
        ILEDaily: Query "GSO IR ILE Daily";
        WhseDaily: Query "GSO IR Whse Daily";
    begin
        SetWarehouseDayFilters(WhseDaily, Finding."Item No.", Finding."Variant Code", Finding."Location Code", Finding."Bin Code");
        WhseDaily.SetRange(UnitOfMeasureCode, Finding."Unit of Measure Code");
        WhseDaily.SetRange(LotNo, Finding."Lot No.");
        WhseDaily.SetRange(SerialNo, Finding."Serial No.");
        WhseDaily.SetRange(PackageNo, Finding."Package No.");
        exit(WalkBackDays(ILEDaily, false, WhseDaily, CurrentDifference, Tolerance));
    end;

    /// <summary>
    /// FindFirstDate for one item tracking group (R2): lot, serial and package number of the finding.
    /// The warehouse side is filtered on all three, blank values included; the item ledger side only
    /// on the tracking that the warehouse keeps for the item (see KeepWarehouseTracking).
    /// </summary>
    procedure FindFirstTrackingDate(Finding: Record "GSO IR Finding"; CurrentDifference: Decimal; Tolerance: Decimal): Date
    var
        ILEDaily: Query "GSO IR ILE Daily";
        WhseDaily: Query "GSO IR Whse Daily";
        LotTracked: Boolean;
        SerialTracked: Boolean;
        PackageTracked: Boolean;
    begin
        SetWarehouseDayFilters(WhseDaily, Finding."Item No.", Finding."Variant Code", Finding."Location Code", '');
        WhseDaily.SetRange(LotNo, Finding."Lot No.");
        WhseDaily.SetRange(SerialNo, Finding."Serial No.");
        WhseDaily.SetRange(PackageNo, Finding."Package No.");

        SetItemLedgerDayFilters(ILEDaily, Finding."Item No.", Finding."Variant Code", Finding."Location Code");
        GetWarehouseTracking(Finding."Item No.", LotTracked, SerialTracked, PackageTracked);
        if LotTracked then
            ILEDaily.SetRange(LotNo, Finding."Lot No.");
        if SerialTracked then
            ILEDaily.SetRange(SerialNo, Finding."Serial No.");
        if PackageTracked then
            ILEDaily.SetRange(PackageNo, Finding."Package No.");
        exit(WalkBackDays(ILEDaily, true, WhseDaily, CurrentDifference, Tolerance));
    end;

    /// <summary>
    /// Blanks the lot, serial and package numbers that the warehouse does not track for the item.
    /// Warehouse entries carry only the numbers whose Warehouse Tracking is on in the item tracking
    /// code, so the item ledger side must be compared on the same numbers.
    /// </summary>
    procedure KeepWarehouseTracking(ItemNo: Code[20]; var LotNo: Code[50]; var SerialNo: Code[50]; var PackageNo: Code[50])
    var
        LotTracked: Boolean;
        SerialTracked: Boolean;
        PackageTracked: Boolean;
    begin
        GetWarehouseTracking(ItemNo, LotTracked, SerialTracked, PackageTracked);
        if not LotTracked then
            LotNo := '';
        if not SerialTracked then
            SerialNo := '';
        if not PackageTracked then
            PackageNo := '';
    end;

    /// <summary>Returns which item tracking the warehouse keeps for the item. Each item is read once.</summary>
    procedure GetWarehouseTracking(ItemNo: Code[20]; var LotTracked: Boolean; var SerialTracked: Boolean; var PackageTracked: Boolean)
    var
        Flags: Integer;
    begin
        // Flags: 1 = lot, 2 = serial, 4 = package.
        if not WarehouseTrackingCache.Get(ItemNo, Flags) then begin
            Flags := ReadWarehouseTracking(ItemNo);
            WarehouseTrackingCache.Add(ItemNo, Flags);
        end;
        LotTracked := Flags mod 2 = 1;
        SerialTracked := (Flags div 2) mod 2 = 1;
        PackageTracked := (Flags div 4) mod 2 = 1;
    end;

    local procedure ReadWarehouseTracking(ItemNo: Code[20]) Flags: Integer
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        Item.SetLoadFields("Item Tracking Code");
        if not Item.Get(ItemNo) then
            exit(0);
        if Item."Item Tracking Code" = '' then
            exit(0);
        ItemTrackingCode.SetLoadFields("Lot Warehouse Tracking", "SN Warehouse Tracking", "Package Warehouse Tracking");
        if not ItemTrackingCode.Get(Item."Item Tracking Code") then
            exit(0);
        if ItemTrackingCode."Lot Warehouse Tracking" then
            Flags += 1;
        if ItemTrackingCode."SN Warehouse Tracking" then
            Flags += 2;
        if ItemTrackingCode."Package Warehouse Tracking" then
            Flags += 4;
    end;

    /// <summary>Walks the daily totals of the filtered queries back from the newest day; see FindFirstDate.</summary>
    local procedure WalkBackDays(var ILEDaily: Query "GSO IR ILE Daily"; IncludeItemLedger: Boolean; var WhseDaily: Query "GSO IR Whse Daily"; CurrentDifference: Decimal; Tolerance: Decimal): Date
    var
        HasItemLedgerDay: Boolean;
        HasWarehouseDay: Boolean;
        CurrentDate: Date;
        LastDate: Date;
        Difference: Decimal;
    begin
        WhseDaily.Open();
        HasWarehouseDay := WhseDaily.Read();
        if IncludeItemLedger then begin
            ILEDaily.Open();
            HasItemLedgerDay := ILEDaily.Read();
        end;

        Difference := CurrentDifference;
        while HasItemLedgerDay or HasWarehouseDay do begin
            CurrentDate := GetNextDay(ILEDaily, HasItemLedgerDay, WhseDaily, HasWarehouseDay);
            TakeItemLedgerDay(ILEDaily, HasItemLedgerDay, CurrentDate, Difference);
            TakeWarehouseDay(WhseDaily, HasWarehouseDay, CurrentDate, Difference);

            LastDate := CurrentDate;
            if Abs(Difference) <= Tolerance then
                exit(CurrentDate);
        end;
        exit(LastDate);
    end;

    /// <summary>Filters the daily warehouse totals (read newest day first) on the item, location and, if given, the bin.</summary>
    local procedure SetWarehouseDayFilters(var WhseDaily: Query "GSO IR Whse Daily"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20])
    begin
        WhseDaily.SetRange(ItemNo, ItemNo);
        WhseDaily.SetRange(VariantCode, VariantCode);
        WhseDaily.SetRange(LocationCode, LocationCode);
        if BinCode <> '' then
            WhseDaily.SetRange(BinCode, BinCode);
    end;

    /// <summary>Filters the daily item ledger totals (read newest day first) on the item and location.</summary>
    local procedure SetItemLedgerDayFilters(var ILEDaily: Query "GSO IR ILE Daily"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        ILEDaily.SetRange(ItemNo, ItemNo);
        ILEDaily.SetRange(VariantCode, VariantCode);
        ILEDaily.SetRange(LocationCode, LocationCode);
    end;

    /// <summary>Returns the newest of the current item ledger day and the current warehouse day (both are read newest first).</summary>
    local procedure GetNextDay(var ILEDaily: Query "GSO IR ILE Daily"; HasItemLedgerDay: Boolean; var WhseDaily: Query "GSO IR Whse Daily"; HasWarehouseDay: Boolean) NextDay: Date
    begin
        if HasItemLedgerDay then
            NextDay := ILEDaily.PostingDate;
        if HasWarehouseDay then
            if WhseDaily.RegisteringDate > NextDay then
                NextDay := WhseDaily.RegisteringDate;
    end;

    /// <summary>If the current item ledger day is CurrentDate, removes its quantity from the difference and moves to the next day.</summary>
    local procedure TakeItemLedgerDay(var ILEDaily: Query "GSO IR ILE Daily"; var HasItemLedgerDay: Boolean; CurrentDate: Date; var Difference: Decimal)
    begin
        if not HasItemLedgerDay then
            exit;
        if ILEDaily.PostingDate <> CurrentDate then
            exit;
        Difference -= ILEDaily.SumQuantity;
        HasItemLedgerDay := ILEDaily.Read();
    end;

    /// <summary>If the current warehouse day is CurrentDate, adds its quantity back to the difference and moves to the next day.</summary>
    local procedure TakeWarehouseDay(var WhseDaily: Query "GSO IR Whse Daily"; var HasWarehouseDay: Boolean; CurrentDate: Date; var Difference: Decimal)
    begin
        if not HasWarehouseDay then
            exit;
        if WhseDaily.RegisteringDate <> CurrentDate then
            exit;
        Difference += WhseDaily.SumQtyBase;
        HasWarehouseDay := WhseDaily.Read();
    end;

    procedure KeySeparator(): Text
    var
        Tab: Char;
    begin
        Tab := 9;
        exit(Format(Tab));
    end;

    procedure ItemKey(ItemNo: Code[20]; VariantCode: Code[10]): Text
    begin
        exit(ItemNo + KeySeparator() + VariantCode);
    end;

    procedure AddToTotal(var Totals: Dictionary of [Text, Decimal]; KeyText: Text; Quantity: Decimal)
    var
        Total: Decimal;
    begin
        if Totals.Get(KeyText, Total) then
            Totals.Set(KeyText, Total + Quantity)
        else
            Totals.Add(KeyText, Quantity);
    end;

    procedure GetTotal(var Totals: Dictionary of [Text, Decimal]; KeyText: Text): Decimal
    var
        Total: Decimal;
    begin
        if Totals.Get(KeyText, Total) then
            exit(Total);
        exit(0);
    end;

    procedure ShowItemLedgerEntries(Finding: Record "GSO IR Finding")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotTracked: Boolean;
        SerialTracked: Boolean;
        PackageTracked: Boolean;
    begin
        ItemLedgerEntry.SetCurrentKey("Item No.");
        ItemLedgerEntry.SetRange("Item No.", Finding."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", Finding."Variant Code");
        ItemLedgerEntry.SetRange("Location Code", Finding."Location Code");
        // The item ledger side of a tracking group holds every number the warehouse does not track.
        if IsPerItemTracking(Finding.Rule) then begin
            GetWarehouseTracking(Finding."Item No.", LotTracked, SerialTracked, PackageTracked);
            if LotTracked then
                ItemLedgerEntry.SetRange("Lot No.", Finding."Lot No.");
            if SerialTracked then
                ItemLedgerEntry.SetRange("Serial No.", Finding."Serial No.");
            if PackageTracked then
                ItemLedgerEntry.SetRange("Package No.", Finding."Package No.");
        end;
        Page.Run(Page::"Item Ledger Entries", ItemLedgerEntry);
    end;

    procedure ShowWarehouseEntries(Finding: Record "GSO IR Finding")
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetCurrentKey("Item No.");
        WarehouseEntry.SetRange("Item No.", Finding."Item No.");
        WarehouseEntry.SetRange("Variant Code", Finding."Variant Code");
        WarehouseEntry.SetRange("Location Code", Finding."Location Code");
        if IsPerBin(Finding.Rule) then
            WarehouseEntry.SetRange("Bin Code", Finding."Bin Code");
        if IsPerUnitOfMeasure(Finding.Rule) then
            WarehouseEntry.SetRange("Unit of Measure Code", Finding."Unit of Measure Code");
        // R5 is also per conversion factor: entries of one unit with an old and a new factor are separate findings.
        // Findings created before the factor was stored have 0 and keep the drill-down per unit of measure.
        if (Finding.Rule = Finding.Rule::R5) and (Finding."Qty. per Unit of Measure" <> 0) then
            WarehouseEntry.SetRange("Qty. per Unit of Measure", Finding."Qty. per Unit of Measure");
        if IsPerItemTracking(Finding.Rule) then begin
            WarehouseEntry.SetRange("Lot No.", Finding."Lot No.");
            WarehouseEntry.SetRange("Serial No.", Finding."Serial No.");
            WarehouseEntry.SetRange("Package No.", Finding."Package No.");
        end;
        Page.Run(Page::"Warehouse Entries", WarehouseEntry);
    end;

    procedure ShowBinContents(Finding: Record "GSO IR Finding")
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", Finding."Location Code");
        if Finding."Item No." <> '' then
            BinContent.SetRange("Item No.", Finding."Item No.");
        if Finding."Item No." <> '' then
            BinContent.SetRange("Variant Code", Finding."Variant Code");
        if IsPerBin(Finding.Rule) then
            BinContent.SetRange("Bin Code", Finding."Bin Code");
        if IsPerUnitOfMeasure(Finding.Rule) then
            BinContent.SetRange("Unit of Measure Code", Finding."Unit of Measure Code");
        Page.Run(Page::"Bin Contents", BinContent);
    end;

    // The drill-downs filter on what a rule groups its findings by, blank values included: a blank
    // bin code of an R6 finding means entries without a bin, not entries in every bin.

    /// <summary>Rules whose findings are per bin (R3 the adjustment bin, R4, R6, R9).</summary>
    local procedure IsPerBin(Rule: Enum "GSO IR Rule"): Boolean
    begin
        exit(Rule in [Rule::R3, Rule::R4, Rule::R6, Rule::R9]);
    end;

    /// <summary>Rules whose findings are per unit of measure (R3, R4, R5, R6, R9).</summary>
    local procedure IsPerUnitOfMeasure(Rule: Enum "GSO IR Rule"): Boolean
    begin
        exit(Rule in [Rule::R3, Rule::R4, Rule::R5, Rule::R6, Rule::R9]);
    end;

    /// <summary>Rules whose findings are per lot, serial and package number (R2, R3).</summary>
    local procedure IsPerItemTracking(Rule: Enum "GSO IR Rule"): Boolean
    begin
        exit(Rule in [Rule::R2, Rule::R3]);
    end;
}
