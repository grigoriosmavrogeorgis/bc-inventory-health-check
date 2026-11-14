# APP.md - Inventory Health Check

Generic rules live in [AGENTS.md](./AGENTS.md). This file holds only what is true for **this one app**.

## Identity

| | |
|---|---|
| App name | **Inventory Health Check** |
| App ID | 22b44ef7-69c0-4a5a-9dc7-7d5ddc45cc2a |
| Version | 1.29.1.0 (Major.BC.Release.Fix) |
| Publisher | GMSOFT Limited |
| `app.json` folder | `./app` |
| Test app | `./test` (IDs 50100-50199, depends on Microsoft Application Test Library) |
| Demo data app | `./demo` (IDs 60100-60199) |
| Object ID range | `73031485-73031504` |
| Affix | `GSO ` (objects named `GSO IR ...`) |
| Target | Cloud (BC online, application 29.0 or later) |
| Debug sandbox | `GMSOFT_AP` (`.vscode/launch.json` in each project) |
| Locales | en-GB, el-GR, it-IT |

## Purpose

Diagnose differences between Item Ledger Entries, Warehouse Entries and Bin Content (quantity, rules R1-R8) and between Value Entries and the General Ledger (value, rules V1-V7), explain the cause and prepare standard journals. Specification: `..\docs\04-Technical-Design.md`, `..\docs\06-GL-Reconciliation.md`.

## Hard rules for this app

- Read-only on Item Ledger Entry (32), Warehouse Entry (7312), Bin Content (7302), Value Entry (5802), G/L Entry (17), G/L - Item Ledger Relation (5823).
- No Insert/Modify/Delete on those tables, no `Permissions` property giving write access to them.
- Never call posting or register codeunits (Item Jnl.-Post, Whse. Jnl.-Register, Post Inventory Cost to G/L, Adjust Cost). Only fill journal lines; the user posts.
- Aggregations with Query objects (SUM), never CALCFIELDS in loops over entries.

## Object IDs in use

Each object type has its own numbering, so every type starts at 73031485. Next free: table 73031488, query 73033909, codeunit 73031493, page 73031488, report 73031486, enum 73031489, permission set 73031487.

| Type | ID | Object |
|---|---|---|
| table | 73031485 | GSO IR Setup |
| table | 73031486 | GSO IR Analysis Run |
| table | 73031487 | GSO IR Finding |
| enum | 73031485 | GSO IR Rule (R1-R8; V1-V7 to follow) |
| enum | 73031486 | GSO IR Severity |
| enum | 73031487 | GSO IR Finding Status |
| enum | 73031488 | GSO IR Run Status |
| query | 73031485-73031488 | GSO IR ILE Totals / ILE Tracking Totals / ILE Open Entries / ILE Daily |
| query | 73031489-73031493 | GSO IR Whse Totals / Whse Tracking Totals / Whse Bin Totals / Whse UoM Totals / Whse Daily |
| codeunit | 73031485 | GSO IR Install |
| codeunit | 73031486 | GSO IR Upgrade |
| codeunit | 73031487 | GSO IR Telemetry |
| codeunit | 73031488 | GSO IR Finding Mgt |
| codeunit | 73031489 | GSO IR Ledger Rules (R1, R2, R7) |
| codeunit | 73031490 | GSO IR Bin Rules (R3, R4, R5, R6, R8) |
| codeunit | 73031491 | GSO IR Analysis Engine |
| codeunit | 73031492 | GSO IR Analysis Mgt |
| page | 73031485 | GSO IR Setup |
| page | 73031486 | GSO IR Analysis Runs |
| page | 73031487 | GSO IR Findings |
| report | 73031485 | GSO IR Run Analysis |
| permissionset | 73031485 | GSO IR Read |
| permissionset | 73031486 | GSO IR Prepare |
| test codeunit | 50100 | GSO IR Analysis Tests |
| test codeunit | 50101 | GSO IR Test Helper |
| test codeunit | 50149 | GSO IR Test Runner |

## Local build

Symbols are not in git. Copy the BC 29 packages into `app\.alpackages` and `test\.alpackages` (the test app also needs Application Test Library, Library Assert, Library Variable Storage, Business Foundation Test Libraries, Any, Permissions Mock, System Application Test Library, Tests-TestLibraries), then run `scripts\Build.ps1 -IncludeTests`. The output goes to `artifacts\`.

`app\images\logo.png` is a placeholder. Replace it with the real logo before AppSource submission.
