<#
.SYNOPSIS
    Compiles the GSO Inventory Health Check app (and optionally its test and demo
    apps) with the code analyzers and the project rulesets, failing on compiler errors
    and on a non-zero compiler exit code.

.DESCRIPTION
    Uses alc.exe from -AlcPath, $env:ALC_PATH, or the newest installed AL Language
    VS Code extension. Analyzers are REQUIRED: the build fails if one cannot be found.
      main app:      CodeCop, UICop, AppSourceCop, LinterCop
      test and demo: CodeCop, UICop, LinterCop
    CodeCop, UICop and AppSourceCop come from next to alc.exe. LinterCop (ALCops)
    is looked up next to alc.exe, then in $env:ALCOPS_PATH, then in
    build\.tools\alcops (where scripts/DownloadSymbols.ps1 puts it). LinterCop needs
    ALCops.Common.dll passed as an analyzer too; without it every LinterCop rule
    crashes with AD0001 and reports nothing.
    Symbols are read from <project>\.alpackages (or -PackageCachePath). With
    -IncludeTests / -IncludeDemo the freshly built main .app is copied into that
    project's package cache and the project is compiled too.

.EXAMPLE
    ./scripts/Build.ps1
    ./scripts/Build.ps1 -IncludeTests -IncludeDemo -FailOnWarnings
    ./scripts/Build.ps1 -AlcPath 'C:\tools\alc\alc.exe' -PackageCachePath 'C:\symbols'
#>
[CmdletBinding()]
param(
    [string] $AlcPath,
    [string] $PackageCachePath,
    [string] $OutputPath = (Join-Path $PSScriptRoot '..\artifacts'),
    [switch] $IncludeTests,
    [switch] $IncludeDemo,
    [switch] $FailOnWarnings
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$appProject = Join-Path $repo 'app'
$testProject = Join-Path $repo 'test'
$demoProject = Join-Path $repo 'demo'

function Resolve-Alc {
    param([string] $Explicit)
    if ($Explicit) { if (Test-Path $Explicit) { return (Resolve-Path $Explicit).Path }; throw "alc.exe not found at $Explicit" }
    if ($env:ALC_PATH -and (Test-Path $env:ALC_PATH)) { return $env:ALC_PATH }
    $extRoot = Join-Path $env:USERPROFILE '.vscode\extensions'
    $ext = Get-ChildItem $extRoot -Directory -Filter 'ms-dynamics-smb.al-*' -ErrorAction SilentlyContinue |
        Sort-Object { [version](($_.Name -replace '^ms-dynamics-smb\.al-', '') -replace '-.*$', '') } -Descending |
        Select-Object -First 1
    if (-not $ext) { throw 'alc.exe not found: install the AL Language extension, pass -AlcPath, set ALC_PATH, or run scripts/DownloadSymbols.ps1.' }
    foreach ($c in @((Join-Path $ext.FullName 'bin\alc.exe'), (Join-Path $ext.FullName 'bin\win32\alc.exe'))) {
        if (Test-Path $c) { return $c }
    }
    throw "alc.exe not found under $($ext.FullName)\bin"
}

function Resolve-Analyzer {
    param([string] $AlcDir, [string] $Name)
    foreach ($c in @((Join-Path $AlcDir $Name), (Join-Path $AlcDir "Analyzers\$Name"))) {
        if (Test-Path $c) { return $c }
    }
    throw "Required analyzer $Name not found next to alc.exe ($AlcDir). The build does not run without analyzers."
}

function Resolve-LinterCop {
    # Returns ALCops.Common.dll and ALCops.LinterCop.dll from the first folder that has both.
    param([string] $AlcDir)
    $candidates = @($AlcDir, $env:ALCOPS_PATH, (Join-Path $repo 'build\.tools\alcops\lib\net10.0'), (Join-Path $repo 'build\.tools\alcops\lib\net8.0'))
    foreach ($dir in $candidates | Where-Object { $_ }) {
        $common = Join-Path $dir 'ALCops.Common.dll'
        $linter = Join-Path $dir 'ALCops.LinterCop.dll'
        if ((Test-Path $common) -and (Test-Path $linter)) { return @($common, $linter) }
    }
    throw "LinterCop (ALCops.Common.dll + ALCops.LinterCop.dll) not found next to alc.exe, in ALCOPS_PATH or in build\.tools\alcops. Run scripts/DownloadSymbols.ps1 to fetch it."
}

function Add-ProjectBuild {
    # Seeds a dependent project's package cache with the base symbols and the
    # main app just built, then compiles it.
    param([string] $Project, [string] $CacheName, [string] $Ruleset, [string[]] $RequiredLibraries = @())
    $cache = if ($PackageCachePath) { Join-Path $PackageCachePath $CacheName } else { Join-Path $Project '.alpackages' }
    New-Item -ItemType Directory -Force $cache | Out-Null
    Get-ChildItem $appCache -Filter '*.app' | Copy-Item -Destination $cache -Force
    # Only one package of the main app may be in the cache.
    Get-ChildItem $cache -Filter ("{0}_{1}_*.app" -f $manifest.publisher, $manifest.name) | Remove-Item -Force
    Copy-Item $appFile (Join-Path $cache (Split-Path $appFile -Leaf)) -Force
    foreach ($lib in $RequiredLibraries) {
        if (-not (Get-ChildItem $cache -Filter "*$lib*.app" -ErrorAction SilentlyContinue)) {
            throw "Library '$lib' is missing from $cache. Run scripts/DownloadSymbols.ps1 (it copies the test libraries from the BC artifacts)."
        }
    }
    $m = Get-Content (Join-Path $Project 'app.json') -Raw | ConvertFrom-Json
    $out = Join-Path $OutputPath ("{0}_{1}_{2}.app" -f $m.publisher, $m.name, $m.version)
    if (-not (Test-Path $Ruleset)) { $Ruleset = $null }
    Invoke-AlCompile -Project $Project -PackageCache $cache -OutFile $out -Analyzers (@($codeCop, $uiCop) + $linterCop) -Ruleset $Ruleset
}

function Invoke-AlCompile {
    param(
        [string] $Project,
        [string] $PackageCache,
        [string] $OutFile,
        [string[]] $Analyzers,
        [string] $Ruleset
    )
    $alcArgs = @("/project:$Project", "/packagecachepath:$PackageCache", "/out:$OutFile")
    foreach ($a in $Analyzers) { $alcArgs += "/analyzer:$a" }
    if ($Ruleset) { $alcArgs += "/ruleset:$Ruleset" }

    Write-Host "alc $Project -> $OutFile"
    $output = & $alc @alcArgs 2>&1
    $exitCode = $LASTEXITCODE
    $output | ForEach-Object { Write-Host $_ }

    # Case-sensitive and anchored on the diagnostic code: a LinterCop message such as
    # "warning LC0048: Error is called ..." must not count as a compile error.
    $errors = @($output | Where-Object { "$_" -cmatch '(^|: )error [A-Z]+\d+' })
    $warnings = @($output | Where-Object { "$_" -cmatch ': warning [A-Z]+\d+' })
    $crashes = @($output | Where-Object { "$_" -cmatch 'AD0001|AL1003' })
    Write-Host ("exit code {0}, {1} error(s), {2} warning(s)" -f $exitCode, $errors.Count, $warnings.Count)

    if ($exitCode -ne 0) { throw "alc exited with code $exitCode for $Project." }
    if ($errors.Count -gt 0) { throw "Compilation of $Project reported $($errors.Count) error(s)." }
    if ($crashes.Count -gt 0) { throw "An analyzer did not load for $Project (AD0001/AL1003); the analysis is not valid." }
    if (-not (Test-Path $OutFile)) { throw "alc reported success but $OutFile was not produced." }
    if ($FailOnWarnings -and $warnings.Count -gt 0) { throw "Compilation of $Project produced $($warnings.Count) warning(s) and -FailOnWarnings is set." }
}

$alc = Resolve-Alc -Explicit $AlcPath
$alcDir = Split-Path $alc -Parent
$codeCop = Resolve-Analyzer -AlcDir $alcDir -Name 'Microsoft.Dynamics.Nav.CodeCop.dll'
$uiCop = Resolve-Analyzer -AlcDir $alcDir -Name 'Microsoft.Dynamics.Nav.UICop.dll'
$appSourceCop = Resolve-Analyzer -AlcDir $alcDir -Name 'Microsoft.Dynamics.Nav.AppSourceCop.dll'
$linterCop = Resolve-LinterCop -AlcDir $alcDir

$appRuleset = Join-Path $appProject 'app.ruleset.json'
if (-not (Test-Path $appRuleset)) { $appRuleset = $null }
$testRuleset = Join-Path $testProject 'test.ruleset.json'

$appCache = if ($PackageCachePath) { $PackageCachePath } else { Join-Path $appProject '.alpackages' }
if (-not (Test-Path $appCache) -or -not (Get-ChildItem $appCache -Filter '*.app' -ErrorAction SilentlyContinue)) {
    throw "No symbol packages found in $appCache. Download symbols first (see scripts/DownloadSymbols.ps1 or the CI workflow)."
}

New-Item -ItemType Directory -Force $OutputPath | Out-Null
$manifest = Get-Content (Join-Path $appProject 'app.json') -Raw | ConvertFrom-Json
$appFile = Join-Path $OutputPath ("{0}_{1}_{2}.app" -f $manifest.publisher, $manifest.name, $manifest.version)

Invoke-AlCompile -Project $appProject -PackageCache $appCache -OutFile $appFile -Analyzers (@($codeCop, $uiCop, $appSourceCop) + $linterCop) -Ruleset $appRuleset

if ($IncludeTests) {
    Add-ProjectBuild -Project $testProject -CacheName 'test' -Ruleset $testRuleset -RequiredLibraries @('Library Assert', 'Application Test Library')
}

if ($IncludeDemo) {
    # The demo app uses the test ruleset (see demo\.vscode\settings.json).
    Add-ProjectBuild -Project $demoProject -CacheName 'demo' -Ruleset $testRuleset
}

Write-Host 'Build succeeded.'
