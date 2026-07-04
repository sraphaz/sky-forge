#Requires -Version 5.1
<#
.SYNOPSIS
  Publica snapshot sanitizado de observabilidade de agentes para o showcase UI.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'get-sky-config.ps1')
$RepoRoot = Get-SkyRepoRoot

function Sanitize-Details([string]$d) {
    if (-not $d) { return '' }
    $d = $d -replace '[A-Z]:\\[^\s"]+', '[path]'
    $d = $d -replace '/Users/[^\s"]+', '[path]'
    if ($d.Length -gt 120) { $d = $d.Substring(0, 117) + '...' }
    return $d
}

# Métricas
$metrics = @{ total_events = 0; last_agent = $null; last_action = $null; last_outcome = $null }
$summaryPath = Join-Path $RepoRoot '.sky\observability\summary.yaml'
if (Test-Path $summaryPath) {
    $s = Get-Content $summaryPath -Raw
    if ($s -match 'total_events:\s*(\d+)') { $metrics.total_events = [int]$Matches[1] }
    if ($s -match 'last_agent:\s*(.+)') { $metrics.last_agent = $Matches[1].Trim() }
    if ($s -match 'last_action:\s*(.+)') { $metrics.last_action = $Matches[1].Trim() }
    if ($s -match 'last_outcome:\s*(.+)') { $metrics.last_outcome = $Matches[1].Trim() }
}

# Eventos
$events = @()
$auditFile = Join-Path $RepoRoot ".sky\audit\$Slug\events.jsonl"
if (Test-Path $auditFile) {
    Get-Content $auditFile | ForEach-Object {
        try {
            $e = $_ | ConvertFrom-Json
            $events += [ordered]@{
                ts = $e.ts
                agent_id = $e.agent_id
                action = $e.action
                outcome = $e.outcome
                autonomy_level = $e.autonomy_level
                human_gate = $e.human_gate
                details = Sanitize-Details $e.details
            }
        } catch { }
    }
}
$events = @($events | Select-Object -Last 30)

# Coreografia
$choreo = @{}
$choreoScript = Join-Path $RepoRoot 'scripts\agents\choreograph-agents.ps1'
if (Test-Path $choreoScript) {
    $raw = & $choreoScript -Slug $Slug -Trigger manual -Json 2>$null
    if ($raw) {
        $c = $raw | ConvertFrom-Json
        $choreo = [ordered]@{
            matched_rules = @($c.matched_rules)
            readiness = $c.readiness
            operational = @($c.operational | ForEach-Object {
                [ordered]@{
                    id = $_.id
                    type = $_.type
                    max_autonomy = $_.max_autonomy
                    skills = @($_.skills)
                    requires_gate = @($_.requires_gate)
                }
            })
            domain_consults = @($c.domain_consults | ForEach-Object { $_.id })
            skills = @($c.skills)
            gates_required = @($c.gates_required)
        }
    }
}

# Gates / approvals
$gates = @()
$gateIds = @('brief', 'elevation', 'package', 'public_showcase')
$approvalsPath = Join-Path $RepoRoot ".sky\sessions\$Slug\approvals.yaml"
$apRaw = if (Test-Path $approvalsPath) { Get-Content $approvalsPath -Raw } else { '' }
foreach ($g in $gateIds) {
    $approved = $false
    if ($apRaw -match "(?m)^\s+$g`:\s*approved") { $approved = $true }
    $gates += [ordered]@{ id = $g; approved = $approved }
}

# Níveis de autonomia (labels)
$autonomyLevels = @(
    @{ id = 'observe'; rank = 0; label = 'Observar' }
    @{ id = 'consult'; rank = 1; label = 'Consultar' }
    @{ id = 'route'; rank = 2; label = 'Rotear' }
    @{ id = 'activate'; rank = 3; label = 'Ativar' }
    @{ id = 'invoke_skill'; rank = 4; label = 'Invocar skill' }
    @{ id = 'side_effect'; rank = 5; label = 'Efeito externo' }
    @{ id = 'public'; rank = 6; label = 'Público' }
)

# Journey phase
$journeyPhase = $null
$journeyPath = Join-Path $RepoRoot ".sky\sessions\$Slug\journey.yaml"
if (Test-Path $journeyPath) {
    $j = Get-Content $journeyPath -Raw
    if ($j -match 'current_phase:\s*(\S+)') { $journeyPhase = $Matches[1] }
}

$agentsView = [ordered]@{
    slug = $Slug
    published_at = (Get-Date).ToUniversalTime().ToString('o')
    journey_phase = $journeyPhase
    metrics = $metrics
    choreography = $choreo
    gates = $gates
    autonomy_levels = $autonomyLevels
    events = $events
    event_counts = [ordered]@{
        ok = @($events | Where-Object { $_.outcome -eq 'ok' }).Count
        blocked = @($events | Where-Object { $_.outcome -eq 'blocked' }).Count
        other = @($events | Where-Object { $_.outcome -notin @('ok', 'blocked') }).Count
    }
}

$registryDir = Get-SkyRegistryDir
New-Item -ItemType Directory -Path $registryDir -Force | Out-Null
$outPath = Join-Path $registryDir "$Slug.agents.json"
$agentsView | ConvertTo-Json -Depth 12 | Set-Content $outPath -Encoding UTF8

# Atualizar index.json
$indexPath = Join-Path $registryDir 'index.json'
if (Test-Path $indexPath) {
    $index = Get-Content $indexPath -Raw | ConvertFrom-Json
    foreach ($p in $index.projects) {
        if ($p.slug -eq $Slug) {
            $p | Add-Member -NotePropertyName 'agents_file' -NotePropertyValue "$Slug.agents.json" -Force
        }
    }
    @{ version = '1.0'; projects = $index.projects } | ConvertTo-Json -Depth 10 | Set-Content $indexPath -Encoding UTF8
}

Write-Host "Agents view publicado: $outPath" -ForegroundColor Cyan
