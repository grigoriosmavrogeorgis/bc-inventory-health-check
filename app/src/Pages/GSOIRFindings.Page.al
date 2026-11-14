namespace GMSOFT.InventoryHealthCheck;

page 73031487 "GSO IR Findings"
{
    Caption = 'Inventory Health Check Findings';
    PageType = List;
    SourceTable = "GSO IR Finding";
    SourceTableView = sorting("Run No.", Severity) order(descending);
    ApplicationArea = All;
    UsageCategory = Lists;
    InsertAllowed = false;
    DeleteAllowed = false;
    AboutTitle = 'About findings';
    AboutText = 'Each line is one difference with its probable cause and the Microsoft best practice to fix it. Drill down to the entries behind it. This app proposes corrections; posting them is the responsibility of the user. Consult your partner for directed put-away and pick locations.';

    layout
    {
        area(Content)
        {
            repeater(Findings)
            {
                field(Severity; Rec.Severity)
                {
                    StyleExpr = SeverityStyle;
                }
                field(Rule; Rec.Rule)
                {
                }
                field("Location Code"; Rec."Location Code")
                {
                }
                field("Item No."; Rec."Item No.")
                {
                }
                field("Item Description"; Rec."Item Description")
                {
                }
                field("Variant Code"; Rec."Variant Code")
                {
                }
                field("Bin Code"; Rec."Bin Code")
                {
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    Visible = false;
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    Visible = false;
                }
                field("Lot No."; Rec."Lot No.")
                {
                }
                field("Serial No."; Rec."Serial No.")
                {
                }
                field("Package No."; Rec."Package No.")
                {
                    Visible = false;
                }
                field("Item Ledger Qty. (Base)"; Rec."Item Ledger Qty. (Base)")
                {
                    trigger OnDrillDown()
                    begin
                        FindingMgt.ShowItemLedgerEntries(Rec);
                    end;
                }
                field("Warehouse Qty. (Base)"; Rec."Warehouse Qty. (Base)")
                {
                    trigger OnDrillDown()
                    begin
                        FindingMgt.ShowWarehouseEntries(Rec);
                    end;
                }
                field("Difference (Base)"; Rec."Difference (Base)")
                {
                    Style = Strong;
                }
                field("First Date"; Rec."First Date")
                {
                }
                field("Probable Cause"; Rec."Probable Cause")
                {
                }
                field(Advice; Rec.Advice)
                {
                }
                field(Status; Rec.Status)
                {
                }
                field(Comment; Rec.Comment)
                {
                }
                field("Run No."; Rec."Run No.")
                {
                    Visible = false;
                }
                field("Status Changed By"; Rec."Status Changed By")
                {
                    Visible = false;
                }
                field("Status Changed At"; Rec."Status Changed At")
                {
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(ItemLedgerEntries)
            {
                Caption = 'Item Ledger Entries';
                ToolTip = 'View the item ledger entries behind this finding.';
                Image = ItemLedger;

                trigger OnAction()
                begin
                    FindingMgt.ShowItemLedgerEntries(Rec);
                end;
            }
            action(WarehouseEntries)
            {
                Caption = 'Warehouse Entries';
                ToolTip = 'View the warehouse entries behind this finding.';
                Image = BinLedger;

                trigger OnAction()
                begin
                    FindingMgt.ShowWarehouseEntries(Rec);
                end;
            }
            action(BinContents)
            {
                Caption = 'Bin Contents';
                ToolTip = 'View the bin contents of the item at this location.';
                Image = BinContent;

                trigger OnAction()
                begin
                    FindingMgt.ShowBinContents(Rec);
                end;
            }
        }
        area(Processing)
        {
            action(MarkReviewed)
            {
                Caption = 'Mark as Reviewed';
                ToolTip = 'Set the status of the selected findings to Reviewed.';
                Image = Approve;

                trigger OnAction()
                begin
                    SetStatusOnSelection(Rec.Status::Reviewed);
                end;
            }
            action(CloseFinding)
            {
                Caption = 'Close';
                ToolTip = 'Set the status of the selected findings to Closed.';
                Image = Close;

                trigger OnAction()
                begin
                    SetStatusOnSelection(Rec.Status::Closed);
                end;
            }
            action(GetHelp)
            {
                Caption = 'Get Help from GMSOFT';
                ToolTip = 'Open the GMSOFT web page to ask for help with differences that no standard posting fixes. Nothing about the finding is sent.';
                Image = Help;

                trigger OnAction()
                begin
                    FindingMgt.OpenGetHelp(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Entries)
            {
                Caption = 'Entries';

                actionref(ItemLedgerEntries_Promoted; ItemLedgerEntries)
                {
                }
                actionref(WarehouseEntries_Promoted; WarehouseEntries)
                {
                }
                actionref(BinContents_Promoted; BinContents)
                {
                }
            }
            group(Category_Review)
            {
                Caption = 'Review';

                actionref(MarkReviewed_Promoted; MarkReviewed)
                {
                }
                actionref(CloseFinding_Promoted; CloseFinding)
                {
                }
            }
            actionref(GetHelp_Promoted; GetHelp)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        case Rec.Severity of
            Rec.Severity::Critical:
                SeverityStyle := Format(PageStyle::Unfavorable);
            Rec.Severity::Warning:
                SeverityStyle := Format(PageStyle::Ambiguous);
            else
                SeverityStyle := Format(PageStyle::Standard);
        end;
    end;

    local procedure SetStatusOnSelection(NewStatus: Enum "GSO IR Finding Status")
    var
        Finding: Record "GSO IR Finding";
        Telemetry: Codeunit "GSO IR Telemetry";
        NoOfFindings: Integer;
    begin
        CurrPage.SetSelectionFilter(Finding);
        if Finding.FindSet(true) then
            repeat
                Finding.Validate(Status, NewStatus);
                Finding.Modify(true);
                NoOfFindings += 1;
            until Finding.Next() = 0;
        Telemetry.FindingStatusChanged(NewStatus, NoOfFindings);
        CurrPage.Update(false);
    end;

    var
        FindingMgt: Codeunit "GSO IR Finding Mgt";
        SeverityStyle: Text;
}
