namespace GMSOFT.InventoryHealthCheck;

using Microsoft.Inventory.Ledger;

query 73031485 "GSO IR ILE Totals"
{
    Caption = 'Item Ledger Totals';
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
            column(SumQuantity; Quantity)
            {
                Method = Sum;
            }
        }
    }
}
