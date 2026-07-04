#Requires -Version 5.1
<#
.SYNOPSIS
  Wrapper Sky-Forge — delega para o core a partir do repositório da aplicação.
.EXAMPLE
  ./scripts/sky.ps1 status
  ./scripts/sky.ps1 pull-spec
  ./scripts/sky.ps1 export -ForAI -Scope spec
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet('status', 'validate', 'export', 'pull-spec', 'sync-spec', 'audit', 'agents')]
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
    throw 'Nenhum .sky/link.yaml — ligue com: sky-forge/scripts/sky/sky.ps1 link -Slug <slug> -WorkspacePath .'
}

$slug = Read-LinkField $linkFile 'slug'
$forgeRel = Read-LinkField $linkFile 'forge_root'
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
            Write-Host "  ./scripts/sky/sky.ps1 export -Slug $slug"
            Write-Host ""
            Write-Host "Do app repo, use: ./scripts/sky.ps1 export -ForAI -Scope spec" -ForegroundColor Cyan
        }
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
