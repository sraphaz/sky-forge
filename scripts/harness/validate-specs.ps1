#Requires -Version 5.1
param(
    [string]$SpecId
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$specsDir = Join-Path $RepoRoot 'docs\specs'
$errors = @()

$files = Get-ChildItem -Path $specsDir -Filter '*.spec.yaml' -Recurse |
    Where-Object { $_.Name -ne '_template.spec.yaml' }

if ($SpecId) {
    $files = $files | Where-Object { (Get-Content $_.FullName -Raw) -match "id:\s*$SpecId" }
    if (-not $files) { throw "Spec nao encontrada: $SpecId" }
}

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if ($content -notmatch 'id:\s*\S+') { $errors += "$($file.Name): id ausente" }
    if ($content -notmatch 'acceptance:') { $errors += "$($file.Name): acceptance ausente" }
    if ($content -notmatch 'status:\s*(draft|active)') { $errors += "$($file.Name): status invalido" }
    Write-Host "OK spec: $($file.Name)"
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Host "ERROR: $_" -ForegroundColor Red }
    exit 1
}

Write-Host "validate-specs: $($files.Count) spec(s)" -ForegroundColor Green
