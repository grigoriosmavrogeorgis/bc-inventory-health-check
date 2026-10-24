namespace GMSOFT.InventoryHealthCheck;

codeunit 73033902 "GSO IR Telemetry"
{
    // Event catalogue (keep IDs stable once released):
    //   GSOIHC-0001  Feature used ("Get Help": the user opened the GMSOFT page from a finding; result = rule number)
    //   GSOIHC-0010  Analysis completed
    //   GSOIHC-0011  Analysis failed (no error text: it can contain item numbers or other customer data)
    //   GSOIHC-0020  Finding status changed by the user (count and new status only)
    // Only counts, codes and durations are logged, never item numbers, locations or user names.
    Access = Internal;

    var
        FeatureUsedTxt: Label 'Feature used', Locked = true;
        AnalysisCompletedTxt: Label 'Analysis completed', Locked = true;
        AnalysisFailedTxt: Label 'Analysis failed', Locked = true;
        FindingStatusChangedTxt: Label 'Finding status changed', Locked = true;

    procedure FeatureUsed(FeatureName: Text; Result: Text)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Add('feature', FeatureName);
        CustomDimensions.Add('result', Result);

        Session.LogMessage(
            'GSOIHC-0001',
            FeatureUsedTxt,
            Verbosity::Normal,
            DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher,
            CustomDimensions);
    end;

    procedure AnalysisFinished(AnalysisRun: Record "GSO IR Analysis Run")
    var
        CustomDimensions: Dictionary of [Text, Text];
        DurationMs: BigInteger;
    begin
        DurationMs := AnalysisRun.Duration;
        CustomDimensions.Add('locations', Format(AnalysisRun."Locations Analysed", 0, 9));
        CustomDimensions.Add('critical', Format(AnalysisRun."No. of Critical", 0, 9));
        CustomDimensions.Add('warnings', Format(AnalysisRun."No. of Warnings", 0, 9));
        CustomDimensions.Add('info', Format(AnalysisRun."No. of Info", 0, 9));
        CustomDimensions.Add('durationMs', Format(DurationMs, 0, 9));
        CustomDimensions.Add('itemFiltered', Format(AnalysisRun."Item Filter" <> '', 0, 9));

        if AnalysisRun.Status = AnalysisRun.Status::Completed then
            Session.LogMessage(
                'GSOIHC-0010',
                AnalysisCompletedTxt,
                Verbosity::Normal,
                DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher,
                CustomDimensions)
        else
            Session.LogMessage(
                'GSOIHC-0011',
                AnalysisFailedTxt,
                Verbosity::Warning,
                DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher,
                CustomDimensions);
    end;

    procedure FindingStatusChanged(NewStatus: Enum "GSO IR Finding Status"; NoOfFindings: Integer)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Add('newStatus', Format(NewStatus.AsInteger(), 0, 9));
        CustomDimensions.Add('findings', Format(NoOfFindings, 0, 9));

        Session.LogMessage(
            'GSOIHC-0020',
            FindingStatusChangedTxt,
            Verbosity::Normal,
            DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher,
            CustomDimensions);
    end;
}
