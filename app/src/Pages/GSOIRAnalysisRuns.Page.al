namespace GMSOFT.InventoryHealthCheck;

page 73033901 "GSO IR Analysis Runs"
{
    Caption = 'Inventory Health Check Runs';
    PageType = List;
    SourceTable = "GSO IR Analysis Run";
    SourceTableView = sorting("No.") order(descending);
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    AboutTitle = 'About the analysis log';
    AboutText = 'Every analysis is logged here with the filters it used and the number of differences it found. Open a run to see its findings.';

    layout
    {
        area(Content)
        {
            repeater(Runs)
            {
                field("No."; Rec."No.")
                {
                }
                field("Started At"; Rec."Started At")
                {
                }
                field(Status; Rec.Status)
                {
                    StyleExpr = StatusStyle;
                }
                field("Location Filter"; Rec."Location Filter")
                {
                }
                field("Item Filter"; Rec."Item Filter")
                {
                }
                field("Locations Analysed"; Rec."Locations Analysed")
                {
                }
                field("No. of Critical"; Rec."No. of Critical")
                {
                    Style = Unfavorable;
                }
                field("No. of Warnings"; Rec."No. of Warnings")
                {
                    Style = Ambiguous;
                }
                field("No. of Info"; Rec."No. of Info")
                {
                }
                field("No. of Findings"; Rec."No. of Findings")
                {
                }
                field("User ID"; Rec."User ID")
                {
                }
                field(Duration; Rec.Duration)
                {
                }
                field("Finished At"; Rec."Finished At")
                {
                    Visible = false;
                }
                field("Error Message"; Rec."Error Message")
                {
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunAnalysis)
            {
                Caption = 'Run Analysis';
                ToolTip = 'Compare the item ledger, the warehouse entries and the bin contents. The analysis only reads entries.';
                Image = Start;
                RunObject = report "GSO IR Run Analysis";
            }
        }
        area(Navigation)
        {
            action(Findings)
            {
                Caption = 'Findings';
                ToolTip = 'View the differences that this run found.';
                Image = ErrorLog;
                RunObject = page "GSO IR Findings";
                RunPageLink = "Run No." = field("No.");
            }
            action(Setup)
            {
                Caption = 'Setup';
                ToolTip = 'Set up the locations and the tolerance of the analysis.';
                Image = Setup;
                RunObject = page "GSO IR Setup";
            }
        }
        area(Promoted)
        {
            actionref(RunAnalysis_Promoted; RunAnalysis)
            {
            }
            actionref(Findings_Promoted; Findings)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Failed:
                StatusStyle := Format(PageStyle::Unfavorable);
            Rec.Status::Running:
                StatusStyle := Format(PageStyle::Ambiguous);
            else
                StatusStyle := Format(PageStyle::Standard);
        end;
    end;

    var
        StatusStyle: Text;
}
