namespace GMSOFT.InventoryHealthCheck.Test;

using GMSOFT.InventoryHealthCheck;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Journal;
using System.TestLibraries.Utilities;

codeunit 50106 "GSO IR Setup Tests"
{
    // The setup table: defaults, InsertIfNotExists, GetRecordOnce and the journal template/batch pairs.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        TestHelper: Codeunit "GSO IR Test Helper";

    [Test]
    procedure InsertIfNotExistsCreatesDefaults()
    var
        Setup: Record "GSO IR Setup";
    begin
        // [SCENARIO] A new setup gets the documented defaults.
        // [GIVEN] No setup record
        Setup.DeleteAll(false);

        // [WHEN] The setup is created
        Setup.InsertIfNotExists();

        // [THEN] Maximum adjustment age 1 day, first date search on, no tolerance
        Setup.Get();
        Assert.AreEqual(1, Setup."Max. Pending Adj. Age (Days)", 'Max. pending adjustment age');
        Assert.IsTrue(Setup."Find First Date", 'Find first date');
        Assert.AreEqual(0, Setup."Tolerance (Base)", 'Tolerance');
    end;

    [Test]
    procedure InsertIfNotExistsKeepsExistingSetup()
    var
        Setup: Record "GSO IR Setup";
    begin
        // [SCENARIO] InsertIfNotExists never overwrites an existing setup.
        // [GIVEN] A setup with tolerance 3
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.SetTolerance(3);

        // [WHEN] InsertIfNotExists runs again
        Setup.InsertIfNotExists();

        // [THEN] The tolerance is still 3
        Setup.Get();
        Assert.AreEqual(3, Setup."Tolerance (Base)", 'Tolerance');
    end;

    [Test]
    procedure GetRecordOnceWithoutSetupUsesDefaults()
    var
        Setup: Record "GSO IR Setup";
        CheckSetup: Record "GSO IR Setup";
    begin
        // [SCENARIO] The analysis can run before anyone opens the setup: it uses the defaults and writes nothing.
        // [GIVEN] No setup record
        Setup.DeleteAll(false);

        // [WHEN] The setup is read
        Setup.GetRecordOnce();

        // [THEN] Default values, and still no record in the table
        Assert.AreEqual(1, Setup."Max. Pending Adj. Age (Days)", 'Max. pending adjustment age');
        Assert.IsTrue(Setup."Find First Date", 'Find first date');
        Assert.IsTrue(CheckSetup.IsEmpty(), 'Reading the setup must not insert it.');
    end;

    [Test]
    procedure ChangingItemJournalTemplateClearsBatch()
    var
        Setup: Record "GSO IR Setup";
        ItemJournalTemplate: Record "Item Journal Template";
        OtherItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [SCENARIO] A batch belongs to its template, so a new template clears the batch.
        // [GIVEN] A setup with an item journal template and batch
        TestHelper.SetMaxPendingAdjustmentAge(1);
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalTemplate(OtherItemJournalTemplate);
        Setup.Get();
        Setup.Validate("Item Jnl. Template Name", ItemJournalTemplate.Name);
        Setup.Validate("Item Jnl. Batch Name", ItemJournalBatch.Name);

        // [WHEN] Another template is chosen
        Setup.Validate("Item Jnl. Template Name", OtherItemJournalTemplate.Name);

        // [THEN] The batch is cleared
        Assert.AreEqual('', Setup."Item Jnl. Batch Name", 'Item journal batch');
    end;

    [Test]
    procedure SameItemJournalTemplateKeepsBatch()
    var
        Setup: Record "GSO IR Setup";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [SCENARIO] Validating the same template again keeps the batch.
        // [GIVEN] A setup with an item journal template and batch
        TestHelper.SetMaxPendingAdjustmentAge(1);
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        Setup.Get();
        Setup.Validate("Item Jnl. Template Name", ItemJournalTemplate.Name);
        Setup.Validate("Item Jnl. Batch Name", ItemJournalBatch.Name);

        // [WHEN] The same template is validated again
        Setup.Validate("Item Jnl. Template Name", ItemJournalTemplate.Name);

        // [THEN] The batch is kept
        Assert.AreEqual(ItemJournalBatch.Name, Setup."Item Jnl. Batch Name", 'Item journal batch');
    end;

    [Test]
    procedure ChangingWarehouseJournalTemplateClearsBatch()
    var
        Setup: Record "GSO IR Setup";
        Location: Record Location;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        OtherWarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        // [SCENARIO] A new warehouse journal template clears the warehouse journal batch.
        // [GIVEN] A setup with a warehouse journal template and batch
        TestHelper.SetMaxPendingAdjustmentAge(1);
        TestHelper.CreateBinLocation(Location, true);
        LibraryWarehouse.CreateWhseJournalTemplate(WarehouseJournalTemplate, Enum::"Warehouse Journal Template Type"::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location.Code);
        LibraryWarehouse.CreateWhseJournalTemplate(OtherWarehouseJournalTemplate, Enum::"Warehouse Journal Template Type"::Item);
        Setup.Get();
        Setup.Validate("Whse. Jnl. Template Name", WarehouseJournalTemplate.Name);
        Setup."Whse. Jnl. Batch Name" := WarehouseJournalBatch.Name;

        // [WHEN] Another template is chosen
        Setup.Validate("Whse. Jnl. Template Name", OtherWarehouseJournalTemplate.Name);

        // [THEN] The batch is cleared
        Assert.AreEqual('', Setup."Whse. Jnl. Batch Name", 'Warehouse journal batch');
    end;
}
