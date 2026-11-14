namespace GMSOFT.InventoryHealthCheck;

using System.Upgrade;

/// <summary>
/// Upgrade logic. Each step is guarded by an upgrade tag so it runs once per company.
/// A fresh install sets every tag (see "GSO IR Install"), so no step runs there.
/// </summary>
codeunit 73031486 "GSO IR Upgrade"
{
    Subtype = Upgrade;
    Access = Internal;

    var
        EnsureSetupTagTxt: Label 'GSO-IHC-EnsureSetup-1.29', Locked = true;

    trigger OnUpgradePerCompany()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(EnsureSetupTagTxt) then begin
            EnsureSetup();
            UpgradeTag.SetUpgradeTag(EnsureSetupTagTxt);
        end;
    end;

    /// <summary>Upgrade tags that a fresh install or a new company sets at once, so these steps never run there.</summary>
    procedure GetPerCompanyTags(var Tags: List of [Code[250]])
    begin
        Tags.Add(EnsureSetupTagTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    var
        Tags: List of [Code[250]];
        Tag: Code[250];
    begin
        GetPerCompanyTags(Tags);
        foreach Tag in Tags do
            if not PerCompanyUpgradeTags.Contains(Tag) then
                PerCompanyUpgradeTags.Add(Tag);
    end;

    /// <summary>Companies that existed before the setup record was created on install get it now.</summary>
    local procedure EnsureSetup()
    var
        Setup: Record "GSO IR Setup";
    begin
        Setup.InsertIfNotExists();
    end;
}
