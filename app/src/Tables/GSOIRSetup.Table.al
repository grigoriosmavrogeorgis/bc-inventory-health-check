namespace GMSOFT.InventoryHealthCheck;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Journal;
using Microsoft.Warehouse.Journal;
using System.Security.AccessControl;

table 73031485 "GSO IR Setup"
{
    Caption = 'Inventory Health Check Setup';
    DataClassification = CustomerContent;
    DrillDownPageId = "GSO IR Setup";
    LookupPageId = "GSO IR Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            AllowInCustomizations = Never;
        }
        field(10; "Location Filter"; Text[250])
        {
            Caption = 'Location Filter';
            ToolTip = 'Specifies the locations that the analysis checks. Leave blank to check every location with Bin Mandatory turned on.';
        }
        field(11; "Tolerance (Base)"; Decimal)
        {
            Caption = 'Tolerance (Base)';
            ToolTip = 'Specifies the largest difference, in the base unit of measure, that is not reported. Leave 0 to report every difference.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(12; "Max. Pending Adj. Age (Days)"; Integer)
        {
            Caption = 'Max. Pending Adjustment Age (Days)';
            ToolTip = 'Specifies how many days quantity can stay in the adjustment bin before the finding becomes a warning. Microsoft recommends posting warehouse adjustments regularly, for example daily.';
            MinValue = 0;
            InitValue = 1;
        }
        field(13; "Find First Date"; Boolean)
        {
            Caption = 'Find First Date of Difference';
            ToolTip = 'Specifies if the analysis walks back through the entries to find the date on which each difference first appeared. This points to the document that created it, but makes the analysis slower.';
            InitValue = true;
        }
        field(20; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code that prepared journal lines get, so that the posted entries can be traced back to the finding.';
            TableRelation = "Reason Code";
        }
        field(21; "Item Jnl. Template Name"; Code[10])
        {
            Caption = 'Item Journal Template';
            ToolTip = 'Specifies the item journal template in which correction journals are prepared.';
            TableRelation = "Item Journal Template";

            trigger OnValidate()
            begin
                if "Item Jnl. Template Name" <> xRec."Item Jnl. Template Name" then
                    "Item Jnl. Batch Name" := '';
            end;
        }
        field(22; "Item Jnl. Batch Name"; Code[10])
        {
            Caption = 'Item Journal Batch';
            ToolTip = 'Specifies the item journal batch in which correction journals are prepared.';
            TableRelation = "Item Journal Batch".Name where("Journal Template Name" = field("Item Jnl. Template Name"));
        }
        field(23; "Whse. Jnl. Template Name"; Code[10])
        {
            Caption = 'Warehouse Journal Template';
            ToolTip = 'Specifies the warehouse journal template in which correction journals are prepared.';
            TableRelation = "Warehouse Journal Template";

            trigger OnValidate()
            begin
                if "Whse. Jnl. Template Name" <> xRec."Whse. Jnl. Template Name" then
                    "Whse. Jnl. Batch Name" := '';
            end;
        }
        field(24; "Whse. Jnl. Batch Name"; Code[10])
        {
            Caption = 'Warehouse Journal Batch';
            ToolTip = 'Specifies the warehouse journal batch in which correction journals are prepared.';
            TableRelation = "Warehouse Journal Batch".Name where("Journal Template Name" = field("Whse. Jnl. Template Name"));
        }
        field(30; "Notification User ID"; Code[50])
        {
            Caption = 'Notification User ID';
            ToolTip = 'Specifies the user who is notified when the scheduled health check finds new critical differences.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        RecordHasBeenRead: Boolean;

    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        if not Get() then
            Init();
        RecordHasBeenRead := true;
    end;

    procedure InsertIfNotExists()
    begin
        Reset();
        if not Get() then begin
            Init();
            Insert(true);
        end;
    end;
}
