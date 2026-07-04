#Requires -Version 5.1
<#
.SYNOPSIS
  Gera preview sanitizado para o showcase a partir do pacote exportado.
.EXAMPLE
  ./scripts/sky/publish-preview.ps1 -Slug iautos
  $env:SKY_OUTPUTS_DIR = 'C:\sky-projects'; ./scripts/sky/publish-preview.ps1 -Slug iautos
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [switch]$Public
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'get-sky-config.ps1')

function Read-YamlField([string]$Content, [string]$Field) {
    if ($Content -match "(?m)^$Field`:\s*(.+)$") { return $Matches[1].Trim() }
    return $null
}

function Read-YamlBlock([string]$Content, [string]$Field) {
    $lines = $Content -split "`r?`n"
    $block = [System.Collections.Generic.List[string]]::new()
    $inBlock = $false
    $fieldPattern = "^$([regex]::Escape($Field))`:\s*\|\s*$"
    foreach ($line in $lines) {
        if ($line -match $fieldPattern) { $inBlock = $true; continue }
        if ($inBlock) {
            if ($line -match '^  (.+)$') { $block.Add($Matches[1]) }
            elseif ($line -match '^\S') { break }
        }
    }
    if ($block.Count -eq 0) { return $null }
    return ($block -join "`n").Trim()
}

function Read-YamlList([string]$Content, [string]$Field) {
    $lines = $Content -split "`r?`n"
    $items = [System.Collections.Generic.List[string]]::new()
    $inList = $false
    $fieldPattern = "^$([regex]::Escape($Field))`:\s*$"
    foreach ($line in $lines) {
        if ($line -match $fieldPattern) { $inList = $true; continue }
        if ($inList) {
            if ($line -match '^  - (.+)$') { $items.Add($Matches[1].Trim()) }
            elseif ($line -match '^\S') { break }
        }
    }
    return @($items)
}

function Read-YamlItems([string]$Content, [string]$RootField, [string[]]$ItemFields) {
    $lines = $Content -split "`r?`n"
    $items = [System.Collections.Generic.List[hashtable]]::new()
    $current = $null
    $inRoot = $false
    $rootPattern = "^$([regex]::Escape($RootField))`:\s*$"
    foreach ($line in $lines) {
        if ($line -match $rootPattern) { $inRoot = $true; continue }
        if (-not $inRoot) { continue }
        if ($line -match '^  - id:\s*(\S+)\s*$') {
            if ($current) { $items.Add($current) }
            $current = @{ id = $Matches[1] }
            continue
        }
        if ($line -match '^\S') { break }
        if ($current -and $line -match '^\s{4}(\w+):\s*(.+)$') {
            $key = $Matches[1]
            if ($ItemFields -contains $key) {
                $val = $Matches[2].Trim().Trim('"').Trim("'")
                if ($val -eq 'true') { $val = $true }
                elseif ($val -eq 'false') { $val = $false }
                elseif ($val -eq 'null') { continue }
                $current[$key] = $val
            }
        }
    }
    if ($current) { $items.Add($current) }
    return @($items)
}

function Read-DimensionScores([string]$Maturity) {
    $dims = @{}
    foreach ($d in @('business', 'product', 'ux_design', 'technical', 'sustainability', 'elevation')) {
        if ($Maturity -match "(?ms)$d`:\s*\r?\n(?:[^\r\n]+\r?\n)*?\s+score:\s*([0-9.]+)") {
            $dims[$d] = [double]$Matches[1]
        }
    }
    return $dims
}

function Read-Indices([string]$Merits) {
    $idx = @{}
    foreach ($i in @('SPI', 'HCE', 'GAP', 'CWB', 'UXD')) {
        if ($Merits -match "(?ms)$i`:\s*\r?\n\s+score:\s*(\d+)") {
            $idx[$i] = [int]$Matches[1]
        }
    }
    return $idx
}

function Read-Phases([string]$Roadmap) {
    $phases = @()
    $matches = [regex]::Matches($Roadmap, '(?ms)- id:\s*(\S+)\s*\r?\n\s+title:\s*(.+?)\s*\r?\n(?:[^\r\n]+\r?\n)*?\s+status:\s*(\S+)')
    foreach ($m in $matches) {
        $phases += @{
            id = $m.Groups[1].Value
            title = $m.Groups[2].Value.Trim()
            status = $m.Groups[3].Value
        }
    }
    return $phases
}

function Read-Pipeline([string]$Maturity) {
    $items = @()
    $matches = [regex]::Matches($Maturity, '(?ms)^  (\w+):\s*\r?\n(?:[^\r\n]+\r?\n)*?\s+approved:\s*(true|false)')
    foreach ($m in $matches) {
        $items += @{
            stage = $m.Groups[1].Value
            approved = ($m.Groups[2].Value -eq 'true')
        }
    }
    return $items
}

function Resolve-SkyDataFile([string]$Slug, [string]$OutputName, [string]$SessionName) {
    $outputDir = Get-SkyOutputDirForSlug $Slug
    $sessionDir = Join-Path (Get-SkyRepoRoot) ".sky\sessions\$Slug"
    foreach ($p in @(
            (Join-Path $outputDir $OutputName),
            (Join-Path $sessionDir $SessionName)
        )) {
        if (Test-Path $p) { return Get-Content $p -Raw }
    }
    return ''
}

function Read-YamlRequirementItems([string]$Content) {
    return Read-YamlItems $Content 'requirements' @('title', 'description', 'category', 'statement', 'priority', 'mvp', 'epic', 'source')
}

function Read-Integrations([string]$Content) {
    $raw = Read-YamlItems $Content 'integrations' @('type', 'required', 'ai_recommendation', 'user_choice', 'reason')
    return @($raw | ForEach-Object {
        @{
            id = $_.id
            type = $_.type
            provider = if ($_.user_choice -and $_.user_choice -ne 'pending' -and $_.user_choice -ne 'delegated') { $_.user_choice } else { $_.ai_recommendation }
            required = [bool]$_.required
            reason = $_.reason
        }
    })
}

function Read-UxSummary([string]$Content) {
    if (-not $Content) { return $null }
    $principles = Read-YamlList $Content 'principles'
    $screens = @()
    $lines = $Content -split "`r?`n"
    $inScreens = $false
    $currentId = $null
    foreach ($line in $lines) {
        if ($line -match '^key_screens:\s*$') { $inScreens = $true; continue }
        if ($inScreens) {
            if ($line -match '^\S' -and $line -notmatch '^  ') { break }
            if ($line -match '^  - id:\s*(\S+)\s*$') { $currentId = $Matches[1]; continue }
            if ($currentId -and $line -match '^\s{4}title:\s*(.+)$') {
                $screens += @{ id = $currentId; title = $Matches[1].Trim() }
                $currentId = $null
            }
        }
    }
    return @{
        principles = $principles
        key_screens = $screens
    }
}

$OutputDir = Get-SkyOutputDirForSlug $Slug
$SessionDir = Join-Path (Get-SkyRepoRoot) ".sky\sessions\$Slug"
if (-not (Test-Path $OutputDir) -and -not (Test-Path $SessionDir)) {
    throw "Pacote ou sessao nao encontrados para '$Slug' (exporte ou rode intake)"
}
if (-not (Test-Path $OutputDir)) {
    $OutputDir = $null
    Write-Host "Usando sessao local (.sky/sessions/$Slug) — export recomendado para pacote completo." -ForegroundColor Yellow
}

$brief = Resolve-SkyDataFile $Slug 'brief.yaml' 'brief-draft.yaml'
$maturity = Resolve-SkyDataFile $Slug 'maturity.yaml' 'maturity.yaml'
$merits = Resolve-SkyDataFile $Slug 'sky-merits.yaml' 'sky-merits.yaml'
$roadmap = Resolve-SkyDataFile $Slug 'roadmap/phases.yaml' 'roadmap/phases.yaml'
$functional = Resolve-SkyDataFile $Slug 'functional-requirements.yaml' 'functional-requirements.yaml'
$nfr = Resolve-SkyDataFile $Slug 'nfr.yaml' 'nfr.yaml'
$integrations = Resolve-SkyDataFile $Slug 'integrations.yaml' 'integrations.yaml'
$uxSpec = Resolve-SkyDataFile $Slug 'ux-spec.yaml' 'ux-spec.yaml'

$title = Read-YamlField $brief 'title'
if (-not $title) { $title = $Slug }
$excerpt = Read-YamlBlock $brief 'value_proposition'
if (-not $excerpt) { $excerpt = Read-YamlBlock $brief 'problem' }
if ($excerpt) {
    $excerpt = ($excerpt -split "`n" | Select-Object -First 3) -join ' '
    if ($excerpt.Length -gt 220) { $excerpt = $excerpt.Substring(0, 217) + '...' }
}

$readiness = Read-YamlField $maturity 'overall_readiness'
$skyScore = Read-YamlField $merits 'sky_score'
$elevation = Read-YamlField $merits 'elevation_level'
$tier = Read-YamlField $brief 'tier'

$tags = Read-YamlList $brief 'app_types'

$vision = [ordered]@{
    problem = Read-YamlBlock $brief 'problem'
    motivation = Read-YamlBlock $brief 'motivation'
    value_proposition = Read-YamlBlock $brief 'value_proposition'
    primary_users = @(Read-YamlList $brief 'primary_users')
    mvp_scope = Read-YamlBlock $brief 'mvp_scope'
    out_of_scope = @(Read-YamlList $brief 'out_of_scope')
    reference_tenant = Read-YamlField $brief 'reference_tenant'
}

$functionalReqs = Read-YamlRequirementItems $functional | ForEach-Object {
    @{
        id = $_.id
        title = $_.title
        epic = $_.epic
        priority = $_.priority
        mvp = [bool]$_.mvp
    }
}

$nfrReqs = Read-YamlRequirementItems $nfr | ForEach-Object {
    @{
        id = $_.id
        category = $_.category
        statement = $_.statement
    }
}

$uxSummary = Read-UxSummary $uxSpec

$preview = [ordered]@{
    slug = $Slug
    title = $title
    excerpt = $excerpt
    tier = $tier
    sky_score = if ($skyScore) { [int]$skyScore } else { $null }
    readiness = if ($readiness) { [double]$readiness } else { $null }
    elevation_level = $elevation
    tags = $tags
    vision = $vision
    requirements = @{
        functional = @($functionalReqs)
        non_functional = @($nfrReqs)
    }
    architecture = @{
        integrations = @(Read-Integrations $integrations)
        ux = $uxSummary
    }
    indices = Read-Indices $merits
    dimensions = Read-DimensionScores $maturity
    phases = Read-Phases $roadmap
    pipeline = Read-Pipeline $maturity
    artifacts = @(
        @{ label = 'Brief'; type = 'yaml'; path = 'brief.yaml' }
        @{ label = 'Requisitos'; type = 'yaml'; path = 'functional-requirements.yaml' }
        @{ label = 'NFR'; type = 'yaml'; path = 'nfr.yaml' }
        @{ label = 'Integrações'; type = 'yaml'; path = 'integrations.yaml' }
        @{ label = 'UX'; type = 'yaml'; path = 'ux-spec.yaml' }
        @{ label = 'Maturidade'; type = 'yaml'; path = 'maturity.yaml' }
        @{ label = 'Roadmap'; type = 'yaml'; path = 'roadmap/phases.yaml' }
        @{ label = 'Cloud Design'; type = 'cloud-design'; path = 'cloud-design/' }
    )
    public = [bool]$Public
    published_at = (Get-Date).ToUniversalTime().ToString('o')
    outputs_dir = $OutputDir
}

$registryDir = Get-SkyRegistryDir
New-Item -ItemType Directory -Path $registryDir -Force | Out-Null
$previewPath = Join-Path $registryDir "$Slug.preview.json"
$preview | ConvertTo-Json -Depth 10 | Set-Content $previewPath -Encoding UTF8

# Atualizar index.json
$indexPath = Join-Path $registryDir 'index.json'
$index = @{ version = '1.0'; projects = @() }
if (Test-Path $indexPath) {
    $index = Get-Content $indexPath -Raw | ConvertFrom-Json
    if (-not $index.projects) { $index.projects = @() }
}
$existing = @($index.projects | Where-Object { $_.slug -ne $Slug })
$prev = @($index.projects | Where-Object { $_.slug -eq $Slug } | Select-Object -First 1)
$isPublic = [bool]$Public
if (-not $Public -and $prev -and $prev.public -eq $true) { $isPublic = $true }
$entry = [ordered]@{
    slug = $Slug
    title = $title
    excerpt = $excerpt
    tier = $tier
    sky_score = $preview.sky_score
    readiness = $preview.readiness
    elevation_level = $elevation
    tags = $tags
    preview_file = "$Slug.preview.json"
    agents_file = "$Slug.agents.json"
    public = $isPublic
}
$index.projects = @($existing) + @($entry)
@{ version = '1.0'; projects = $index.projects } | ConvertTo-Json -Depth 10 | Set-Content $indexPath -Encoding UTF8

Write-Host "Preview publicado: $previewPath" -ForegroundColor Green
Write-Host "Indice atualizado: $indexPath"

$agentsScript = Join-Path $PSScriptRoot 'publish-agents-view.ps1'
if (Test-Path $agentsScript) {
    & $agentsScript -Slug $Slug
}
