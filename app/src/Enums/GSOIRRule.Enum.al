namespace GMSOFT.InventoryHealthCheck;

enum 73033900 "GSO IR Rule"
{
    Caption = 'Health Check Rule';
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; R1)
    {
        Caption = 'R1 - Item ledger vs. warehouse';
    }
    value(2; R2)
    {
        Caption = 'R2 - Item tracking mismatch';
    }
    value(3; R3)
    {
        Caption = 'R3 - Pending adjustment bin';
    }
    value(4; R4)
    {
        Caption = 'R4 - Negative bin content';
    }
    value(5; R5)
    {
        Caption = 'R5 - Unit of measure mismatch';
    }
    value(6; R6)
    {
        Caption = 'R6 - Quantity in invalid bin';
    }
    value(7; R7)
    {
        Caption = 'R7 - Open item ledger entries';
    }
    value(8; R8)
    {
        Caption = 'R8 - Count with pending adjustment';
    }
    value(9; R9)
    {
        Caption = 'R9 - Missing bin content';
    }
}
