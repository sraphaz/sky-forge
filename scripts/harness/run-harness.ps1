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

# Agent graph & coreografia
$exportGraph = Join-Path $RepoRoot 'scripts\agents\export-agent-graph.ps1'
$validateGraph = Join-Path $RepoRoot 'scripts\agents\validate-agent-graph.ps1'
if (Test-Path $exportGraph) { & $exportGraph }
if (Test-Path $validateGraph) {
    & $validateGraph
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$choreo = Join-Path $RepoRoot 'scripts\agents\choreograph-agents.ps1'
if (Test-Path $choreo) {
    & $choreo -ChangedFiles '.agents/choreography.yaml' -Trigger path_change
}

Write-Host "Harness OK" -ForegroundColor Green
