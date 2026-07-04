#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [Parameter()]
    [ValidateSet('partial', 'full')]
    [string]$Completeness = 'full',

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$SessionDir = Join-Path $RepoRoot ".sky\sessions\$Slug"
$OutputDir = Join-Path $RepoRoot "outputs\$Slug"
$errors = @()
$warnings = @()

if (-not (Test-Path $SessionDir)) {
    throw "Sessao nao encontrada: $Slug"
}

& (Join-Path $PSScriptRoot 'validate-maturity.ps1') -Slug $Slug
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$maturity = Get-Content (Join-Path $SessionDir 'maturity.yaml') -Raw
$readiness = 0.0
if ($maturity -match 'overall_readiness:\s*([0-9.]+)') {
    $readiness = [double]$Matches[1]
}

$minReadiness = if ($Completeness -eq 'full') { 0.85 } else { 0.55 }
if ($readiness -lt $minReadiness -and -not $Force) {
    $errors += "overall_readiness $readiness < $minReadiness para completeness=$Completeness (use -Force para ignorar)"
}

# AC-FP-1 brief
$briefPath = Join-Path $SessionDir 'brief-draft.yaml'
if (Test-Path $briefPath) {
    $brief = Get-Content $briefPath -Raw
    if ($brief -notmatch 'problem:\s*\S') { $warnings += 'brief: problem vazio' }
    if ($brief -notmatch 'tier:\s*\S') { $warnings += 'brief: tier indefinido' }
} else {
    $errors += 'brief-draft.yaml ausente'
}

# AC-FP-3 RF must confirmado (sessao ou output)
$rfPath = Join-Path $SessionDir 'functional-requirements.yaml'
$rfMustConfirmed = $false
if (Test-Path $rfPath) {
    $rf = Get-Content $rfPath -Raw
    if ($rf -match 'priority:\s*must' -and $rf -match 'user_confirmed:\s*true') {
        $rfMustConfirmed = $true
    }
}
if (-not $rfMustConfirmed -and $Completeness -eq 'full') {
    $warnings += 'nenhum RF must com user_confirmed: true'
}

# Outputs opcionais
if (Test-Path $OutputDir) {
    if (-not (Test-Path (Join-Path $OutputDir 'tier-matrix.yaml'))) {
        $warnings += 'outputs: tier-matrix.yaml ausente (gerar em forge-plan PR2)'
    }
} else {
    $warnings += "outputs/$Slug/ ainda nao criado — OK no intake puro"
}

$report = @{
    slug               = $Slug
    completeness       = $Completeness
    overall_readiness  = $readiness
    errors             = $errors
    warnings           = $warnings
    passed             = ($errors.Count -eq 0)
    validated_at       = (Get-Date).ToUniversalTime().ToString('o')
}
$reportPath = Join-Path $RepoRoot 'harness-report.json'
$report | ConvertTo-Json -Depth 5 | Set-Content $reportPath -Encoding UTF8

if ($errors.Count -gt 0) {
    Write-Host "validate-package FALHOU" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  ERROR: $_" }
    exit 1
}

Write-Host "validate-package OK ($Completeness)" -ForegroundColor Green
if ($warnings.Count -gt 0) {
    $warnings | ForEach-Object { Write-Host "  WARN: $_" -ForegroundColor Yellow }
}
