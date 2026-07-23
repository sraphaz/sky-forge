#Requires -Version 5.1
<#
.SYNOPSIS
  Wrapper Sky-Forge Host — delega ao core a partir do repo da plataforma brownfield.
.EXAMPLE
  ./scripts/sky.ps1 assess
  ./scripts/sky.ps1 status
  ./scripts/sky.ps1 architect
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet('status', 'validate', 'export', 'pull-spec', 'sync-spec', 'audit', 'agents', 'assess', 'elevate', 'architect', 'benchmark', 'seed-roadmap')]
    [string]$Command,

    [Parameter()]
    [ValidateSet('partial', 'full')]
    [string]$Completeness = 'full',

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$ForAI,

    [Parameter()]
    [ValidateSet('essential', 'spec', 'full')]
    [string]$Scope = 'essential',

    [Parameter()]
    [int]$Last = 20
)

$ErrorActionPreference = 'Stop'

function Find-AppLinkFile {
    $start = if ($PSScriptRoot) { Split-Path $PSScriptRoot -Parent } else { (Get-Location).Path }
    $current = (Resolve-Path $start).Path
    while ($true) {
        $candidate = Join-Path $current '.sky\link.yaml'
        if (Test-Path $candidate) { return $candidate }
        $parent = Split-Path $current -Parent
        if (-not $parent -or $parent -eq $current) { return $null }
        $current = $parent
    }
}

function Read-LinkField([string]$Path, [string]$Field) {
    $raw = Get-Content $Path -Raw
    if ($raw -match "(?m)^${Field}:\s*(.+)$") {
        return $Matches[1].Trim().Trim('"').Trim("'")
    }
    return $null
}

$linkFile = Find-AppLinkFile
if (-not $linkFile) {
    throw 'Nenhum .sky/link.yaml — instale com: sky-forge/scripts/sky/sky.ps1 attach -WorkspacePath .'
}

$slug = Read-LinkField $linkFile 'slug'
$forgeRel = Read-LinkField $linkFile 'forge_root'
$mode = Read-LinkField $linkFile 'mode'
$appRoot = Split-Path (Split-Path $linkFile -Parent) -Parent
$forgeRoot = if ([System.IO.Path]::IsPathRooted($forgeRel)) {
    (Resolve-Path $forgeRel).Path
} else {
    (Resolve-Path (Join-Path $appRoot $forgeRel)).Path
}

$coreSky = Join-Path $forgeRoot 'scripts\sky\sky.ps1'
if (-not (Test-Path $coreSky)) {
    throw "Sky-Forge nao encontrado em $forgeRoot"
}

switch ($Command) {
    'assess' {
        & (Join-Path $forgeRoot 'scripts\sky\assess-platform.ps1') -Slug $slug -WorkspacePath $appRoot
    }
    'pull-spec' {
        & (Join-Path $forgeRoot 'scripts\sky\pull-spec.ps1') -WorkspacePath $appRoot
    }
    'sync-spec' {
        & (Join-Path $forgeRoot 'scripts\sky\pull-spec.ps1') -WorkspacePath $appRoot
        Write-Host ""
        & $coreSky status -Slug $slug
    }
    'export' {
        if ($ForAI) {
            & $coreSky export -Slug $slug -ForAI -Scope $Scope
        } else {
            Write-Host "Export completo roda no Sky-Forge (sessao + gates)." -ForegroundColor Yellow
            Write-Host "  cd $forgeRoot"
            Write-Host "  ./scripts/sky/sky.ps1 export -Slug $slug -Profile platform-evolution"
            Write-Host ""
            Write-Host "Do app repo: ./scripts/sky.ps1 export -ForAI -Scope spec" -ForegroundColor Cyan
        }
    }
    'elevate' {
        & $coreSky elevate -Slug $slug
    }
    'architect' {
        & $coreSky architect -Slug $slug
    }
    'benchmark' {
        & $coreSky benchmark -Slug $slug
    }
    'seed-roadmap' {
        & (Join-Path $forgeRoot 'scripts\sky\seed-evolution-roadmap.ps1') -Slug $slug
    }
    default {
        $delegate = @{
            Command = $Command
            Slug = $slug
        }
        if ($PSBoundParameters.ContainsKey('Completeness')) { $delegate.Completeness = $Completeness }
        if ($Force) { $delegate.Force = $true }
        if ($PSBoundParameters.ContainsKey('Last')) { $delegate.Last = $Last }
        & $coreSky @delegate
    }
}

if ($mode -eq 'host' -and $Command -eq 'status') {
    $assessment = Join-Path $appRoot 'integrations\sky-forge\platform-assessment.yaml'
    if (Test-Path $assessment) {
        Write-Host "`n--- platform-assessment (host) ---" -ForegroundColor Cyan
        Get-Content $assessment -Raw | Write-Host
    }
}
