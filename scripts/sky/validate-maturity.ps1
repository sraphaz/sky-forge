#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$maturityPath = Join-Path $RepoRoot ".sky\sessions\$Slug\maturity.yaml"

if (-not (Test-Path $maturityPath)) {
    throw "maturity.yaml nao encontrado para slug: $Slug"
}

$content = Get-Content $maturityPath -Raw
$errors = @()

if ($content -notmatch 'overall_readiness:\s*([0-9.]+)') {
    $errors += 'overall_readiness ausente'
} else {
    $readiness = [double]$Matches[1]
    if ($readiness -lt 0 -or $readiness -gt 1) {
        $errors += "overall_readiness fora de 0-1: $readiness"
    }
}

foreach ($dim in @('business', 'product', 'ux_design', 'technical', 'sustainability', 'elevation')) {
    if ($content -notmatch "${dim}:\s*\r?\n\s*level:") {
        $errors += "dimensao ausente: $dim"
    }
}

if ($errors.Count -gt 0) {
    Write-Host "validate-maturity FALHOU:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  - $_" }
    exit 1
}

Write-Host "validate-maturity OK: $Slug (readiness=$readiness)" -ForegroundColor Green
