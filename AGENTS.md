# GMSOFT Business Central Development Instructions

## Project
This repository contains a Microsoft Dynamics 365 Business Central AL extension.

- Production application: `/app`
- Automated tests: `/test`
- Telemetry assets: `/telemetry`
- MCP assets: `/mcp`
- Development scripts: `/scripts`

## Source Structure
The repository uses an object-type-first AL structure.

Production objects must be placed according to AL object type:
- Tables -> app/src/Tables/
- Table Extensions -> app/src/TableExtensions/
- Pages -> app/src/Pages/
- Page Extensions -> app/src/PageExtensions/
- Codeunits -> app/src/Codeunits/
- Reports -> app/src/Reports/
- Report Extensions -> app/src/ReportExtensions/
- Queries -> app/src/Queries/
- XMLPorts -> app/src/XMLPorts/
- Enums -> app/src/Enums/
- Enum Extensions -> app/src/EnumExtensions/
- Interfaces -> app/src/Interfaces/
- API Pages -> app/src/APIs/
- Permission Sets -> app/src/PermissionSets/
- Install -> app/src/Install/
- Upgrade -> app/src/Upgrade/
- Event Subscribers -> app/src/EventSubscribers/
- Telemetry -> app/src/Telemetry/

Do not introduce feature-based folders under `app/src`.

## Object Ranges
- Production: 73033900..73033959
- Tests: 50750..50799 (demo: 61100..61199)

Never create AL objects outside these ranges unless the project explicitly changes them.

## Naming
Use the project prefix `GMSOFT` by default and replace it per application when needed.

File naming convention:
`<ObjectName>.<ObjectType>.al`

Examples:
- GMSOFTSetup.Table.al
- GMSOFTSetup.Page.al
- GMSOFTSalesManagement.Codeunit.al
- GMSOFTCustomer.PageExt.al

## AL Rules
- Never use implicit `with`.
- Follow AL compiler, CodeCop, UICop and project ruleset guidance.
- Do not suppress analyzer warnings without justification.
- Keep business logic out of pages where practical.
- Put reusable business logic in codeunits.
- Prefer event subscribers when extending standard Business Central behavior.
- Do not modify standard Microsoft objects.
- Prefer extension objects.
- Every new field must have an appropriate `DataClassification`.

## Permissions
Review permission sets whenever adding new tables, tabledata, pages, reports, or codeunits.

## Tests
- Put automated tests in `/test`.
- Test codeunits use `Subtype = Test`.
- Test runners use `Subtype = TestRunner`.
- Follow Arrange / Act / Assert.
- Avoid interdependent tests.

## Telemetry
Use the shared telemetry abstraction in `app/src/Telemetry/`.
Use event IDs in the form `GMSOFT-XXXX`.
Never log secrets, tokens, passwords, authentication headers, or personal data.

## Upgrade Safety
For schema changes, review `app/src/Install/` and `app/src/Upgrade/`.
Use obsoletion and data migration patterns rather than destructive changes.

## Before Completing a Change
Verify:
1. AL compilation
2. CodeCop / UICop / project ruleset
3. Automated tests
4. Permission impact
5. Telemetry impact
6. Upgrade impact
