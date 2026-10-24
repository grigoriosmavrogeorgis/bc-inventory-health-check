namespace GMSOFT.InventoryHealthCheck;

using Microsoft.Warehouse.Ledger;

query 73033907 "GSO IR Whse UoM Totals"
{
    Caption = 'Warehouse Totals per Unit of Measure';
    QueryType = Normal;
    Access = Internal;

    elements
    {
        dataitem(WarehouseEntry; "Warehouse Entry")
        {
            column(LocationCode; "Location Code")
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
            column(QtyPerUnitOfMeasure; "Qty. per Unit of Measure")
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
            column(NoOfEntries)
            {
                Method = Count;
            }
        }
    }
}
