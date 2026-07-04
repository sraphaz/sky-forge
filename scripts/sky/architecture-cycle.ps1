#Requires -Version 5.1
<#
.SYNOPSIS
  Ciclo de arquitetura: sync C4/jornadas/craft → export → publish.
.EXAMPLE
  ./scripts/sky/architecture-cycle.ps1 -Slug iautos
  ./scripts/sky/architecture-cycle.ps1 -Slug iautos -SkipPublish
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [switch]$SkipPublish,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'get-sky-config.ps1')

$RepoRoot = Get-SkyRepoRoot
$SessionDir = Join-Path $RepoRoot ".sky\sessions\$Slug"
$OutputDir = Get-SkyOutputDirForSlug $Slug
$ArchSession = Join-Path $SessionDir 'architecture'
$ArchOutput = Join-Path $OutputDir 'architecture'

if (-not (Test-Path $SessionDir)) {
    throw "Sessao nao encontrada: $Slug"
}

function Sync-ArchitectureDir([string]$From, [string]$To, [string]$Label) {
    if (-not (Test-Path $From)) { return 0 }
    New-Item -ItemType Directory -Path $To -Force | Out-Null
    $files = @(Get-ChildItem $From -Recurse -File -ErrorAction SilentlyContinue)
    if ($files.Count -eq 0) { return 0 }
    Copy-Item -Path (Join-Path $From '*') -Destination $To -Recurse -Force
    Write-Host "  Sync $Label : $($files.Count) arquivo(s) -> $To" -ForegroundColor Cyan
    return $files.Count
}

Write-Host "=== Architecture cycle · $Slug ===" -ForegroundColor Green

# 1) outputs → sessão (brownfield: outputs já tem C4)
$fromOutput = Sync-ArchitectureDir $ArchOutput $ArchSession 'outputs→session'

# 2) sessão → outputs (se sessão tiver mais recente)
$fromSession = 0
if (Test-Path $ArchSession) {
    $sessionFiles = @(Get-ChildItem $ArchSession -Recurse -File -ErrorAction SilentlyContinue)
    if ($sessionFiles.Count -gt 0) {
        New-Item -ItemType Directory -Path $ArchOutput -Force | Out-Null
        Copy-Item -Path (Join-Path $ArchSession '*') -Destination $ArchOutput -Recurse -Force
        $fromSession = $sessionFiles.Count
        Write-Host "  Sync session→outputs : $fromSession arquivo(s)" -ForegroundColor Cyan
    }
}

if ($fromOutput -eq 0 -and $fromSession -eq 0) {
    Write-Host "  Nenhum artefato de arquitetura encontrado." -ForegroundColor Yellow
    Write-Host "  Use agentes c4-modeler + journey-sequence-modeler + clean-craft-advisor" -ForegroundColor Yellow
    Write-Host "  ou skills sky-c4-model / sky-journey-sequences / sky-clean-craft no Cursor." -ForegroundColor Yellow
}

# 3) Gate architecture (auto se -Force)
$approveScript = Join-Path $PSScriptRoot 'approve-stage.ps1'
$approvalsPath = Join-Path $SessionDir 'approvals.yaml'
$archApproved = $false
if (Test-Path $approvalsPath) {
    $ap = Get-Content $approvalsPath -Raw
    if ($ap -match '(?m)^\s+architecture:\s*approved') { $archApproved = $true }
}
if (-not $archApproved) {
    if ($Force) {
        & $approveScript -Slug $Slug -Stage architecture
    } else {
        Write-Host "  Gate architecture pendente — rode: sky approve -Slug $Slug -Stage architecture" -ForegroundColor Yellow
    }
}

# 4) Coreografia — registra agentes do batch
$choreo = Join-Path $RepoRoot 'scripts\agents\choreograph-agents.ps1'
if (Test-Path $choreo) {
    Write-Host "`n--- Coreografia architecture-spec ---" -ForegroundColor Cyan
    & $choreo -Slug $Slug -Trigger manual -Intent 'architecture-batch' -ChangedFiles @(
        '.sky/sessions/' + $Slug + '/architecture/'
    ) -ErrorAction SilentlyContinue
}

# 5) Export + publish
Write-Host "`n--- Export ---" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'sky.ps1') export -Slug $Slug -Completeness partial -Force

if (-not $SkipPublish) {
    Write-Host "`n--- Publish ---" -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot 'sky.ps1') publish -Slug $Slug -Public
}

$rec = Join-Path $PSScriptRoot 'record-agent-event.ps1'
if (Test-Path $rec) {
    & $rec -Slug $Slug -AgentId 'solutions-architect' -Action 'architecture.cycle' -Outcome 'ok' `
        -AutonomyLevel 'activate' -Details "sync_out=$fromOutput sync_in=$fromSession" -ErrorAction SilentlyContinue | Out-Null
}

Write-Host "`nCiclo de arquitetura concluido para $Slug" -ForegroundColor Green
