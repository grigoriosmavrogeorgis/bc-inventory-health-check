namespace GMSOFT.InventoryHealthCheck.Test;

codeunit 50799 "GSO IR Test Runner"
{
    Subtype = TestRunner;
    TestIsolation = Codeunit;

    trigger OnRun()
    begin
        Codeunit.Run(Codeunit::"GSO IR Analysis Tests");
        Codeunit.Run(Codeunit::"GSO IR Ledger Rule Tests");
        Codeunit.Run(Codeunit::"GSO IR Bin Rule Tests");
        Codeunit.Run(Codeunit::"GSO IR Analysis Run Tests");
        Codeunit.Run(Codeunit::"GSO IR Finding Tests");
        Codeunit.Run(Codeunit::"GSO IR Setup Tests");
        Codeunit.Run(Codeunit::"GSO IR Page Tests");
        Codeunit.Run(Codeunit::"GSO IR Report Tests");
        Codeunit.Run(Codeunit::"GSO IR Upgrade Tests");
    end;
}
