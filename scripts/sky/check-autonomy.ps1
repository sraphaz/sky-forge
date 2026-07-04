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
    'export.package' = @('package')
    'publish.preview' = @()
    'publish.public' = @('public_showcase', 'package')
    'skill.invoke' = @('brief')
}
$allGates = [System.Collections.Generic.List[string]]::new()
foreach ($g in $gates) { if ($allGates -notcontains $g) { $allGates.Add($g) } }
if ($actionGates.ContainsKey($Action)) {
    foreach ($g in $actionGates[$Action]) {
        if ($allGates -notcontains $g) { $allGates.Add($g) }
    }
}
$gates = @($allGates)

# Verificar approvals.yaml (stages:)
$approvalsPath = Join-Path $RepoRoot ".sky\sessions\$Slug\approvals.yaml"
$gateStatus = @{}
if (Test-Path $approvalsPath) {
    $ap = Get-Content $approvalsPath -Raw
    foreach ($g in $gates) {
        if ($ap -match "(?m)^\s+$g`:\s*approved") { $gateStatus[$g] = $true }
        elseif ($ap -match "(?m)^\s+$g`:") { $gateStatus[$g] = $false }
        else { $gateStatus[$g] = $false }
    }
}

$needsGate = $false
$blockingGates = @()

if ($actionGates.ContainsKey($Action)) {
    foreach ($g in $actionGates[$Action]) {
        if (-not $gateStatus.ContainsKey($g) -or -not $gateStatus[$g]) {
            $needsGate = $true
            if ($blockingGates -notcontains $g) { $blockingGates += $g }
        }
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
