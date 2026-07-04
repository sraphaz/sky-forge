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
    [ValidateSet('intake', 'status', 'approve', 'run', 'validate', 'export', 'elevate')]
    [string]$Command,

    [Parameter()]
    [string]$Slug,

    [Parameter()]
    [ValidateSet('brief', 'research', 'architecture', 'elevation', 'package')]
    [string]$Stage,

    [Parameter()]
    [ValidateSet('partial', 'full')]
    [string]$Completeness = 'full',

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')

function Get-SessionDir([string]$s) {
    Join-Path $RepoRoot ".sky\sessions\$s"
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
        $validateArgs = @{ Slug = $Slug; Completeness = $Completeness }
        if ($Force -or $Completeness -eq 'partial') { $validateArgs.Force = $true }
        & (Join-Path $PSScriptRoot 'validate-package.ps1') @validateArgs
        & (Join-Path $PSScriptRoot 'export-package.ps1') -Slug $Slug
        $dcScript = Join-Path $RepoRoot 'extensions\sky-cloud-design\scripts\export-dc.ps1'
        if (Test-Path $dcScript) { & $dcScript -Slug $Slug }
    }
}
