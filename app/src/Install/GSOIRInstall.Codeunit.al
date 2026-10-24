namespace GMSOFT.InventoryHealthCheck;

using System.Upgrade;

codeunit 73033900 "GSO IR Install"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    var
        Setup: Record "GSO IR Setup";
    begin
        Setup.InsertIfNotExists();
        SetUpgradeTags();
    end;

    /// <summary>A fresh install is already current: mark every upgrade step done so none runs later.</summary>
    local procedure SetUpgradeTags()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        IRUpgrade: Codeunit "GSO IR Upgrade";
        Tags: List of [Code[250]];
        Tag: Code[250];
    begin
        IRUpgrade.GetPerCompanyTags(Tags);
        foreach Tag in Tags do
            if not UpgradeTag.HasUpgradeTag(Tag) then
                UpgradeTag.SetUpgradeTag(Tag);
    end;
}
