#Requires -Version 5.1
<#
.SYNOPSIS
  Resolve paths do Sky-Forge (outputs externos, registry, showcase).
#>
$ErrorActionPreference = 'Stop'

function Get-SkyRepoRoot {
    if ($script:SkyRepoRoot) { return $script:SkyRepoRoot }
    $script:SkyRepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
    return $script:SkyRepoRoot
}

function Read-SkyConfigFile {
    $path = Join-Path (Get-SkyRepoRoot) 'sky.config.yaml'
    if (-not (Test-Path $path)) { return @{} }
    $raw = Get-Content $path -Raw
    $config = @{
        outputsDir = 'outputs'
        registryDir = 'showcase/registry'
        registryExternal = $null
        showcasePort = 4321
        showcaseDataSource = 'registry'
    }
    if ($raw -match '(?m)^outputs:\s*\r?\n(?:[^\r\n]+\r?\n)*?\s+dir:\s*(.+)$') {
        $config.outputsDir = $Matches[1].Trim().Trim('"').Trim("'")
    }
    if ($raw -match '(?m)^registry:\s*\r?\n(?:[^\r\n]+\r?\n)*?\s+dir:\s*(.+)$') {
        $config.registryDir = $Matches[1].Trim().Trim('"').Trim("'")
    }
    if ($raw -match 'external_dir:\s*(.+)$') {
        $ext = $Matches[1].Trim().Trim('"').Trim("'")
        if ($ext -and $ext -ne 'null') { $config.registryExternal = $ext }
    }
    if ($raw -match 'data_source:\s*(\w+)') {
        $config.showcaseDataSource = $Matches[1].Trim()
    }
    if ($raw -match 'port:\s*(\d+)') {
        $config.showcasePort = [int]$Matches[1]
    }
    return $config
}

function Resolve-SkyPath([string]$Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return Join-Path (Get-SkyRepoRoot) $Path
}

function Get-SkyOutputsDir {
    if ($env:SKY_OUTPUTS_DIR) {
        return Resolve-SkyPath $env:SKY_OUTPUTS_DIR
    }
    $cfg = Read-SkyConfigFile
    return Resolve-SkyPath $cfg.outputsDir
}

function Get-SkyRegistryDir {
    if ($env:SKY_REGISTRY_DIR) {
        return Resolve-SkyPath $env:SKY_REGISTRY_DIR
    }
    $cfg = Read-SkyConfigFile
    return Resolve-SkyPath $cfg.registryDir
}

function Get-SkyOutputDirForSlug([string]$Slug) {
    Join-Path (Get-SkyOutputsDir) $Slug
}
