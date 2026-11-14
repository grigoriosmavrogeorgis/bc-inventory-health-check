namespace GMSOFT.InventoryHealthCheck;

enum 73031488 "GSO IR Run Status"
{
    Caption = 'Analysis Run Status';
    Extensible = false;

    value(0; Running)
    {
        Caption = 'Running';
    }
    value(1; Completed)
    {
        Caption = 'Completed';
    }
    value(2; Failed)
    {
        Caption = 'Failed';
    }
}
