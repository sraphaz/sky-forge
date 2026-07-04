#Requires -Version 5.1
<#
.SYNOPSIS
  Liga repositório da aplicação à sessão Sky-Forge (bidirecional).
.EXAMPLE
  ./scripts/sky/sky.ps1 link -Slug iautos -WorkspacePath C:\repos\iautos
  cd C:\repos\iautos && ../sky-forge/scripts/sky/sky.ps1 link -Slug iautos
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [Parameter()]
    [string]$WorkspacePath = (Get-Location).Path,

    [Parameter()]
    [ValidateSet('manual', 'after_export')]
    [string]$SyncMode = 'manual',

    [Parameter()]
    [switch]$PullSpec,

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'get-sky-config.ps1')
. (Join-Path $PSScriptRoot 'resolve-sky-link.ps1')

$forgeRoot = Get-SkyRepoRoot
$sessionDir = Join-Path $forgeRoot ".sky\sessions\$Slug"
if (-not (Test-Path $sessionDir)) { throw "Sessao nao encontrada: $Slug" }

$workspace = (Resolve-Path $WorkspacePath).Path
$gitMarker = Join-Path $workspace '.git'
if (-not (Test-Path $gitMarker) -and -not $Force) {
    Write-Host "Aviso: nenhum .git em $workspace — use -Force se for intencional." -ForegroundColor Yellow
}

$existing = Get-SkyLinkContext -StartPath $workspace -Slug $Slug
if ($existing -and $existing.LinkFile -and -not $Force) {
    throw "Workspace ja ligado ($($existing.LinkFile)). Use -Force para religar."
}

$relativeForge = $forgeRoot
try {
    $relativeForge = [System.IO.Path]::GetRelativePath($workspace, $forgeRoot)
    if ($relativeForge -match '^\.\.') {
        # ok — sibling or outside
    } elseif ($relativeForge -eq '.') {
        throw 'Workspace nao pode ser a raiz do Sky-Forge.'
    }
} catch {
    $relativeForge = $forgeRoot
}

$script:SkyRepoRoot = $forgeRoot
$packageDir = Get-SkyOutputDirForSlug $Slug
$linkedAt = (Get-Date).ToUniversalTime().ToString('o')

$skyDir = Join-Path $workspace '.sky'
New-Item -ItemType Directory -Path $skyDir -Force | Out-Null

$linkYaml = @"
version: "1.0"
slug: $Slug
forge_root: $($relativeForge -replace '\\', '/')
package_dir: null
sync_mode: $SyncMode
linked_at: $linkedAt
"@
Set-Content (Join-Path $skyDir 'link.yaml') -Value $linkYaml -Encoding UTF8

$gitYaml = @"
version: "1.0"
workspace_path: $($workspace -replace '\\', '/')
remote_url: null
sync_mode: $SyncMode
linked_at: $linkedAt
"@
Set-Content (Join-Path $sessionDir 'git.yaml') -Value $gitYaml -Encoding UTF8

$scaffoldRoot = Join-Path $forgeRoot 'templates\scaffold'
$wrapperSrc = Join-Path $scaffoldRoot 'scripts\sky.ps1'
$wrapperDest = Join-Path $workspace 'scripts\sky.ps1'
if (Test-Path $wrapperSrc) {
    New-Item -ItemType Directory -Path (Split-Path $wrapperDest -Parent) -Force | Out-Null
    Copy-Item $wrapperSrc $wrapperDest -Force
}

$ruleSrc = Join-Path $scaffoldRoot '.cursor\rules\sky-linked.mdc'
$ruleDest = Join-Path $workspace '.cursor\rules\sky-linked.mdc'
if (Test-Path $ruleSrc) {
    New-Item -ItemType Directory -Path (Split-Path $ruleDest -Parent) -Force | Out-Null
    Copy-Item $ruleSrc $ruleDest -Force
}

Write-Host "Ligado: $Slug ↔ $workspace" -ForegroundColor Green
Write-Host "  Sessao: .sky/sessions/$Slug/git.yaml"
Write-Host "  App:    .sky/link.yaml"
Write-Host "  CLI:    ./scripts/sky.ps1 status"

if ($PullSpec) {
    & (Join-Path $PSScriptRoot 'pull-spec.ps1') -Slug $Slug -WorkspacePath $workspace
}
