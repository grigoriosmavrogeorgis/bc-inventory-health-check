# Changelog

## 1.29.1.0 (in development)

- Quantity checks R1-R8 for locations with Bin Mandatory: item ledger vs. warehouse totals including the adjustment bin (R1), per lot/serial/package (R2), pending adjustment bin with age (R3), negative bin content (R4), unit of measure problems (R5), quantity in missing, blocked or blank bins (R6), open item ledger entries and the Microsoft known item application issue (R7), warehouse physical inventory while adjustments are pending (R8).
- First date of each item ledger vs. warehouse difference, found by walking the entries back day by day.
- Analysis run log, findings list with probable cause, Microsoft advice and drill-down to item ledger entries, warehouse entries and bin contents.
- Setup page, permission sets GSO IR Read and GSO IR Prepare.
- All totals come from Query objects with SUM; the app is read-only on every ledger table and never posts.

Fixes from the code review of 23-10-2026:

- R7 also reports inventory that has no open item ledger entries at all (all entries wrongly closed).
- R3 checks the adjustment bin per unit of measure and lot/serial/package, so opposite pending adjustments no longer cancel each other out (and R8 no longer misses them). The first date is found per group.
- Drill-downs filter on what the rule reports per, blank values included: an R6 finding for entries without a bin, or an R2 finding without a lot, no longer opens every bin or lot.
- Location and item filters longer than 250 characters are used in full; the run log keeps the first 250 characters for display.

Fixes from the follow-up review:

- A translated cause or advice longer than 250 characters no longer fails the analysis (the Italian and German R7 text did); such texts are cut, and the two translations are shortened.
- R2 compares only the lot, serial and package numbers that the item tracking code has Warehouse Tracking for, so items tracked in the item ledger only are no longer reported every run.
- R2 findings get a First Date per lot, serial and package number.
- R6: a bin blocked for inbound movement only is no longer reported; stock in a bin blocked for outbound or all movement is info instead of a warning.
- R4 ignores negative residues within the tolerance.
- Permission set GSO IR Read: read on Item Tracking Code.

Free-app readiness and the third review:

- New rule R9 - Missing bin content: the warehouse entries hold quantity in a bin whose Bin Content line is missing, so the stock is not shown in Bin Contents and is not offered for picks.
- The Run Analysis request page honours filters on any Location or Item field (for example Item Category Code); they are turned into the matching codes. A filter that matches nothing stops with an error.
- R5 findings store Qty. per Unit of Measure, and the drill-down filters on it.
- Findings: action Get Help from GMSOFT opens the app's web page (telemetry logs only the rule number).
- Setup page: the correction journal and notification fields are hidden until the journal preparer and the scheduled check exist.
- Run Analysis in the background (job queue) now fails when the analysis failed, so the job queue shows the error; the failed run stays logged.
- R5 findings without a stored Qty. per Unit of Measure keep the drill-down per unit of measure instead of opening an empty list.

Rebrand (24-10-2026):

- Captions say Inventory Health Check instead of Inventory Reconciliation (pages, tables, report, permission sets, rule enum). Every translation keeps "Inventory Health Check" in English as the product name; object names stay GSO IR.
- New logo (box with a pulse line) in `app/images/logo.png`; listing sizes in `listing/logo`.
- Website paths moved to `gmsoftdynamics.com/apps/free/inventory-health-check/` (app, help and Get Help links).
- User guide in `docs/user-guide/User-Guide.md` and AppSource listing texts in `listing/doc/AppSource-Listing.md` (English).
- App name in app.json is now "Inventory Health Check" (was "GSO Inventory Health Check"), because AppSource validation requires it to match the offer name. The test and demo apps and the translation files are renamed to match; the app ID, object names and IDs are unchanged.
