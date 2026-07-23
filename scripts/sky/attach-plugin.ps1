#Requires -Version 5.1
<#
.SYNOPSIS
  Instala Sky-Forge Host Plugin num repo brownfield existente.
.EXAMPLE
  ./scripts/sky/sky.ps1 attach -WorkspacePath C:\repos\minha-plataforma
  ./scripts/sky/sky.ps1 attach -Slug minha-plataforma -WorkspacePath . -Assess
#>
param(
    [Parameter()]
    [string]$Slug,

    [Parameter()]
    [string]$WorkspacePath = (Get-Location).Path,

    [Parameter()]
    [ValidateSet('platform-evolution')]
    [string]$Profile = 'platform-evolution',

    [Parameter()]
    [ValidateSet('manual', 'after_export')]
    [string]$SyncMode = 'manual',

    [Parameter()]
    [switch]$Assess,

    [Parameter()]
    [switch]$NoAssess,

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'get-sky-config.ps1')

$forgeRoot = Get-SkyRepoRoot
$workspace = (Resolve-Path $WorkspacePath).Path

if ((Resolve-Path $forgeRoot).Path -eq $workspace) {
    throw 'Workspace nao pode ser a raiz do Sky-Forge — aponte para o repo da plataforma.'
}

function ConvertTo-KebabSlug([string]$Name) {
    $s = $Name -replace '[_\s]+', '-'
    $s = $s -replace '[^a-zA-Z0-9-]', ''
    $s = $s.ToLower()
    $s = $s -replace '-+', '-'
    $s = $s.Trim('-')
    if ($s -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
        throw "Nao foi possivel derivar slug valido de: $Name"
    }
    return $s
}

if (-not $Slug) {
    $Slug = ConvertTo-KebabSlug (Split-Path $workspace -Leaf)
    Write-Host "Slug derivado: $Slug" -ForegroundColor Cyan
}

$sessionDir = Join-Path $forgeRoot ".sky\sessions\$Slug"
if (-not (Test-Path $sessionDir)) {
    Write-Host "Criando sessao brownfield: $Slug" -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot 'new-session.ps1') -Slug $Slug
}

$profilePath = Join-Path $sessionDir 'profile.yaml'
$profileYaml = @"
version: "1.0"
profile: $Profile
intake_mode: brownfield_host
attached_at: $((Get-Date).ToUniversalTime().ToString('o'))
"@
Set-Content -Path $profilePath -Value $profileYaml -Encoding UTF8

$journeyPath = Join-Path $sessionDir 'journey.yaml'
if (Test-Path $journeyPath) {
    $jRaw = Get-Content $journeyPath -Raw
    $now = (Get-Date).ToUniversalTime().ToString('o')
    $jRaw = $jRaw -replace '(?m)^current_phase:\s*.+$', 'current_phase: shape'
    $jRaw = $jRaw -replace '(?m)^updated_at:\s*.+$', "updated_at: $now"
    if ($jRaw -notmatch 'host_plugin:') {
        $jRaw = $jRaw -replace '(?m)^slug:\s*.+$', "`$0`nhost_plugin: true`nprofile: $Profile"
    }
    Set-Content -Path $journeyPath -Value $jRaw -Encoding UTF8
}

$pluginSrc = Join-Path $forgeRoot 'plugins\examples\sky-forge-host'
if (-not (Test-Path $pluginSrc)) {
    throw "Plugin host exemplo ausente: $pluginSrc"
}

$integrationDir = Join-Path $workspace 'integrations\sky-forge'
New-Item -ItemType Directory -Path $integrationDir -Force | Out-Null

$existingConsumer = Test-Path (Join-Path $integrationDir 'plugin.yaml')
if ($existingConsumer) {
    $consumerRaw = Get-Content (Join-Path $integrationDir 'plugin.yaml') -Raw
    if ($consumerRaw -match 'direction:\s*consumer') {
        Write-Host "Consumer plugin detectado — modo dual (host + consumer)." -ForegroundColor Cyan
    }
}

foreach ($f in @('services.yaml', 'README.md')) {
    $src = Join-Path $pluginSrc $f
    $destName = if ($existingConsumer -and $f -eq 'services.yaml') { 'host-services.yaml' } else { $f }
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $integrationDir $destName) -Force
    }
}

$hostPluginDest = if ($existingConsumer) {
    Join-Path $integrationDir 'host-plugin.yaml'
} else {
    Join-Path $integrationDir 'plugin.yaml'
}
Copy-Item (Join-Path $pluginSrc 'plugin.yaml') $hostPluginDest -Force

$tplDir = Join-Path $pluginSrc 'templates'
$ruleDest = Join-Path $workspace '.cursor\rules\sky-host-plugin.mdc'
$ruleSrc = Join-Path $tplDir 'sky-host-plugin.mdc'
if (Test-Path $ruleSrc) {
    New-Item -ItemType Directory -Path (Split-Path $ruleDest -Parent) -Force | Out-Null
    Copy-Item $ruleSrc $ruleDest -Force
}

$agentsSky = Join-Path $workspace 'AGENTS.sky.md'
$agentsSrc = Join-Path $tplDir 'AGENTS.sky.md'
if ((Test-Path $agentsSrc) -and -not (Test-Path $agentsSky)) {
    Copy-Item $agentsSrc $agentsSky -Force
}

$hostWrapperSrc = Join-Path $forgeRoot 'templates\scaffold-host\scripts\sky.ps1'
$hostWrapperDest = Join-Path $workspace 'scripts\sky.ps1'
if (Test-Path $hostWrapperSrc) {
    New-Item -ItemType Directory -Path (Split-Path $hostWrapperDest -Parent) -Force | Out-Null
    Copy-Item $hostWrapperSrc $hostWrapperDest -Force
}

$linkArgs = @{
    Slug = $Slug
    WorkspacePath = $workspace
    SyncMode = $SyncMode
    Force = $Force
}
& (Join-Path $PSScriptRoot 'link-workspace.ps1') @linkArgs

$skyDir = Join-Path $workspace '.sky'
$pluginManifest = Join-Path $skyDir 'host-plugin.yaml'
Copy-Item (Join-Path $pluginSrc 'plugin.yaml') $pluginManifest -Force

$linkFile = Join-Path $skyDir 'link.yaml'
if (Test-Path $linkFile) {
    $linkRaw = Get-Content $linkFile -Raw
    if ($linkRaw -notmatch '(?m)^mode:\s*host') {
        if ($linkRaw -notmatch '(?m)^forge_root:' -and $linkRaw -match '(?m)^forge_path:\s*(.+)$') {
            $fp = $Matches[1].Trim()
            $linkRaw = $linkRaw -replace '(?m)^forge_path:\s*.+$', "forge_root: $fp"
        }
        $linkRaw = $linkRaw.TrimEnd() + "`nmode: host`nprofile: $Profile`n"
        if ($existingConsumer) { $linkRaw += "consumer_plugin: surya-labs-workspace`n" }
        Set-Content $linkFile -Value $linkRaw -Encoding UTF8
    }
}

$runAssess = $Assess -or -not $NoAssess
if ($runAssess) {
    Write-Host ""
    & (Join-Path $PSScriptRoot 'assess-platform.ps1') -Slug $Slug -WorkspacePath $workspace
}

Write-Host ""
Write-Host "Host plugin instalado: $Slug ↔ $workspace" -ForegroundColor Green
Write-Host "  integrations/sky-forge/"
Write-Host "  .cursor/rules/sky-host-plugin.mdc"
Write-Host ""
Write-Host "No repo da plataforma:" -ForegroundColor Cyan
Write-Host "  ./scripts/sky.ps1 status"
Write-Host "  ./scripts/sky.ps1 assess"
Write-Host ""
Write-Host "Intake/evolucao: converse com sky-host no Cursor (profile $Profile)."
