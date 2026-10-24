namespace GMSOFT.InventoryHealthCheck;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

report 73033900 "GSO IR Run Analysis"
{
    Caption = 'Run Inventory Health Check';
    ToolTip = 'Compare the item ledger, the warehouse entries and the bin contents, and list every difference. The analysis only reads entries; it never posts or changes them.';
    ProcessingOnly = true;
    UsageCategory = Tasks;
    ApplicationArea = All;

    dataset
    {
        dataitem(Location; Location)
        {
            DataItemTableView = sorting(Code) where("Bin Mandatory" = const(true));
            RequestFilterFields = "Code";
            RequestFilterHeading = 'Locations';

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Items';

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'Run the health check';
        AboutText = 'Filter on the locations and items to check. Only locations with Bin Mandatory are checked. Leave the location filter blank to use the filter from the setup.';
    }

    trigger OnPreReport()
    var
        AnalysisMgt: Codeunit "GSO IR Analysis Mgt";
    begin
        RunNo := AnalysisMgt.RunAnalysisForSelection(Location, Item);
    end;

    trigger OnPostReport()
    var
        AnalysisRun: Record "GSO IR Analysis Run";
        Finding: Record "GSO IR Finding";
        AnalysisMgt: Codeunit "GSO IR Analysis Mgt";
    begin
        // In the background (job queue) a failed analysis must fail the report, so the scheduler sees it.
        if not GuiAllowed() then begin
            AnalysisMgt.CheckRunSucceeded(RunNo);
            exit;
        end;
        AnalysisRun.Get(RunNo);
        if AnalysisRun.Status = AnalysisRun.Status::Failed then begin
            Message(AnalysisFailedMsg, AnalysisRun."No.", AnalysisRun."Error Message");
            exit;
        end;
        AnalysisRun.CalcFields("No. of Findings", "No. of Critical", "No. of Warnings", "No. of Info");
        if AnalysisRun."No. of Findings" = 0 then begin
            Message(NoFindingsMsg, AnalysisRun."Locations Analysed");
            exit;
        end;
        Message(AnalysisCompletedMsg, AnalysisRun."Locations Analysed", AnalysisRun."No. of Critical", AnalysisRun."No. of Warnings", AnalysisRun."No. of Info");
        Finding.SetRange("Run No.", AnalysisRun."No.");
        Page.Run(Page::"GSO IR Findings", Finding);
    end;

    var
        RunNo: Integer;
        AnalysisCompletedMsg: Label '%1 location(s) checked: %2 critical, %3 warning(s) and %4 info finding(s).', Comment = '%1 = number of locations, %2 = critical, %3 = warnings, %4 = info';
        NoFindingsMsg: Label '%1 location(s) checked. The item ledger, the warehouse entries and the bin contents agree.', Comment = '%1 = number of locations';
        AnalysisFailedMsg: Label 'Analysis %1 failed: %2', Comment = '%1 = run number, %2 = error message';
}
