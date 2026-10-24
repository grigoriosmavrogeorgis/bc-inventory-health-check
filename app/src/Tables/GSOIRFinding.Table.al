namespace GMSOFT.InventoryHealthCheck;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

table 73033902 "GSO IR Finding"
{
    Caption = 'Inventory Health Check Finding';
    DataClassification = CustomerContent;
    DrillDownPageId = "GSO IR Findings";
    LookupPageId = "GSO IR Findings";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the finding.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "Run No."; Integer)
        {
            Caption = 'Run No.';
            ToolTip = 'Specifies the analysis run that found the difference.';
            TableRelation = "GSO IR Analysis Run";
            Editable = false;
        }
        field(3; Rule; Enum "GSO IR Rule")
        {
            Caption = 'Rule';
            ToolTip = 'Specifies the check that found the difference.';
            Editable = false;
        }
        field(4; Severity; Enum "GSO IR Severity")
        {
            Caption = 'Severity';
            ToolTip = 'Specifies how serious the difference is. Critical differences have no standard posting that fixes them.';
            Editable = false;
        }
        field(5; Status; Enum "GSO IR Finding Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies where the finding is in your review.';

            trigger OnValidate()
            begin
                if Status <> xRec.Status then begin
                    "Status Changed By" := CopyStr(UserId(), 1, MaxStrLen("Status Changed By"));
                    "Status Changed At" := CurrentDateTime();
                end;
            end;
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the item that has the difference.';
            TableRelation = Item;
            Editable = false;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the item variant that has the difference.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
            Editable = false;
        }
        field(12; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the location that has the difference.';
            TableRelation = Location;
            Editable = false;
        }
        field(13; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            ToolTip = 'Specifies the bin that has the difference, if the check is per bin.';
            Editable = false;
        }
        field(14; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies the unit of measure of the warehouse entries, if the check is per unit of measure.';
            Editable = false;
        }
        field(15; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            ToolTip = 'Specifies the lot number that has the difference.';
            Editable = false;
        }
        field(16; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            ToolTip = 'Specifies the serial number that has the difference.';
            Editable = false;
        }
        field(17; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            ToolTip = 'Specifies the package number that has the difference.';
            Editable = false;
        }
        field(18; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            ToolTip = 'Specifies the quantity per unit of measure of the warehouse entries, if the check is per conversion factor.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(20; "Item Ledger Qty. (Base)"; Decimal)
        {
            Caption = 'Item Ledger Qty. (Base)';
            ToolTip = 'Specifies the quantity in the item ledger entries, in the base unit of measure.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(21; "Warehouse Qty. (Base)"; Decimal)
        {
            Caption = 'Warehouse Qty. (Base)';
            ToolTip = 'Specifies the quantity in the warehouse entries, in the base unit of measure. For the item ledger check this includes the adjustment bin.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(22; "Difference (Base)"; Decimal)
        {
            Caption = 'Difference (Base)';
            ToolTip = 'Specifies the difference in the base unit of measure.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(23; "First Date"; Date)
        {
            Caption = 'First Date';
            ToolTip = 'Specifies the posting or registering date on which the difference first appeared. Look at the documents posted on this date to find the cause.';
            Editable = false;
        }
        field(30; "Probable Cause"; Text[250])
        {
            Caption = 'Probable Cause';
            ToolTip = 'Specifies the most likely reason for the difference.';
            Editable = false;
        }
        field(31; Advice; Text[250])
        {
            Caption = 'Advice';
            ToolTip = 'Specifies what Microsoft best practice recommends for this kind of difference. The app never posts; you review and post any correction.';
            Editable = false;
        }
        field(32; Comment; Text[250])
        {
            Caption = 'Comment';
            ToolTip = 'Specifies your own notes about the finding.';
        }
        field(40; "Created At"; DateTime)
        {
            Caption = 'Created At';
            ToolTip = 'Specifies when the finding was created.';
            Editable = false;
        }
        field(41; "Status Changed By"; Code[50])
        {
            Caption = 'Status Changed By';
            ToolTip = 'Specifies the user who last changed the status.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(42; "Status Changed At"; DateTime)
        {
            Caption = 'Status Changed At';
            ToolTip = 'Specifies when the status was last changed.';
            Editable = false;
        }
        field(50; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
            ToolTip = 'Specifies the description of the item.';
            FieldClass = FlowField;
            CalcFormula = lookup(Item.Description where("No." = field("Item No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(RunSeverity; "Run No.", Severity)
        {
        }
        key(ItemLocation; "Item No.", "Variant Code", "Location Code")
        {
        }
    }
}
