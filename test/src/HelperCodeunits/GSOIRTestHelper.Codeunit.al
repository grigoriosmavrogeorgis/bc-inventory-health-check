namespace GMSOFT.InventoryHealthCheck.Test;

using GMSOFT.InventoryHealthCheck;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;

codeunit 50101 "GSO IR Test Helper"
{
    // Builds item ledger and warehouse scenarios by inserting entries directly.
    // This is only allowed in the test app: the main app never writes to ledger tables.
    // Every scenario uses its own new location and item, so tests do not depend on each other.

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";

    procedure CreateBinLocation(var Location: Record Location; Directed: Boolean)
    begin
        Location.Init();
        Location.Code := LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), Database::Location);
        Location."Bin Mandatory" := true;
        Location."Directed Put-away and Pick" := Directed;
        if Directed then
            Location."Adjustment Bin Code" := AdjustmentBinCode();
        Location.Insert(false);

        if Directed then
            CreateBin(Location.Code, AdjustmentBinCode());
        CreateBin(Location.Code, StockBinCode());
        CreateBin(Location.Code, SecondBinCode());
    end;

    procedure CreateLocationWithoutBins(var Location: Record Location)
    begin
        Location.Init();
        Location.Code := LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), Database::Location);
        Location.Insert(false);
    end;

    procedure CreateBin(LocationCode: Code[10]; BinCode: Code[20])
    var
        Bin: Record Bin;
    begin
        Bin.Init();
        Bin."Location Code" := LocationCode;
        Bin.Code := BinCode;
        Bin.Insert(false);
    end;

    procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
    end;

    /// <summary>An item that is lot, serial and package tracked, with Warehouse Tracking only where asked.</summary>
    procedure CreateTrackedItem(var Item: Record Item; LotWarehouseTracking: Boolean; SNWarehouseTracking: Boolean; PackageWarehouseTracking: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.Init();
        ItemTrackingCode.Code := LibraryUtility.GenerateRandomCode(ItemTrackingCode.FieldNo(Code), Database::"Item Tracking Code");
        ItemTrackingCode."Lot Specific Tracking" := true;
        ItemTrackingCode."SN Specific Tracking" := true;
        ItemTrackingCode."Package Specific Tracking" := true;
        ItemTrackingCode."Lot Warehouse Tracking" := LotWarehouseTracking;
        ItemTrackingCode."SN Warehouse Tracking" := SNWarehouseTracking;
        ItemTrackingCode."Package Warehouse Tracking" := PackageWarehouseTracking;
        ItemTrackingCode.Insert(false);

        LibraryInventory.CreateItem(Item);
        Item."Item Tracking Code" := ItemTrackingCode.Code;
        Item.Modify(false);
    end;

    procedure InsertItemLedgerEntry(Item: Record Item; LocationCode: Code[10]; Quantity: Decimal; PostingDate: Date; LotNo: Code[50])
    begin
        InsertItemLedgerEntry(Item, LocationCode, Quantity, Quantity, PostingDate, LotNo);
    end;

    procedure InsertItemLedgerEntry(Item: Record Item; LocationCode: Code[10]; Quantity: Decimal; RemainingQuantity: Decimal; PostingDate: Date; LotNo: Code[50])
    begin
        InsertItemLedgerEntryCore(Item, LocationCode, '', Quantity, RemainingQuantity, PostingDate, LotNo, '', '');
    end;

    procedure InsertTrackedItemLedgerEntry(Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Quantity: Decimal; PostingDate: Date; LotNo: Code[50]; SerialNo: Code[50]; PackageNo: Code[50])
    begin
        InsertItemLedgerEntryCore(Item, LocationCode, VariantCode, Quantity, Quantity, PostingDate, LotNo, SerialNo, PackageNo);
    end;

    local procedure InsertItemLedgerEntryCore(Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Quantity: Decimal; RemainingQuantity: Decimal; PostingDate: Date; LotNo: Code[50]; SerialNo: Code[50]; PackageNo: Code[50])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        EntryNo: Integer;
    begin
        if ItemLedgerEntry.FindLast() then
            EntryNo := ItemLedgerEntry."Entry No.";
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := EntryNo + 1;
        ItemLedgerEntry."Item No." := Item."No.";
        ItemLedgerEntry."Variant Code" := VariantCode;
        ItemLedgerEntry."Location Code" := LocationCode;
        ItemLedgerEntry."Posting Date" := PostingDate;
        if Quantity > 0 then
            ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::"Positive Adjmt."
        else
            ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::"Negative Adjmt.";
        ItemLedgerEntry.Quantity := Quantity;
        ItemLedgerEntry."Invoiced Quantity" := Quantity;
        ItemLedgerEntry."Remaining Quantity" := RemainingQuantity;
        ItemLedgerEntry.Open := RemainingQuantity <> 0;
        ItemLedgerEntry.Positive := Quantity > 0;
        ItemLedgerEntry."Unit of Measure Code" := Item."Base Unit of Measure";
        ItemLedgerEntry."Qty. per Unit of Measure" := 1;
        ItemLedgerEntry."Lot No." := LotNo;
        ItemLedgerEntry."Serial No." := SerialNo;
        ItemLedgerEntry."Package No." := PackageNo;
        ItemLedgerEntry.Insert(false);
    end;

    procedure InsertWarehouseEntry(Item: Record Item; LocationCode: Code[10]; BinCode: Code[20]; QtyBase: Decimal; RegisteringDate: Date; LotNo: Code[50])
    begin
        InsertWarehouseEntry(Item, LocationCode, BinCode, Item."Base Unit of Measure", 1, QtyBase, QtyBase, RegisteringDate, LotNo);
    end;

    procedure InsertWarehouseEntry(Item: Record Item; LocationCode: Code[10]; BinCode: Code[20]; UnitOfMeasureCode: Code[10]; QtyPerUnitOfMeasure: Decimal; Quantity: Decimal; QtyBase: Decimal; RegisteringDate: Date; LotNo: Code[50])
    begin
        InsertWarehouseEntryCore(Item, LocationCode, BinCode, '', UnitOfMeasureCode, QtyPerUnitOfMeasure, Quantity, QtyBase, RegisteringDate, LotNo, '', '');
    end;

    procedure InsertTrackedWarehouseEntry(Item: Record Item; LocationCode: Code[10]; BinCode: Code[20]; VariantCode: Code[10]; QtyBase: Decimal; RegisteringDate: Date; LotNo: Code[50]; SerialNo: Code[50]; PackageNo: Code[50])
    begin
        InsertWarehouseEntryCore(Item, LocationCode, BinCode, VariantCode, Item."Base Unit of Measure", 1, QtyBase, QtyBase, RegisteringDate, LotNo, SerialNo, PackageNo);
    end;

    local procedure InsertWarehouseEntryCore(Item: Record Item; LocationCode: Code[10]; BinCode: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; QtyPerUnitOfMeasure: Decimal; Quantity: Decimal; QtyBase: Decimal; RegisteringDate: Date; LotNo: Code[50]; SerialNo: Code[50]; PackageNo: Code[50])
    var
        WarehouseEntry: Record "Warehouse Entry";
        EntryNo: Integer;
    begin
        if WarehouseEntry.FindLast() then
            EntryNo := WarehouseEntry."Entry No.";
        WarehouseEntry.Init();
        WarehouseEntry."Entry No." := EntryNo + 1;
        WarehouseEntry."Item No." := Item."No.";
        WarehouseEntry."Variant Code" := VariantCode;
        WarehouseEntry."Location Code" := LocationCode;
        WarehouseEntry."Bin Code" := BinCode;
        WarehouseEntry."Registering Date" := RegisteringDate;
        WarehouseEntry."Unit of Measure Code" := UnitOfMeasureCode;
        WarehouseEntry."Qty. per Unit of Measure" := QtyPerUnitOfMeasure;
        WarehouseEntry.Quantity := Quantity;
        WarehouseEntry."Qty. (Base)" := QtyBase;
        WarehouseEntry."Lot No." := LotNo;
        WarehouseEntry."Serial No." := SerialNo;
        WarehouseEntry."Package No." := PackageNo;
        WarehouseEntry.Insert(false);
        EnsureBinContent(WarehouseEntry);
    end;

    /// <summary>Registering a warehouse entry creates its bin content line, as Business Central does, when the bin exists.</summary>
    local procedure EnsureBinContent(WarehouseEntry: Record "Warehouse Entry")
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
    begin
        if not Bin.Get(WarehouseEntry."Location Code", WarehouseEntry."Bin Code") then
            exit;
        if BinContent.Get(WarehouseEntry."Location Code", WarehouseEntry."Bin Code", WarehouseEntry."Item No.", WarehouseEntry."Variant Code", WarehouseEntry."Unit of Measure Code") then
            exit;
        BinContent.Init();
        BinContent."Location Code" := WarehouseEntry."Location Code";
        BinContent."Bin Code" := WarehouseEntry."Bin Code";
        BinContent."Item No." := WarehouseEntry."Item No.";
        BinContent."Variant Code" := WarehouseEntry."Variant Code";
        BinContent."Unit of Measure Code" := WarehouseEntry."Unit of Measure Code";
        BinContent.Insert(false);
    end;

    procedure DeleteBinContent(LocationCode: Code[10]; BinCode: Code[20]; Item: Record Item)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.DeleteAll(false);
    end;

    procedure InsertWhsePhysInventoryLine(LocationCode: Code[10])
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        WarehouseJournalTemplate.Init();
        WarehouseJournalTemplate.Name := LibraryUtility.GenerateRandomCode(WarehouseJournalTemplate.FieldNo(Name), Database::"Warehouse Journal Template");
        WarehouseJournalTemplate.Type := WarehouseJournalTemplate.Type::"Physical Inventory";
        WarehouseJournalTemplate.Insert(false);

        WarehouseJournalLine.Init();
        WarehouseJournalLine."Journal Template Name" := WarehouseJournalTemplate.Name;
        WarehouseJournalLine."Journal Batch Name" := 'DEFAULT';
        WarehouseJournalLine."Location Code" := LocationCode;
        WarehouseJournalLine."Line No." := 10000;
        WarehouseJournalLine.Insert(false);
    end;

    procedure SetMaxPendingAdjustmentAge(Days: Integer)
    var
        Setup: Record "GSO IR Setup";
    begin
        Setup.InsertIfNotExists();
        Setup."Max. Pending Adj. Age (Days)" := Days;
        Setup."Tolerance (Base)" := 0;
        Setup."Find First Date" := true;
        Setup."Location Filter" := '';
        Setup.Modify(false);
    end;

    procedure SetTolerance(Tolerance: Decimal)
    var
        Setup: Record "GSO IR Setup";
    begin
        Setup.Get();
        Setup."Tolerance (Base)" := Tolerance;
        Setup.Modify(false);
    end;

    procedure SetFindFirstDate(FindFirstDate: Boolean)
    var
        Setup: Record "GSO IR Setup";
    begin
        Setup.Get();
        Setup."Find First Date" := FindFirstDate;
        Setup.Modify(false);
    end;

    procedure SetLocationFilter(LocationFilter: Text[250])
    var
        Setup: Record "GSO IR Setup";
    begin
        Setup.Get();
        Setup."Location Filter" := LocationFilter;
        Setup.Modify(false);
    end;

    procedure BlockBin(LocationCode: Code[10]; BinCode: Code[20])
    var
        Bin: Record Bin;
    begin
        Bin.Get(LocationCode, BinCode);
        Bin."Block Movement" := Bin."Block Movement"::All;
        Bin.Modify(false);
    end;

    procedure BlockBinForInbound(LocationCode: Code[10]; BinCode: Code[20])
    var
        Bin: Record Bin;
    begin
        Bin.Get(LocationCode, BinCode);
        Bin."Block Movement" := Bin."Block Movement"::Inbound;
        Bin.Modify(false);
    end;

    procedure RunAnalysis(Location: Record Location; Item: Record Item): Integer
    begin
        exit(RunAnalysis(Location.Code, Item."No."));
    end;

    procedure RunAnalysis(LocationFilter: Text; ItemFilter: Text): Integer
    var
        AnalysisMgt: Codeunit "GSO IR Analysis Mgt";
    begin
        exit(AnalysisMgt.RunAnalysis(LocationFilter, ItemFilter));
    end;

    procedure CreateFinding(var Finding: Record "GSO IR Finding"; RunNo: Integer; Rule: Enum "GSO IR Rule")
    var
        FindingMgt: Codeunit "GSO IR Finding Mgt";
    begin
        FindingMgt.InitFinding(Finding, RunNo, Rule, Enum::"GSO IR Severity"::Warning, '', '', '');
        FindingMgt.InsertFinding(Finding);
    end;

    procedure CountFindings(RunNo: Integer; Rule: Enum "GSO IR Rule"): Integer
    var
        Finding: Record "GSO IR Finding";
    begin
        Finding.SetRange("Run No.", RunNo);
        Finding.SetRange(Rule, Rule);
        exit(Finding.Count());
    end;

    procedure CountAllFindings(RunNo: Integer): Integer
    var
        Finding: Record "GSO IR Finding";
    begin
        Finding.SetRange("Run No.", RunNo);
        exit(Finding.Count());
    end;

    procedure GetFinding(RunNo: Integer; Rule: Enum "GSO IR Rule"; var Finding: Record "GSO IR Finding")
    begin
        Finding.SetRange("Run No.", RunNo);
        Finding.SetRange(Rule, Rule);
        Finding.FindFirst();
    end;

    procedure AdjustmentBinCode(): Code[20]
    begin
        exit('ADJUSTMENT');
    end;

    procedure StockBinCode(): Code[20]
    begin
        exit('STOCK-1');
    end;

    procedure SecondBinCode(): Code[20]
    begin
        exit('STOCK-2');
    end;
}
