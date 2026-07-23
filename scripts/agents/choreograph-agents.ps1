#Requires -Version 5.1
<#
.SYNOPSIS
  Resolve coreografia Sky-Forge: agentes, autonomia, skills e gates.
.EXAMPLE
  ./choreograph-agents.ps1 -ChangedFiles .sky/sessions/iautos/maturity.yaml -Slug iautos -Json
  ./choreograph-agents.ps1 -Intent deliver -Slug iautos
#>
param(
    [string[]]$ChangedFiles = @(),
    [string]$Slug = '',
    [string]$Intent = '',
    [ValidateSet('manual', 'path_change', 'maturity_gate', 'post_export', 'hook_stop')]
    [string]$Trigger = 'manual',
    [string]$Action = '',
    [string]$AgentId = '',
    [switch]$CheckAutonomy,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$ChoreoPath = Join-Path $RepoRoot '.agents\choreography.yaml'

. (Join-Path $PSScriptRoot 'choreography-parser.ps1')
. (Join-Path $RepoRoot 'scripts\sky\get-sky-config.ps1')

function Normalize-FileList {
    param([string[]]$Files)
    @($Files | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique)
}

$files = Normalize-FileList -Files $ChangedFiles
if ($Slug -and $files.Count -eq 0) {
    $files = @(".sky/sessions/$Slug")
}

$readiness = $null
if ($Slug) {
    $maturityPath = Join-Path $RepoRoot ".sky\sessions\$Slug\maturity.yaml"
    if (Test-Path $maturityPath) {
        $m = Get-Content $maturityPath -Raw
        if ($m -match 'overall_readiness:\s*([0-9.]+)') { $readiness = [double]$Matches[1] }
    }
}

$intentPaths = @{
    intake = '.sky/sessions/**'
    deliver = 'outputs/**'
    showcase = 'showcase/**'
    experience = 'sky.config.yaml'
}
if ($Intent -and $intentPaths.ContainsKey($Intent)) {
    $files += $intentPaths[$Intent]
    $files = Normalize-FileList -Files $files
}

$rules = @()
$coActivation = @()
$partyMode = @{ policy = ''; sessions = @() }
$choreoRaw = ''
if (Test-Path $ChoreoPath) {
    $choreoRaw = Get-Content $ChoreoPath -Raw
    $rules = Parse-ChoreographyRules -Raw $choreoRaw
    $coActivation = Parse-CoActivation -Raw $choreoRaw
    $partyMode = Parse-PartyMode -Raw $choreoRaw
}

$ranks = Get-AutonomyRanks -RepoRoot $RepoRoot
$matchedRules = @()
$operational = @()
$domainConsults = @()
$skillRuns = @()
$gatesRequired = @()

foreach ($rule in $rules) {
    if ($rule.when.Count -gt 0 -and $rule.when -notcontains $Trigger) { continue }
    if ($rule.maturity_min -and $readiness -ne $null -and $readiness -lt $rule.maturity_min) { continue }

    $ruleHit = $false
    if ($files.Count -eq 0 -and $Trigger -eq 'manual') { $ruleHit = $true }
    foreach ($f in $files) {
        foreach ($p in $rule.paths) {
            if (Test-PathMatchesGlob -FilePath $f -Pattern $p) { $ruleHit = $true; break }
        }
        if ($ruleHit) { break }
    }
    if (-not $ruleHit) { continue }

    $matchedRules += $rule.id
    foreach ($agent in $rule.agents) {
        $entry = [ordered]@{
            id = $agent.id
            type = $agent.type
            rule = $rule.id
            max_autonomy = $agent.max_autonomy
            autonomy = $agent.autonomy
            skills = $agent.skills
            requires_gate = $agent.requires_gate
        }
        if ($agent.type -eq 'domain') {
            if ($domainConsults.id -notcontains $agent.id) { $domainConsults += $entry }
        } else {
            if ($operational.id -notcontains $agent.id) { $operational += $entry }
        }
        foreach ($sk in $agent.skills) {
            if ($skillRuns -notcontains $sk) { $skillRuns += $sk }
        }
        foreach ($g in $agent.requires_gate) {
            if ($gatesRequired -notcontains $g) { $gatesRequired += $g }
        }
    }
}

$autonomyCheck = $null
if ($CheckAutonomy -and $AgentId -and $Action) {
    $agentEntry = $operational | Where-Object { $_.id -eq $AgentId } | Select-Object -First 1
    $maxAutonomy = 'observe'
    foreach ($rule in $rules) {
        foreach ($agent in $rule.agents) {
            if ($agent.id -eq $AgentId -and $agent.max_autonomy) {
                if (-not $ranks.ContainsKey($maxAutonomy) -or ($ranks.ContainsKey($agent.max_autonomy) -and $ranks[$agent.max_autonomy] -gt $ranks[$maxAutonomy])) {
                    $maxAutonomy = $agent.max_autonomy
                    $agentEntry = $agent
                }
            }
        }
    }
    $max = $maxAutonomy
    $allowed = Test-AutonomyAllowed -Action $Action -MaxAutonomy $max -Ranks $ranks
    $autonomyCheck = [ordered]@{ agent = $AgentId; action = $Action; max_autonomy = $max; allowed = $allowed }
    if ($agentEntry -and $agentEntry.requires_gate) {
        foreach ($g in $agentEntry.requires_gate) {
            if ($gatesRequired -notcontains $g) { $gatesRequired += $g }
        }
    }
    foreach ($rule in $rules) {
        foreach ($agent in $rule.agents) {
            if ($agent.id -eq $AgentId -and $agent.requires_gate) {
                foreach ($g in $agent.requires_gate) {
                    if ($gatesRequired -notcontains $g) { $gatesRequired += $g }
                }
            }
        }
    }
}

$journeyPhase = $null
if ($Slug) {
    $journeyPath = Join-Path $RepoRoot ".sky\sessions\$Slug\journey.yaml"
    if (Test-Path $journeyPath) {
        $j = Get-Content $journeyPath -Raw
        if ($j -match 'current_phase:\s*(\S+)') { $journeyPhase = $Matches[1] }
    }
}

$activeParty = Resolve-ActiveParty -PartyMode $partyMode -CoActivation $coActivation -JourneyPhase $journeyPhase

$result = [ordered]@{
    version = 3
    trigger = $Trigger
    slug = $Slug
    readiness = $readiness
    intent = $Intent
    changed_files = $files
    matched_rules = $matchedRules
    operational = $operational
    domain_consults = $domainConsults
    skills = $skillRuns
    gates_required = $gatesRequired
    autonomy_check = $autonomyCheck
    co_activation = $coActivation
    party_mode = [ordered]@{
        policy = $partyMode.policy
        sessions = $partyMode.sessions
        active = $activeParty
    }
}

$recordScript = Join-Path $RepoRoot 'scripts\sky\record-agent-event.ps1'
if ($Slug -and (Test-Path $recordScript)) {
    $details = @{ matched_rules = $matchedRules; files = $files } | ConvertTo-Json -Compress
    & $recordScript -Slug $Slug -AgentId 'orchestrator' -Action 'choreography.resolve' -Outcome 'ok' -Details $details -AutonomyLevel 'route' -ErrorAction SilentlyContinue | Out-Null
}

if ($Json) {
    $result | ConvertTo-Json -Depth 8
} else {
    Write-Host "=== Sky-Forge Choreography ===" -ForegroundColor Cyan
    Write-Host "Trigger: $Trigger | Slug: $(if ($Slug) { $Slug } else { '-' }) | Readiness: $(if ($readiness -ne $null) { $readiness } else { '-' })"
    Write-Host "Rules: $($matchedRules -join ', ')"
    Write-Host "Operational: $(($operational | ForEach-Object { $_.id }) -join ', ')"
    Write-Host "Domain consults: $(($domainConsults | ForEach-Object { $_.id }) -join ', ')"
    Write-Host "Skills: $($skillRuns -join ', ')"
    Write-Host "Gates: $($gatesRequired -join ', ')"
    if ($activeParty) {
        Write-Host "Party Mode: $($activeParty.id) ($($activeParty.label)) — host: $($activeParty.host), primary: $($activeParty.primary)" -ForegroundColor Magenta
    }
    if ($autonomyCheck) {
        $color = if ($autonomyCheck.allowed) { 'Green' } else { 'Red' }
        Write-Host "Autonomy $($autonomyCheck.action): $($autonomyCheck.allowed)" -ForegroundColor $color
    }
}
