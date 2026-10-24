# Architecture

## Source organization
This project uses an object-type-first AL structure under `app/src`.

## Application layering
- UI objects: Pages, Page Extensions, Reports
- Domain/application logic: Codeunits, Interfaces
- Data model: Tables, Table Extensions, Enums
- Integration surface: APIs, XMLPorts, integration codeunits
- Infrastructure: Install, Upgrade, Telemetry, Event Subscribers

## Rules
- Pages should contain minimal business logic.
- Reusable logic belongs in codeunits.
- Integrations should be isolated and testable.
- Telemetry must go through the shared telemetry layer.
