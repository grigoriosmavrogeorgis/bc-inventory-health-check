namespace GMSOFT.InventoryHealthCheck;

permissionset 73033901 "GSO IR Prepare"
{
    // Everything in "GSO IR Read", plus the setup and the findings. Journal tables are
    // added here when the journal preparer is built; ledger tables stay read only.
    Assignable = true;
    Caption = 'Inventory Health Check - Prepare';
    IncludedPermissionSets = "GSO IR Read";

    Permissions =
        tabledata "GSO IR Setup" = RIMD,
        tabledata "GSO IR Finding" = RIMD;
}
