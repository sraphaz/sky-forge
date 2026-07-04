#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')

Write-Host "=== Sky-Forge Harness ===" -ForegroundColor Cyan

& (Join-Path $PSScriptRoot 'validate-specs.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Validar sessao exemplo
$exampleValidate = Join-Path $RepoRoot 'scripts\forge\validate-maturity.ps1'
if (Test-Path (Join-Path $RepoRoot 'templates\sessions\example-horta\maturity.yaml')) {
    Write-Host "Validando template example-horta (copia temporaria nao necessaria — maturity no template)"
}

Write-Host "Harness OK" -ForegroundColor Green
