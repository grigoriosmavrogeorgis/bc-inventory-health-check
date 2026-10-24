# AL Development Toolchain — Reference & Setup

Reference for a complete Business Central AL development environment in VS Code.
Every extension ID, command, and package name below was verified against the VS Code
Marketplace gallery API, the npm registry, PowerShell Gallery, or the local install on
**2026-08-20**. Versions move; identifiers rarely do.

**How to use this:** run the [Quick Start](#quick-start) block, then work through
[Tier 1](#tier-1--non-negotiable) to confirm nothing is missing. [Tier 4](#tier-4--remove-or-replace)
lists what to uninstall — dead tooling costs more than it gives.

---

## Quick Start

Verify what you have, then install what's missing:

```powershell
# 1. What AL tooling is already installed?
code --list-extensions | Select-String -Pattern "al|dynamics|lintercop|xliff|nab" -CaseSensitive:$false

# 2. Core (non-negotiable)
code --install-extension ms-dynamics-smb.al
code --install-extension andrzejzwierzchowski.al-code-outline
code --install-extension Arthurvdv.alcops

# 3. Productivity
code --install-extension wbrakowski.al-navigator
code --install-extension nabsolutions.nab-al-tools
code --install-extension vjeko.vjeko-al-objid

# 4. Performance & telemetry (install when you need them)
code --install-extension ms-dynamics-smb.bcpt
code --install-extension waldoBC.bc-telemetry-buddy

# 5. Command-line + agent tooling (the piece most setups miss)
dotnet tool install --global Microsoft.Dynamics.BusinessCentral.Development.Tools --prerelease
al --version

# 6. Container tooling (only if Docker with Windows containers is available)
Install-Module BcContainerHelper -Force
```

Then apply the [settings](#workspace-settings) and [MCP configuration](#mcp-servers) below.

---

## Tier 1 — Non-negotiable

Without these you do not have a complete AL environment.

### AL Language extension

| | |
|---|---|
| **ID** | `ms-dynamics-smb.al` |
| **Source** | [Marketplace](https://marketplace.visualstudio.com/items?itemName=ms-dynamics-smb.al) · issues at [github.com/microsoft/AL](https://github.com/microsoft/AL) |
| **Install** | `code --install-extension ms-dynamics-smb.al` |
| **Prereqs** | VS Code; a BC tenant (SaaS sandbox, on-prem, or container) |

The compiler, language server, debugger, and the four Microsoft analyzers. Everything else
in this document is built on top of it.

Capabilities worth knowing, because they replace whole categories of third-party tooling:

- **Test Explorer** (BC 28.0+) — discovers and runs test codeunits from the IDE, with
  procedure-level coverage as CodeLens. Supersedes external test-runner extensions.
- **AL Explorer** (`Ctrl+Shift+F12`) and **AL Home** — object browsing across your app and
  its dependencies. Replaces the abandoned AL Object Designer.
- **Snapshot debugging** (`F7`) — capture a production/sandbox execution and step through it
  afterwards. The only practical way to debug something you cannot reproduce locally.
- **AL Profiler** — statement-level timing lenses; `al.statementLensMin` defaults to 500 ms.
- **Built-in formatter** (`Alt+Shift+F`) — do not install a third-party AL formatter alongside it.
- **AL agent tools** (17.0+) — `al_build`, `al_compile`, `al_publish`, `al_symbolsearch`,
  `al_getdiagnostics` and friends, exposed to Copilot agent mode and to MCP clients.

> **Pre-release channel:** there is no separate insider extension. Use
> `code --install-extension ms-dynamics-smb.al --pre-release`, or the Extensions view →
> "Switch to Pre-Release Version". New agent/LSP capabilities land here first.

### AL Development Tools (`al` CLI)

| | |
|---|---|
| **Package** | `Microsoft.Dynamics.BusinessCentral.Development.Tools` (.NET global tool) |
| **Install** | `dotnet tool install --global Microsoft.Dynamics.BusinessCentral.Development.Tools --prerelease` |
| **Source** | [NuGet](https://www.nuget.org/packages/Microsoft.Dynamics.BusinessCentral.Development.Tools) · [docs](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-tool) |
| **Prereqs** | .NET SDK 8+ |

The most commonly missed piece of a complete setup. Puts `al` on your PATH so scripts and
agents stop hardcoding paths like
`…\.vscode\extensions\ms-dynamics-smb.al-<version>\bin\win32\alc.exe`.

```powershell
al compile <args>              # compile without VS Code
al runtests <codeunitId>       # run tests against a BC server — no Docker required
al publishapp <appPath>        # publish a .app
al workspace map               # emit a Mermaid dependency diagram of a multi-app workspace
al graph extract               # extract the AL call graph across apps
al launchmcpserver             # MCP server for AI agents
al launchlspserver             # LSP server for agent code navigation
al auth login                  # Entra ID sign-in; tokens cached on disk
```

`al runtests` is the answer to "I have no Docker but I need to run my test suite." It reads
connection settings from `launch.json` via `--project`, authenticates to a cloud sandbox with
OAuth, and emits structured JSON. Use `--testgroups <file.json>` to run many codeunits over a
single session instead of paying the connect cost per codeunit.

### AZ AL Dev Tools / AL Code Outline

| | |
|---|---|
| **ID** | `andrzejzwierzchowski.al-code-outline` |
| **Source** | [Marketplace](https://marketplace.visualstudio.com/items?itemName=andrzejzwierzchowski.al-code-outline) |
| **Install** | `code --install-extension andrzejzwierzchowski.al-code-outline` |

Symbol browsing, code outline, object/page/report wizards (including permission sets), and a
large set of bulk code actions — add ApplicationArea, add ToolTips, add DataClassification,
fix keyword casing, sort permissions, remove `with` usage — in both "active editor" and
"whole project" variants. Also ships a duplicate-code analysis panel and a code-analyzer rules
viewer. Tracks every BC major release closely.

It is the load-bearing piece of the community ecosystem: **AL Navigator, AL CodeActions, and
AL Toolbox all declare it as a hard `extensionDependency`.** Install it even if you never open
its views.

> **Dependency chain to be aware of:** al-code-outline itself hard-depends on
> `waldo.crs-al-language-extension`, so installing it force-installs CRS. CRS is in maintenance
> mode (roughly one release a year, recent releases are merged community PRs), but it is neither
> archived nor broken, and its file-naming/reorganize commands are genuinely useful. You cannot
> adopt the healthy extension without the slower one.

### An analyzer set beyond Microsoft's four

Microsoft ships CodeCop, UICop, AppSourceCop, and PerTenantExtensionCop. They do not catch
missing `SetLoadFields`, implicit `Rec`, or many performance and data-classification slips.

**ALCops** is the current answer:

| | |
|---|---|
| **ID** | `Arthurvdv.alcops` |
| **Source** | [github.com/ALCops](https://github.com/ALCops) |
| **Install** | `code --install-extension Arthurvdv.alcops` |

Six cops — ApplicationCop, DocumentationCop, FormattingCop, LinterCop, PlatformCop,
TestCop — distributed via NuGet with AL-Go support.

> **Migration note:** BusinessCentral.LinterCop is **deprecated by its own author**. Its README
> states: *"This repository is deprecated and will not receive any new updates for the
> foreseeable future. Development continues at ALCops."* The last analyzer release was v0.40.1
> (2025-09-15). ALCops has migrated ~95% of the rules and publishes a mapping guide — if your
> ruleset names `LC####` rules, remap them. Note the VS Code *downloader* extension
> (`stefanmaron.businesscentral-lintercop`) still receives updates; that is not the analyzer.

---

## Tier 2 — Productivity

Actively maintained, each solving a specific pain point.

| Tool | ID | Solves | Notes |
|---|---|---|---|
| **AL Navigator** | `wbrakowski.al-navigator` | Variable/parameter creation with AL-standard type ordering; jump to variables/keys/actions; report optimization analysis; field-name translation on hover | Very actively maintained. Requires al-code-outline |
| **NAB AL Tools** | `nabsolutions.nab-al-tools` | The complete XLIFF workflow, external documentation generation from AL, tooltip docs from pages, permission-set generation, object renumbering | The healthiest community AL extension. Also ships an MCP server |
| **AL Object ID Ninja** | `vjeko.vjeko-al-objid` | Collision-free object/field ID assignment across a team | **Now closed-source commercial.** Free for solo devs; teams get a 2-week trial then pay. Self-hosting was removed in March 2026 — see the note below |
| **ALRM (AL ID Range Manager)** | `TKapitan.al-id-range-manager` ([repo](https://github.com/TKapitan/ALRM-VSCode)) | Same job as Ninja, but the back end is **a BC extension you host yourself** | The credible self-hosted alternative now that Ninja's is gone. Verify the exact marketplace ID before scripting it |
| **AL EventLens** | `dvlprlife.al-eventlens` | Indexes event publishers and subscribers across the workspace *and* `.alpackages`; answers "who subscribes to this" and "does the event I subscribed to still exist"; Mermaid export | Valuable for any app with a large base-app subscription surface. Young project, small install base |
| **AL Toolbox** | `BartPermentier.al-toolbox` | Automatic `SetLoadFields` generation, colored regions, batch renumbering, affix renaming | Feature-frozen since mid-2024 (security updates only). Known bug: renumbering breaks with namespaces |
| **XLIFF Sync** | `rvanbekkum.xliff-sync` | Translation sync + validation, XLIFF 1.2 **and 2.0**, with a PowerShell module for CI | Overlaps NAB AL Tools. Pick one for interactive work; its `XliffSync` PS module is the better CI story |
| **Performance Toolkit** | `ms-dynamics-smb.bcpt` | Scripted multi-session load testing | Windows only; sandbox/container only, never production. Needs the BCPT app in BC and the `BC PERF. TOOLKIT` permission set |
| **BC Telemetry Buddy** | `waldoBC.bc-telemetry-buddy` | Natural-language → KQL over your Application Insights telemetry; Copilot chat participant | Only worth it if your app actually emits telemetry |

> **Object ID Ninja changed materially in 2026.** The source was closed and private back ends
> were switched off on 5 March 2026 — there is no supported self-hosting path any more, and the
> repository licence now reads "provided exclusively for support of existing paying customers."
> What is sent to the vendor also changed: the community version sent only a *hash* of the app
> ID, whereas the commercial platform sends the **raw app ID, publisher name, app name, and your
> email address**. Worth a deliberate decision if you work under client-confidentiality or
> data-residency constraints. The `.objidconfig` authorization key must be committed to the
> repo; lose it and you cannot assign IDs for that app. Ninja also now ships a
> [GitHub Action](https://github.com/vjekob/al-objid-ninja-action) that fails a build on
> untracked object, field, or enum-value IDs — genuinely useful regardless of the licensing.

### Tradeoffs worth knowing

- **NAB AL Tools vs XLIFF Sync** — heavy overlap. NAB is AL-specific and far broader (docs
  generation, AI translation, MCP) and updates roughly ten times as often. XLIFF Sync is
  format-generic, handles XLIFF 2.0, and has the mature PowerShell/CI path. Running both in one
  workspace duplicates commands; if you want both, use NAB interactively and XLIFF Sync in CI.
- **Built-in Test Explorer vs AL Test Runner** (`jamespearson.al-test-runner`) — the community
  extension has richer decoration, code coverage, and a performance profiler view, but Microsoft's
  guidance on BC 28.0+ is to use the built-in explorer. Two prerequisites its README understates:
  it drives **BcContainerHelper** from a PowerShell terminal (so it wants a container), and code
  coverage plus test debugging need a **separate Test Runner Service app** published into BC.
  Its per-project settings live in `.altestrunner/config.json`, *not* `settings.json` — including
  `testRunnerCodeunitId`, which the public docs omit entirely.
- **AL Navigator vs AL CodeActions** (`davidfeldhoff.al-codeactions`) — they overlap on variable
  creation. AL CodeActions has had no code change in ~18 months but still offers refactorings
  AL Navigator lacks (extract procedure, extract to Label, assignment→Validate). Keep it, but
  don't build habits that depend on it being maintained.
- **Analyzers vs speed** — every analyzer costs compile time. `al.backgroundCodeAnalysis:
  "Project"` keeps the editor responsive; leave the full set for the command-line build and CI.

---

## Tier 3 — Agents and MCP servers

This is where the largest recent gains are, and where most setups are furthest behind.

### Microsoft first-party

| Server | Command / endpoint | Purpose |
|---|---|---|
| **AL MCP Server** | `al launchmcpserver --transport stdio` | Build, compile, publish, download symbols, symbol search, diagnostics — headless, works in CI |
| **AL LSP Server** | `al launchlspserver` | Semantic navigation for agents: go-to-definition, find-references across projects, resolves `internalsVisibleTo`. Strictly better than grep for agent code search |
| **Microsoft Learn MCP** | `https://learn.microsoft.com/api/mcp` (HTTP, no install) | Authoritative docs and code-sample search. The cheapest possible fix for agents inventing API signatures |
| **BC MCP Server** | `https://mcp.businesscentral.dynamics.com` | Read/write **business data** over exposed API pages. Not dev tooling. Enable via Feature Management; read-only by default |
| **Troubleshooting MCP** | see AL docs | Live debug: read stack frames and variables while paused at a breakpoint |

> The AL MCP server binary is `al` when installed as the .NET global tool. Microsoft's docs
> sometimes write `altool`, which is the in-extension binary name and is **not on PATH**.
> A config using `"command": "altool"` will silently fail to start.

### Community

| Server | Package | Status |
|---|---|---|
| **AL Dependency MCP** | `npx al-mcp-server` | Object/member search over `.alpackages` symbols. Widely used; no license file — check before redistribution |
| **NAB AL Tools MCP** | `npx -y @nabsolutions/nab-al-tools-mcp` | XLIFF operations for agents. Most actively maintained community BC MCP |
| **AL Object ID Ninja MCP** | `npx -y @vjeko.com/al-object-id-ninja-mcp` | Official successor to the archived `@sshadows/objid-mcp` fork |
| **BC Code Intelligence** | `npx bc-code-intelligence-mcp` | Pattern/persona-based AL review over a curated knowledge base. Single maintainer |
| **ALCops MCP** | `dotnet tool install -g ALCops.Mcp` | Analyzer results as agent tools. **v0.1 alpha — do not gate CI on it** |

### Agent frameworks

- **[alguidelines.dev](https://alguidelines.dev/docs/agentic-coding/)** — Microsoft-maintained, the
  canonical index for agentic AL coding, including "Vibe Coding Rules for AL". Note the rules are
  copy-paste; they are not distributed as `copilot-instructions.md` or `AGENTS.md` files.
- **[ALDC — AL Development Collection](https://github.com/javiarmesto/ALDC-AL-Development-Collection)** —
  the most active AL agentic framework; dual-targets GitHub Copilot and Claude Code. Install from
  the repo (its marketplace listing did not resolve at time of writing).
- **[bc-agentic-dev-tools](https://github.com/FBakkensen/bc-agentic-dev-tools-marketplace)** —
  Claude Code plugin marketplace: `/plugin marketplace add fbakkensen/bc-agentic-dev-tools`.
  Includes `al-code-review` (parallel review subagents) and `al-language-server`.
- **Copilot custom instructions** — `.github/copilot-instructions.md` repo-wide, plus
  `*.instructions.md` files with `applyTo:` globs for path-scoped rules.

---

## Tier 4 — Remove or replace

Dead tooling is not neutral: it shadows working features, breaks on new AL versions, and
misleads whoever inherits the workspace.

| Extension | Verdict | Replacement |
|---|---|---|
| `rasmus.al-formatter` | **Dead** — last code change 2018; source for the shipped version was never published | Built-in AL formatter (`Alt+Shift+F`) — they fight over the same formatting provider |
| `martonsagi.al-object-designer` | **Dead** — abandoned 2020; **broken by namespaces**, so it shows almost nothing from a modern base app | AL Explorer (`Ctrl+Shift+F12`) or AZ AL Dev Tools |
| `rasmus.al-var-helper` | Dormant since 2024, 24 open issues | AL Navigator + the built-in formatter |
| `stefanmaron.businesscentral-lintercop` | Deprecated; no new rules; repo going read-only end-2026 | `Arthurvdv.alcops` |
| `waldo.al-extension-pack` | **Abandoned 2023** — and it packs `microsoft.al`, an ID that no longer exists, so the pack never installs the AL compiler it exists to bootstrap. Seven of its 26 entries are 4–10 years untouched | Hand-pick the extensions you actually use |
| `@modelcontextprotocol/server-github` | Deprecated TypeScript server | GitHub's official Go MCP server |
| `@sshadows/objid-mcp` | Repo **archived 2026-07** | `@vjeko.com/al-object-id-ninja-mcp` |
| NavContainerHelper | Unsupported since 2020 | `BcContainerHelper` |

---

## Workspace settings

`.vscode/settings.json` — Microsoft's cops plus ALCops. Third-party analyzers are referenced
through **`${analyzerfolder}`**, which resolves to the `bin/Analyzers` folder inside the
installed AL Language extension (this is how both LinterCop and ALCops document it; the token
is case-insensitive in practice):

```jsonc
{
  "al.enableCodeAnalysis": true,          // defaults to FALSE — must be set explicitly
  "al.backgroundCodeAnalysis": "Project",
  "al.codeAnalyzers": [
    "${CodeCop}",
    "${UICop}",
    "${AppSourceCop}",                    // use ${PerTenantExtensionCop} for PTEs instead
    "${analyzerfolder}ALCops.ApplicationCop.dll",
    "${analyzerfolder}ALCops.DocumentationCop.dll",
    "${analyzerfolder}ALCops.FormattingCop.dll",
    "${analyzerfolder}ALCops.LinterCop.dll",
    "${analyzerfolder}ALCops.PlatformCop.dll",
    "${analyzerfolder}ALCops.Common.dll"  // MANDATORY — the others fail to load without it
  ],
  "al.ruleSetPath": "<yourapp>.ruleset.json",
  "al.enableCodeActions": true,           // defaults to FALSE — needed for `with` quick fixes
  "al.packageCachePath": "./.alpackages"
}
```

> **Settings precedence is the number one cause of "my analyzer isn't running":** folder
> settings override workspace, which override user. If `al.codeAnalyzers` is defined at folder
> level, any analyzer you added at user level is silently ignored. Check the **AL Cop** status
> bar indicator — it shows which analyzers are actually active for the current file.
>
> `${...}` tokens are resolved at runtime by the language server, not declared in the
> extension manifest, so grepping `package.json` for them proves nothing either way.
>
> Never run LinterCop and ALCops together — their diagnostic IDs collide.

ALCops behaviour (complexity thresholds, naming patterns) is configured in **`alcops.json`**
next to `app.json`; rule *severity* still comes from your `.ruleset.json` via `al.ruleSetPath`.

`.vscode/launch.json` — **always define a sandbox target, and make it the first entry** so
`F5` cannot publish to production by accident:

```jsonc
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Sandbox",
      "request": "launch",
      "type": "al",
      "environmentType": "Sandbox",
      "environmentName": "<sandbox-name>",
      "server": "https://businesscentral.dynamics.com",
      "tenant": "<tenant-guid>",
      "schemaUpdateMode": "Synchronize",   // ForceSync only in a sandbox you can rebuild
      "breakOnError": true,
      "launchBrowser": true
    }
  ]
}
```

`.vscode/mcp.json` — agent access:

```jsonc
{
  "mcpServers": {
    "al":       { "command": "al", "args": ["launchmcpserver", "--transport", "stdio"] },
    "al-deps":  { "command": "npx", "args": ["-y", "al-mcp-server"] },
    "objid":    { "command": "npx", "args": ["-y", "@vjeko.com/al-object-id-ninja-mcp"] },
    "nab":      { "command": "npx", "args": ["-y", "@nabsolutions/nab-al-tools-mcp"] },
    "learn":    { "type": "http", "url": "https://learn.microsoft.com/api/mcp" }
  }
}
```

Never put credentials in `mcp.json` — use environment variables or a credential store.

---

## Running tests without Docker

Docker with Windows containers is the traditional requirement, and on many machines it is
simply unavailable. There are now two ways around that.

### Fastest inner loop: AL Runner

```powershell
dotnet tool install --global MSDyn365BC.AL.Runner
```

[BusinessCentral.AL.Runner](https://github.com/StefanMaron/BusinessCentral.AL.Runner) (MIT) runs
`Subtype = Test` codeunits **in-process in milliseconds** — no service tier, no SQL, no
container, no licence. It loads the unmodified `Microsoft.Dynamics.Nav.*` assemblies, compiles
through BC's own pipeline, and executes via Roslyn. Ships watch mode and a JSON-RPC server mode,
and added code coverage in v2.2. Requires .NET SDK 9 or 10.

Deliberately out of scope — it throws rather than silently passing: SMTP, external HTTP, file
I/O, OData/SOAP endpoints, printers, the real job scheduler, and page/report *rendering*. So it
is a fast pre-check gate and an excellent feedback loop for coding agents, not a replacement for
a real integration run.

### Against a real sandbox: `al runtests`

```powershell
# One codeunit
al runtests 50130 --project "." --environmenttype Sandbox --environmentname <sandbox> `
   --tenant <tenant-guid> --company "<company>"

# Many codeunits over a single authenticated session
al runtests --testgroups testgroups.json --project "." --environmenttype Sandbox `
   --environmentname <sandbox> --tenant <tenant-guid> --company "<company>"
```

```jsonc
// testgroups.json
[
  { "codeunitId": 50130 },
  { "codeunitId": 50131, "testMethods": ["OneSpecificTest"] }
]
```

Environment rules: **production never runs tests.** SaaS sandboxes are fine for manual and
light automated runs. Containers remain the intended CI target, and AL-Go handles that for you.

---

## CI/CD

**[AL-Go for GitHub](https://github.com/microsoft/AL-Go)** is the only Microsoft-authored,
Microsoft-maintained CI/CD for BC apps: build, test, sign, version, release, deploy, and submit
to AppSource. Start from a template rather than hand-writing workflows:

- PTE apps → [microsoft/AL-Go-PTE](https://github.com/microsoft/AL-Go-PTE)
- AppSource apps → [microsoft/AL-Go-AppSource](https://github.com/microsoft/AL-Go-AppSource)

Settings reference: <https://aka.ms/algosettings>. Workflows self-update via **Update AL-Go
System Files**. Keep current — old versions are explicitly unsupported and may break without
notice. AL-Go is GitHub Actions only; for Azure DevOps, Microsoft ships migration guides rather
than a pipeline offering, and ALOps is the commercial alternative there.

> **Code signing caveat:** AL-Go officially supports **Azure Key Vault + .NET Sign** only
> (`keyVaultCodesignCertificateName`, with the Key Vault Crypto User and Certificate User roles).
> **Azure Trusted Signing / Azure Artifact Signing is not a documented AL-Go path** — there are
> open issues requesting it. If you sign with Trusted Signing today, plan a signing step of your
> own rather than assuming AL-Go will absorb it.

---

## Reference assets worth bookmarking

- **[MSDyn365BC.Code.History](https://github.com/StefanMaron/MSDyn365BC.Code.History)** — every
  BC version's source, one branch per country-major version, auto-updated daily from artifacts.
  The canonical way to diff base-app behaviour between versions. Arguably the single most
  valuable community asset for a senior dev.
- **[microsoft/BCApps](https://github.com/microsoft/BCApps)** — the open collaboration hub for
  System Application, Base Application, and the dev tools (Test Framework, Performance Toolkit).
- **[microsoft/BCTech](https://github.com/microsoft/BCTech)** — 200+ KQL queries for App Insights
  telemetry under `samples/AppInsights/KQL/`, plus free Power BI telemetry apps.
- **[alguidelines.dev](https://alguidelines.dev/)** — Microsoft-maintained patterns, including
  the agentic-coding index.

---

## Setup checklist

- [ ] AL Language extension installed and on the current major version
- [ ] `al --version` resolves (the .NET global tool is on PATH)
- [ ] `al.enableCodeAnalysis` is `true` and `al.codeAnalyzers` lists your full set
- [ ] An extended analyzer (ALCops) is referenced by a path that actually exists on disk
- [ ] A **sandbox** launch configuration exists and is listed first
- [ ] Tests run — via the built-in Test Explorer, `al runtests`, or a container
- [ ] MCP servers start (no `altool`-on-PATH assumption, no archived packages)
- [ ] Dead extensions from [Tier 4](#tier-4--remove-or-replace) uninstalled
- [ ] CI builds and tests the app on every PR

---

*Verified 2026-08-20. Re-check extension IDs and deprecation status roughly twice a year;
the AL tooling ecosystem turns over quickly.*
