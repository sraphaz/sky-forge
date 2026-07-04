#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$errors = @()

$graphPath = Join-Path $RepoRoot 'docs\_meta\agent-graph.generated.json'
if (-not (Test-Path $graphPath)) {
    & (Join-Path $PSScriptRoot 'export-agent-graph.ps1')
}

$graph = Get-Content $graphPath -Raw | ConvertFrom-Json
$agentIds = @($graph.nodes.agents | ForEach-Object { $_.id })
$skillIds = @($graph.nodes.skills | ForEach-Object { $_.id })

foreach ($edge in $graph.edges) {
    if ($edge.to -match '^agent:(.+)$') {
        if ($agentIds -notcontains $Matches[1]) { $errors += "Agente inexistente: $($edge.to)" }
    }
    if ($edge.to -match '^skill:(.+)$') {
        if ($skillIds -notcontains $Matches[1]) { $errors += "Skill inexistente: $($edge.to)" }
    }
}

$choreoAgents = @()
foreach ($rule in $graph.nodes.rules) { $choreoAgents += $rule.agents }
$choreoAgents = $choreoAgents | Select-Object -Unique
foreach ($ca in $choreoAgents) {
    if ($agentIds -notcontains $ca) { $errors += "Coreografia referencia agente sem manifest: $ca" }
}

if (-not (Test-Path (Join-Path $RepoRoot '.agents\autonomy.yaml'))) {
    $errors += 'autonomy.yaml ausente'
}

if ($errors.Count -gt 0) {
    Write-Host "Agent graph INVALID" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  $_" }
    exit 1
}
Write-Host "Agent graph OK ($($graph.edges.Count) edges)" -ForegroundColor Green
