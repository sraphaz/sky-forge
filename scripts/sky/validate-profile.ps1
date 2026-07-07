#Requires -Version 5.1
<#
.SYNOPSIS
  Valida um pacote exportado contra um profile Sky-Forge.
.EXAMPLE
  ./validate-profile.ps1 -Profile consulting-handoff -PackagePath examples/sky-forge-packages/surya-workspace-mvp
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Profile,

    [Parameter(Mandatory = $true)]
    [string]$PackagePath,

    [switch]$FixtureMode
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$ProfilePath = Join-Path $RepoRoot "profiles\$Profile.yaml"
$PkgDir = if ([System.IO.Path]::IsPathRooted($PackagePath)) { $PackagePath } else { Join-Path $RepoRoot $PackagePath }

$errors = @()
$warnings = @()

if (-not (Test-Path $ProfilePath)) {
    Write-Error "Profile nao encontrado: $ProfilePath"
}
if (-not (Test-Path $PkgDir)) {
    Write-Error "Pacote nao encontrado: $PkgDir"
}

function Get-YamlListBlock {
    param([string]$Content, [string]$Key)
    if ($Content -notmatch "(?ms)^\s*$Key\s*:\s*\[(.*?)\]") { return @() }
    $inner = $Matches[1]
    [regex]::Matches($inner, '([a-z0-9_-]+)') | ForEach-Object { $_.Groups[1].Value }
}

function Get-YamlScalar {
    param([string]$Content, [string]$Key)
    if ($Content -match "(?m)^\s*$Key\s*:\s*(\S+)") { return $Matches[1] }
    return $null
}

$profileRaw = Get-Content $ProfilePath -Raw
$required = Get-YamlListBlock $profileRaw 'required'
if (-not $required.Count) {
    if ($profileRaw -match '(?ms)artifacts:\s*\r?\n\s*required:\s*\[(.*?)\]') {
        $required = [regex]::Matches($Matches[1], '([a-z0-9_-]+)') | ForEach-Object { $_.Groups[1].Value }
    }
}

$pkgManifest = Join-Path $PkgDir 'package.yaml'
if (-not (Test-Path $pkgManifest)) {
    $errors += 'package.yaml ausente'
} else {
    $pkgRaw = Get-Content $pkgManifest -Raw
    $pkgProfile = Get-YamlScalar $pkgRaw 'profile'
    if ($pkgProfile -ne $Profile) {
        $errors += "package profile '$pkgProfile' != '$Profile'"
    }
    foreach ($art in $required) {
        $file = "$art.yaml"
        $path = Join-Path $PkgDir $file
        if (-not (Test-Path $path)) {
            $errors += "artefato obrigatorio ausente: $file"
        }
    }
}

# Regras duras (subset implementado)
$scopePath = Join-Path $PkgDir 'proposal-scope.yaml'
if (Test-Path $scopePath) {
    $scopeRaw = Get-Content $scopePath -Raw
    if ($scopeRaw -notmatch '(?ms)out_of_scope:\s*\r?\n\s*-\s+\S') {
        $errors += 'proposal-scope.out_of_scope vazio (regra out_of_scope_required)'
    }
}

$pvalPath = Join-Path $PkgDir 'professional-validation-needed.yaml'
if ($required -contains 'professional-validation-needed' -and -not (Test-Path $pvalPath)) {
    $errors += 'professional-validation-needed ausente'
}

$riskPath = Join-Path $PkgDir 'risks-and-open-questions.yaml'
if (Test-Path $riskPath) {
    $riskRaw = Get-Content $riskPath -Raw
    if ($riskRaw -match 'blocking:\s*true') {
        if (-not $FixtureMode) {
            $warnings += 'open_questions com blocking=true (verificar antes de export real)'
        }
    }
}

if ($errors.Count) {
    Write-Host "validate-profile FALHOU ($Profile)" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    if ($warnings.Count) { $warnings | ForEach-Object { Write-Host "  ! $_" -ForegroundColor Yellow } }
    exit 1
}

Write-Host "validate-profile OK ($Profile) -> $PkgDir" -ForegroundColor Green
if ($warnings.Count) { $warnings | ForEach-Object { Write-Host "  ! $_" -ForegroundColor Yellow } }
exit 0
