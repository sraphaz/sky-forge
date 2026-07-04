#Requires -Version 5.1
<#
.SYNOPSIS
  Exibe trilha de auditoria e métricas de observabilidade.
#>
param(
    [string]$Slug = '',
    [int]$Last = 20,
    [switch]$Json,
    [switch]$MetricsOnly
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$ObsFile = Join-Path $RepoRoot '.sky\observability\summary.yaml'

if ($MetricsOnly) {
    if (Test-Path $ObsFile) { Get-Content $ObsFile -Raw } else { Write-Host "Sem métricas ainda." }
    exit 0
}

$slugs = @()
if ($Slug) {
    $slugs = @($Slug)
} else {
    $auditRoot = Join-Path $RepoRoot '.sky\audit'
    if (Test-Path $auditRoot) {
        $slugs = Get-ChildItem $auditRoot -Directory | ForEach-Object { $_.Name }
    }
}

$allEvents = @()
foreach ($s in $slugs) {
    $file = Join-Path $RepoRoot ".sky\audit\$s\events.jsonl"
    if (Test-Path $file) {
        Get-Content $file | ForEach-Object {
            try { $allEvents += ($_ | ConvertFrom-Json) } catch { }
        }
    }
}

$allEvents = $allEvents | Sort-Object { $_.ts } -Descending | Select-Object -First $Last

if ($Json) {
    @{
        metrics = if (Test-Path $ObsFile) { Get-Content $ObsFile -Raw } else { $null }
        events = $allEvents
    } | ConvertTo-Json -Depth 6
    exit 0
}

Write-Host "=== Sky-Forge Agent Audit ===" -ForegroundColor Cyan
if (Test-Path $ObsFile) {
    Write-Host "--- Observability ---" -ForegroundColor Yellow
    Get-Content $ObsFile | Write-Host
}
Write-Host "--- Últimos $Last eventos ---" -ForegroundColor Yellow
if ($allEvents.Count -eq 0) {
    Write-Host "Nenhum evento registrado. Use record-agent-event ou hook stop."
} else {
    foreach ($e in $allEvents) {
        $gate = if ($e.human_gate) { " gate=$($e.human_gate)" } else { '' }
        Write-Host "$($e.ts) [$($e.agent_id)] $($e.action) → $($e.outcome) ($($e.autonomy_level))$gate"
    }
}
