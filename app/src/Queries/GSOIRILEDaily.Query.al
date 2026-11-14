namespace GMSOFT.InventoryHealthCheck;

using Microsoft.Inventory.Ledger;

query 73031488 "GSO IR ILE Daily"
{
    Caption = 'Item Ledger Quantity per Day';
    QueryType = Normal;
    Access = Internal;
    OrderBy = descending(PostingDate);

    elements
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            filter(ItemNo; "Item No.")
            {
            }
            filter(VariantCode; "Variant Code")
            {
            }
            filter(LocationCode; "Location Code")
            {
            }
            filter(LotNo; "Lot No.")
            {
            }
            filter(SerialNo; "Serial No.")
            {
            }
            filter(PackageNo; "Package No.")
            {
            }
            column(PostingDate; "Posting Date")
            {
            }
            column(SumQuantity; Quantity)
            {
                Method = Sum;
            }
        }
    }
}
