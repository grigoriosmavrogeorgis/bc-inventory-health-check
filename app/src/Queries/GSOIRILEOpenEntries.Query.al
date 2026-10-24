namespace GMSOFT.InventoryHealthCheck;

using Microsoft.Inventory.Ledger;

query 73033902 "GSO IR ILE Open Entries"
{
    Caption = 'Open Item Ledger Entries';
    QueryType = Normal;
    Access = Internal;

    elements
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            DataItemTableFilter = Open = const(true);

            column(ItemNo; "Item No.")
            {
            }
            column(VariantCode; "Variant Code")
            {
            }
            column(LocationCode; "Location Code")
            {
            }
            column(Positive; Positive)
            {
            }
            column(SumRemainingQuantity; "Remaining Quantity")
            {
                Method = Sum;
            }
            column(NoOfEntries)
            {
                Method = Count;
            }
        }
    }
}
