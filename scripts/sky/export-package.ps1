#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'get-sky-config.ps1')
$RepoRoot = Get-SkyRepoRoot
$SessionDir = Join-Path $RepoRoot ".sky\sessions\$Slug"
$OutputDir = Get-SkyOutputDirForSlug $Slug

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputDir 'prompts') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputDir 'scaffold') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputDir 'cloud-design\screens') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputDir 'architecture') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputDir 'architecture\sequences') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputDir 'architecture\adrs') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputDir 'architecture\agents') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputDir 'architecture\specs') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputDir 'stories') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputDir 'testing') -Force | Out-Null

# Copiar arquitetura da sessao (C4, jornadas, craft)
$archSrc = Join-Path $SessionDir 'architecture'
if (Test-Path $archSrc) {
    Copy-Item -Path (Join-Path $archSrc '*') -Destination (Join-Path $OutputDir 'architecture') -Recurse -Force
}
$storiesSrc = Join-Path $SessionDir 'stories'
if (Test-Path $storiesSrc) {
    Copy-Item -Path (Join-Path $storiesSrc '*') -Destination (Join-Path $OutputDir 'stories') -Recurse -Force
}
$testingSrc = Join-Path $SessionDir 'testing'
if (Test-Path $testingSrc) {
    Copy-Item -Path (Join-Path $testingSrc '*') -Destination (Join-Path $OutputDir 'testing') -Recurse -Force
}
$copyFiles = @('brief-draft.yaml', 'functional-requirements.yaml', 'nfr.yaml', 'integrations.yaml', 'maturity.yaml', 'sky-merits.yaml', 'ux-spec.yaml', 'ops.yaml', 'tier-pricing.yaml', 'technical-decisions.yaml', 'acceptance-criteria.yaml')
foreach ($f in $copyFiles) {
    $src = Join-Path $SessionDir $f
    if (Test-Path $src) {
        $destName = if ($f -eq 'brief-draft.yaml') { 'brief.yaml' } else { $f }
        Copy-Item $src (Join-Path $OutputDir $destName) -Force
    }
}

$designRedesign = Join-Path $SessionDir 'design-redesign'
if (Test-Path $designRedesign) {
    Copy-Item -Path $designRedesign -Destination (Join-Path $OutputDir 'design-redesign') -Recurse -Force
}

# tier-matrix stub
$tierMatrix = @"
# Tier matrix — $Slug
generated_at: $((Get-Date).ToUniversalTime().ToString('o'))
tiers:
  - ref: docs/tiers/mvp-free.yaml
  - ref: docs/tiers/growth.yaml
  - ref: docs/tiers/enterprise.yaml
selected: undecided
trade_offs_summary: |
  Preencher apos intake tecnico e consulta cost-tier-advisor.
"@
Set-Content (Join-Path $OutputDir 'tier-matrix.yaml') -Value $tierMatrix -Encoding UTF8

# scaffold copy
$scaffoldSrc = Join-Path $RepoRoot 'templates\scaffold'
if (Test-Path $scaffoldSrc) {
    Copy-Item -Path (Join-Path $scaffoldSrc '*') -Destination (Join-Path $OutputDir 'scaffold') -Recurse -Force
}
$sessionScaffold = Join-Path $SessionDir 'scaffold'
if (Test-Path $sessionScaffold) {
    Copy-Item -Path (Join-Path $sessionScaffold '*') -Destination (Join-Path $OutputDir 'scaffold') -Recurse -Force
}

$maturity = Get-Content (Join-Path $SessionDir 'maturity.yaml') -Raw -ErrorAction SilentlyContinue
$readiness = '0'
if ($maturity -match 'overall_readiness:\s*([0-9.]+)') { $readiness = $Matches[1] }
$completeness = if ([double]$readiness -ge 0.85) { 'full' } else { 'partial' }

$manifest = @"
slug: $Slug
exported_at: $((Get-Date).ToUniversalTime().ToString('o'))
package_completeness: $completeness
overall_readiness: $readiness
outputs_dir: $OutputDir
artifacts:
  - brief.yaml
  - functional-requirements.yaml
  - nfr.yaml
  - integrations.yaml
  - maturity.yaml
  - sky-merits.yaml
  - ux-spec.yaml
  - tier-matrix.yaml
  - scaffold/AGENTS.md
  - architecture/
  - stories/
  - testing/
  - cloud-design/
  - cloud-design/screens/
  - design-redesign/
next_step: ./scripts/sky/sky.ps1 link -Slug $Slug -WorkspacePath <app-repo> -PullSpec
next_step_alt: ./scripts/sky/sky.ps1 publish -Slug $Slug -Public
"@
Set-Content (Join-Path $OutputDir 'PACKAGE_MANIFEST.yaml') -Value $manifest -Encoding UTF8

Write-Host "Exportado: $OutputDir" -ForegroundColor Green

& (Join-Path $PSScriptRoot 'sync-linked-workspace.ps1') -Slug $Slug
