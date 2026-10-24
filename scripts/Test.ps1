<#
.SYNOPSIS
    Runs the Inventory Health Check test suite in a Business Central container.

.DESCRIPTION
    The tests build their scenarios by inserting Item Ledger Entry and Warehouse Entry rows
    directly, which a Business Central online licence never allows, so they cannot run in a
    SaaS sandbox. A container with the test toolkit allows it.

    Steps: create a BC container (sandbox artifact, test libraries only), compile and publish
    the app and the test app, run every test codeunit of the test app, write JUnit-style XML
    results and fail when any test fails. The container password is generated for this run
    and never stored.

    Needs Docker with Windows containers (GitHub-hosted windows-latest runners have it) and
    BcContainerHelper (installed if missing).

.EXAMPLE
    ./scripts/Test.ps1
    ./scripts/Test.ps1 -BcVersion 29 -Country w1 -KeepContainer
#>
[CmdletBinding()]
param(
    [string] $ContainerName = 'irtest',
    [string] $BcVersion = '29',
    [string] $Country = 'w1',
    [string] $ResultsPath = (Join-Path $PSScriptRoot '..\artifacts\TestResults.xml'),
    [switch] $KeepContainer
)

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$testAppId = (Get-Content (Join-Path $repo 'test\app.json') -Raw | ConvertFrom-Json).id

if (-not (Get-Module -ListAvailable BcContainerHelper)) {
    Install-Module BcContainerHelper -Force -Scope CurrentUser -AllowClobber
}
Import-Module BcContainerHelper -WarningAction SilentlyContinue

# One-off credential for this container only; never written anywhere.
$chars = [char[]]'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
$password = -join (1..20 | ForEach-Object { $chars | Get-Random }) + '!9a'
$credential = New-Object PSCredential 'admin', (ConvertTo-SecureString $password -AsPlainText -Force)

$artifactUrl = Get-BCArtifactUrl -type Sandbox -version $BcVersion -country $Country -select Latest
Write-Host "Artifact: $artifactUrl"

New-BcContainer `
    -accept_eula `
    -containerName $ContainerName `
    -artifactUrl $artifactUrl `
    -auth NavUserPassword `
    -Credential $credential `
    -includeTestToolkit `
    -includeTestLibrariesOnly `
    -updateHosts:$false `
    -multitenant:$false `
    -additionalParameters @("--volume ""$($repo):c:\sources""")

try {
    $output = Join-Path $repo 'artifacts'
    New-Item -ItemType Directory -Force $output | Out-Null

    foreach ($project in 'app', 'test') {
        $folder = Join-Path $repo $project
        $appFile = Compile-AppInBcContainer `
            -containerName $ContainerName `
            -credential $credential `
            -appProjectFolder $folder `
            -appOutputFolder $output `
            -appSymbolsFolder (Join-Path $folder '.alpackages') `
            -EnableCodeCop -EnableUICop `
            -FailOn error
        Publish-BcContainerApp `
            -containerName $ContainerName `
            -credential $credential `
            -appFile $appFile `
            -skipVerification `
            -sync `
            -install
    }

    New-Item -ItemType Directory -Force (Split-Path $ResultsPath) | Out-Null
    $allPassed = Run-TestsInBcContainer `
        -containerName $ContainerName `
        -credential $credential `
        -extensionId $testAppId `
        -detailed `
        -XUnitResultFileName $ResultsPath `
        -returnTrueIfAllPassed

    if (-not $allPassed) {
        throw "One or more tests failed. Results: $ResultsPath"
    }
    Write-Host "All tests passed. Results: $ResultsPath"
}
finally {
    if (-not $KeepContainer) {
        Remove-BcContainer -containerName $ContainerName
    }
}
