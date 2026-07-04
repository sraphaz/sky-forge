#Requires -Version 5.1
<#
.SYNOPSIS
  Registra evento de agente na trilha de auditoria (append-only JSONL).
.EXAMPLE
  ./record-agent-event.ps1 -Slug iautos -AgentId delivery-steward -Action export.package -Outcome ok
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [Parameter(Mandatory = $true)]
    [string]$AgentId,

    [Parameter(Mandatory = $true)]
    [string]$Action,

    [ValidateSet('ok', 'blocked', 'denied', 'error', 'pending')]
    [string]$Outcome = 'ok',

    [string]$AutonomyLevel = 'activate',
    [string]$Details = '',
    [string]$CorrelationId = '',
    [string]$HumanGate = '',
    [switch]$Blocked
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$AuditDir = Join-Path $RepoRoot ".sky\audit\$Slug"
$AuditFile = Join-Path $AuditDir 'events.jsonl'
$ObsDir = Join-Path $RepoRoot '.sky\observability'
$SummaryFile = Join-Path $ObsDir 'summary.yaml'

New-Item -ItemType Directory -Path $AuditDir -Force | Out-Null
New-Item -ItemType Directory -Path $ObsDir -Force | Out-Null

if (-not $CorrelationId) {
    $CorrelationId = [guid]::NewGuid().ToString('N').Substring(0, 12)
}

$event = [ordered]@{
    ts = (Get-Date).ToUniversalTime().ToString('o')
    correlation_id = $CorrelationId
    slug = $Slug
    agent_id = $AgentId
    action = $Action
    autonomy_level = $AutonomyLevel
    outcome = if ($Blocked) { 'blocked' } else { $Outcome }
    human_gate = if ($HumanGate) { $HumanGate } else { $null }
    details = $Details
}

$line = ($event | ConvertTo-Json -Compress -Depth 5)
Add-Content -Path $AuditFile -Value $line -Encoding UTF8

# Atualizar summary agregado
$counts = @{
    total_events = 0
    by_agent = @{}
    by_action = @{}
    by_outcome = @{}
    last_event_at = $event.ts
    last_agent = $AgentId
    last_slug = $Slug
}
if (Test-Path $SummaryFile) {
    $existing = Get-Content $SummaryFile -Raw
    if ($existing -match 'total_events:\s*(\d+)') { $counts.total_events = [int]$Matches[1] }
}
$counts.total_events++
if (-not $counts.by_agent.ContainsKey($AgentId)) { $counts.by_agent[$AgentId] = 0 }
$counts.by_agent[$AgentId]++
$oa = $event.outcome
if (-not $counts.by_outcome.ContainsKey($oa)) { $counts.by_outcome[$oa] = 0 }
$counts.by_outcome[$oa]++

$summary = @"
# Gerado por record-agent-event.ps1 — nao editar manualmente
updated_at: $($event.ts)
total_events: $($counts.total_events)
last_slug: $Slug
last_agent: $AgentId
last_action: $Action
last_outcome: $($event.outcome)
"@
Set-Content -Path $SummaryFile -Value $summary -Encoding UTF8

if (-not $Blocked) {
    Write-Verbose "Audit: $AuditFile"
}
