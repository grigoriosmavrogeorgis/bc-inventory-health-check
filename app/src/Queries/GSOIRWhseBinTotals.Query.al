namespace GMSOFT.InventoryHealthCheck;

using Microsoft.Warehouse.Ledger;

query 73033906 "GSO IR Whse Bin Totals"
{
    // Port of the NAV 2017 query 50000 "Bin Total Quantity". Grouped like the
    // primary key of Bin Content, so each row is one bin content line.
    Caption = 'Warehouse Totals per Bin';
    QueryType = Normal;
    Access = Internal;

    elements
    {
        dataitem(WarehouseEntry; "Warehouse Entry")
        {
            column(LocationCode; "Location Code")
            {
            }
            column(BinCode; "Bin Code")
            {
            }
            column(ItemNo; "Item No.")
            {
            }
            column(VariantCode; "Variant Code")
            {
            }
            column(UnitOfMeasureCode; "Unit of Measure Code")
            {
            }
            column(SumQuantity; Quantity)
            {
                Method = Sum;
            }
            column(SumQtyBase; "Qty. (Base)")
            {
                Method = Sum;
            }
        }
    }
}
