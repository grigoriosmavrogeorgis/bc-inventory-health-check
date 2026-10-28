namespace GMSOFT.InventoryHealthCheck.Demo;

using GMSOFT.InventoryHealthCheck;

pageextension 61100 "GSO IR Demo Setup" extends "GSO IR Setup"
{
    actions
    {
        addfirst(Processing)
        {
            action(GSOIRCreateDemoData)
            {
                ApplicationArea = All;
                Caption = 'Create Demo Data';
                ToolTip = 'Create two demo locations and demo items with deliberate differences between the item ledger, the warehouse entries and the bin contents, so that every health check rule has something to report. Use this only in a demo, trial or training company.';
                Image = CreateDocuments;

                trigger OnAction()
                var
                    DemoData: Codeunit "GSO IR Demo Data";
                begin
                    if DemoData.DemoDataExists() then begin
                        Message(AlreadyExistsMsg, DemoData.DirectedLocationCode(), DemoData.BinLocationCode());
                        exit;
                    end;
                    if not Confirm(CreateQst, false) then
                        exit;
                    DemoData.CreateDemoData();
                    Commit();
                    Message(CreatedMsg, DemoData.DirectedLocationCode(), DemoData.BinLocationCode());
                end;
            }
        }
    }

    var
        CreateQst: Label 'This inserts item ledger entries and warehouse entries with deliberate differences for demo items. Do this only in a demo, trial or training company.\\Do you want to create the demo data?';
        CreatedMsg: Label 'The demo data was created at locations %1 and %2. Run the Inventory Health Check to see the findings.', Comment = '%1 = directed location code, %2 = bin location code';
        AlreadyExistsMsg: Label 'The demo data already exists at locations %1 and %2.', Comment = '%1 = directed location code, %2 = bin location code';
}
