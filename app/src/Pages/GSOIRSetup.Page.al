namespace GMSOFT.InventoryHealthCheck;

page 73031485 "GSO IR Setup"
{
    Caption = 'Inventory Health Check Setup';
    PageType = Card;
    SourceTable = "GSO IR Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;
    AboutTitle = 'About Inventory Health Check';
    AboutText = 'The app compares the item ledger, the warehouse entries and the bin contents and explains each difference. It never posts and never changes ledger entries. You review and post any correction yourself.';

    layout
    {
        area(Content)
        {
            group(Analysis)
            {
                Caption = 'Analysis';

                field("Location Filter"; Rec."Location Filter")
                {
                }
                field("Tolerance (Base)"; Rec."Tolerance (Base)")
                {
                }
                field("Max. Pending Adj. Age (Days)"; Rec."Max. Pending Adj. Age (Days)")
                {
                }
                field("Find First Date"; Rec."Find First Date")
                {
                }
            }
            // The correction journal and notification fields of the table are for the journal preparer
            // and the scheduled check; they are shown only when those features exist.
        }
    }

    actions
    {
        area(Navigation)
        {
            action(AnalysisRuns)
            {
                Caption = 'Analysis Runs';
                ToolTip = 'View the log of analysis runs.';
                Image = Log;
                RunObject = page "GSO IR Analysis Runs";
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.InsertIfNotExists();
    end;
}
