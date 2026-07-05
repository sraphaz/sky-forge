#Requires -Version 5.1
<#
.SYNOPSIS
  Integra um .dc.html gerado pelo Claude Design no pacote Sky-Forge e app ligado.
.EXAMPLE
  ./scripts/sky/integrate-dc.ps1 -Slug iautos -Screen design-system -SourcePath C:\Downloads\design-system.dc.html
  ./scripts/sky/integrate-dc.ps1 -Slug iautos -Screen login -SourcePath .\novo-login.dc.html -Sync
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [Parameter(Mandatory = $true)]
    [string]$Screen,

    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [ValidateSet('screens', 'institutional', 'platform', 'mobile', 'sky-forge')]
    [string]$Folder = 'screens',

    [switch]$Sync
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'get-sky-config.ps1')
. (Join-Path $PSScriptRoot 'resolve-sky-link.ps1')

if (-not (Test-Path $SourcePath)) { throw "Arquivo nao encontrado: $SourcePath" }

$fileName = if ($Screen -match '\.dc\.html$') { $Screen } else { "$Screen.dc.html" }
$outputDir = Get-SkyOutputDirForSlug $Slug
$destPackage = Join-Path $outputDir "cloud-design\$Folder\$fileName"
New-Item -ItemType Directory -Path (Split-Path $destPackage -Parent) -Force | Out-Null
Copy-Item $SourcePath $destPackage -Force
Write-Host "Pacote: $destPackage" -ForegroundColor Green

$ctx = Get-SkyLinkContext -Slug $Slug
if ($ctx.WorkspacePath) {
    $destApp = Join-Path $ctx.WorkspacePath "spec\cloud-design\$Folder\$fileName"
    New-Item -ItemType Directory -Path (Split-Path $destApp -Parent) -Force | Out-Null
    Copy-Item $SourcePath $destApp -Force
    Write-Host "App spec: $destApp" -ForegroundColor Green
}

$indexPath = Join-Path $outputDir 'cloud-design\DESIGN_INVENTORY.yaml'
if (Test-Path $indexPath) {
    $raw = Get-Content $indexPath -Raw
    $raw = $raw -replace 'updated_at:.*', "updated_at: `"$((Get-Date).ToUniversalTime().ToString('o'))`""
    Set-Content $indexPath -Value $raw -Encoding UTF8
}

if ($Sync) {
    & (Join-Path $PSScriptRoot 'sync-showcase.ps1') -Slug $Slug -Public -SkipExport
}

Write-Host "Integrado: $Folder/$fileName" -ForegroundColor Cyan
