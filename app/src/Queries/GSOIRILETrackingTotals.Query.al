namespace GMSOFT.InventoryHealthCheck;

using Microsoft.Inventory.Ledger;

query 73033901 "GSO IR ILE Tracking Totals"
{
    Caption = 'Item Ledger Totals by Item Tracking';
    QueryType = Normal;
    Access = Internal;

    elements
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            column(ItemNo; "Item No.")
            {
            }
            column(VariantCode; "Variant Code")
            {
            }
            column(LocationCode; "Location Code")
            {
            }
            column(LotNo; "Lot No.")
            {
            }
            column(SerialNo; "Serial No.")
            {
            }
            column(PackageNo; "Package No.")
            {
            }
            column(SumQuantity; Quantity)
            {
                Method = Sum;
            }
        }
    }
}
