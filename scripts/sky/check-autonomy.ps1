#Requires -Version 5.1
<#
.SYNOPSIS
  Verifica se ação é permitida pela autonomia do agente e gates humanos.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [Parameter(Mandatory = $true)]
    [string]$AgentId,

    [Parameter(Mandatory = $true)]
    [string]$Action,

    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')

. (Join-Path $RepoRoot 'scripts\agents\choreography-parser.ps1')

$ranks = Get-AutonomyRanks -RepoRoot $RepoRoot
$choreo = Join-Path $RepoRoot 'scripts\agents\choreograph-agents.ps1'
$resolution = & $choreo -Slug $Slug -AgentId $AgentId -Action $Action -CheckAutonomy -Json | ConvertFrom-Json

$allowed = $resolution.autonomy_check.allowed
$gates = @($resolution.gates_required)

$actionGates = @{
    'export.package' = @('package', 'architecture')
    'publish.preview' = @()
    'publish.public' = @('public_showcase', 'package')
    # brief global; architecture vem de requires_gate da coreografia (architecture-spec)
    'skill.invoke' = @('brief')
    'side_effect' = @('architecture', 'package')
}
$allGates = [System.Collections.Generic.List[string]]::new()
foreach ($g in $gates) { if ($allGates -notcontains $g) { $allGates.Add($g) } }
if ($actionGates.ContainsKey($Action)) {
    foreach ($g in $actionGates[$Action]) {
        if ($allGates -notcontains $g) { $allGates.Add($g) }
    }
}
$gates = @($allGates)

# Verificar approvals.yaml (stages:) — timestamp de approve-stage conta como aprovado
$approvalsPath = Join-Path $RepoRoot ".sky\sessions\$Slug\approvals.yaml"
$gateStatus = @{}
if (Test-Path $approvalsPath) {
    $ap = Get-Content $approvalsPath -Raw
    $stagesBlock = $ap
    if ($ap -match '(?ms)^stages:\s*\r?\n(.*?)(?=^[a-zA-Z_][a-zA-Z0-9_]*:\s*$|\z)') {
        $stagesBlock = $Matches[1]
    }
    foreach ($g in $gates) {
        if ($stagesBlock -match "(?m)^\s+$([regex]::Escape($g)):\s*(.+)$") {
            $gateValue = $Matches[1].Trim().Trim('"').Trim("'")
            if ($gateValue -match '^approved(?:\s|$)' -or $gateValue -match '^\d{4}-\d{2}-\d{2}T') {
                $gateStatus[$g] = $true
            } else {
                $gateStatus[$g] = $false
            }
        } else {
            $gateStatus[$g] = $false
        }
    }
}

$needsGate = $false
$blockingGates = @()

# Bloquear por TODOS os gates (actionGates + requires_gate da coreografia, ex.: architecture)
foreach ($g in $gates) {
    if ([string]::IsNullOrWhiteSpace("$g")) { continue }
    $approved = $gateStatus.ContainsKey($g) -and $gateStatus[$g]
    if (-not $approved) {
        $needsGate = $true
        if ($blockingGates -notcontains $g) { $blockingGates += $g }
    }
}

$finalAllowed = $allowed -and ($blockingGates.Count -eq 0)

$result = [ordered]@{
    slug = $Slug
    agent_id = $AgentId
    action = $Action
    autonomy_allowed = $allowed
    gates_required = $gates
    gates_blocking = $blockingGates
    allowed = $finalAllowed
}

$recordScript = Join-Path $RepoRoot 'scripts\sky\record-agent-event.ps1'
if (-not $finalAllowed) {
    & $recordScript -Slug $Slug -AgentId $AgentId -Action $Action -Outcome 'blocked' -AutonomyLevel $resolution.autonomy_check.max_autonomy -Details ($result | ConvertTo-Json -Compress) -Blocked
}

if ($Json) { $result | ConvertTo-Json -Depth 5 }
else {
    if ($finalAllowed) { Write-Host "ALLOWED: $AgentId → $Action" -ForegroundColor Green }
    else {
        Write-Host "BLOCKED: $AgentId → $Action" -ForegroundColor Red
        if (-not $allowed) { Write-Host "  Autonomia insuficiente (max: $($resolution.autonomy_check.max_autonomy))" }
        if ($blockingGates.Count -gt 0) { Write-Host "  Gates pendentes: $($blockingGates -join ', ')" }
    }
}
if (-not $finalAllowed) { exit 1 }
