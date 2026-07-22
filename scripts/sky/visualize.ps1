#Requires -Version 5.1
<#
.SYNOPSIS
  Integração opcional e fina: delega visualização pós-export ao plugin Archify.
  Não falha o core se o plugin estiver ausente — orienta o uso opcional.
.EXAMPLE
  ./scripts/sky/visualize.ps1 -PackagePath examples/sky-forge-packages/surya-workspace-mvp -Renderer archify
  ./scripts/sky/visualize.ps1 -Slug minha-sessao -Renderer archify
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Slug,

    [Parameter()]
    [string]$PackagePath,

    [Parameter()]
    [ValidateSet('archify')]
    [string]$Renderer = 'archify',

    [Parameter()]
    [string]$Views = 'architecture,workflow,sequence',

    [Parameter()]
    [ValidateSet('standard', 'showcase')]
    [string]$Quality = 'standard',

    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')

if ($Renderer -ne 'archify') {
    throw "Unsupported renderer: $Renderer"
}

$pluginScript = Join-Path $RepoRoot 'plugins\examples\archify\scripts\visualize.ps1'
if (-not (Test-Path $pluginScript)) {
    Write-Host 'Visualize renderer "archify" is optional and not installed in this checkout.' -ForegroundColor Yellow
    Write-Host 'Expected plugin path:'
    Write-Host "  $pluginScript"
    Write-Host 'Install/restore plugins/examples/archify and bootstrap Archify, then retry.'
    exit 0
}

if (-not $PackagePath) {
    if (-not $Slug) {
        throw 'Provide -PackagePath or -Slug'
    }
    $candidates = @(
        (Join-Path $RepoRoot ".sky\sessions\$Slug\export"),
        (Join-Path $RepoRoot ".sky\sessions\$Slug\package"),
        (Join-Path $RepoRoot "examples\sky-forge-packages\$Slug")
    )
    $PackagePath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $PackagePath) {
        throw "Could not resolve package for slug '$Slug'. Pass -PackagePath explicitly."
    }
}

if (-not $OutputPath) {
    $name = if ($Slug) { $Slug } else { Split-Path -Leaf $PackagePath }
    $OutputPath = Join-Path $RepoRoot ".tmp\archify\$name"
}

$invokeArgs = @{
    PackagePath = $PackagePath
    OutputPath  = $OutputPath
    Views       = $Views
    Quality     = $Quality
}
if ($Json) { $invokeArgs.Json = $true }

& $pluginScript @invokeArgs
exit $LASTEXITCODE
