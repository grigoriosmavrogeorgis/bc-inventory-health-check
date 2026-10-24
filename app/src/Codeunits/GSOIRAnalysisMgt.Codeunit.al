namespace GMSOFT.InventoryHealthCheck;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.Text;

codeunit 73033907 "GSO IR Analysis Mgt"
{
    // Entry point for an analysis: logs the run, runs the engine and records the result.
    // The run log is read-only for users; only this codeunit and the engine write to it.
    Access = Internal;
    Permissions = tabledata "GSO IR Analysis Run" = rim;

    var
        NothingMatchesErr: Label 'No location or item matches the filters you set. Change the filters and run the analysis again.';
        AnalysisFailedErr: Label 'Analysis %1 failed: %2', Comment = '%1 = run number, %2 = error message';

    /// <summary>
    /// Runs the analysis for the locations and items that a request page selected, with filters on any
    /// field. The rules filter on Location Code and Item No. only, so other filters (for example Item
    /// Category Code) are turned into the matching codes first.
    /// </summary>
    procedure RunAnalysisForSelection(var Location: Record Location; var Item: Record Item): Integer
    begin
        exit(RunAnalysis(GetLocationFilter(Location), GetItemFilter(Item)));
    end;

    local procedure GetLocationFilter(var Location: Record Location): Text
    var
        LocationWithoutCodeFilter: Record Location;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        LocationWithoutCodeFilter.CopyFilters(Location);
        LocationWithoutCodeFilter.SetRange(Code);
        if LocationWithoutCodeFilter.GetFilters() = '' then
            exit(Location.GetFilter(Code));
        if Location.IsEmpty() then
            Error(NothingMatchesErr);
        exit(SelectionFilterManagement.GetSelectionFilterForLocation(Location));
    end;

    local procedure GetItemFilter(var Item: Record Item): Text
    var
        ItemWithoutNoFilter: Record Item;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        ItemWithoutNoFilter.CopyFilters(Item);
        ItemWithoutNoFilter.SetRange("No.");
        if ItemWithoutNoFilter.GetFilters() = '' then
            exit(Item.GetFilter("No."));
        if Item.IsEmpty() then
            Error(NothingMatchesErr);
        exit(SelectionFilterManagement.GetSelectionFilterForItem(Item));
    end;

    /// <summary>
    /// Runs all checks for the locations and items in the filters and returns the run number.
    /// A blank location filter uses the location filter from the setup.
    /// Commits the run header before the analysis starts.
    /// </summary>
    procedure RunAnalysis(LocationFilter: Text; ItemFilter: Text): Integer
    var
        Setup: Record "GSO IR Setup";
        AnalysisRun: Record "GSO IR Analysis Run";
        AnalysisEngine: Codeunit "GSO IR Analysis Engine";
        Telemetry: Codeunit "GSO IR Telemetry";
        Succeeded: Boolean;
    begin
        Setup.GetRecordOnce();
        if LocationFilter = '' then
            LocationFilter := Setup."Location Filter";

        AnalysisRun.Init();
        AnalysisRun."Started At" := CurrentDateTime();
        AnalysisRun."User ID" := CopyStr(UserId(), 1, MaxStrLen(AnalysisRun."User ID"));
        AnalysisRun.Status := AnalysisRun.Status::Running;
        AnalysisRun."Location Filter" := CopyStr(LocationFilter, 1, MaxStrLen(AnalysisRun."Location Filter"));
        AnalysisRun."Item Filter" := CopyStr(ItemFilter, 1, MaxStrLen(AnalysisRun."Item Filter"));
        AnalysisRun.Insert(false);
        Commit();

        // The run log keeps the first 250 characters of each filter; the engine gets them in full.
        ClearLastError();
        AnalysisEngine.SetFilters(LocationFilter, ItemFilter);
        Succeeded := AnalysisEngine.Run(AnalysisRun);

        AnalysisRun.Get(AnalysisRun."No.");
        AnalysisRun."Finished At" := CurrentDateTime();
        AnalysisRun.Duration := AnalysisRun."Finished At" - AnalysisRun."Started At";
        if Succeeded then
            AnalysisRun.Status := AnalysisRun.Status::Completed
        else begin
            AnalysisRun.Status := AnalysisRun.Status::Failed;
            AnalysisRun."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(AnalysisRun."Error Message"));
        end;
        AnalysisRun.Modify(false);
        // The result is kept even when the caller then fails the session (see CheckRunSucceeded).
        Commit();

        AnalysisRun.CalcFields("No. of Critical", "No. of Warnings", "No. of Info");
        Telemetry.AnalysisFinished(AnalysisRun);
        exit(AnalysisRun."No.");
    end;

    /// <summary>
    /// Raises an error when the run failed, so that a background caller such as the job queue reports
    /// the failure. The failed run stays in the log: RunAnalysis has committed it.
    /// </summary>
    procedure CheckRunSucceeded(RunNo: Integer)
    var
        AnalysisRun: Record "GSO IR Analysis Run";
    begin
        AnalysisRun.Get(RunNo);
        if AnalysisRun.Status = AnalysisRun.Status::Failed then
            Error(AnalysisFailedErr, AnalysisRun."No.", AnalysisRun."Error Message");
    end;
}
