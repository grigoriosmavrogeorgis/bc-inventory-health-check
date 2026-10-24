<#
.SYNOPSIS
    Provisions the AL compiler and the symbol packages the build needs, for a
    machine (or CI runner) that has neither.

.DESCRIPTION
    1. Downloads the AL Language VS Code extension (VSIX) from the marketplace and
       extracts alc.exe + analyzers to -ToolsPath\alc. Sets $env:ALC_PATH. Also
       downloads LinterCop (NuGet ALCops.Analyzers) to -ToolsPath\alcops.
    2. Uses BcContainerHelper to download the Business Central artifacts matching
       app.json "application" and copies every Microsoft .app symbol (System,
       System Application, Base Application, Business Foundation, Application)
       into -PackageCachePath.

.EXAMPLE
    ./scripts/DownloadSymbols.ps1 -PackageCachePath ./app/.alpackages
#>
[CmdletBinding()]
param(
    [string] $PackageCachePath = (Join-Path $PSScriptRoot '..\app\.alpackages'),
    [string] $ToolsPath = (Join-Path $PSScriptRoot '..\build\.tools'),
    [string] $Country = 'w1',
    [string] $ALCopsVersion = '1.3.1',
    [switch] $SkipCompiler
)

$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force $PackageCachePath, $ToolsPath | Out-Null

if (-not $SkipCompiler) {
    $alcDir = Join-Path $ToolsPath 'alc'
    if (-not (Test-Path (Join-Path $alcDir 'extension\bin\alc.exe'))) {
        $vsix = Join-Path $ToolsPath 'al.vsix'
        Write-Host 'Downloading AL Language extension...'
        Invoke-WebRequest -UseBasicParsing -OutFile $vsix `
            -Uri 'https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-dynamics-smb/vsextensions/al/latest/vspackage'
        $zip = "$vsix.zip"
        Copy-Item $vsix $zip -Force
        Expand-Archive $zip -DestinationPath $alcDir -Force
    }
    $alcExe = Join-Path $alcDir 'extension\bin\alc.exe'
    if (-not (Test-Path $alcExe)) { $alcExe = Join-Path $alcDir 'extension\bin\win32\alc.exe' }
    if (-not (Test-Path $alcExe)) { throw 'alc.exe not found after extracting the AL extension.' }
    $env:ALC_PATH = $alcExe
    if ($env:GITHUB_ENV) { "ALC_PATH=$alcExe" | Out-File -Append -Encoding utf8 $env:GITHUB_ENV }
    Write-Host "alc: $alcExe"

    # LinterCop (ALCops) is not part of the AL extension package. Fetch the pinned
    # NuGet release unless it already sits next to alc.exe. Build.ps1 finds it in
    # build\.tools\alcops\lib\<framework>.
    if (-not (Test-Path (Join-Path (Split-Path $alcExe -Parent) 'ALCops.LinterCop.dll'))) {
        $alcopsDir = Join-Path $ToolsPath 'alcops'
        if (-not (Test-Path (Join-Path $alcopsDir 'lib\net10.0\ALCops.LinterCop.dll'))) {
            Write-Host "Downloading ALCops.Analyzers $ALCopsVersion (LinterCop)..."
            $nupkg = Join-Path $ToolsPath "alcops.$ALCopsVersion.zip"
            Invoke-WebRequest -UseBasicParsing -OutFile $nupkg -Uri "https://www.nuget.org/api/v2/package/ALCops.Analyzers/$ALCopsVersion"
            Expand-Archive $nupkg -DestinationPath $alcopsDir -Force
        }
        Write-Host "LinterCop: $alcopsDir"
    }
}

Import-Module BcContainerHelper -ErrorAction Stop
$manifest = Get-Content (Join-Path $PSScriptRoot '..\app\app.json') -Raw | ConvertFrom-Json
$version = ([version]$manifest.application).Major
Write-Host "Resolving Business Central $version artifacts ($Country)..."
$artifactUrl = Get-BCArtifactUrl -type Sandbox -country $Country -version "$version" -select Latest
if (-not $artifactUrl) { throw "No Business Central artifact found for version $version / $Country." }
$paths = Download-Artifacts -artifactUrl $artifactUrl -includePlatform
# Copies the application symbols AND the test framework libraries (Library Assert,
# Any, Tests-TestLibraries, Application Test Library ...) that live under
# Applications\TestFramework in the application artifact — the test app needs them.
foreach ($p in $paths) {
    Get-ChildItem $p -Recurse -Filter 'Microsoft_*.app' | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $PackageCachePath $_.Name) -Force
    }
    Get-ChildItem $p -Recurse -Filter 'System.app' | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $PackageCachePath 'Microsoft_System.app') -Force
    }
}
foreach ($lib in @('Library Assert')) {
    if (-not (Get-ChildItem $PackageCachePath -Filter "*$lib*.app" -ErrorAction SilentlyContinue)) {
        Write-Warning "Test library '$lib' was not found in the artifacts; the test app will not compile until it is added to $PackageCachePath."
    }
}

Write-Host ("Symbols in {0}:" -f $PackageCachePath)
Get-ChildItem $PackageCachePath -Filter '*.app' | ForEach-Object { Write-Host "  $($_.Name)" }
