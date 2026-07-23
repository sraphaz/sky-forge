#Requires -Version 5.1
<#
.SYNOPSIS
  Sincroniza showcase após mudanças na sessão: export → publish → ZIP.
  Chamado automaticamente pelo sky-local-api após decisões no portal.
.EXAMPLE
  ./scripts/sky/sync-showcase.ps1 -Slug iautos
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [switch]$SkipExport,
    [switch]$SkipZip,
    [switch]$Public,
    [switch]$NoPublic
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'get-sky-config.ps1')
$RepoRoot = Get-SkyRepoRoot
$SessionDir = Join-Path $RepoRoot ".sky\sessions\$Slug"

if (-not (Test-Path $SessionDir)) {
    throw "Sessao nao encontrada: $Slug"
}

$doPublic = [bool]$Public
if (-not $Public -and -not $NoPublic) {
    $journeyPath = Join-Path $SessionDir 'journey.yaml'
    if (Test-Path $journeyPath) {
        $journey = Get-Content $journeyPath -Raw
        if ($journey -match '(?m)^\s*public_showcase:\s*true\s*$') { $doPublic = $true }
    }
    $indexPath = Join-Path (Get-SkyRegistryDir) 'index.json'
    if (-not $doPublic -and (Test-Path $indexPath)) {
        $index = Get-Content $indexPath -Raw | ConvertFrom-Json
        $prev = @($index.projects | Where-Object { $_.slug -eq $Slug } | Select-Object -First 1)
        if ($prev -and $prev.public -eq $true) { $doPublic = $true }
    }
}

if (-not $SkipExport) {
    Write-Host "== export ($Slug) ==" -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot 'validate-maturity.ps1') -Slug $Slug
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & (Join-Path $PSScriptRoot 'validate-package.ps1') -Slug $Slug -Completeness full -Force
    & (Join-Path $PSScriptRoot 'export-package.ps1') -Slug $Slug
    $dcScript = Join-Path $RepoRoot 'extensions\sky-cloud-design\scripts\export-dc.ps1'
    if (Test-Path $dcScript) { & $dcScript -Slug $Slug }
}

Write-Host "== publish preview ==" -ForegroundColor Cyan
$pubArgs = @{ Slug = $Slug }
if ($doPublic) { $pubArgs.Public = $true }
& (Join-Path $PSScriptRoot 'publish-preview.ps1') @pubArgs

if (-not $SkipZip) {
    Write-Host "== package zip ==" -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot 'package-zip.ps1') -Slug $Slug
    # Republicar para incluir metadados do ZIP no registry
    & (Join-Path $PSScriptRoot 'publish-preview.ps1') @pubArgs
}

Write-Host "Showcase sincronizado: $Slug (public=$doPublic)" -ForegroundColor Green
