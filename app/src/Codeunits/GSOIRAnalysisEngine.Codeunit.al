namespace GMSOFT.InventoryHealthCheck;

using Microsoft.Inventory.Location;

codeunit 73031491 "GSO IR Analysis Engine"
{
    // Runs every rule for every location in the run's filter, one location at a time.
    // Only locations with Bin Mandatory have warehouse entries, so only those are checked.
    // Started through Codeunit.Run by "GSO IR Analysis Mgt", so an error rolls back the
    // findings of this run and the run is logged as failed.
    // The run record keeps only the first 250 characters of each filter, for the log. The full
    // filters come through SetFilters; without it the filters of the run record are used.
    Access = Internal;
    TableNo = "GSO IR Analysis Run";
    Permissions = tabledata "GSO IR Analysis Run" = m;

    var
        LocationFilter: Text;
        ItemFilter: Text;
        FiltersSet: Boolean;

    trigger OnRun()
    var
        Location: Record Location;
        LedgerRules: Codeunit "GSO IR Ledger Rules";
        BinRules: Codeunit "GSO IR Bin Rules";
        LocationsAnalysed: Integer;
    begin
        if not FiltersSet then
            SetFilters(Rec."Location Filter", Rec."Item Filter");

        Location.SetRange("Bin Mandatory", true);
        if LocationFilter <> '' then
            Location.SetFilter(Code, LocationFilter);
        if Location.FindSet() then
            repeat
                LedgerRules.CheckLocation(Rec."No.", Location, ItemFilter);
                BinRules.CheckLocation(Rec."No.", Location, ItemFilter);
                LocationsAnalysed += 1;
            until Location.Next() = 0;

        Rec."Locations Analysed" := LocationsAnalysed;
        Rec.Modify(false);
    end;

    /// <summary>Sets the location and item filters of the run in full, however long they are.</summary>
    procedure SetFilters(NewLocationFilter: Text; NewItemFilter: Text)
    begin
        LocationFilter := NewLocationFilter;
        ItemFilter := NewItemFilter;
        FiltersSet := true;
    end;
}
