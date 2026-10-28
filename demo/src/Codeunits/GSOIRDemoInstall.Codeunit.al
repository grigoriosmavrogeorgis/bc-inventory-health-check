namespace GMSOFT.InventoryHealthCheck.Demo;

using System.Environment;

/// <summary>
/// Schedules the demo data for evaluation companies (such as CRONUS) when the demo app is installed.
/// Other companies, for example a sandbox copied from production, get it only through the Create Demo
/// Data action on the setup page, because the scenario inserts ledger entries on purpose. The work runs
/// as a background task after the install has committed, so a failure cannot stop the installation.
/// </summary>
codeunit 61101 "GSO IR Demo Install"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    var
        Company: Record Company;
    begin
        if not Company.Get(CompanyName()) then
            exit;
        if not Company."Evaluation Company" then
            exit;
        TaskScheduler.CreateTask(Codeunit::"GSO IR Demo Data", 0, true, CompanyName(), CurrentDateTime());
    end;
}
