#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$SessionDir = Join-Path $RepoRoot ".sky\sessions\$Slug"
$OutputDir = Join-Path $RepoRoot "outputs\$Slug"

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputDir 'prompts') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputDir 'scaffold') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputDir 'cloud-design') -Force | Out-Null

# Copiar artefatos da sessao
$copyFiles = @('brief-draft.yaml', 'functional-requirements.yaml', 'nfr.yaml', 'integrations.yaml', 'maturity.yaml', 'sky-merits.yaml', 'ux-spec.yaml')
foreach ($f in $copyFiles) {
    $src = Join-Path $SessionDir $f
    if (Test-Path $src) {
        $destName = if ($f -eq 'brief-draft.yaml') { 'brief.yaml' } else { $f }
        Copy-Item $src (Join-Path $OutputDir $destName) -Force
    }
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

$maturity = Get-Content (Join-Path $SessionDir 'maturity.yaml') -Raw -ErrorAction SilentlyContinue
$readiness = '0'
if ($maturity -match 'overall_readiness:\s*([0-9.]+)') { $readiness = $Matches[1] }

$manifest = @"
slug: $Slug
exported_at: $((Get-Date).ToUniversalTime().ToString('o'))
package_completeness: partial
overall_readiness: $readiness
artifacts:
  - brief.yaml
  - functional-requirements.yaml
  - tier-matrix.yaml
  - scaffold/AGENTS.md
next_pr: forge-plan para architecture, roadmap, prompts avancados
"@
Set-Content (Join-Path $OutputDir 'PACKAGE_MANIFEST.yaml') -Value $manifest -Encoding UTF8

Write-Host "Exportado: outputs/$Slug/" -ForegroundColor Green
