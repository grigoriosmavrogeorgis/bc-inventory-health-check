# Glossary English -> Greek (el-GR), GSO Inventory Health Check

One Greek term per English concept; the app's Greek UI (`app/Translations/GSO Inventory Health Check.el-GR.xlf`)
uses exactly these terms. Style: formal; ToolTips start with "Καθορίζει ..."; action ToolTips are nominal
("Προβολή ...", "Σύγκριση ..."); "must"/"cannot" are never softened.

Sources: [CA] verified glossary of the Cost Accounting Production Costing app
(`20-In-Development/Cost Accounting Production Costing/source/tools/translation/glossary.el-GR.md`);
[GS] existing el-GR XLFs of the live GMSOFT apps (Production Entry, Shelf-Life Aware Replenishment,
Inventory Planning, Vendor Claims); [D] decision made for this app (no other source).
Microsoft Learn el-gr pages for Business Central return the English text (no Greek docs), so BC terms
not covered by [CA] rest on [GS] and should be re-checked against a Greek BC client.

## Business Central standard terms

| English | Greek | Evidence |
|---|---|---|
| item / items | είδος / είδη | [CA] |
| item ledger / item ledger entries | καθολικό ειδών / εγγραφές καθολικού ειδών | [CA] |
| inventory (stock) | απόθεμα | [CA] |
| location / Location Code / location filter | αποθήκη / Κωδικός αποθήκης / φίλτρο αποθηκών | [GS] Production Entry, Shelf-Life "Κωδικός αποθήκης" |
| warehouse (WMS ledger) / warehouse entries | αποθήκη / εγγραφές αποθήκης | [GS] "Εγγραφών αποθήκης"; BC Greek uses "αποθήκη" for both Location and Warehouse; the app keeps them apart by the nouns that follow (εγγραφές/ημερολόγιο/σύνολα αποθήκης vs φίλτρο/κωδικός αποθήκης) |
| bin / Bin Code | θέση / Κωδικός θέσης | [GS] "Κωδικός θέσης" |
| bin content(s) | περιεχόμενο θέσης / περιεχόμενα θέσεων | [D] aligned with "θέση" |
| adjustment bin | θέση προσαρμογής | [GS] "Κωδικός θέσης προσαρμογών" (singular used) |
| warehouse adjustment | προσαρμογή αποθήκης | [D] |
| Calculate Warehouse Adjustment | Υπολογισμός προσαρμογής αποθήκης | [D] |
| Bin Mandatory | Υποχρεωτική θέση | [D] |
| directed put-away and pick | κατευθυνόμενη τακτοποίηση και συλλογή | [GS] Production Entry |
| item tracking | παρακολούθηση είδους | [GS] "κωδικός παρακολούθησης είδους", "γραμμές παρακολούθησης" |
| Lot No. / Serial No. / Package No. | Αρ. παρτίδας / Σειριακός αρ. / Αρ. συσκευασίας | [GS] |
| Variant Code / item variant | Κωδικός παραλλαγής / παραλλαγή είδους | [GS] "Κωδ. παραλλαγής" (written in full) |
| unit of measure / base unit of measure | μονάδα μέτρησης / βασική μονάδα μέτρησης | [GS] |
| (Base) in captions; Qty. per Unit of Measure | (Βάσης); Ποσ. ανά μονάδα μέτρησης | [D] |
| Reason Code | Κωδικός αιτιολογίας | [GS] |
| item journal / template / batch | ημερολόγιο ειδών / πρότυπο ημερολογίου ειδών / δέσμη ημερολογίου ειδών | [GS] "Ημερολόγια ειδών", "δέσμη ημερ. ειδών" |
| warehouse journal / template / batch | ημερολόγιο αποθήκης / πρότυπο / δέσμη ημερολογίου αποθήκης | [D] same pattern |
| warehouse physical inventory journal | ημερολόγιο φυσικής απογραφής αποθήκης | [D] |
| warehouse reclassification journal; reclassify | ημερολόγιο ανακατάταξης αποθήκης; ανακατατάσσω | [GS] "Ημερολόγιο ανακατάταξης ειδών" |
| movement | μετακίνηση | [D] |
| physical inventory; count | φυσική απογραφή; καταμέτρηση | [GS] "Φυσ. Απογραφής" |
| post / posting / posted | καταχωρίζω / καταχώριση / καταχωρισμένος | [CA] |
| register (warehouse) | καταγράφω / καταγραφή | [D] kept apart from "post" |
| Preview Posting | Προεπισκόπηση Καταχώρισης | [CA], [GS] |
| positive / negative adjustment | θετική / αρνητική προσαρμογή | [D] |
| Applies-from Entry / Applies-to Entry | Εφαρμογή από εγγραφή / Εφαρμογή σε εγγραφή | [D] |
| item application | εφαρμογή ειδών | [D] |
| remaining quantity | υπολειπόμενη ποσότητα | [GS] |
| open (entries) | ανοιχτές (εγγραφές) | [D] |
| inbound / outbound | εισερχόμενος / εξερχόμενος | [D] |
| credit memo; undo shipment | πιστωτικό σημείωμα; αναίρεση αποστολής | [D] |
| blocked; block | αποκλεισμένη; αποκλείω | [GS] "Αποκλεισμός" |
| document (posted) | παραστατικό | [D] |
| User ID | Αναγνωριστικό χρήστη | [D] |
| Primary Key | Πρωτεύον κλειδί | [D] |
| your partner (Microsoft partner) | ο συνεργάτης σας | [D] |

## App-specific terms

| English | Greek | Evidence |
|---|---|---|
| Inventory Health Check (product name, captions) | Inventory Health Check (not translated: "Ρύθμιση Inventory Health Check", "Ευρήματα Inventory Health Check") | [App] decided 2026-10-24: the product name stays English in every language |
| check; Health Check Rule; rule | έλεγχος; κανόνας ελέγχου; κανόνας | [App] |
| analysis; analysis run; run | ανάλυση; εκτέλεση ανάλυσης; εκτέλεση | [CA] run = εκτέλεση |
| analysis log | αρχείο καταγραφής αναλύσεων | [D] |
| finding / findings | εύρημα / ευρήματα | [GS] "Εύρημα" |
| difference | διαφορά | [D] |
| mismatch | ασυμφωνία | [D] |
| severity: Critical / Warning / Info | σοβαρότητα: Κρίσιμο / Προειδοποίηση / Πληροφορία | [GS] "Σοβαρότητα"; same Greek for the count columns |
| Finding Status: New / Reviewed / Accepted / Journal Prepared / Closed | Νέο / Ελεγμένο / Αποδεκτό / Ημερολόγιο προετοιμάστηκε / Κλειστό | [D] |
| Run Status: Running / Completed / Failed | Σε εξέλιξη / Ολοκληρώθηκε / Απέτυχε | [D] |
| review (noun) | έλεγχος | [D] |
| Advice | Σύσταση | [D] |
| Probable Cause | Πιθανή αιτία | [D] |
| Microsoft best practice | βέλτιστη πρακτική της Microsoft | [D] |
| known issue; workaround | γνωστό ζήτημα; λύση | [D] |
| pending (adjustment) | εκκρεμής (προσαρμογή) | [D] |
| tolerance | ανοχή | [GS] "Κανόνες ανοχής" |
| correction journals | ημερολόγια διόρθωσης | [D] |
| health check | έλεγχος υγείας | [D] |
| evidence | αποδεικτικά στοιχεία | [D] |
| totals | σύνολα | [D] |

Kept unchanged: Microsoft, R1-R8, placeholders %1-%4.
