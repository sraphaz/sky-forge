#Requires -Version 5.1
<#
.SYNOPSIS
  Garante que o core Sky-Forge nao acopla consultoria especifica no core.
.EXAMPLE
  ./check-core-agnostic.ps1
#>
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'
$errors = @()

# Presenca de profile acoplado e proibido
$forbiddenProfiles = @(
    (Join-Path $RepoRoot 'profiles\surya-consulting.yaml'),
    (Join-Path $RepoRoot 'profiles\surya_labs_consulting.yaml')
)
foreach ($p in $forbiddenProfiles) {
    if (Test-Path $p) { $errors += "profile proibido existe: $p" }
}

# Referencia obrigatoria no core (fora de examples)
$coreProfileDir = Join-Path $RepoRoot 'profiles'
if (Test-Path $coreProfileDir) {
    Get-ChildItem $coreProfileDir -Filter '*.yaml' | ForEach-Object {
        $raw = Get-Content $_.FullName -Raw
        if ($raw -match '(?m)^\s*id:\s*surya') {
            $errors += "$($_.Name): id acoplado a marca no core"
        }
    }
}

# Plugin obrigatorio no core (nao em examples)
$badPlugin = Join-Path $RepoRoot 'plugins\surya-labs-workspace'
if (Test-Path $badPlugin) {
    $errors += 'plugin surya fora de plugins/examples/ (deve ser opcional)'
}

if ($errors.Count) {
    Write-Host 'check-core-agnostic FALHOU' -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'check-core-agnostic OK' -ForegroundColor Green
exit 0
