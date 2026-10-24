# Glossary - French (France), fr-FR

Inventory Health Check by GMSoft. One French term per English concept; use it everywhere.

Sources:
- **MS-BC**: Microsoft Learn, Business Central documentation in French (learn.microsoft.com/fr-fr/dynamics365/business-central/...), UI names in bold on the pages cited.
- **CAPC**: verified glossary of the Cost Accounting Production Costing app (`Cost Accounting Production Costing/source/tools/translation/glossary.fr-FR.md`), reused for shared BC terms.
- **App**: app-specific choice.

## Business Central standard terms

| English | French | Evidence / source |
|---|---|---|
| Item / Inventory (stock) | Article / Stock | CAPC; MS-BC |
| Location | Magasin | MS-BC warehouse-how-to-set-up-locations-to-use-bins (fiche **Magasin**) |
| Bin / Bin Code | Emplacement / Code emplacement | MS-BC warehouse-how-to-set-up-locations-to-use-bins (**Code emplacement**) |
| Bin Content(s) | Contenu emplacement | MS-BC warehouse-how-to-restructure-warehouses / BC UI (**Contenu emplacement**) |
| Bin Mandatory | Emplacement obligatoire | MS-BC warehouse-how-to-set-up-locations-to-use-bins (**Emplacement obligatoire**) |
| Adjustment bin | Emplacement d'ajustement | MS-BC inventory-how-count-adjust-reclassify ("emplacement d'ajustement", **Code emplacement ajustement**) |
| Directed put-away and pick | Rangement et prélèvement dirigés | MS-BC inventory-how-count-adjust-reclassify |
| Item ledger / Item ledger entries | Écritures comptables article | CAPC; MS-BC inventory-how-count-adjust-reclassify |
| Warehouse entries | Écritures entrepôt | MS-BC inventory-how-count-adjust-reclassify |
| Item Journal / Template / Batch | Feuille article / Modèle feuille article / Nom feuille article | MS-BC inventory-how-count-adjust-reclassify; CAPC (Modèle feuille / Nom feuille) |
| Warehouse Journal / Template / Batch | Feuille entrepôt / Modèle feuille entrepôt / Nom feuille entrepôt | CAPC pattern; MS-BC ("feuilles entrepôt") |
| Warehouse Physical Inventory Journal | Feuille inventaire entrepôt | MS-BC inventory-how-count-adjust-reclassify |
| Warehouse reclassification journal | Feuille reclassement entrepôt | MS-BC ("feuille reclassement") |
| Calculate Warehouse Adjustment | Calculer ajustement entrepôt | MS-BC inventory-how-count-adjust-reclassify |
| Warehouse adjustment | Ajustement entrepôt | MS-BC inventory-how-count-adjust-reclassify |
| Positive / negative adjustment | Ajustement positif / négatif | MS-BC finance-how-to-close-open-item-ledger-entries... |
| Register (warehouse) | Enregistrer | MS-BC inventory-how-count-adjust-reclassify (action **Enregistrer**) |
| Post / posting | Valider / validation | CAPC |
| Preview Posting | Aperçu compta. | CAPC |
| Physical inventory / count | Inventaire physique / inventaire | MS-BC inventory-how-count-adjust-reclassify |
| Movement | Mouvement | BC UI (Mouvement entrepôt) |
| Item application | Lettrage article | MS-BC design-details-inventory-zero-level-open-item-ledger-entries ("problème de lettrage article connu") |
| Known item application issue | Problème de lettrage article connu | same page |
| Applies-from Entry | Lettrage à partir écriture | MS-BC finance-how-to-close-open-item-ledger-entries-resulting-from-fixed-application-in-the-item-journal |
| Applies-to Entry | Écriture lettrage | BC UI Item Journal field (not shown distinctly on the fr-fr page, which repeats the Applies-from label) |
| Workaround | Solution de contournement | MS-BC design-details-inventory-zero-level-open-item-ledger-entries |
| Credit memo / Undo shipment | Avoir / Annuler expédition | same page ("avoir vente", "Annuler expédition") |
| Remaining quantity | Quantité restante | same page |
| Item tracking (lines) | Traçabilité (lignes traçabilité) | BC UI |
| Lot No. / Serial No. / Package No. | N° lot / N° de série / N° package | BC UI |
| Variant Code / Item variant | Code variante / Variante article | BC UI |
| Unit of Measure (Code) / Base unit of measure | Unité (Code unité) / Unité de base | CAPC |
| Qty. per Unit of Measure / Qty. (Base) | Qté par unité / Quantité (base) | BC UI |
| Reason Code | Code motif | BC UI |
| User ID | Code utilisateur | BC UI |
| Entry No. / No. | N° séquence / N° | BC UI |
| Setup | Paramètres | CAPC |
| Partner | Partenaire | MS-BC |

## App-specific terms

| English | French | Evidence / source |
|---|---|---|
| Inventory Health Check (product name, captions) | Inventory Health Check (not translated: "Paramètres Inventory Health Check", "Constats Inventory Health Check") | App, decided 2026-10-24: the product name stays English in every language |
| Health Check Rule | Règle de vérification | App |
| Analysis run / run | Exécution d'analyse / exécution | App |
| Analysis log | Journal des analyses | App |
| Finding | Constat | App |
| Difference | Écart | App (this app has no separate "variance" concept) |
| Mismatch (rule names) | Incohérence | App |
| Probable Cause | Cause probable | App |
| Advice | Recommandation | App |
| Rule / check | Règle / vérification | App |
| Severity: Critical / Warning / Info | Gravité : Critique / Avertissement / Info | App |
| Finding status: New / Reviewed / Accepted / Journal Prepared / Closed | Nouveau / Revu / Accepté / Feuille préparée / Clôturé | App |
| Run status: Running / Completed / Failed | En cours / Terminé / Échec | App |
| Review (action group / process) | Revue | App |
| First Date (of difference) | Date d'apparition | App |
| Pending (adjustment) | En attente | App |
| Correction journals | Feuilles de correction | App |
| Tolerance | Tolérance | App |
| Health check (scheduled) | Contrôle d'intégrité | App |
| Evidence (export the evidence) | Éléments probants | App |
| Side (only one side) | Côté | App |
| Permission sets Prepare / Read | Préparer / Lecture | App |

## Kept unchanged

Business Central, Microsoft, GMSoft, rule codes R1-R8, placeholders %1-%4.
