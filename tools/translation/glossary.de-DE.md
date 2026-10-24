# Glossary English -> German (de-DE), Inventory Health Check

One German term per English concept; used everywhere in `app/Translations/GSO Inventory Health Check.de-DE.xlf`.
Style: formal "Sie"; field ToolTips "Gibt ... an."; action ToolTips imperative ("Zeigen Sie ... an.");
"must / cannot" kept strict ("muss", "kann nicht", "darf nicht").

Sources: [L] Microsoft Learn de-de, Business Central, pages checked 2026-10-17:
inventory-how-count-adjust-reclassify, design-details-integration-with-inventory,
design-details-warehouse-management, design-details-inventory-zero-level-open-item-ledger-entries;
[CAPC] verified glossary of the Cost Accounting Production Costing repo (tools/translation/glossary.de-DE.md);
[NAV] long-standing German NAV/BC UI captions; [App] app-specific decision.

## Business Central standard terms

| English | German | Evidence |
|---|---|---|
| Item Ledger Entry / item ledger (entries) | Artikelposten | [CAPC] [L] |
| Warehouse Entry / warehouse entries | Lagerplatzposten | [L] count-adjust-reclassify, integration-with-inventory |
| Bin / Bin Code | Lagerplatz / Lagerplatzcode | [L] |
| Bin Content(s) | Lagerplatzinhalt(e) | [L] warehouse-management |
| Adjustment bin | Ausgleichslagerplatz | [L] integration-with-inventory, count-adjust-reclassify |
| Calculate Warehouse Adjustment | Lagerausgleich berechnen | [L] count-adjust-reclassify (action and page name) |
| warehouse adjustment | Lagerausgleich | [L] derived from the action name |
| Directed put-away and pick | gesteuerte Einlagerung und Kommissionierung | [L] warehouse-management |
| Bin Mandatory | Lagerplatz obligatorisch | [NAV] Location field caption; Learn MT shows "Lagerplatzcode obligatorisch" |
| Item Journal | Artikel Buch.-Blatt | [L] |
| Warehouse journal (template / batch) | Logistik Buch.-Blatt (Logistik Buch.-Blattvorlage / Logistik Buch.-Blattname) | [L] "Logistik Artikel Buch.-Blatt"; [CAPC] Buch.-Blattvorlage / Buch.-Blattname |
| Item Journal Template / Batch | Artikel Buch.-Blattvorlage / Artikel Buch.-Blattname | [CAPC] [NAV] |
| Warehouse Physical Inventory Journal | Logistik Inventur Buch.-Blatt | [L] |
| Warehouse Reclassification Journal | Logistik Artikel Umlag. Buch.-Blatt | [L] warehouse-management |
| Movement (warehouse) | Lagerplatzumlagerung | [L] warehouse-management |
| Preview Posting | Buchungsvorschau | [L] [CAPC] |
| register (warehouse) | registrieren | [L] |
| physical inventory / count | Inventur / zählen | [L] |
| Positive / Negative Adjmt. | Zugang / Abgang | [L] zero-level open entries workaround |
| Applies-to Entry / Applies-from Entry | Ausgleich mit Lfd. Nr. / Ausgegl. von Lfd. Nr. | [NAV] item journal line captions (not verified on Learn) |
| item application | Artikelausgleich | [L] "Bekannte Probleme bei Artikelausgleich" |
| known item application issue | bekanntes Problem beim Artikelausgleich | [L] page title |
| Remaining Quantity | Restmenge | [L] |
| open entries; inbound / outbound | offene Posten; eingehend / ausgehend | [L] |
| Credit memo / Undo shipment | Gutschrift / Lieferung rückgängig machen | [L] [NAV] |
| Qty. per Unit of Measure / Qty. (Base) | Menge pro Einheit / Menge (Basis) | [NAV] |
| Unit of Measure (Code) / base unit of measure | Einheit (Einheitencode) / Basiseinheit | [NAV] [L] |
| Item tracking (lines) | Artikelverfolgung(szeilen) | [L] |
| Lot No. / Serial No. / Package No. | Chargennr. / Seriennr. / Paketnr. | [NAV] |
| Location / Location Code / Location Filter | Lagerort / Lagerortcode / Lagerortfilter | [L] |
| Variant Code / Reason Code / User ID | Variantencode / Ursachencode / Benutzer-ID | [NAV] |
| Entry No. / No. / Item No. | Lfd. Nr. / Nr. / Artikelnr. | [CAPC] |
| Comment | Bemerkung | [NAV] |
| Inventory (on hand) / stock | Lagerbestand / Bestand | [L] |
| Setup | Einrichtung | [CAPC] |
| Primary Key | Primärschlüssel | [NAV] |

## App-specific concepts

| English | German | Evidence |
|---|---|---|
| Inventory Health Check (product name, captions) | Inventory Health Check (not translated: "Inventory Health Check einrichten", "Inventory Health Check-Befunde") | [App] decided 2026-10-24: the product name stays English in every language |
| check (short) / Health Check Rule | Prüfung / Prüfregel | [App] |
| analysis / analysis run / analysis log | Analyse / Analyselauf / Analyseprotokoll | [App] |
| finding / findings | Befund / Befunde | [App] |
| difference | Differenz | [App] (kept apart from "mismatch" = Abweichung) |
| mismatch / differ | Abweichung / abweichen | [App] |
| check (rule that checks; to check) | Prüfung / prüfen | [App] |
| review / Reviewed / Mark as Reviewed | Überprüfung / Überprüft / Als überprüft markieren | [App] kept apart from "check" |
| Severity: Critical / Warning / Info | Schweregrad: Kritisch / Warnung / Info | [App] |
| Finding Status: New / Reviewed / Accepted / Journal Prepared / Closed | Neu / Überprüft / Akzeptiert / Buch.-Blatt vorbereitet / Geschlossen | [App] |
| Run Status: Running / Completed / Failed | Wird ausgeführt / Abgeschlossen / Fehlgeschlagen | [App] |
| Probable Cause / Advice | Wahrscheinliche Ursache / Empfehlung | [App] |
| Microsoft best practice | bewährte Methode von Microsoft | [App] |
| pending (adjustment) | ausstehend(er Ausgleich) | [App] |
| correction journal(s) | Korrektur-Buch.-Blatt / Korrektur-Buch.-Blätter | [App] |
| standard posting | Standardbuchung | [App] |
| Tolerance (Base) | Toleranz (Basis) | [App] |
| scheduled health check | geplante Zustandsprüfung | [App] |
| First Date / Find First Date of Difference | Erstes Datum / Erstes Datum der Differenz ermitteln | [App] |
| Started At / Finished At / Created At | Gestartet am / Beendet am / Erstellt am | [App] |
| Status Changed At / By | Status geändert am / von | [App] |
| Item Ledger Qty. (Base) / Warehouse Qty. (Base) | Menge Artikelposten (Basis) / Menge Lagerplatzposten (Basis) | [App] |
| warehouse totals | Lagerplatzpostensummen | [App] |
| evidence (export) | Nachweise | [App] |
| partner | Partner | [App] |
| Prepare / Read (permission sets) | Vorbereiten / Lesen | [App] |

Kept unchanged: Microsoft, R1-R8 rule codes, %1-%4 placeholders.
