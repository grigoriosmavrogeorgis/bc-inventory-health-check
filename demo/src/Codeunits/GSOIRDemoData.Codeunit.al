namespace GMSOFT.InventoryHealthCheck.Demo;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;

/// <summary>
/// Builds a demo scenario in which every Inventory Health Check rule has something to report:
///   IHC-DIRECT (directed put-away and pick)
///     IHC-1001  healthy item, no finding
///     IHC-1002  R3 pending warehouse adjustment (older than a day, so a warning) and R8 open phys. inventory journal
///     IHC-1003  R1 item ledger 40, warehouse 30
///     IHC-1004  R4 negative bin content in STOCK-2
///   IHC-BINS (bin mandatory)
///     IHC-2001  R2 lot quantities swapped between LOT-A and LOT-B
///     IHC-2002  R5 warehouse entries in BOX of 10, the item now says BOX of 12
///     IHC-2003  R6 quantity in a deleted bin (warning) and in a bin blocked for outbound (info)
///     IHC-2004  R9 quantity in STOCK-1 without a bin content line
///     IHC-2005  R7 remaining quantity 30 against inventory 20
/// The differences cannot come from normal posting, so the entries are inserted directly, like the
/// test helper does. Use it only in demo, trial or training companies. It only adds its own items and
/// locations and does nothing when the demo locations already exist.
/// </summary>
codeunit 61100 "GSO IR Demo Data"
{
    Access = Public;
    Permissions = tabledata "Item Ledger Entry" = ri,
                  tabledata "Warehouse Entry" = ri,
                  tabledata "Bin Content" = ri;

    var
        DirectedLocationTok: Label 'IHC-DIRECT', Locked = true;
        BinLocationTok: Label 'IHC-BINS', Locked = true;
        DirectedLocationNameTok: Label 'Health Check demo - directed', Locked = true;
        BinLocationNameTok: Label 'Health Check demo - bins', Locked = true;
        AdjustmentBinTok: Label 'ADJUSTMENT', Locked = true;
        StockBinTok: Label 'STOCK-1', Locked = true;
        SecondBinTok: Label 'STOCK-2', Locked = true;
        QuarantineBinTok: Label 'QUARANTINE', Locked = true;
        DeletedBinTok: Label 'OLD-BIN', Locked = true;
        PiecesTok: Label 'PCS', Locked = true;
        BoxTok: Label 'BOX', Locked = true;
        LotTrackingTok: Label 'IHC-LOT', Locked = true;
        LotATok: Label 'LOT-A', Locked = true;
        LotBTok: Label 'LOT-B', Locked = true;
        PhysInventoryTemplateTok: Label 'IHC-PHYS', Locked = true;
        DefaultBatchTok: Label 'DEFAULT', Locked = true;
        DocumentNoTok: Label 'IHC-DEMO', Locked = true;

    trigger OnRun()
    begin
        CreateDemoData();
    end;

    procedure CreateDemoData()
    begin
        if DemoDataExists() then
            exit;

        CreateUnitsOfMeasure();
        CreateLocations();
        CreateDirectedScenario();
        CreateBinScenario();
    end;

    procedure DemoDataExists(): Boolean
    var
        Location: Record Location;
    begin
        exit(Location.Get(DirectedLocationTok) or Location.Get(BinLocationTok));
    end;

    procedure DirectedLocationCode(): Code[10]
    begin
        exit(DirectedLocationTok);
    end;

    procedure BinLocationCode(): Code[10]
    begin
        exit(BinLocationTok);
    end;

    local procedure CreateDirectedScenario()
    var
        Item: Record Item;
    begin
        CreateItem(Item, 'IHC-1001', 'Health Check demo - healthy item');
        InsertItemLedgerEntry(Item, DirectedLocationTok, 100, 100, StartDate(), '');
        InsertWarehouseEntry(Item, DirectedLocationTok, StockBinTok, 100, StartDate(), '');

        // A count found 3 less in STOCK-1; the warehouse adjustment was registered 5 days ago but never posted.
        CreateItem(Item, 'IHC-1002', 'Health Check demo - pending adjustment');
        InsertItemLedgerEntry(Item, DirectedLocationTok, 50, 50, StartDate(), '');
        InsertWarehouseEntry(Item, DirectedLocationTok, StockBinTok, 50, StartDate(), '');
        InsertWarehouseEntry(Item, DirectedLocationTok, StockBinTok, -3, Today() - 5, '');
        InsertWarehouseEntry(Item, DirectedLocationTok, AdjustmentBinTok, 3, Today() - 5, '');
        CreateOpenPhysInventoryLine(Item, DirectedLocationTok, StockBinTok, 47);

        CreateItem(Item, 'IHC-1003', 'Health Check demo - ledger vs. warehouse');
        InsertItemLedgerEntry(Item, DirectedLocationTok, 40, 40, StartDate(), '');
        InsertWarehouseEntry(Item, DirectedLocationTok, StockBinTok, 30, StartDate(), '');

        CreateItem(Item, 'IHC-1004', 'Health Check demo - negative bin');
        InsertItemLedgerEntry(Item, DirectedLocationTok, 20, 20, StartDate(), '');
        InsertWarehouseEntry(Item, DirectedLocationTok, StockBinTok, 30, StartDate(), '');
        InsertWarehouseEntry(Item, DirectedLocationTok, SecondBinTok, -10, Today() - 10, '');
    end;

    local procedure CreateBinScenario()
    var
        Item: Record Item;
    begin
        CreateItem(Item, 'IHC-2001', 'Health Check demo - lot mismatch');
        SetLotTracking(Item);
        InsertItemLedgerEntry(Item, BinLocationTok, 10, 10, StartDate(), LotATok);
        InsertItemLedgerEntry(Item, BinLocationTok, 10, 10, StartDate(), LotBTok);
        InsertWarehouseEntry(Item, BinLocationTok, StockBinTok, 15, StartDate(), LotATok);
        InsertWarehouseEntry(Item, BinLocationTok, StockBinTok, 5, StartDate(), LotBTok);

        // Registered as 5 boxes of 10; later the box was changed to 12 pieces.
        CreateItem(Item, 'IHC-2002', 'Health Check demo - changed box size');
        CreateItemUnitOfMeasure(Item."No.", BoxTok, 12);
        InsertItemLedgerEntry(Item, BinLocationTok, 50, 50, StartDate(), '');
        InsertWarehouseEntryCore(Item, BinLocationTok, StockBinTok, BoxTok, 10, 5, 50, StartDate(), '', true);

        CreateItem(Item, 'IHC-2003', 'Health Check demo - invalid bins');
        InsertItemLedgerEntry(Item, BinLocationTok, 25, 25, StartDate(), '');
        InsertWarehouseEntry(Item, BinLocationTok, DeletedBinTok, 15, StartDate(), '');
        InsertWarehouseEntry(Item, BinLocationTok, QuarantineBinTok, 10, StartDate(), '');

        CreateItem(Item, 'IHC-2004', 'Health Check demo - missing bin content');
        InsertItemLedgerEntry(Item, BinLocationTok, 12, 12, StartDate(), '');
        InsertWarehouseEntryCore(Item, BinLocationTok, StockBinTok, PiecesTok, 1, 12, 12, StartDate(), '', false);

        // The sale of 10 closed its own entry but never reduced the purchase it should have applied to.
        CreateItem(Item, 'IHC-2005', 'Health Check demo - open entries');
        InsertItemLedgerEntry(Item, BinLocationTok, 30, 30, StartDate(), '');
        InsertItemLedgerEntry(Item, BinLocationTok, -10, 0, Today() - 10, '');
        InsertWarehouseEntry(Item, BinLocationTok, StockBinTok, 20, StartDate(), '');
    end;

    local procedure CreateUnitsOfMeasure()
    begin
        CreateUnitOfMeasure(PiecesTok, 'Piece');
        CreateUnitOfMeasure(BoxTok, 'Box');
    end;

    local procedure CreateUnitOfMeasure(UnitOfMeasureCode: Code[10]; UnitOfMeasureDescription: Text[50])
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if UnitOfMeasure.Get(UnitOfMeasureCode) then
            exit;
        UnitOfMeasure.Init();
        UnitOfMeasure.Code := UnitOfMeasureCode;
        UnitOfMeasure.Description := UnitOfMeasureDescription;
        UnitOfMeasure.Insert(true);
    end;

    local procedure CreateLocations()
    begin
        CreateLocation(DirectedLocationTok, DirectedLocationNameTok, true);
        CreateBin(DirectedLocationTok, AdjustmentBinTok);
        CreateBin(DirectedLocationTok, StockBinTok);
        CreateBin(DirectedLocationTok, SecondBinTok);

        CreateLocation(BinLocationTok, BinLocationNameTok, false);
        CreateBin(BinLocationTok, StockBinTok);
        CreateBin(BinLocationTok, QuarantineBinTok);
        BlockBinForOutbound(BinLocationTok, QuarantineBinTok);
        // OLD-BIN is not created: its entries stand for a bin that was deleted while it held stock.
    end;

    local procedure CreateLocation(LocationCode: Code[10]; LocationName: Text[100]; Directed: Boolean)
    var
        Location: Record Location;
    begin
        Location.Init();
        Location.Code := LocationCode;
        Location.Name := LocationName;
        Location."Bin Mandatory" := true;
        if Directed then begin
            Location."Require Receive" := true;
            Location."Require Shipment" := true;
            Location."Require Put-away" := true;
            Location."Require Pick" := true;
            Location."Directed Put-away and Pick" := true;
            Location."Adjustment Bin Code" := AdjustmentBinTok;
        end;
        Location.Insert(true);
    end;

    local procedure CreateBin(LocationCode: Code[10]; BinCode: Code[20])
    var
        Bin: Record Bin;
    begin
        // Inserted without the trigger: bins at a directed location otherwise need zones and bin types,
        // which the health check does not look at.
        Bin.Init();
        Bin."Location Code" := LocationCode;
        Bin.Code := BinCode;
        Bin.Insert(false);
    end;

    local procedure BlockBinForOutbound(LocationCode: Code[10]; BinCode: Code[20])
    var
        Bin: Record Bin;
    begin
        Bin.Get(LocationCode, BinCode);
        Bin."Block Movement" := Bin."Block Movement"::Outbound;
        Bin.Modify(false);
    end;

    local procedure CreateItem(var Item: Record Item; ItemNo: Code[20]; ItemDescription: Text[100])
    begin
        Item.Init();
        Item."No." := ItemNo;
        Item.Description := ItemDescription;
        Item.Type := Item.Type::Inventory;
        Item.Insert(true);
        CreateItemUnitOfMeasure(ItemNo, PiecesTok, 1);
        Item."Base Unit of Measure" := PiecesTok;
        Item.Modify(true);
    end;

    local procedure CreateItemUnitOfMeasure(ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; QtyPerUnitOfMeasure: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitOfMeasure.Init();
        ItemUnitOfMeasure."Item No." := ItemNo;
        ItemUnitOfMeasure.Code := UnitOfMeasureCode;
        ItemUnitOfMeasure."Qty. per Unit of Measure" := QtyPerUnitOfMeasure;
        ItemUnitOfMeasure.Insert(true);
    end;

    local procedure SetLotTracking(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if not ItemTrackingCode.Get(LotTrackingTok) then begin
            ItemTrackingCode.Init();
            ItemTrackingCode.Code := LotTrackingTok;
            ItemTrackingCode.Description := 'Health Check demo - lot tracking';
            ItemTrackingCode."Lot Specific Tracking" := true;
            ItemTrackingCode."Lot Warehouse Tracking" := true;
            ItemTrackingCode.Insert(true);
        end;
        Item."Item Tracking Code" := ItemTrackingCode.Code;
        Item.Modify(true);
    end;

    local procedure CreateOpenPhysInventoryLine(Item: Record Item; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        if not WarehouseJournalTemplate.Get(PhysInventoryTemplateTok) then begin
            WarehouseJournalTemplate.Init();
            WarehouseJournalTemplate.Name := PhysInventoryTemplateTok;
            WarehouseJournalTemplate.Description := 'Health Check demo - physical inventory';
            WarehouseJournalTemplate.Type := WarehouseJournalTemplate.Type::"Physical Inventory";
            WarehouseJournalTemplate.Insert(true);
        end;

        if not WarehouseJournalBatch.Get(PhysInventoryTemplateTok, DefaultBatchTok, LocationCode) then begin
            WarehouseJournalBatch.Init();
            WarehouseJournalBatch."Journal Template Name" := PhysInventoryTemplateTok;
            WarehouseJournalBatch.Name := DefaultBatchTok;
            WarehouseJournalBatch."Location Code" := LocationCode;
            WarehouseJournalBatch.Insert(false);
        end;

        // A count that was calculated but never registered: Calculate Warehouse Adjustment must wait for it.
        WarehouseJournalLine.Init();
        WarehouseJournalLine."Journal Template Name" := PhysInventoryTemplateTok;
        WarehouseJournalLine."Journal Batch Name" := DefaultBatchTok;
        WarehouseJournalLine."Location Code" := LocationCode;
        WarehouseJournalLine."Line No." := 10000;
        WarehouseJournalLine."Registering Date" := Today();
        WarehouseJournalLine."Item No." := Item."No.";
        WarehouseJournalLine.Description := Item.Description;
        WarehouseJournalLine."Bin Code" := BinCode;
        WarehouseJournalLine."Unit of Measure Code" := Item."Base Unit of Measure";
        WarehouseJournalLine."Qty. per Unit of Measure" := 1;
        WarehouseJournalLine."Phys. Inventory" := true;
        WarehouseJournalLine."Qty. (Calculated)" := Quantity;
        WarehouseJournalLine."Qty. (Calculated) (Base)" := Quantity;
        WarehouseJournalLine."Qty. (Phys. Inventory)" := Quantity;
        WarehouseJournalLine."Qty. (Phys. Inventory) (Base)" := Quantity;
        WarehouseJournalLine.Insert(false);
    end;

    local procedure InsertItemLedgerEntry(Item: Record Item; LocationCode: Code[10]; Quantity: Decimal; RemainingQuantity: Decimal; PostingDate: Date; LotNo: Code[50])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        EntryNo: Integer;
    begin
        ItemLedgerEntry.ReadIsolation(IsolationLevel::UpdLock);
        if ItemLedgerEntry.FindLast() then
            EntryNo := ItemLedgerEntry."Entry No.";
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := EntryNo + 1;
        ItemLedgerEntry."Item No." := Item."No.";
        ItemLedgerEntry."Location Code" := LocationCode;
        ItemLedgerEntry."Posting Date" := PostingDate;
        ItemLedgerEntry."Document No." := DocumentNoTok;
        ItemLedgerEntry.Description := Item.Description;
        if Quantity > 0 then
            ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::"Positive Adjmt."
        else
            ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::"Negative Adjmt.";
        ItemLedgerEntry.Quantity := Quantity;
        ItemLedgerEntry."Invoiced Quantity" := Quantity;
        ItemLedgerEntry."Remaining Quantity" := RemainingQuantity;
        ItemLedgerEntry.Open := RemainingQuantity <> 0;
        ItemLedgerEntry.Positive := Quantity > 0;
        ItemLedgerEntry."Completely Invoiced" := true;
        ItemLedgerEntry."Unit of Measure Code" := Item."Base Unit of Measure";
        ItemLedgerEntry."Qty. per Unit of Measure" := 1;
        ItemLedgerEntry."Lot No." := LotNo;
        ItemLedgerEntry.Insert(false);
    end;

    local procedure InsertWarehouseEntry(Item: Record Item; LocationCode: Code[10]; BinCode: Code[20]; QtyBase: Decimal; RegisteringDate: Date; LotNo: Code[50])
    begin
        InsertWarehouseEntryCore(Item, LocationCode, BinCode, Item."Base Unit of Measure", 1, QtyBase, QtyBase, RegisteringDate, LotNo, true);
    end;

    local procedure InsertWarehouseEntryCore(Item: Record Item; LocationCode: Code[10]; BinCode: Code[20]; UnitOfMeasureCode: Code[10]; QtyPerUnitOfMeasure: Decimal; Quantity: Decimal; QtyBase: Decimal; RegisteringDate: Date; LotNo: Code[50]; WithBinContent: Boolean)
    var
        WarehouseEntry: Record "Warehouse Entry";
        EntryNo: Integer;
    begin
        WarehouseEntry.ReadIsolation(IsolationLevel::UpdLock);
        if WarehouseEntry.FindLast() then
            EntryNo := WarehouseEntry."Entry No.";
        WarehouseEntry.Init();
        WarehouseEntry."Entry No." := EntryNo + 1;
        WarehouseEntry."Item No." := Item."No.";
        WarehouseEntry.Description := Item.Description;
        WarehouseEntry."Location Code" := LocationCode;
        WarehouseEntry."Bin Code" := BinCode;
        WarehouseEntry."Registering Date" := RegisteringDate;
        WarehouseEntry."Reference No." := DocumentNoTok;
        if QtyBase > 0 then
            WarehouseEntry."Entry Type" := WarehouseEntry."Entry Type"::"Positive Adjmt."
        else
            WarehouseEntry."Entry Type" := WarehouseEntry."Entry Type"::"Negative Adjmt.";
        WarehouseEntry."Unit of Measure Code" := UnitOfMeasureCode;
        WarehouseEntry."Qty. per Unit of Measure" := QtyPerUnitOfMeasure;
        WarehouseEntry.Quantity := Quantity;
        WarehouseEntry."Qty. (Base)" := QtyBase;
        WarehouseEntry."Lot No." := LotNo;
        WarehouseEntry.Insert(false);
        if WithBinContent then
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

    local procedure StartDate(): Date
    begin
        exit(Today() - 30);
    end;
}
