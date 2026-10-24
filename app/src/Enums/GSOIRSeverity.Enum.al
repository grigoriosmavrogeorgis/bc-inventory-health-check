namespace GMSOFT.InventoryHealthCheck;

enum 73033901 "GSO IR Severity"
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
