#Requires -Version 5.1
<#
.SYNOPSIS
  Avalia se ARAH Harness é recomendação plausível para a sessão e persiste agentic-repo-recommendation.yaml
.EXAMPLE
  ./scripts/sky/suggest-agentic-repo.ps1 -Slug minha-ideia
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [Parameter()]
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'get-sky-config.ps1')

$repoRoot = Get-SkyRepoRoot
$sessionDir = Join-Path $repoRoot ".sky\sessions\$Slug"
if (-not (Test-Path $sessionDir)) { throw "Sessao nao encontrada: $Slug" }

$catalogPath = Join-Path $repoRoot 'docs\recommendations\agentic-repo.catalog.yaml'
if (-not (Test-Path $catalogPath)) { throw "Catalogo ausente: $catalogPath" }

$catalogRaw = Get-Content $catalogPath -Raw
$productId = 'arah-harness'
if ($catalogRaw -match 'default_recommendation:\s*(\S+)') { $productId = $Matches[1].Trim() }

function Read-SessionFile([string]$Name) {
    $p = Join-Path $sessionDir $Name
    if (Test-Path $p) { return Get-Content $p -Raw }
    return ''
}

function Get-BriefAppTypes([string]$BriefRaw) {
    $types = @()
    if ($BriefRaw -match '(?ms)app_types:\s*\r?\n((?:\s+-\s*.+\r?\n)+)') {
        foreach ($line in ($Matches[1] -split '\r?\n')) {
            if ($line -match '^\s+-\s*(.+)\s*$') { $types += $Matches[1].Trim().Trim('"').Trim("'") }
        }
    }
    return $types
}

$briefRaw = Read-SessionFile 'brief-draft.yaml'
$maturityRaw = Read-SessionFile 'maturity.yaml'
$journeyRaw = Read-SessionFile 'journey.yaml'
$frRaw = Read-SessionFile 'functional-requirements.yaml'
$agentArchRaw = Read-SessionFile 'architecture\agent-architecture.md'

$matchedStrong = @()
$matchedModerate = @()
$blockers = @()

# Hard excludes
if ($briefRaw -match '(?m)static_only:\s*true') {
    $blockers += 'static_only_explicit'
}

$appTypes = Get-BriefAppTypes $briefRaw
$hasCodeIntent = ($appTypes.Count -gt 0) -or (Test-Path (Join-Path $sessionDir 'git.yaml')) -or ($briefRaw -match 'target_repo')

if ($appTypes.Count -eq 1 -and $appTypes[0] -eq 'institutional_site' -and -not (Test-Path (Join-Path $sessionDir 'git.yaml'))) {
    if (-not ($briefRaw -match 'target_repo') -and $maturityRaw -notmatch 'conversation_level:\s*(technical|sustainability|delivery)') {
        $blockers += 'spec_only_static_landing'
    }
}

# Strong signals
if (Test-Path (Join-Path $sessionDir 'architecture\specs\agent-harness.spec.yaml')) {
    $matchedStrong += 'agent_harness_spec'
}
if ($agentArchRaw -and $agentArchRaw -notmatch 'N/A \(site estático\)' -and $agentArchRaw -notmatch 'Status:\*\* N/A') {
    if ($agentArchRaw -match 'agent|harness|copilot') { $matchedStrong += 'agent_architecture_active' }
}
$combinedText = $briefRaw + "`n" + $frRaw
if ($briefRaw -match '(?ms)out_of_scope:\s*\r?\n(.+?)(?:\r?\n[a-z_]+:|\z)') {
    $combinedText = $combinedText -replace [regex]::Escape($Matches[1]), ''
}
# Ignorar menções a projetos do portfólio (arah-harness como repo, não intenção do produto)
$filteredLines = ($combinedText -split '\r?\n') | Where-Object {
    $_ -notmatch 'arah-harness' -and
    $_ -notmatch 'github\.com' -and
    $_ -notmatch 'listando arah-harness' -and
    $_ -notmatch 'ARAH Harness, Sky-Forge'
}
$filteredText = ($filteredLines -join "`n")
$agenticIntentPatterns = @(
    'oper[aá]veis por agentes',
    'gerenciados por agentes',
    'agentic repo',
    'agentic software',
    'agent graph',
    'multi-agente',
    'multi-agent',
    'copilot',
    'harness spec',
    'harness de agentes',
    'orquestra[cç][aã]o multi-agente'
)
$hasAgenticIntent = $false
foreach ($pat in $agenticIntentPatterns) {
    if ($filteredText -match $pat) { $hasAgenticIntent = $true; break }
}
if ($hasAgenticIntent) {
    $matchedStrong += 'agentic_intent'
}
$platformTypes = @('platform', 'saas', 'api', 'mobile_app', 'web_app', 'multi_tenant', 'legaltech', 'agentic_product')
foreach ($t in $appTypes) {
    if ($platformTypes -contains $t) { $matchedStrong += 'app_platform'; break }
}

# Moderate signals
if ($maturityRaw -match 'technical:\s*\r?\n(?:[^\r\n]+\r?\n)*?\s+score:\s*([0-9.]+)') {
    if ([double]$Matches[1] -ge 0.50) { $matchedModerate += 'technical_maturity' }
}
if ($maturityRaw -match 'conversation_level:\s*(technical|sustainability|delivery)') {
    $matchedModerate += 'sustainability_phase'
}
if ($journeyRaw -match 'current_phase:\s*(implement|specify|deliver)') {
    $matchedModerate += 'implement_phase'
}
if (Test-Path (Join-Path $sessionDir 'git.yaml')) {
    $matchedModerate += 'workspace_linked'
}
if ($appTypes -contains 'institutional_site' -or $appTypes -contains 'web_app') {
    $matchedModerate += 'code_app_type'
}
if (Test-Path (Join-Path $sessionDir 'architecture\agents')) {
    $matchedModerate += 'architecture_folder'
}

# Decide tier
$tier = 'not_applicable'
$plausible = $false
$reason = ''

if ($blockers.Count -gt 0 -and $matchedStrong.Count -eq 0) {
    $tier = 'not_applicable'
    $reason = "Bloqueado: $($blockers -join ', ')."
} elseif ($matchedStrong.Count -ge 1) {
    $tier = 'recommended'
    $plausible = $true
    $reason = "Sinais fortes: $($matchedStrong -join ', ')."
} elseif ($matchedModerate.Count -ge 2 -or ($matchedModerate -contains 'workspace_linked')) {
    $tier = 'suggested'
    $plausible = $true
    $reason = "Sinais moderados: $($matchedModerate -join ', ')."
} elseif ($hasCodeIntent -and $matchedModerate.Count -ge 1) {
    $tier = 'suggested'
    $plausible = $true
    $reason = "Repo de código previsto; sinal: $($matchedModerate -join ', ')."
} else {
    $reason = 'Perfil ainda exploratório ou landing sem repo agentic.'
}

# Site institucional: cap em suggested salvo harness spec ou arquitetura agêntica ativa
if ($tier -eq 'recommended' -and $appTypes.Count -eq 1 -and $appTypes[0] -eq 'institutional_site') {
    if ($matchedStrong -notcontains 'agent_harness_spec' -and $matchedStrong -notcontains 'agent_architecture_active') {
        $tier = 'suggested'
        $reason = "Repo de site — ARAH Harness plausível para implementação/manutenção. $($reason)"
    }
}

$localHarness = $env:ARAH_HARNESS_PATH
if (-not $localHarness) {
    $sibling = Join-Path (Split-Path $repoRoot -Parent) 'arah-harness'
    if (Test-Path $sibling) { $localHarness = $sibling }
}

$now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$outPath = Join-Path $sessionDir 'agentic-repo-recommendation.yaml'

$strongYaml = ($matchedStrong | ForEach-Object { "`"$_`"" }) -join ', '
$moderateYaml = ($matchedModerate | ForEach-Object { "`"$_`"" }) -join ', '
$blockersYaml = ($blockers | ForEach-Object { "`"$_`"" }) -join ', '

$yaml = @"
version: "1.0"
slug: $Slug
generated_at: $now
generated_by: suggest-agentic-repo.ps1
ai_suggested: true

product:
  id: $productId
  name: ARAH Harness
  repo: https://github.com/sraphaz/arah-harness
  local_path: $(if ($localHarness) { ($localHarness -replace '\\', '/') } else { 'null' })
  catalog: docs/recommendations/agentic-repo.catalog.yaml

plausible: $($plausible.ToString().ToLower())
tier: $tier
reason: "$($reason -replace '"', '\"')"

signals:
  strong: [$strongYaml]
  moderate: [$moderateYaml]
  blockers: [$blockersYaml]

install:
  summary: "Bootstrap agentic repo com specs, .agents/, CI e coreografia"
  steps:
    - "git clone https://github.com/sraphaz/arah-harness (ou usar ARAH_HARNESS_PATH)"
    - "No repo-alvo: arah.ps1 install -ProjectName {slug}"
    - "Editar arah.config.yaml; arah.ps1 domain sync; doctor"
  sky_link: "./scripts/sky/sky.ps1 link -Slug $Slug -WorkspacePath <app-repo> -PullSpec"

presentation:
  recommended: "Recomendamos instalar ARAH Harness neste repo antes do scaffold."
  suggested: "Plausível usar ARAH Harness para manter o repo com agentes, specs e CI."
"@

Set-Content $outPath -Value $yaml -Encoding UTF8

if (-not $Quiet) {
    $color = switch ($tier) {
        'recommended' { 'Green' }
        'suggested' { 'Yellow' }
        default { 'DarkGray' }
    }
    Write-Host "Agentic repo [$Slug]: tier=$tier plausible=$plausible" -ForegroundColor $color
    Write-Host "  $reason" -ForegroundColor DarkGray
    if ($plausible) {
        Write-Host "  -> agentic-repo-recommendation.yaml" -ForegroundColor DarkGray
    }
}

return @{
    Tier      = $tier
    Plausible = $plausible
    Path      = $outPath
}
