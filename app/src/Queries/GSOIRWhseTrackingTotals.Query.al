namespace GMSOFT.InventoryHealthCheck;

using Microsoft.Warehouse.Ledger;

query 73033905 "GSO IR Whse Tracking Totals"
{
    // R2 adds the rows up per item tracking key, so the unit of measure column does not change it.
    // R3 reads one bin (the adjustment bin) and needs every unit of measure and tracking group apart.
    Caption = 'Warehouse Totals by Item Tracking';
    QueryType = Normal;
    Access = Internal;

    elements
    {
        dataitem(WarehouseEntry; "Warehouse Entry")
        {
            filter(BinCode; "Bin Code")
            {
            }
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
            column(UnitOfMeasureCode; "Unit of Measure Code")
            {
            }
            column(SumQtyBase; "Qty. (Base)")
            {
                Method = Sum;
            }
        }
    }
}
