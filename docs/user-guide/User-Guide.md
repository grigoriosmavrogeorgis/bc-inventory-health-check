# Inventory Health Check – User Guide

Inventory Health Check is a free app from GMSOFT for Microsoft Dynamics 365 Business Central. It compares three places where Business Central keeps your stock quantities – the **item ledger entries**, the **warehouse entries** and the **bin contents** – and tells you where they do not agree, why that probably happened and what Microsoft recommends you do about it.

**The app only reads.** It never posts, never changes a ledger entry and never creates a journal. You review every finding and decide yourself what to post.

## 1. What you need

- Business Central online, version 29 or later.
- Locations with **Bin Mandatory** turned on. Locations without bins have no warehouse entries, so the app skips them.
- Users who run the check need the permission set **Inventory Health Check - Read** (`GSO IR READ`). Users who change the setup need **Inventory Health Check - Prepare** (`GSO IR PREPARE`). Both sets read the item ledger, warehouse entries, bins and item tracking codes; neither can write to them.

## 2. Set up

Search for **Inventory Health Check Setup** and fill in:

| Field | What it does |
|---|---|
| Location Filter | The locations the check uses when you leave the location filter blank when you run it. Leave blank to check every location with Bin Mandatory. |
| Tolerance (Base) | The largest difference, in the base unit of measure, that is not reported. Leave 0 to report every difference. |
| Max. Pending Adjustment Age (Days) | How many days quantity may wait in the adjustment bin before the finding becomes a warning. Microsoft recommends posting warehouse adjustments regularly, for example daily. |
| Find First Date of Difference | Walks back through the entries to find the date each difference first appeared. This points you to the document that caused it, but makes the check slower. |

The setup is created automatically the first time you open the page.

## 3. Run the check

1. Search for **Run Inventory Health Check**.
2. Set filters on **Locations** and **Items**. You can filter on any field, for example *Item Category Code*, *Vendor No.* or *Blocked*. Only locations with Bin Mandatory are checked.
3. Choose **OK**. When the check is finished you see how many locations were checked and how many critical findings, warnings and info findings it found, and the findings open.

If no location or item matches your filters, the check stops with a message instead of checking everything.

**Run it from the job queue.** You can schedule the report **GSO IR Run Analysis** in a job queue entry, for example every night. If an analysis fails, the job queue entry shows the error, so it never fails silently.

## 4. Review the results

**Inventory Health Check Runs** lists every run with its filters, status, duration and the number of critical findings, warnings and info findings. A failed run shows its error message. Choose **Findings** to open the findings of a run.

**Inventory Health Check Findings** shows one line per difference:

- **Severity** – *Critical*: no standard posting fixes it, so ask your partner. *Warning*: a standard correction exists. *Info*: expected, but act on it soon.
- **Rule** – which check found it (see section 5).
- **Item Ledger Qty. (Base)**, **Warehouse Qty. (Base)** and **Difference (Base)** – the quantities behind the finding. Choose a quantity to see the entries.
- **First Date** – the date the difference appeared. Look at the documents posted on that date.
- **Probable Cause** and **Advice** – why it probably happened and what Microsoft best practice recommends.
- **Status** and **Comment** – your review. Use **Mark as Reviewed** and **Close**; the app records who changed the status and when.

The actions **Item Ledger Entries**, **Warehouse Entries** and **Bin Contents** open exactly the entries behind the finding – including blank values. A finding for entries *without* a bin code opens only the entries without a bin code, not every bin.

**Get Help from GMSOFT** opens the GMSOFT web page, where you can ask for help with differences that no standard posting fixes. Nothing about the finding is sent.

## 5. The checks

| Rule | Severity | What it finds | What to do |
|---|---|---|---|
| **R1 – Item ledger vs. warehouse** | Critical | The item ledger total and the warehouse total (all bins, including the adjustment bin) differ for an item, variant and location. | No standard posting changes only one side. Do not try to fix it with an item or warehouse journal; export the evidence and ask your partner. |
| **R2 – Item tracking mismatch** | Critical | The item total agrees, but the quantity per lot, serial or package number differs. Only the numbers the warehouse tracks are compared (Lot/SN/Package Warehouse Tracking on the item tracking code). | Check the item tracking lines of the documents posted on the First Date, then ask your partner. |
| **R3 – Pending adjustment bin** | Info, Warning when older than the setup allows | Quantity registered in the adjustment bin but not yet posted to the item ledger, per unit of measure and lot/serial/package. Also a directed location without an adjustment bin. | Run **Calculate Warehouse Adjustment** in the item journal and post it (use Preview Posting first). |
| **R4 – Negative bin content** | Warning | A bin holds less than zero. | Check the warehouse entries of the bin, then move or reclassify quantity into it. |
| **R5 – Unit of measure mismatch** | Warning | Quantity × Qty. per Unit of Measure does not equal Qty. (Base), the unit no longer exists on the item, or its Qty. per Unit of Measure changed. | Correct the unit of measure before you run Calculate Warehouse Adjustment. Do not change Qty. per Unit of Measure while the unit is in use in bins. |
| **R6 – Quantity in invalid bin** | Warning (Info for a bin blocked for outbound or all movement) | Quantity without a bin code, in a bin that no longer exists, or in a bin blocked for outbound movement. Bins blocked for inbound movement only are fine. | Move the quantity to a valid bin with a movement or a warehouse reclassification journal. For a quarantine bin, check that the stock should stay there. |
| **R7 – Open item ledger entries** | Critical | The remaining quantity of the open item ledger entries does not match the inventory – including inventory with no open entries at all – or inventory is zero while open inbound and outbound entries remain (Microsoft's known item application issue). | Microsoft workaround: post a positive adjustment with Applies-from Entry and a negative adjustment of the same quantity with Applies-to Entry. Otherwise ask your partner. |
| **R8 – Count with pending adjustment** | Warning | A warehouse physical inventory journal has lines for a location while its adjustment bin still holds pending adjustments. | Run Calculate Warehouse Adjustment and post it before you count. |
| **R9 – Missing bin content** | Warning | Warehouse entries hold quantity in a bin, but the bin content line for the item, variant and unit of measure is missing, so the stock is not shown in Bin Contents and is not offered for picks. | Create the bin content line on the Bin Contents page. Its quantity is calculated from the warehouse entries, so no posting is needed. |

## 6. Your data and privacy

- The app reads item ledger entries, warehouse entries, bins, bin contents, items, item units of measure, item tracking codes, locations and warehouse journal lines. It writes only to its own tables: the setup, the run log and the findings.
- The app sends technical telemetry to GMSOFT through Microsoft Application Insights: that a run completed or failed, how long it took, how many locations were checked, how many critical findings, warnings and info findings it found, how many findings were set to a new status, and how often Get Help from GMSOFT was used. It never sends item numbers, location codes, quantities, error texts, names or anything you type.
- See the GMSOFT privacy statement: https://gmsoftdynamics.com/privacy-statement-uk/

## 7. Questions

**A location is not checked.** Only locations with Bin Mandatory are checked. Check the Location Filter in the setup and on the request page.

**The run failed.** Open Inventory Health Check Runs and read the Error Message. Your user probably lacks permission to read one of the tables in section 6.

**An item tracked in the item ledger is not reported by R2.** This is intended when the item tracking code does not have Warehouse Tracking for that number: Business Central then leaves the number blank on warehouse entries.

**The check takes long.** Turn off Find First Date of Difference in the setup, or filter on fewer locations or items.

**Can the app correct the differences?** No. Inventory Health Check only diagnoses. You review and post every correction yourself.

## 8. Support

Use **Get Help from GMSOFT** on the findings page, or visit https://gmsoftdynamics.com/apps/free/inventory-health-check/.

Inventory Health Check is published by GMSOFT Limited.
