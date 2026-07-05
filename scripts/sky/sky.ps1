#Requires -Version 5.1
<#
.SYNOPSIS
  CLI principal do Sky-Forge.
.EXAMPLE
  ./scripts/sky/sky.ps1 intake -Slug minha-ideia
  ./scripts/sky/sky.ps1 elevate -Slug minha-ideia
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet('intake', 'status', 'approve', 'run', 'validate', 'export', 'elevate', 'benchmark', 'publish', 'sync', 'showcase', 'agents', 'audit', 'choreograph', 'architect', 'link', 'link-sync', 'pull-spec', 'integrate-dc')]
    [string]$Command,

    [Parameter()]
    [string]$Screen,

    [Parameter()]
    [string]$SourcePath,

    [Parameter()]
    [ValidateSet('screens', 'institutional', 'platform', 'mobile', 'sky-forge')]
    [string]$Folder = 'screens',

    [Parameter()]
    [string]$WorkspacePath,

    [Parameter()]
    [ValidateSet('manual', 'after_export')]
    [string]$SyncMode = 'manual',

    [Parameter()]
    [switch]$PullSpec,

    [Parameter()]
    [string]$Slug,

    [Parameter()]
    [ValidateSet('brief', 'research', 'architecture', 'elevation', 'package', 'public_showcase')]
    [string]$Stage,

    [Parameter()]
    [ValidateSet('partial', 'full')]
    [string]$Completeness = 'full',

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$Public,

    [Parameter()]
    [switch]$ForAI,

    [Parameter()]
    [ValidateSet('essential', 'spec', 'full')]
    [string]$Scope = 'essential',

    [Parameter()]
    [string]$Intent,

    [Parameter()]
    [string[]]$ChangedFiles,

    [Parameter()]
    [int]$Last = 20
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')

function Get-SessionDir([string]$s) {
    Join-Path $RepoRoot ".sky\sessions\$s"
}

function Invoke-AgentAudit {
    param([string]$s, [string]$agent, [string]$action, [string]$level, [string]$outcome, [string]$details = '')
    $rec = Join-Path $PSScriptRoot 'record-agent-event.ps1'
    if (Test-Path $rec) {
        & $rec -Slug $s -AgentId $agent -Action $action -Outcome $outcome -AutonomyLevel $level -Details $details -ErrorAction SilentlyContinue | Out-Null
    }
}

switch ($Command) {
    'intake' {
        if (-not $Slug) { throw 'intake requires -Slug' }
        & (Join-Path $PSScriptRoot 'new-session.ps1') -Slug $Slug
        Write-Host ""
        Write-Host "Sessao criada: .sky/sessions/$Slug" -ForegroundColor Green
        Write-Host "Converse com intake-conductor (regra sky-intake.mdc)."
        Write-Host "Leia docs/_meta/INTAKE_PROTOCOL.md e SKY_MERIT_INDICES.md"
    }
    'status' {
        if (-not $Slug) { throw 'status requires -Slug' }
        $maturityPath = Join-Path (Get-SessionDir $Slug) 'maturity.yaml'
        if (-not (Test-Path $maturityPath)) { throw "Sessao nao encontrada: $Slug" }
        Get-Content $maturityPath -Raw | Write-Host
        $meritsPath = Join-Path (Get-SessionDir $Slug) 'sky-merits.yaml'
        if (Test-Path $meritsPath) {
            Write-Host "`n--- sky-merits.yaml ---" -ForegroundColor Cyan
            Get-Content $meritsPath -Raw | Write-Host
        }
    }
    'approve' {
        if (-not $Slug -or -not $Stage) { throw 'approve requires -Slug and -Stage' }
        & (Join-Path $PSScriptRoot 'approve-stage.ps1') -Slug $Slug -Stage $Stage
    }
    'elevate' {
        if (-not $Slug) { throw 'elevate requires -Slug' }
        Write-Host "sky elevate — invoque skill sky-elevate no Cursor (agentes sky-elevator + ux-design-specialist)."
        & (Join-Path $PSScriptRoot 'validate-maturity.ps1') -Slug $Slug
        $merits = Join-Path (Get-SessionDir $Slug) 'sky-merits.yaml'
        if (-not (Test-Path $merits)) {
            Write-Host "Criando sky-merits.yaml inicial..."
            Copy-Item (Join-Path $RepoRoot 'templates\sessions\example-horta\sky-merits.yaml') $merits -Force
            (Get-Content $merits -Raw) -replace 'example-horta', $Slug | Set-Content $merits -Encoding UTF8
        }
    }
    'benchmark' {
        if (-not $Slug) { throw 'benchmark requires -Slug' }
        if (-not (Test-Path (Get-SessionDir $Slug))) { throw "Sessao nao encontrada: $Slug" }
        Write-Host "sky benchmark — agente market-benchmark (conversacional, no Cursor)." -ForegroundColor Cyan
        Write-Host ""
        Write-Host "O que ele faz:"
        Write-Host "  1. Pesquisa mercado + iniciativas open-source (GitHub) que atacam o mesmo problema"
        Write-Host "  2. Veredito de novidade por eixo: novo / melhor / paridade / atras"
        Write-Host "  3. Calcula o indice MPI (rubrica em docs/_meta/SKY_INDICES_METHOD.md, espec v1.2)"
        Write-Host "  4. Sugere lacunas do segmento como RFs ai_suggested — voce decide, nada muda sozinho"
        Write-Host ""
        $bench = Join-Path (Get-SessionDir $Slug) 'market-benchmark.yaml'
        if (Test-Path $bench) {
            Write-Host "Artefato existente: .sky/sessions/$Slug/market-benchmark.yaml" -ForegroundColor Green
            if ((Get-Content $bench -Raw) -match '(?ms)^mpi:\s*\r?\n\s+score:\s*(\d+)') {
                Write-Host "MPI atual: $($Matches[1])"
            }
        } else {
            Write-Host "Artefato ainda nao gerado — converse com o agente (regra sky-benchmark.mdc)." -ForegroundColor Yellow
        }
        Invoke-AgentAudit $Slug 'market-benchmark' 'benchmark.review' 'consult' $(if (Test-Path $bench) { 'ok' } else { 'pending' })
    }
    'run' {
        if (-not $Slug) { throw 'run requires -Slug' }
        Write-Host "sky run (batch) — PR 2."
        & (Join-Path $PSScriptRoot 'validate-maturity.ps1') -Slug $Slug
    }
    'validate' {
        if (-not $Slug) { throw 'validate requires -Slug' }
        $vargs = @{ Slug = $Slug; Completeness = $Completeness }
        if ($Force) { $vargs.Force = $true }
        & (Join-Path $PSScriptRoot 'validate-package.ps1') @vargs
    }
    'export' {
        if (-not $Slug) { throw 'export requires -Slug' }
        if ($ForAI) {
            # Contexto sanitizado para IA — nao passa pelo gate de pacote completo
            & (Join-Path $PSScriptRoot 'export-for-ai.ps1') -Slug $Slug -Scope $Scope
            Invoke-AgentAudit $Slug 'delivery-steward' 'export.ai_context' 'invoke_skill' 'ok' "scope=$Scope"
            break
        }
        $check = Join-Path $PSScriptRoot 'check-autonomy.ps1'
        if (Test-Path $check) {
            & $check -Slug $Slug -AgentId 'delivery-steward' -Action 'export.package' -ErrorAction SilentlyContinue
            if ($LASTEXITCODE -eq 1 -and -not $Force) {
                Write-Host "Export bloqueado — aprove gate package ou use -Force com consciencia." -ForegroundColor Yellow
                Invoke-AgentAudit $Slug 'delivery-steward' 'export.package' 'side_effect' 'blocked' 'gate package'
                throw 'autonomy gate package'
            }
        }
        $validateArgs = @{ Slug = $Slug; Completeness = $Completeness }
        if ($Force -or $Completeness -eq 'partial') { $validateArgs.Force = $true }
        & (Join-Path $PSScriptRoot 'validate-package.ps1') @validateArgs
        & (Join-Path $PSScriptRoot 'export-package.ps1') -Slug $Slug
        $dcScript = Join-Path $RepoRoot 'extensions\sky-cloud-design\scripts\export-dc.ps1'
        if (Test-Path $dcScript) { & $dcScript -Slug $Slug }
        Invoke-AgentAudit $Slug 'delivery-steward' 'export.package' 'side_effect' 'ok'
        & (Join-Path $RepoRoot 'scripts\agents\choreograph-agents.ps1') -Slug $Slug -Trigger post_export -ErrorAction SilentlyContinue | Out-Null
    }
    'publish' {
        if (-not $Slug) { throw 'publish requires -Slug' }
        $action = if ($Public) { 'publish.public' } else { 'publish.preview' }
        $check = Join-Path $PSScriptRoot 'check-autonomy.ps1'
        if (Test-Path $check) {
            & $check -Slug $Slug -AgentId 'showcase-curator' -Action $action -ErrorAction SilentlyContinue
            if ($LASTEXITCODE -eq 1 -and $Public) {
                Invoke-AgentAudit $Slug 'showcase-curator' $action 'public' 'blocked'
                throw 'autonomy gate public_showcase'
            }
        }
        $pubArgs = @{ Slug = $Slug }
        if ($Public) { $pubArgs.Public = $true }
        & (Join-Path $PSScriptRoot 'publish-preview.ps1') @pubArgs
        Invoke-AgentAudit $Slug 'showcase-curator' $action $(if ($Public) { 'public' } else { 'invoke_skill' }) 'ok'
    }
    'sync' {
        if (-not $Slug) { throw 'sync requires -Slug' }
        $syncArgs = @{ Slug = $Slug }
        if ($Public) { $syncArgs.Public = $true }
        if ($Force) { $syncArgs.SkipExport = $false }
        & (Join-Path $PSScriptRoot 'sync-showcase.ps1') @syncArgs
        Invoke-AgentAudit $Slug 'showcase-curator' 'showcase.sync' 'side_effect' 'ok'
    }
    'showcase' {
        . (Join-Path $PSScriptRoot 'get-sky-config.ps1')
        $cfg = Read-SkyConfigFile
        $showcaseDir = Join-Path $RepoRoot 'apps\showcase'
        if (-not (Test-Path (Join-Path $showcaseDir 'package.json'))) {
            throw "Showcase nao encontrado em apps/showcase"
        }
        $port = $cfg.showcasePort
        Write-Host "Liberando porta $port (servidor antigo do showcase)..." -ForegroundColor Yellow
        try {
            Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction Stop |
                Select-Object -ExpandProperty OwningProcess -Unique |
                ForEach-Object {
                    if ($_ -gt 0) {
                        Write-Host "  Encerrando PID $_" -ForegroundColor DarkYellow
                        Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue
                    }
                }
            Start-Sleep -Milliseconds 400
        } catch {
            Write-Host "  Porta $port livre ou netstat indisponivel." -ForegroundColor DarkGray
        }
        Write-Host "Iniciando showcase em http://localhost:$port/sky-forge" -ForegroundColor Cyan
        Write-Host "Modo interativo local: em /projects/{slug}/lacunas/ voce pode aceitar/recusar" -ForegroundColor Cyan
        Write-Host "sugestoes e responder lacunas direto no site (grava em .sky/sessions/ + auditoria)." -ForegroundColor Cyan
        Push-Location $showcaseDir
        try {
            if (-not (Test-Path 'node_modules')) {
                Write-Host "pnpm install..." -ForegroundColor Yellow
                pnpm install
            }
            pnpm dev --port $port
        } finally {
            Pop-Location
        }
        if ($Slug) { Invoke-AgentAudit $Slug 'showcase-curator' 'showcase.open' 'invoke_skill' 'ok' }
    }
    'agents' {
        $choreo = Join-Path $RepoRoot 'scripts\agents\choreograph-agents.ps1'
        $cargs = @{ Trigger = 'manual' }
        if ($Slug) { $cargs.Slug = $Slug }
        if ($Intent) { $cargs.Intent = $Intent }
        if ($ChangedFiles) { $cargs.ChangedFiles = $ChangedFiles }
        & $choreo @cargs
    }
    'audit' {
        $aargs = @{ Last = $Last }
        if ($Slug) { $aargs.Slug = $Slug }
        & (Join-Path $PSScriptRoot 'agent-audit.ps1') @aargs
    }
    'choreograph' {
        $choreo = Join-Path $RepoRoot 'scripts\agents\choreograph-agents.ps1'
        $cargs = @{ Json = $true; Trigger = 'manual' }
        if ($Slug) { $cargs.Slug = $Slug }
        if ($Intent) { $cargs.Intent = $Intent }
        if ($ChangedFiles) { $cargs.ChangedFiles = $ChangedFiles }
        & $choreo @cargs
    }
    'architect' {
        if (-not $Slug) { throw 'architect requires -Slug' }
        $acArgs = @{ Slug = $Slug }
        if ($Force) { $acArgs.Force = $true }
        & (Join-Path $PSScriptRoot 'architecture-cycle.ps1') @acArgs
    }
    'link' {
        if (-not $Slug) { throw 'link requires -Slug' }
        $linkArgs = @{
            Slug = $Slug
            SyncMode = $SyncMode
        }
        if ($WorkspacePath) { $linkArgs.WorkspacePath = $WorkspacePath }
        if ($PullSpec) { $linkArgs.PullSpec = $true }
        if ($Force) { $linkArgs.Force = $true }
        & (Join-Path $PSScriptRoot 'link-workspace.ps1') @linkArgs
        Invoke-AgentAudit $Slug 'repo-scaffolder' 'workspace.link' 'side_effect' 'ok'
    }
    'link-sync' {
        if (-not $Slug) { throw 'link-sync requires -Slug' }
        . (Join-Path $PSScriptRoot 'resolve-sky-link.ps1')
        Set-SkyLinkSyncMode -Slug $Slug -SyncMode $SyncMode
        Invoke-AgentAudit $Slug 'repo-scaffolder' 'workspace.link_sync_mode' 'invoke_skill' 'ok' "mode=$SyncMode"
    }
    'pull-spec' {
        $pullArgs = @{}
        if ($Slug) { $pullArgs.Slug = $Slug }
        if ($WorkspacePath) { $pullArgs.WorkspacePath = $WorkspacePath }
        if ($Force) { $pullArgs.Force = $true }
        & (Join-Path $PSScriptRoot 'pull-spec.ps1') @pullArgs
        if ($Slug) {
            Invoke-AgentAudit $Slug 'repo-scaffolder' 'workspace.pull_spec' 'invoke_skill' 'ok'
        }
    }
    'integrate-dc' {
        if (-not $Slug -or -not $Screen -or -not $SourcePath) {
            throw 'integrate-dc requires -Slug, -Screen and -SourcePath'
        }
        $iArgs = @{ Slug = $Slug; Screen = $Screen; SourcePath = $SourcePath }
        if ($Folder) { $iArgs.Folder = $Folder }
        if ($Public) { $iArgs.Sync = $true }
        & (Join-Path $PSScriptRoot 'integrate-dc.ps1') @iArgs
        Invoke-AgentAudit $Slug 'showcase-curator' 'design.integrate_dc' 'side_effect' 'ok' "$Folder/$Screen"
    }
}
