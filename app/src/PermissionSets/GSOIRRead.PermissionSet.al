namespace GMSOFT.InventoryHealthCheck;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;

permissionset 73031485 "GSO IR Read"
{
    // Run the analysis and review findings. Ledger tables are read only: this app
    // never inserts, modifies or deletes Item Ledger Entry, Warehouse Entry or Bin Content.
    // The run log is written only through the app's codeunits (indirect permissions).
    Assignable = true;
    Caption = 'Inventory Health Check - Read';

    Permissions =
        tabledata "GSO IR Setup" = R,
        tabledata "GSO IR Analysis Run" = Rim,
        tabledata "GSO IR Finding" = RiM,
        table "GSO IR Setup" = X,
        table "GSO IR Analysis Run" = X,
        table "GSO IR Finding" = X,
        codeunit "GSO IR Analysis Engine" = X,
        codeunit "GSO IR Analysis Mgt" = X,
        codeunit "GSO IR Bin Rules" = X,
        codeunit "GSO IR Finding Mgt" = X,
        codeunit "GSO IR Ledger Rules" = X,
        codeunit "GSO IR Telemetry" = X,
        page "GSO IR Analysis Runs" = X,
        page "GSO IR Findings" = X,
        page "GSO IR Setup" = X,
        report "GSO IR Run Analysis" = X,
        query "GSO IR ILE Daily" = X,
        query "GSO IR ILE Open Entries" = X,
        query "GSO IR ILE Totals" = X,
        query "GSO IR ILE Tracking Totals" = X,
        query "GSO IR Whse Bin Totals" = X,
        query "GSO IR Whse Daily" = X,
        query "GSO IR Whse Totals" = X,
        query "GSO IR Whse Tracking Totals" = X,
        query "GSO IR Whse UoM Totals" = X,
        tabledata "Item Ledger Entry" = R,
        tabledata "Warehouse Entry" = R,
        tabledata "Bin Content" = R,
        tabledata Bin = R,
        tabledata Item = R,
        tabledata "Item Unit of Measure" = R,
        tabledata "Item Tracking Code" = R,
        tabledata Location = R,
        tabledata "Warehouse Journal Template" = R,
        tabledata "Warehouse Journal Line" = R;
}
