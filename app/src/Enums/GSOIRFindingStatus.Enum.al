namespace GMSOFT.InventoryHealthCheck;

enum 73031487 "GSO IR Finding Status"
{
    Caption = 'Finding Status';
    Extensible = false;

    value(0; New)
    {
        Caption = 'New';
    }
    value(1; Reviewed)
    {
        Caption = 'Reviewed';
    }
    value(2; "Journal Prepared")
    {
        Caption = 'Journal Prepared';
    }
    value(3; Accepted)
    {
        Caption = 'Accepted';
    }
    value(4; Closed)
    {
        Caption = 'Closed';
    }
}
