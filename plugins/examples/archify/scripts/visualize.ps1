#Requires -Version 5.1
<#
.SYNOPSIS
  Wrapper PowerShell do adapter Archify (pós-export).
.EXAMPLE
  ./plugins/examples/archify/scripts/visualize.ps1 `
    -PackagePath examples/sky-forge-packages/surya-workspace-mvp `
    -OutputPath .tmp/archify/surya-workspace-mvp `
    -Views architecture,workflow,sequence `
    -Quality standard
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PackagePath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [Parameter()]
    [string]$Views = 'architecture,workflow,sequence',

    [Parameter()]
    [ValidateSet('standard', 'showcase')]
    [string]$Quality = 'standard',

    [Parameter()]
    [string]$GeneratedAt,

    [Parameter()]
    [switch]$Json,

    [Parameter()]
    [switch]$SkipRender
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Visualizer = Join-Path $ScriptDir 'visualize.mjs'

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    throw 'Node.js >= 18 is required to run the Archify adapter.'
}

$nodeArgs = @(
    $Visualizer,
    '--package', (Resolve-Path $PackagePath).Path,
    '--output', $OutputPath,
    '--views', $Views,
    '--quality', $Quality
)

if ($GeneratedAt) { $nodeArgs += @('--generated-at', $GeneratedAt) }
if ($Json) { $nodeArgs += '--json' }
if ($SkipRender) { $nodeArgs += '--skip-render' }

& node @nodeArgs
exit $LASTEXITCODE
