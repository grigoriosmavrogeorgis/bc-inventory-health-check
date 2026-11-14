namespace GMSOFT.InventoryHealthCheck.Test;

using GMSOFT.InventoryHealthCheck;
using System.TestLibraries.Utilities;
using System.Upgrade;

codeunit 50109 "GSO IR Upgrade Tests"
{
    // Upgrade tags: named by the GMSOFT rule, unique, and already set in a company where the app is installed.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        TagPrefixMsg: Label 'Tag %1 must start with GSO-IHC-.', Comment = '%1 = upgrade tag', Locked = true;
        TagRegisteredTwiceMsg: Label 'Tag %1 is registered twice.', Comment = '%1 = upgrade tag', Locked = true;
        TagNotSetMsg: Label 'Upgrade tag %1 is not set after install.', Comment = '%1 = upgrade tag', Locked = true;

    [Test]
    procedure UpgradeTagsFollowNamingRule()
    var
        IRUpgrade: Codeunit "GSO IR Upgrade";
        Tags: List of [Code[250]];
        SeenTags: List of [Code[250]];
        Tag: Code[250];
    begin
        // [SCENARIO] Every upgrade tag is GSO-IHC-<Step>-<version> and appears once.
        // [WHEN] The per-company tags are read
        IRUpgrade.GetPerCompanyTags(Tags);

        // [THEN] There is at least one; each starts with GSO-IHC- and is unique
        Assert.AreNotEqual(0, Tags.Count(), 'The upgrade codeunit must register its tags.');
        foreach Tag in Tags do begin
            Assert.IsTrue(Format(Tag).StartsWith('GSO-IHC-'), StrSubstNo(TagPrefixMsg, Tag));
            Assert.IsFalse(SeenTags.Contains(Tag), StrSubstNo(TagRegisteredTwiceMsg, Tag));
            SeenTags.Add(Tag);
        end;
    end;

    [Test]
    procedure UpgradeTagsAreSetInInstalledCompany()
    var
        IRUpgrade: Codeunit "GSO IR Upgrade";
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: List of [Code[250]];
        Tag: Code[250];
    begin
        // [SCENARIO] After install (or upgrade) every upgrade step is marked done, so none runs again.
        // [WHEN] The per-company tags are read
        IRUpgrade.GetPerCompanyTags(Tags);

        // [THEN] Each tag is set in this company
        foreach Tag in Tags do
            Assert.IsTrue(UpgradeTag.HasUpgradeTag(Tag), StrSubstNo(TagNotSetMsg, Tag));
    end;
}
