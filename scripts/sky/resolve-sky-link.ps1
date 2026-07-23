#Requires -Version 5.1
<#
.SYNOPSIS
  Resolve ligação bidirecional Sky-Forge (sessão) ↔ repositório da aplicação.
#>
$ErrorActionPreference = 'Stop'

function Find-SkyLinkFile {
    param([string]$StartPath = (Get-Location).Path)
    $current = (Resolve-Path $StartPath).Path
    while ($true) {
        $candidate = Join-Path $current '.sky\link.yaml'
        if (Test-Path $candidate) { return $candidate }
        $parent = Split-Path $current -Parent
        if (-not $parent -or $parent -eq $current) { return $null }
        $current = $parent
    }
}

function Read-SkyLinkYaml {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    $raw = Get-Content $Path -Raw
    $link = @{
        version = '1.0'
        slug = $null
        forge_root = $null
        package_dir = $null
        sync_mode = 'manual'
        mode = 'linked'
        profile = $null
        linked_at = $null
    }
    if ($raw -match '(?m)^slug:\s*(.+)$') { $link.slug = $Matches[1].Trim().Trim('"').Trim("'") }
    if ($raw -match '(?m)^forge_root:\s*(.+)$') { $link.forge_root = $Matches[1].Trim().Trim('"').Trim("'") }
    if (-not $link.forge_root -and ($raw -match '(?m)^forge_path:\s*(.+)$')) {
        $link.forge_root = $Matches[1].Trim().Trim('"').Trim("'")
    }
    if ($raw -match '(?m)^package_dir:\s*(.+)$') {
        $val = $Matches[1].Trim().Trim('"').Trim("'")
        if ($val -and $val -ne 'null') { $link.package_dir = $val }
    }
    if ($raw -match '(?m)^sync_mode:\s*(.+)$') { $link.sync_mode = $Matches[1].Trim().Trim('"').Trim("'") }
    if ($raw -match '(?m)^mode:\s*(.+)$') { $link.mode = $Matches[1].Trim().Trim('"').Trim("'") }
    if ($raw -match '(?m)^profile:\s*(.+)$') { $link.profile = $Matches[1].Trim().Trim('"').Trim("'") }
    if ($raw -match '(?m)^linked_at:\s*(.+)$') { $link.linked_at = $Matches[1].Trim().Trim('"').Trim("'") }
    return $link
}

function Read-SkyGitYaml {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    $raw = Get-Content $Path -Raw
    $git = @{
        version = '1.0'
        workspace_path = $null
        remote_url = $null
        sync_mode = 'manual'
        linked_at = $null
    }
    if ($raw -match '(?m)^workspace_path:\s*(.+)$') { $git.workspace_path = $Matches[1].Trim().Trim('"').Trim("'") }
    if ($raw -match '(?m)^remote_url:\s*(.+)$') {
        $val = $Matches[1].Trim().Trim('"').Trim("'")
        if ($val -and $val -ne 'null') { $git.remote_url = $val }
    }
    if ($raw -match '(?m)^sync_mode:\s*(.+)$') { $git.sync_mode = $Matches[1].Trim().Trim('"').Trim("'") }
    if ($raw -match '(?m)^linked_at:\s*(.+)$') { $git.linked_at = $Matches[1].Trim().Trim('"').Trim("'") }
    return $git
}

function Resolve-SkyForgeRoot {
    param([string]$ForgeRoot, [string]$RelativeTo)
    if ([string]::IsNullOrWhiteSpace($ForgeRoot)) { return $null }
    if ([System.IO.Path]::IsPathRooted($ForgeRoot)) {
        return (Resolve-Path $ForgeRoot -ErrorAction Stop).Path
    }
    $base = if ($RelativeTo) { Split-Path $RelativeTo -Parent } else { (Get-Location).Path }
    return (Resolve-Path (Join-Path $base $ForgeRoot) -ErrorAction Stop).Path
}

function Set-SkyLinkSyncMode {
    param(
        [string]$Slug,
        [ValidateSet('manual', 'after_export')]
        [string]$SyncMode
    )
    . (Join-Path $PSScriptRoot 'get-sky-config.ps1')
    $sessionDir = Join-Path (Get-SkyRepoRoot) ".sky\sessions\$Slug"
    $gitFile = Join-Path $sessionDir 'git.yaml'
    if (-not (Test-Path $gitFile)) { throw "git.yaml ausente — rode sky link primeiro." }
    $raw = Get-Content $gitFile -Raw
    $raw = $raw -replace '(?m)^sync_mode:\s*.+$', "sync_mode: $SyncMode"
    Set-Content $gitFile -Value $raw -Encoding UTF8

    $ctx = Get-SkyLinkContext -Slug $Slug
    if ($ctx.LinkFile -and (Test-Path $ctx.LinkFile)) {
        $linkRaw = Get-Content $ctx.LinkFile -Raw
        $linkRaw = $linkRaw -replace '(?m)^sync_mode:\s*.+$', "sync_mode: $SyncMode"
        Set-Content $ctx.LinkFile -Value $linkRaw -Encoding UTF8
    }
    Write-Host "sync_mode atualizado: $SyncMode ($Slug ↔ $($ctx.WorkspacePath))" -ForegroundColor Green
}

function Get-SkyLinkContext {
    param(
        [string]$StartPath = (Get-Location).Path,
        [string]$Slug,
        [string]$ForgeRoot
    )
    . (Join-Path $PSScriptRoot 'get-sky-config.ps1')

    $linkFile = Find-SkyLinkFile -StartPath $StartPath
    if ($linkFile) {
        $link = Read-SkyLinkYaml -Path $linkFile
        if (-not $link.slug) { throw "link.yaml invalido (slug ausente): $linkFile" }
        if (-not $link.forge_root) { throw "link.yaml invalido (forge_root ausente): $linkFile" }
        $appRoot = Split-Path (Split-Path $linkFile -Parent) -Parent
        if ([System.IO.Path]::IsPathRooted($link.forge_root)) {
            $resolvedForge = (Resolve-Path $link.forge_root -ErrorAction Stop).Path
        } else {
            $resolvedForge = (Resolve-Path (Join-Path $appRoot $link.forge_root) -ErrorAction Stop).Path
        }
        $workspace = (Resolve-Path $appRoot).Path
        $packageDir = $link.package_dir
        if (-not $packageDir) {
            $script:SkyRepoRoot = $resolvedForge
            $packageDir = Get-SkyOutputDirForSlug $link.slug
        } elseif (-not [System.IO.Path]::IsPathRooted($packageDir)) {
            $packageDir = Join-Path $workspace $packageDir
        }
        return [PSCustomObject]@{
            Source = 'app'
            Slug = $link.slug
            ForgeRoot = $resolvedForge
            WorkspacePath = $workspace
            PackageDir = $packageDir
            LinkFile = $linkFile
            SyncMode = $link.sync_mode
            Mode = $link.mode
            Profile = $link.profile
        }
    }

    if (-not $Slug) { return $null }
    $script:SkyRepoRoot = if ($ForgeRoot) { (Resolve-Path $ForgeRoot).Path } else { Get-SkyRepoRoot }
    $sessionDir = Join-Path $script:SkyRepoRoot ".sky\sessions\$Slug"
    if (-not (Test-Path $sessionDir)) { throw "Sessao nao encontrada: $Slug" }
    $gitFile = Join-Path $sessionDir 'git.yaml'
    $git = Read-SkyGitYaml -Path $gitFile
    $workspace = $git.workspace_path
    if ($workspace) { $workspace = (Resolve-Path $workspace -ErrorAction SilentlyContinue).Path }
    return [PSCustomObject]@{
        Source = 'forge'
        Slug = $Slug
        ForgeRoot = $script:SkyRepoRoot
        WorkspacePath = $workspace
        PackageDir = (Get-SkyOutputDirForSlug $Slug)
        LinkFile = if ($workspace) { Join-Path $workspace '.sky\link.yaml' } else { $null }
        SyncMode = if ($git) { $git.sync_mode } else { 'manual' }
    }
}
