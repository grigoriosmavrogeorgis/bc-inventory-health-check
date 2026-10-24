# Glossary - Italian (Italy), it-IT

Inventory Health Check by GMSoft. One Italian term per English concept; use it everywhere.
Register: formal and impersonal, as Microsoft's Italian Business Central. ToolTips: "Specifies ..." = "Specifica ...";
action ToolTips in the third person ("Visualizza ...", "Imposta ...", "Confronta ..."); instructions to the user in the
formal infinitive ("Controllare ...", "Eseguire ...", "Lasciare vuoto ...").

Sources:
- **MS-BC**: Microsoft Learn, Business Central documentation in Italian, read 2026-10-17:
  inventory-how-count-adjust-reclassify (IC), design-details-integration-with-inventory (DI),
  warehouse-how-to-set-up-locations-to-use-bins (LB), warehouse-how-to-calculate-bin-replenishment (BR),
  design-details-item-application (IA). UI names in bold on those pages were preferred over running text.
- **CAPC**: verified glossary of the Cost Accounting Production Costing app (`../Cost Accounting Production Costing/source/tools/translation/glossary.it-IT.md`).
- **App**: app-specific choice.

## Business Central standard terms

| English | Italian | Evidence |
|---|---|---|
| Location / Location Code / Location Filter | Ubicazione / Cod. ubicazione / Filtro ubicazioni | MS-BC LB (**Scheda ubicazione**), IA (**Codice ubicazione**) |
| Bin / Bin Code | Collocazione / Cod. collocazione | MS-BC LB (**Codice collocazione**), IC |
| Bin Contents | Contenuto collocazione | MS-BC DI ("contenuto collocazione"), BR |
| Bin Mandatory | Collocazione obbligatoria | MS-BC LB (**Collocazione obbligatoria**) |
| Adjustment bin | Collocazione di rettifica | MS-BC IC, DI, LB (**Codice collocazione rettifica**) |
| Directed put-away and pick | Stoccaggio e prelievo guidati | MS-BC LB, BR ("stoccaggi e prelievi guidati") |
| Warehouse (BC module/entries) | Warehouse | MS-BC IC, DI ("movimenti warehouse", "registro warehouse") |
| Warehouse Entries | Movimenti warehouse | MS-BC IC, DI |
| Item Ledger Entries / item ledger | Movimenti contabili articoli / contabilità articoli | MS-BC IC, DI ("contabilità articoli"), CAPC |
| Item Journal / Template / Batch | Registrazioni articoli / Definizione registrazioni articoli / Batch registrazioni articoli | MS-BC IC (**Registrazioni articoli**); CAPC (Definizione / Batch registrazioni) |
| Warehouse Journal / Template / Batch | Registrazioni warehouse / Definizione registrazioni warehouse / Batch registrazioni warehouse | MS-BC IC ("registrazioni di warehouse"); pattern as CAPC |
| Warehouse physical inventory journal | Registrazioni inventario fisico warehouse | MS-BC IC (**Registrazione dell'inventario fisico warehouse**), DI |
| Warehouse reclassification journal | Registrazioni riclassificazione warehouse | MS-BC IC ("registrazioni di riclassificazione") |
| Calculate Warehouse Adjustment | Calcola rettifica warehouse | MS-BC IC (**Calcola rettifica warehouse**) |
| Warehouse adjustment | Rettifica warehouse | MS-BC IC, DI |
| Movement (warehouse) | Movimentazione | MS-BC BR (**Movimentazioni**, **Crea movimento** is the action) |
| Physical inventory / count | Inventario fisico / conteggiare | MS-BC IC |
| Preview Posting | Anteprima registrazione | MS-BC DI; CAPC |
| Post / register | Registrare | MS-BC IC (warehouse "Registra" too) |
| Posting date | Data di registrazione | CAPC |
| Item tracking / Lot No. / Serial No. / Package No. | Tracciabilità articolo / Nr. lotto / Nr. di serie / Nr. pacchetto | BC UI; Learn uses "numeri di serie e di lotto" (IC) |
| Unit of Measure Code / base unit of measure / Qty. per Unit of Measure / Qty. (Base) | Cod. unità di misura / unità di misura di base / Qtà per unità di misura / Qtà (base) | BC UI; CAPC |
| Variant Code | Cod. variante | BC UI |
| Item No. / Entry No. / No. | Nr. articolo / Nr. movimento / Nr. | MS-BC IC (**Nr. articolo**), IA (**Nr. movimento**) |
| Remaining quantity | Quantità residua | MS-BC IA (**Quantità residua**) |
| Item application / known item application issue | Collegamento articoli / problema noto di collegamento articoli | MS-BC IA ("problema noto di collegamento articoli") |
| Applies-to Entry / Applies-from Entry | Collega a mov. art. / Collega da mov. art. | MS-BC IA (**Collega a mov. art.**, **Collega da mov. art.**) |
| Positive / negative adjustment | Rettifica positiva / rettifica negativa | BC Item Ledger Entry Type |
| Inventory (quantity on hand) | Giacenza | MS-BC IC (**Giacenza**) |
| Reason Code | Cod. motivo audit | BC UI (Codici motivo audit). Doubt: not confirmed on a Learn it-it page (pages unreachable) |
| Credit memo / undo shipment | Nota di credito / annullamento della spedizione | MS-BC IA ("nota di credito"); BC UI (Annulla spedizione) |
| Setup | Setup | CAPC |
| User ID | ID utente | BC UI |

## App concepts (one Italian word each)

| English | Italian | Note |
|---|---|---|
| Inventory Health Check (product name, captions) | Inventory Health Check (not translated: "Setup Inventory Health Check", "Rilevazioni Inventory Health Check") | App, decided 2026-10-24: the product name stays English in every language |
| Health Check Rule / Rule / check | Regola di controllo / Regola / controllo | App |
| Analysis / analysis run / run | Analisi / esecuzione analisi / esecuzione (feminine) | App |
| Finding / findings | Rilevazione / rilevazioni (feminine) | App. Kept apart from "difference" |
| Difference | Differenza | App |
| Severity: Critical / Warning / Info | Gravità: Critico / Avviso / Info | App. "Critical" and "Info" (count captions and enum values) use the same word; "Warnings" = Avvisi |
| Probable Cause | Causa probabile | App |
| Advice / best practice | Consiglio / procedura consigliata da Microsoft | App |
| Tolerance | Tolleranza | App |
| First date (of difference) | Prima data | App |
| Pending (adjustment) | In sospeso | App |
| Correction journals | Registrazioni di correzione | App |
| Check (rule check) | Controllo | App |
| Review / Reviewed / Mark as Reviewed | Verifica / Verificato / Segna come verificato | App |
| Finding status New / Reviewed / Accepted / Journal Prepared / Closed | Nuovo / Verificato / Accettato / Registrazioni preparate / Chiuso | masculine, agreeing with "stato" |
| Run status Running / Completed / Failed | In esecuzione / Completato / Non riuscito | masculine, agreeing with "stato" |
| ... At / ... By (timestamps) | ... il / ... da (Iniziata il, Terminata il, Creata il, Stato modificato il/da) | App |
| Evidence | Evidenze | App |
| Partner | Partner | BC usage |
| Log | Log | App |
| Permission sets Prepare / Read | Preparazione / Lettura | App |

## Kept unchanged

Business Central, Microsoft, GMSoft, rule codes R1-R8, placeholders %1-%4.
