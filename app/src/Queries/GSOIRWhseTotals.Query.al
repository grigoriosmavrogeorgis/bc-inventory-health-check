namespace GMSOFT.InventoryHealthCheck;

using Microsoft.Warehouse.Ledger;

query 73033904 "GSO IR Whse Totals"
{
    Caption = 'Warehouse Totals';
    QueryType = Normal;
    Access = Internal;

    elements
    {
        dataitem(WarehouseEntry; "Warehouse Entry")
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
            column(SumQtyBase; "Qty. (Base)")
            {
                Method = Sum;
            }
        }
    }
}
