# Glossary es-ES - Inventory Health Check

Spanish (Spain) terminology used in `app/Translations/Inventory Health Check.es-ES.xlf`.
One Spanish term per English concept.

Sources:
- **BC-ES**: Microsoft Learn es-es Business Central pages (checked 2026-10-17): `inventory-how-count-adjust-reclassify`,
  `warehouse-how-to-set-up-locations-to-use-bins`, `design-details-item-application`. Where the Learn page is
  machine-translated and mixes variants, the UI caption quoted in bold on the page wins.
- **CAPC**: verified glossary of the Cost Accounting Production Costing app (`tools/translation/glossary.es-ES.md` there).
- **App**: app-specific concept; term chosen here and used everywhere.

## Business Central standard terms

| English | Spanish | Evidence |
|---|---|---|
| Item | producto | CAPC / BC-ES |
| Item Ledger Entry / item ledger | movimiento de producto / movimientos de producto (caption: Movs. producto) | CAPC; BC-ES count-adjust-reclassify |
| Location / Location Code | almacén / Cód. almacén | BC-ES set-up-locations ("Ficha almacén") |
| Bin / Bin Code | ubicación / Cód. ubicación | BC-ES set-up-locations ("Código de ubicación") |
| Bin Content(s) | contenido de ubicación (caption: Contenido ubicación) | BC-ES UI |
| Bin Mandatory | Ubicación obligatoria | BC-ES set-up-locations (**Ubicación obligatoria**) |
| Adjustment bin | ubicación de ajuste | BC-ES count-adjust-reclassify ("ubicación de ajuste") |
| Directed put-away and pick | ubicación y picking dirigidos | BC-ES pages mix "almacenamiento y picking dirigidos" / "ubicación y selección directos"; see unsure note |
| Warehouse / Warehouse Entry | almacén / movimiento de almacén (caption: Movs. almacén) | BC-ES count-adjust-reclassify ("movimientos de almacén") |
| Warehouse adjustment | ajuste de almacén | BC-ES same page |
| Calculate Warehouse Adjustment | Calcular ajuste almacén | BC-ES same page (**Calcular ajuste almacén**) |
| Warehouse Physical Inventory Journal | diario de inventario físico de almacén | BC-ES same page (**Diario de inventario físico de almacén**) |
| physical inventory / count | inventario físico / recuento | BC-ES same page |
| Item Journal | diario de productos | BC-ES same page (**Diarios de productos**) |
| Warehouse journal | diario de almacén | BC-ES ("diarios especiales de almacén") |
| Warehouse reclassification journal | diario de reclasificación de almacén | BC-ES ("diario de reclasificación") |
| Movement (warehouse document) | movimiento de almacén | BC-ES UI; "entries" are movimientos de almacén too, context makes the document clear |
| Journal Template / Journal Batch | libro diario / sección diario | CAPC |
| Item Journal Template / Batch | Libro diario productos / Sección diario productos | CAPC pattern |
| Warehouse Journal Template / Batch | Libro diario almacén / Sección diario almacén | CAPC pattern |
| Post / posting / register (warehouse) | registrar / registro | CAPC; BC-ES uses "registrar" for both post and register |
| Preview Posting | Vista previa de registro | CAPC |
| Positive / Negative adjustment | ajuste positivo / ajuste negativo | BC-ES count-adjust-reclassify |
| Applies-to Entry | Liq. por n.º orden producto | BC-ES design-details-item-application |
| Applies-from Entry | Liquid.-de mov. pdto | BC-ES design-details-item-application |
| Item application | liquidación de productos | BC-ES design-details-item-application ("problema conocido con la liquidación de productos") |
| Remaining Quantity | cantidad pendiente | BC-ES design-details-item-application (**Cantidad pendiente**) |
| Open (entry) | abierto | BC-ES |
| Credit memo / undo shipment | abono / deshacer envío | BC-ES |
| Item tracking | seguimiento de producto | BC-ES |
| Lot No. / Serial No. / Package No. | N.º lote / N.º serie / N.º paquete | BC-ES UI |
| Variant Code | Cód. variante | BC-ES UI |
| Unit of Measure (Code) / base unit of measure | (Cód.) unidad medida / unidad de medida base | BC-ES UI |
| Qty. per Unit of Measure | Cant. por unidad medida | BC-ES UI |
| Qty. (Base) | Cantidad (base) | BC-ES UI |
| Reason Code | Cód. auditoría | BC-ES UI |
| Entry No. | N.º mov. | BC-ES UI |
| User ID | Id. usuario | BC-ES UI |
| Setup | configuración | CAPC |
| Permission set | conjunto de permisos | CAPC |
| Inventory | inventario | CAPC |
| stock (on hand) | existencias | BC-ES ("registrar sin existencias") |
| partner (Microsoft partner) | partner | BC-ES usage |
| best practice | prácticas recomendadas | Microsoft ES style |

## App-specific terms

| English | Spanish | Evidence |
|---|---|---|
| Inventory Health Check (product name, captions) | Inventory Health Check (not translated: "Configuración de Inventory Health Check", "Hallazgos de Inventory Health Check") | App, decided 2026-10-24: the product name stays English in every language |
| check / Health Check Rule | comprobación / regla de comprobación | App |
| finding | hallazgo | App |
| difference | diferencia | App |
| analysis / analysis run / run | análisis / ejecución de análisis / ejecución | App; CAPC ("ejecución") |
| analysis log | historial de análisis | App ("registro" avoided: means posting in BC-ES) |
| check (noun) | comprobación | App |
| scheduled health check | comprobación de estado programada | App |
| Rule | regla | App |
| Severity: Critical / Warning / Info | Gravedad: Crítico / Advertencia / Información | App |
| Finding status: New / Reviewed / Accepted / Journal Prepared / Closed | Nuevo / Revisado / Aceptado / Diario preparado / Cerrado | App (masculine, as BC status values) |
| Run status: Running / Completed / Failed | En ejecución / Completado / Fallido | App |
| Probable Cause | Causa probable | App |
| Advice | Recomendación | App |
| correction journal | diario de corrección | App |
| pending adjustment | ajuste pendiente | App |
| Tolerance (Base) | Tolerancia (base) | App |
| mismatch | discrepancia | App |
| side (no standard posting changes only one side) | parte | App |
| evidence (export) | evidencia | App |
| First Date | Primera fecha | App |
| Created At / Started At / Finished At / Status Changed At | Creado el / Iniciado el / Finalizado el / Estado cambiado el | App |
| Prepare / Read (permission sets) | Preparar / Lectura | App |

## Names kept unchanged

Microsoft, Business Central, rule codes R1-R8, placeholders %1-%4.
