#Requires -Version 5.1
<#
.SYNOPSIS
  Gera evolution-roadmap.yaml draft a partir de platform-assessment e gaps conhecidos.
.EXAMPLE
  ./scripts/sky/sky.ps1 seed-roadmap -Slug surya-labs-workspace
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [Parameter()]
    [string]$Vision,

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'get-sky-config.ps1')
. (Join-Path $PSScriptRoot 'resolve-sky-link.ps1')

$forgeRoot = Get-SkyRepoRoot
$sessionDir = Join-Path $forgeRoot ".sky\sessions\$Slug"
if (-not (Test-Path $sessionDir)) { throw "Sessao nao encontrada: $Slug" }

$roadmapPath = Join-Path $sessionDir 'evolution-roadmap.yaml'
if ((Test-Path $roadmapPath) -and -not $Force) {
    throw "evolution-roadmap.yaml ja existe — use -Force para sobrescrever."
}

$assessmentPath = Join-Path $sessionDir 'platform-assessment.yaml'
$baselineRef = 'manual'
$gaps = @()
if (Test-Path $assessmentPath) {
    $aRaw = Get-Content $assessmentPath -Raw
    if ($aRaw -match '(?m)^assessed_at:\s*(.+)$') { $baselineRef = $Matches[1].Trim() }
    $inGaps = $false
    foreach ($line in (Get-Content $assessmentPath)) {
        if ($line -match '^gaps_detected:') { $inGaps = $true; continue }
        if ($inGaps -and $line -match '^\s+-\s+(.+)$') { $gaps += $Matches[1].Trim() }
        if ($inGaps -and $line -match '^\w') { break }
    }
}

$ctx = Get-SkyLinkContext -Slug $Slug
$workspaceStatus = $null
if ($ctx -and $ctx.WorkspacePath) {
    $statusFile = Join-Path $ctx.WorkspacePath 'docs\WORKSPACE_STATUS.md'
    if (Test-Path $statusFile) {
        $workspaceStatus = Get-Content $statusFile -Raw
    }
}

$phases = @()
$now = (Get-Date).ToUniversalTime().ToString('o')

if ($workspaceStatus -match 'RF06.*?Partial|RF07.*?Ausente') {
    $phases += @{
        id = 'phase-proposal-ledger'
        title = 'Proposta executável + approval ledger'
        priority = 'P0'
        status = 'planned'
        depends_on = @('phase-stabilize')
        deliverables = @('CLI proposta', 'approval-ledger.yaml operacional')
        done_when = 'RF06 gerador executável e RF07 API/CLI de escrita com validate:data OK'
        rf_refs = @('RF06', 'RF07')
        gate = $null
    }
}
if ($workspaceStatus -match 'RF08.*?Ausente|RF15.*?Ausente') {
    $phases += @{
        id = 'phase-repo-export'
        title = 'Vínculo repo + export demanda'
        priority = 'P1'
        status = 'planned'
        depends_on = @('phase-proposal-ledger')
        deliverables = @('repository-link', 'export demanda RF15')
        done_when = 'RF08 fluxo operacional e RF15 export reproduz pacote íntegro'
        rf_refs = @('RF08', 'RF15')
        gate = $null
    }
}
if ($workspaceStatus -match 'Deploy produção.*?❌|deploy_prod: false') {
    $phases += @{
        id = 'phase-deploy'
        title = 'Deploy produção'
        priority = 'P1'
        status = 'planned'
        depends_on = @('phase-proposal-ledger')
        deliverables = @('Vercel + secrets', 'smoke prod')
        done_when = 'Esteira site→workspace passa em prod com secrets configurados'
        rf_refs = @()
        gate = $null
    }
}

$phases = @(
    @{
        id = 'phase-stabilize'
        title = 'Confirmar baseline'
        priority = 'P0'
        status = if ($gaps.Count -gt 0) { 'in_progress' } else { 'planned' }
        depends_on = @()
        deliverables = @('platform-assessment.yaml confirmado')
        done_when = 'Gaps do assessment endereçados ou aceitos; gate baseline_confirmed'
        rf_refs = @()
        gate = 'baseline_confirmed'
    }
) + $phases

if ($phases.Count -eq 1) {
    $phases += @{
        id = 'phase-evolve'
        title = 'Evolução incremental'
        priority = 'P1'
        status = 'planned'
        depends_on = @('phase-stabilize')
        deliverables = @()
        done_when = 'Primeira entrega com acceptance-criteria verificável'
        rf_refs = @()
        gate = 'evolution_approved'
    }
}

if (-not $Vision) {
    $Vision = if ($workspaceStatus -match 'Leitura honesta:\*\* (.+)') {
        "Evoluir plataforma: $($Matches[1].Trim())"
    } else {
        'Evoluir plataforma existente com spec governável e gates humanos.'
    }
}

function Format-YamlList([string[]]$Items, [int]$Indent = 4) {
    $pad = ' ' * $Indent
    if (-not $Items -or $Items.Count -eq 0) { return "${pad}[]" }
    return ($Items | ForEach-Object { "${pad}- $_" }) -join "`n"
}

$phaseYaml = ($phases | ForEach-Object {
    @"
  - id: $($_.id)
    title: "$($_.title)"
    priority: $($_.priority)
    status: $($_.status)
    depends_on:
$(Format-YamlList $_.depends_on)
    deliverables:
$(Format-YamlList $_.deliverables)
    done_when: "$($_.done_when)"
    rf_refs:
$(Format-YamlList $_.rf_refs)
    gate: $(if ($_.gate) { $_.gate } else { 'null' })
"@
}) -join "`n"

$constraintsYaml = if ($gaps.Count -gt 0) {
    ($gaps | ForEach-Object { "  - $_" }) -join "`n"
} else {
    '  - "sem constraints declarados ainda"'
}

$content = @"
version: "0.1"
slug: $Slug
profile: platform-evolution
updated_at: $now
baseline_ref: $baselineRef
ai_suggested: true

vision: "$($Vision -replace '"', '\"')"
constraints:
$constraintsYaml

phases:
$phaseYaml

acceptance_summary: "Draft gerado por seed-roadmap — revisar com platform_owner antes de export."
"@

Set-Content -Path $roadmapPath -Value $content -Encoding UTF8

if ($ctx -and $ctx.WorkspacePath) {
    $hostCopy = Join-Path $ctx.WorkspacePath 'integrations\sky-forge\evolution-roadmap.yaml'
    if (Test-Path (Split-Path $hostCopy -Parent)) {
        Copy-Item $roadmapPath $hostCopy -Force
    }
}

Write-Host "Roadmap: $roadmapPath ($($phases.Count) fases)" -ForegroundColor Green
Write-Host "  vision: $Vision"
