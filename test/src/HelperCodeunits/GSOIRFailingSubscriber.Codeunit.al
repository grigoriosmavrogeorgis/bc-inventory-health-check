namespace GMSOFT.InventoryHealthCheck.Test;

using GMSOFT.InventoryHealthCheck;

codeunit 50110 "GSO IR Failing Subscriber"
{
    // Bind with BindSubscription to make the analysis fail when it writes its first finding.
    // Used to test the failed-run path: status, error message and rollback of the findings.
    EventSubscriberInstance = Manual;

    var
        SimulatedFailureErr: Label 'Simulated failure while writing a finding.';

    [EventSubscriber(ObjectType::Table, Database::"GSO IR Finding", OnBeforeInsertEvent, '', false, false)]
    local procedure FailOnFindingInsert(var Rec: Record "GSO IR Finding"; RunTrigger: Boolean)
    begin
        Error(SimulatedFailureErr);
    end;

    procedure FailureText(): Text
    begin
        exit(SimulatedFailureErr);
    end;
}
