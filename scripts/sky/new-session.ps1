#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$SessionDir = Join-Path $RepoRoot ".sky\sessions\$Slug"
$TemplateDir = Join-Path $RepoRoot 'templates\sessions\example-horta'

if ($Slug -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
    throw "Slug invalido: use kebab-case (ex: minha-ideia)"
}

if (Test-Path $SessionDir) {
    Write-Warning "Sessao ja existe: $SessionDir — use intake resume no Cursor."
    exit 0
}

New-Item -ItemType Directory -Path $SessionDir -Force | Out-Null

$now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

$files = @(
    'maturity.yaml',
    'brief-draft.yaml',
    'functional-requirements.yaml',
    'nfr.yaml',
    'integrations.yaml',
    'alternatives.yaml',
    'approvals.yaml',
    'sky-merits.yaml',
    'ux-spec.yaml',
    'journey.yaml'
)

foreach ($f in $files) {
    $dest = Join-Path $SessionDir $f
    $src = Join-Path $TemplateDir $f
    if (Test-Path $src) {
        $content = Get-Content $src -Raw
        $content = $content -replace 'example-horta', $Slug
        $content = $content -replace 'example-horta', $Slug
        if ($f -eq 'maturity.yaml') {
            $content = $content -replace 'overall_readiness: 0\.42', 'overall_readiness: 0.05'
            $content = $content -replace 'conversation_level: product', 'conversation_level: explore'
            $content = $content -replace 'score: 0\.82', 'score: 0.05'
            $content = $content -replace 'score: 0\.55', 'score: 0.0'
            $content = $content -replace 'score: 0\.25', 'score: 0.0'
            $content = $content -replace 'score: 0\.10', 'score: 0.0'
            $content = $content -replace 'level: 2', 'level: 0'
            $content = $content -replace 'level: 1', 'level: 0'
        }
        if ($f -eq 'brief-draft.yaml') {
            $content = @"
id: $Slug
title: ""
problem: ""
motivation: ""
primary_users: []
value_proposition: ""
mvp_scope: ""
out_of_scope: []
tier: undecided
app_types: []
institutional_site: null
constraints: {}
"@
        }
        if ($f -eq 'functional-requirements.yaml') {
            $content = "requirements: []`n"
        }
        if ($f -eq 'integrations.yaml') {
            $content = "integrations: []`n"
        }
        if ($f -eq 'sky-merits.yaml') {
            $content = @"
version: "1.0"
slug: $Slug
sky_score: 0
elevation_level: ground
policies:
  open_to_elevation: true
  open_to_humanity_connections: true
  open_to_ux_dignity_review: true
indices:
  SPI: { score: 0, rationale: "" }
  HCE: { score: 0, rationale: "" }
  GAP: { score: 0, rationale: "" }
  CWB: { score: 0, rationale: "" }
  UXD: { score: 0, rationale: "" }
elevation_suggestions: []
humanity_connections: []
"@
        }
        if ($f -eq 'ux-spec.yaml') {
            $content = @"
version: "1.0"
slug: $Slug
principles: [mobile_first, wcag_2_1_aa, low_excitation]
key_screens: []
"@
        }
        if ($f -eq 'alternatives.yaml') {
            $content = @"
policies:
  open_to_stack_alternatives: true
  open_to_scope_changes: true
  open_to_tier_upgrade: true
  open_to_ai_recommendation: true
  max_alternatives_per_topic: 3
pending_suggestions: []
"@
        }
        if ($f -eq 'journey.yaml') {
            $content = @"
version: "1.0"
slug: $Slug
current_phase: arrival
updated_at: $now

user_preferences:
  communication_style: concise
  outputs_location: default
  public_showcase: undecided

phase_history:
  - phase: arrival
    at: $now
    agent: sky-host

next_suggested_actions:
  - id: start_intake
    label: Contar sua ideia em linguagem natural
    agent: intake-conductor
  - id: brownfield
    label: Trouxe material existente (zip, docs, mockup)
    agent: intake-conductor

notes: |
  Criado pelo sky-intake. sky-host conduz a experiência.
"@
        }
        Set-Content -Path $dest -Value $content -Encoding UTF8 -NoNewline
    }
}

$maturityPath = Join-Path $SessionDir 'maturity.yaml'
if (Test-Path $maturityPath) {
    $m = Get-Content $maturityPath -Raw
    $m = $m -replace 'updated_at: "[^"]+"', "updated_at: `"$now`""
    Set-Content -Path $maturityPath -Value $m -Encoding UTF8 -NoNewline
}

Write-Host "OK: sessao $Slug em $SessionDir"
