namespace GMSOFT.InventoryHealthCheck;

enum 73031486 "GSO IR Severity"
{
    Caption = 'Severity';
    Extensible = false;

    value(0; Info)
    {
        Caption = 'Info';
    }
    value(1; Warning)
    {
        Caption = 'Warning';
    }
    value(2; Critical)
    {
        Caption = 'Critical';
    }
}
