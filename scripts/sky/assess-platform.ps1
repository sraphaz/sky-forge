#Requires -Version 5.1
<#
.SYNOPSIS
  Varre repo brownfield e gera platform-assessment.yaml + atualiza maturidade inicial.
.EXAMPLE
  ./scripts/sky/sky.ps1 assess -Slug minha-plataforma -WorkspacePath C:\repos\app
  cd C:\repos\app && ./scripts/sky.ps1 assess
#>
param(
    [Parameter()]
    [string]$Slug,

    [Parameter()]
    [string]$WorkspacePath = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'get-sky-config.ps1')
. (Join-Path $PSScriptRoot 'resolve-sky-link.ps1')

$ctx = Get-SkyLinkContext -StartPath $WorkspacePath -Slug $Slug
if (-not $ctx) {
    throw 'Nenhuma ligacao host — rode sky attach -WorkspacePath <repo> primeiro.'
}
$Slug = $ctx.Slug
$workspace = $ctx.WorkspacePath
if (-not $workspace) { $workspace = (Resolve-Path $WorkspacePath).Path }

$sessionDir = Join-Path $ctx.ForgeRoot ".sky\sessions\$Slug"
if (-not (Test-Path $sessionDir)) { throw "Sessao nao encontrada: $Slug" }

function Test-PathAny {
    param([string]$Root, [string[]]$Patterns)
    foreach ($p in $Patterns) {
        $full = Join-Path $Root $p
        if (Test-Path $full) { return $true }
        $glob = Get-ChildItem -Path $Root -Recurse -Filter (Split-Path $p -Leaf) -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($glob) { return $true }
    }
    return $false
}

function Get-ReadmeExcerpt {
    param([string]$Root)
    $readme = @('README.md', 'readme.md', 'Readme.md') | ForEach-Object { Join-Path $Root $_ } | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $readme) { return $null }
    $lines = Get-Content $readme -TotalCount 40 -ErrorAction SilentlyContinue
    return ($lines -join "`n").Trim()
}

function Get-StackSignals {
    param([string]$Root)
    $signals = @()
    $checks = @(
        @{ file = 'package.json'; stack = 'node'; lang = 'javascript/typescript' }
        @{ file = 'pnpm-lock.yaml'; stack = 'node'; lang = 'javascript/typescript' }
        @{ file = 'pyproject.toml'; stack = 'python'; lang = 'python' }
        @{ file = 'requirements.txt'; stack = 'python'; lang = 'python' }
        @{ file = 'Cargo.toml'; stack = 'rust'; lang = 'rust' }
        @{ file = 'go.mod'; stack = 'go'; lang = 'go' }
        @{ file = 'pom.xml'; stack = 'jvm'; lang = 'java/kotlin' }
        @{ file = 'build.gradle.kts'; stack = 'jvm'; lang = 'java/kotlin' }
        @{ file = 'composer.json'; stack = 'php'; lang = 'php' }
        @{ file = 'Gemfile'; stack = 'ruby'; lang = 'ruby' }
    )
    foreach ($c in $checks) {
        if (Test-Path (Join-Path $Root $c.file)) {
            $signals += [PSCustomObject]@{ file = $c.file; stack = $c.stack; language = $c.lang }
        }
    }
    return $signals
}

function Count-Files {
    param([string]$Root, [string]$Pattern)
    if (-not (Test-Path $Root)) { return 0 }
    return @(Get-ChildItem -Path $Root -Recurse -Filter $Pattern -File -ErrorAction SilentlyContinue).Count
}

$now = (Get-Date).ToUniversalTime().ToString('o')
$stacks = Get-StackSignals -Root $workspace
$hasCi = Test-PathAny -Root $workspace -Patterns @('.github/workflows', '.gitlab-ci.yml', 'azure-pipelines.yml', 'Jenkinsfile')
$hasDocs = Test-Path (Join-Path $workspace 'docs')
$hasAgents = Test-Path (Join-Path $workspace 'AGENTS.md')
$hasSpec = Test-Path (Join-Path $workspace 'spec')
$hasCursorRules = Test-Path (Join-Path $workspace '.cursor/rules')
$testCount = (Count-Files -Root $workspace -Pattern '*test*') + (Count-Files -Root $workspace -Pattern '*spec.*')
$readme = Get-ReadmeExcerpt -Root $workspace

try {
    $gitHead = git -C $workspace rev-parse HEAD 2>$null
} catch { $gitHead = $null }

$evidenceScore = 0.0
if ($readme) { $evidenceScore += 0.12 }
if ($hasDocs) { $evidenceScore += 0.18 }
if ($hasCi) { $evidenceScore += 0.15 }
if ($stacks.Count -gt 0) { $evidenceScore += 0.15 }
if ($testCount -gt 0) { $evidenceScore += [Math]::Min(0.20, $testCount * 0.02) }
if ($hasAgents) { $evidenceScore += 0.10 }
if ($hasSpec) { $evidenceScore += 0.10 }
$evidenceScore = [Math]::Round([Math]::Min(0.85, $evidenceScore), 2)

$techScore = if ($stacks.Count -gt 0) { 0.35 } else { 0.10 }
$techScore += if ($hasCi) { 0.20 } else { 0 }
$techScore += if ($testCount -gt 5) { 0.25 } elseif ($testCount -gt 0) { 0.10 } else { 0 }
$techScore = [Math]::Round([Math]::Min(0.75, $techScore), 2)

$productScore = if ($readme) { 0.30 } else { 0.08 }
$productScore += if ($hasDocs) { 0.25 } else { 0 }
$productScore = [Math]::Round([Math]::Min(0.60, $productScore), 2)

$gaps = @()
if (-not $readme) { $gaps += 'README ausente ou vazio' }
if (-not $hasDocs) { $gaps += 'pasta docs/ não encontrada' }
if (-not $hasCi) { $gaps += 'CI não detectado' }
if ($testCount -eq 0) { $gaps += 'nenhum arquivo de teste detectado' }
if (-not $hasSpec) { $gaps += 'spec/ ainda não sincronizada do forge' }
if ($stacks.Count -eq 0) { $gaps += 'stack não identificada (package.json, pyproject, etc.)' }

$stackNames = ($stacks | ForEach-Object { $_.stack }) -join ', '
if (-not $stackNames) { $stackNames = 'unknown' }

$assessmentPath = Join-Path $sessionDir 'platform-assessment.yaml'
$assessmentYaml = @"
version: "0.1"
slug: $Slug
assessed_at: $now
intake_mode: brownfield_host
profile: platform-evolution

baseline:
  workspace_path: $($workspace -replace '\\', '/')
  git_commit: $(if ($gitHead) { $gitHead } else { 'null' })
  stacks_detected:
$(if ($stacks.Count -eq 0) { "    - stack: unknown`n      language: unknown" } else { ($stacks | ForEach-Object { "    - stack: $($_.stack)`n      signal: $($_.file)`n      language: $($_.language)" }) -join "`n" })

signals:
  has_readme: $(if ($readme) { 'true' } else { 'false' })
  has_docs: $hasDocs
  has_ci: $hasCi
  has_agents_md: $hasAgents
  has_spec_sync: $hasSpec
  has_cursor_rules: $hasCursorRules
  test_file_count: $testCount

evidence_score: $evidenceScore
readme_excerpt: |
$(if ($readme) { ($readme -split "`n" | ForEach-Object { "  $_" }) -join "`n" } else { '  null' })

maturity_hints:
  technical: $techScore
  product: $productScore
  sustainability: $(if ($hasCi) { 0.25 } else { 0.08 })

gaps_detected:
$(($gaps | ForEach-Object { "  - $_" }) -join "`n")

next_recommended:
  - agent: intake-conductor
    action: confirmar problema de evolucao e stakeholders
  - agent: sky-elevator
    action: elevar apos baseline confirmado (gate baseline_confirmed)
  - cli: ./scripts/sky.ps1 status
"@

Set-Content -Path $assessmentPath -Value $assessmentYaml -Encoding UTF8

$maturityPath = Join-Path $sessionDir 'maturity.yaml'
if (Test-Path $maturityPath) {
    $mRaw = Get-Content $maturityPath -Raw
    $overall = [Math]::Round(($techScore * 0.35 + $productScore * 0.30 + $evidenceScore * 0.35), 2)
    $mRaw = $mRaw -replace '(?m)^updated_at:\s*.+$', "updated_at: `"$now`""
    $mRaw = $mRaw -replace '(?m)^overall_readiness:\s*[0-9.]+', "overall_readiness: $overall"
    $mRaw = $mRaw -replace '(?m)^  technical:\s*\n    level:\s*\d+\s*\n    score:\s*[0-9.]+', "  technical:`n    level: $(if ($techScore -ge 0.4) { 1 } else { 0 })`n    score: $techScore"
    $mRaw = $mRaw -replace '(?m)^  product:\s*\n    level:\s*\d+\s*\n    score:\s*[0-9.]+', "  product:`n    level: $(if ($productScore -ge 0.35) { 1 } else { 0 })`n    score: $productScore"
    if ($mRaw -notmatch 'intake_mode:') {
        $mRaw = $mRaw -replace '(?m)^slug:\s*.+$', "`$0`nintake_mode: brownfield_host`nprofile: platform-evolution"
    }
    Set-Content -Path $maturityPath -Value $mRaw -Encoding UTF8
}

$hostCopy = Join-Path $workspace 'integrations\sky-forge\platform-assessment.yaml'
if (Test-Path (Split-Path $hostCopy -Parent)) {
    Copy-Item $assessmentPath $hostCopy -Force
}

Write-Host "Assessment: $assessmentPath" -ForegroundColor Green
Write-Host "  evidence_score: $evidenceScore | technical: $techScore | product: $productScore"
Write-Host "  stacks: $stackNames | gaps: $($gaps.Count)"
if ($gaps.Count -gt 0) {
    $gaps | ForEach-Object { Write-Host "    - $_" -ForegroundColor DarkYellow }
}
