#Requires -Version 5.1
<#
.SYNOPSIS
  Gera SKY_AI_CONTEXT.md — contexto sanitizado do projeto, pronto para colar
  em Cursor, Claude, ChatGPT ou pipeline CI.
.DESCRIPTION
  Escopos (SKY_APP_UX.md — fluxo "Exportar para IA"):
    essential — brief + RFs do MVP (top 10) + indices SKY + principios de UX
    spec      — essential + NFRs, integracoes, maturidade e roadmap
    full      — spec + alternativas e manifest do pacote completo
  Sanitizacao: paths absolutos viram <repo>/<outputs>/<home>; prototipos
  proprietarios (.dc.html) viram referencia, nunca conteudo.
.EXAMPLE
  ./scripts/sky/export-for-ai.ps1 -Slug iautos -Scope essential
  ./scripts/sky/sky.ps1 export -Slug iautos -ForAI -Scope spec
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [Parameter()]
    [ValidateSet('essential', 'spec', 'full')]
    [string]$Scope = 'essential'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'get-sky-config.ps1')

$RepoRoot = Get-SkyRepoRoot
$SessionDir = Join-Path $RepoRoot ".sky\sessions\$Slug"
$OutputDir = Get-SkyOutputDirForSlug $Slug

if (-not (Test-Path $SessionDir) -and -not (Test-Path $OutputDir)) {
    throw "Sessao ou pacote nao encontrados para '$Slug' — rode intake ou export primeiro."
}

function Resolve-DataFile([string]$OutputName, [string]$SessionName) {
    foreach ($p in @((Join-Path $OutputDir $OutputName), (Join-Path $SessionDir $SessionName))) {
        if (Test-Path $p) { return Get-Content $p -Raw }
    }
    return $null
}

function Read-YamlField([string]$Content, [string]$Field) {
    if ($Content -and $Content -match "(?m)^$Field`:\s*(.+)$") { return $Matches[1].Trim().Trim('"').Trim("'") }
    return $null
}

function Get-MvpRequirements([string]$Content, [int]$Max = 10) {
    if (-not $Content) { return @() }
    $items = @()
    $blocks = [regex]::Split($Content, '(?m)^  - id:\s*')
    foreach ($block in ($blocks | Select-Object -Skip 1)) {
        $lines = $block -split "`r?`n"
        $req = @{ id = $lines[0].Trim() }
        foreach ($line in $lines) {
            if ($line -match '^\s{4}(title|description|priority|epic|mvp):\s*(.+)$') {
                $req[$Matches[1]] = $Matches[2].Trim().Trim('"').Trim("'")
            }
        }
        if ($req['mvp'] -eq 'true') { $items += $req }
        if ($items.Count -ge $Max) { break }
    }
    return @($items)
}

function Sanitize([string]$Text) {
    if (-not $Text) { return $Text }
    $t = $Text -replace [regex]::Escape("$RepoRoot"), '<repo>'
    $t = $t -replace [regex]::Escape("$OutputDir"), '<outputs>'
    if ($env:USERPROFILE) { $t = $t -replace [regex]::Escape($env:USERPROFILE), '<home>' }
    # Prototipos Cloud Design sao proprietarios — referencia, nunca conteudo/caminho
    $t = ($t -split "`r?`n" | ForEach-Object {
        if ($_ -match '\.dc\.html') { $_ -replace '[^\s:"]*\.dc\.html', '[prototipo Cloud Design - omitido]' } else { $_ }
    }) -join "`n"
    return $t
}

function Add-YamlSection([System.Text.StringBuilder]$Sb, [string]$Title, [string]$Content, [string]$Hint = $null) {
    if (-not $Content) { return }
    [void]$Sb.AppendLine("## $Title")
    [void]$Sb.AppendLine()
    if ($Hint) { [void]$Sb.AppendLine($Hint); [void]$Sb.AppendLine() }
    [void]$Sb.AppendLine('```yaml')
    [void]$Sb.AppendLine($Content.TrimEnd())
    [void]$Sb.AppendLine('```')
    [void]$Sb.AppendLine()
}

# --- Coleta ---------------------------------------------------------------
$brief = Resolve-DataFile 'brief.yaml' 'brief-draft.yaml'
$merits = Resolve-DataFile 'sky-merits.yaml' 'sky-merits.yaml'
$uxSpec = Resolve-DataFile 'ux-spec.yaml' 'ux-spec.yaml'
$functional = Resolve-DataFile 'functional-requirements.yaml' 'functional-requirements.yaml'
$nfr = Resolve-DataFile 'nfr.yaml' 'nfr.yaml'
$integrations = Resolve-DataFile 'integrations.yaml' 'integrations.yaml'
$maturity = Resolve-DataFile 'maturity.yaml' 'maturity.yaml'
$roadmap = Resolve-DataFile 'roadmap/phases.yaml' 'roadmap/phases.yaml'
$alternatives = Resolve-DataFile 'alternatives.yaml' 'alternatives.yaml'
$manifest = Resolve-DataFile 'PACKAGE_MANIFEST.yaml' '__none__'

$title = Read-YamlField $brief 'title'
if (-not $title) { $title = $Slug }
$skyScore = Read-YamlField $merits 'sky_score'
$specVersion = Read-YamlField $merits 'spec_version'
$now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

# --- Montagem -------------------------------------------------------------
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("# SKY_AI_CONTEXT — $title")
[void]$sb.AppendLine()
[void]$sb.AppendLine("| Campo | Valor |")
[void]$sb.AppendLine("|-------|-------|")
[void]$sb.AppendLine("| Slug | ``$Slug`` |")
[void]$sb.AppendLine("| Escopo | $Scope |")
if ($skyScore) { [void]$sb.AppendLine("| SKY Score (intencao) | $skyScore |") }
if ($specVersion) { [void]$sb.AppendLine("| Espec SKY | v$specVersion |") }
[void]$sb.AppendLine("| Gerado em | $now |")
[void]$sb.AppendLine()
[void]$sb.AppendLine("> Contexto sanitizado gerado pelo Sky-Forge para uso em ferramentas de IA.")
[void]$sb.AppendLine("> Paths absolutos e prototipos proprietarios foram removidos.")
[void]$sb.AppendLine()

# Essential — brief + indices + RFs MVP + UX
Add-YamlSection $sb 'Brief' $brief
Add-YamlSection $sb 'Indices SKY (sky-merits)' $merits 'Scores de intencao com evidencia tipada e confianca — ver espec SKY (CC BY-SA).'

$mvpReqs = Get-MvpRequirements $functional
if ($Scope -eq 'essential' -and $mvpReqs.Count -gt 0) {
    [void]$sb.AppendLine('## Requisitos funcionais do MVP (top 10)')
    [void]$sb.AppendLine()
    foreach ($r in $mvpReqs) {
        $line = "- **$($r.id)** — $($r.title)"
        if ($r.epic) { $line += " _(epic $($r.epic), $($r.priority))_" }
        [void]$sb.AppendLine($line)
        if ($r.description) { [void]$sb.AppendLine("  $($r.description)") }
    }
    [void]$sb.AppendLine()
}
if ($Scope -ne 'essential') {
    Add-YamlSection $sb 'Requisitos funcionais (completo)' $functional
}
Add-YamlSection $sb 'Especificacao UX (principios e tokens)' $uxSpec

# Spec — + NFRs, integracoes, maturidade, roadmap
if ($Scope -in @('spec', 'full')) {
    Add-YamlSection $sb 'Requisitos nao funcionais' $nfr
    Add-YamlSection $sb 'Integracoes' $integrations
    Add-YamlSection $sb 'Maturidade' $maturity
    Add-YamlSection $sb 'Roadmap do projeto' $roadmap
}

# Full — + alternativas e manifest do pacote
if ($Scope -eq 'full') {
    Add-YamlSection $sb 'Alternativas e politicas' $alternatives
    Add-YamlSection $sb 'Manifest do pacote' $manifest 'Pacote completo (scaffold, prompts, Cloud Design) fica na pasta de outputs — nao neste arquivo.'
}

[void]$sb.AppendLine('---')
[void]$sb.AppendLine()
[void]$sb.AppendLine('_Gerado por `sky.ps1 export -ForAI` — Sky-Forge. A regua (espec, rubricas, harness) e aberta; nao cole dados de clientes neste contexto._')

$content = Sanitize $sb.ToString()

# --- Escrita --------------------------------------------------------------
$aiDir = Join-Path $OutputDir 'ai-export'
New-Item -ItemType Directory -Path $aiDir -Force | Out-Null
$outPath = Join-Path $aiDir 'SKY_AI_CONTEXT.md'
Set-Content -Path $outPath -Value $content -Encoding UTF8

$lineCount = ($content -split "`n").Count
Write-Host "Export para IA ($Scope): $outPath" -ForegroundColor Green
Write-Host "$lineCount linhas · $([math]::Round($content.Length / 1024, 1)) KB — pronto para colar na ferramenta de IA."
