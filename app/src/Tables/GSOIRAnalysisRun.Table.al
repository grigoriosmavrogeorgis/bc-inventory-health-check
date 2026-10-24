namespace GMSOFT.InventoryHealthCheck;

table 73033901 "GSO IR Analysis Run"
{
    Caption = 'Inventory Health Check Analysis Run';
    DataClassification = CustomerContent;
    DrillDownPageId = "GSO IR Analysis Runs";
    LookupPageId = "GSO IR Analysis Runs";

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the analysis run.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "Started At"; DateTime)
        {
            Caption = 'Started At';
            ToolTip = 'Specifies when the analysis started.';
            Editable = false;
        }
        field(3; "Finished At"; DateTime)
        {
            Caption = 'Finished At';
            ToolTip = 'Specifies when the analysis finished.';
            Editable = false;
        }
        field(4; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the user who ran the analysis.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(5; Status; Enum "GSO IR Run Status")
        {
            Caption = 'Status';
            ToolTip = 'Specifies if the analysis is running, completed or failed.';
            Editable = false;
        }
        field(6; "Location Filter"; Text[250])
        {
            Caption = 'Location Filter';
            ToolTip = 'Specifies the location filter that the analysis used.';
            Editable = false;
        }
        field(7; "Item Filter"; Text[250])
        {
            Caption = 'Item Filter';
            ToolTip = 'Specifies the item filter that the analysis used.';
            Editable = false;
        }
        field(8; "Locations Analysed"; Integer)
        {
            Caption = 'Locations Analysed';
            ToolTip = 'Specifies how many locations the analysis checked.';
            Editable = false;
        }
        field(9; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            ToolTip = 'Specifies why the analysis failed.';
            Editable = false;
        }
        field(10; "Duration"; Duration)
        {
            Caption = 'Duration';
            ToolTip = 'Specifies how long the analysis took.';
            Editable = false;
        }
        field(20; "No. of Findings"; Integer)
        {
            Caption = 'No. of Findings';
            ToolTip = 'Specifies how many differences the analysis found.';
            FieldClass = FlowField;
            CalcFormula = count("GSO IR Finding" where("Run No." = field("No.")));
            Editable = false;
        }
        field(21; "No. of Critical"; Integer)
        {
            Caption = 'Critical';
            ToolTip = 'Specifies how many critical differences the analysis found. Critical differences have no standard posting that fixes them.';
            FieldClass = FlowField;
            CalcFormula = count("GSO IR Finding" where("Run No." = field("No."), Severity = const(Critical)));
            Editable = false;
        }
        field(22; "No. of Warnings"; Integer)
        {
            Caption = 'Warnings';
            ToolTip = 'Specifies how many warnings the analysis found.';
            FieldClass = FlowField;
            CalcFormula = count("GSO IR Finding" where("Run No." = field("No."), Severity = const(Warning)));
            Editable = false;
        }
        field(23; "No. of Info"; Integer)
        {
            Caption = 'Info';
            ToolTip = 'Specifies how many informational findings the analysis found, such as pending warehouse adjustments.';
            FieldClass = FlowField;
            CalcFormula = count("GSO IR Finding" where("Run No." = field("No."), Severity = const(Info)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        Finding: Record "GSO IR Finding";
    begin
        Finding.SetRange("Run No.", "No.");
        Finding.DeleteAll(false);
    end;
}
