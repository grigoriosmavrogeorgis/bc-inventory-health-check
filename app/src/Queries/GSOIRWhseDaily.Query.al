namespace GMSOFT.InventoryHealthCheck;

using Microsoft.Warehouse.Ledger;

query 73031493 "GSO IR Whse Daily"
{
    Caption = 'Warehouse Quantity per Day';
    QueryType = Normal;
    Access = Internal;
    OrderBy = descending(RegisteringDate);

    elements
    {
        dataitem(WarehouseEntry; "Warehouse Entry")
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
            filter(BinCode; "Bin Code")
            {
            }
            filter(UnitOfMeasureCode; "Unit of Measure Code")
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
            column(RegisteringDate; "Registering Date")
            {
            }
            column(SumQtyBase; "Qty. (Base)")
            {
                Method = Sum;
            }
        }
    }
}
