#Requires -Version 5.1
<#
.SYNOPSIS
  Gera ZIP do pacote exportado para download no showcase.
.EXAMPLE
  ./scripts/sky/package-zip.ps1 -Slug iautos
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'get-sky-config.ps1')

function Write-Utf8NoBom([string]$Path, [string]$Content) {
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content, $utf8)
}

$RepoRoot = Get-SkyRepoRoot
$OutputDir = Get-SkyOutputDirForSlug $Slug
if (-not (Test-Path $OutputDir)) {
    throw "Pacote nao exportado: $OutputDir — rode sky export -Slug $Slug"
}

$packagesPublic = Join-Path $RepoRoot 'apps\showcase\public\packages'
$registryDir = Get-SkyRegistryDir
New-Item -ItemType Directory -Path $packagesPublic -Force | Out-Null
New-Item -ItemType Directory -Path $registryDir -Force | Out-Null

$zipFile = "$Slug-package.zip"
$zipPath = Join-Path $packagesPublic $zipFile
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

$staging = Join-Path ([System.IO.Path]::GetTempPath()) "sky-forge-zip-$Slug-$(Get-Random)"
New-Item -ItemType Directory -Path $staging -Force | Out-Null
try {
    Copy-Item -Path (Join-Path $OutputDir '*') -Destination $staging -Recurse -Force
    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $zipPath -CompressionLevel Optimal
}
finally {
    Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
}

$manifestPath = Join-Path $OutputDir 'PACKAGE_MANIFEST.yaml'
$completeness = 'partial'
$readiness = $null
$exportedAt = $null
if (Test-Path $manifestPath) {
    $manifest = Get-Content $manifestPath -Raw
    if ($manifest -match 'package_completeness:\s*(\S+)') { $completeness = $Matches[1] }
    if ($manifest -match 'overall_readiness:\s*([0-9.]+)') { $readiness = [double]$Matches[1] }
    if ($manifest -match 'exported_at:\s*(.+)') { $exportedAt = $Matches[1].Trim() }
}

$item = Get-Item $zipPath
$meta = [ordered]@{
    slug = $Slug
    available = $true
    file = $zipFile
    url_path = "packages/$zipFile"
    size_bytes = $item.Length
    size_human = if ($item.Length -ge 1MB) { '{0:N1} MB' -f ($item.Length / 1MB) } elseif ($item.Length -ge 1KB) { '{0:N0} KB' -f ($item.Length / 1KB) } else { "$($item.Length) B" }
    package_completeness = $completeness
    overall_readiness = $readiness
    exported_at = if ($exportedAt) { $exportedAt } else { (Get-Date).ToUniversalTime().ToString('o') }
    zipped_at = (Get-Date).ToUniversalTime().ToString('o')
    note = 'Pacote completo Sky-Forge — YAMLs, scaffold, cloud-design, arquitetura. Uso local/privado.'
}

$metaPath = Join-Path $registryDir "$Slug.package.json"
Write-Utf8NoBom $metaPath ($meta | ConvertTo-Json -Depth 5)

Write-Host "ZIP: $zipPath ($($meta.size_human))" -ForegroundColor Green
Write-Host "Meta: $metaPath" -ForegroundColor Cyan
