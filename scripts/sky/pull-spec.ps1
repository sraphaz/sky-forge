#Requires -Version 5.1
<#
.SYNOPSIS
  Sincroniza spec do pacote Sky-Forge para spec/ no repositório da aplicação.
#>
param(
    [Parameter()]
    [string]$Slug,

    [Parameter()]
    [string]$WorkspacePath,

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'resolve-sky-link.ps1')

$ctx = Get-SkyLinkContext -StartPath $(if ($WorkspacePath) { $WorkspacePath } else { (Get-Location).Path }) -Slug $Slug
if (-not $ctx) {
    throw 'Nenhuma ligacao encontrada. Rode sky link -Slug <slug> -WorkspacePath <app> primeiro.'
}
if ($WorkspacePath) { $ctx.WorkspacePath = (Resolve-Path $WorkspacePath).Path }
if (-not $ctx.WorkspacePath) { throw 'workspace_path ausente — rode sky link.' }

$packageDir = $ctx.PackageDir
if (-not (Test-Path $packageDir)) {
    Write-Host "Pacote ainda nao exportado em $packageDir — exportando..." -ForegroundColor Yellow
    & (Join-Path $PSScriptRoot 'export-package.ps1') -Slug $ctx.Slug
    $packageDir = $ctx.PackageDir
}

$specDir = Join-Path $ctx.WorkspacePath 'spec'
New-Item -ItemType Directory -Path $specDir -Force | Out-Null

$copyDirs = @('stories', 'architecture', 'testing', 'prompts')
foreach ($dir in $copyDirs) {
    $src = Join-Path $packageDir $dir
    if (Test-Path $src) {
        $dest = Join-Path $specDir $dir
        if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
        Copy-Item $src $dest -Recurse -Force
    }
}

$copyFiles = @(
    'brief.yaml', 'functional-requirements.yaml', 'nfr.yaml',
    'integrations.yaml', 'acceptance-criteria.yaml', 'ux-spec.yaml',
    'maturity.yaml', 'sky-merits.yaml', 'PACKAGE_MANIFEST.yaml'
)
foreach ($file in $copyFiles) {
    $src = Join-Path $packageDir $file
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $specDir $file) -Force
    }
}

$aiContext = Join-Path $packageDir 'ai-export\SKY_AI_CONTEXT.md'
if (Test-Path $aiContext) {
    $aiDestDir = Join-Path $specDir 'ai-export'
    New-Item -ItemType Directory -Path $aiDestDir -Force | Out-Null
    Copy-Item $aiContext (Join-Path $aiDestDir 'SKY_AI_CONTEXT.md') -Force
}

$manifest = @"
slug: $($ctx.Slug)
synced_at: $((Get-Date).ToUniversalTime().ToString('o'))
source: $($packageDir -replace '\\', '/')
forge_root: $($ctx.ForgeRoot -replace '\\', '/')
note: |
  Spec somente leitura — fonte de verdade permanece em Sky-Forge.
  Atualize com: ./scripts/sky.ps1 pull-spec
"@
Set-Content (Join-Path $specDir 'SKY_SPEC_MANIFEST.yaml') -Value $manifest -Encoding UTF8

Write-Host "Spec sincronizado: $specDir" -ForegroundColor Green
Write-Host "  stories/, architecture/, brief.yaml + manifest"
