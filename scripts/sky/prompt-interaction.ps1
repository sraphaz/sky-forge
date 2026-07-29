#Requires -Version 5.1
<#
.SYNOPSIS
  Grava / resolve / limpa pending_interaction em journey.yaml e imprime payload para o agente.
.EXAMPLE
  ./scripts/sky/prompt-interaction.ps1 -Slug minha-ideia -PointId arrival.intent
  ./scripts/sky/prompt-interaction.ps1 -Slug minha-ideia -Resolve -ChoiceId new_idea
  ./scripts/sky/prompt-interaction.ps1 -Slug minha-ideia -Clear
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [Parameter()]
    [string]$PointId,

    [Parameter()]
    [string]$Prompt,

    [Parameter()]
    [string]$OptionsJson,

    [Parameter()]
    [switch]$Clear,

    [Parameter()]
    [switch]$Resolve,

    [Parameter()]
    [string]$ChoiceId,

    [Parameter()]
    [string]$Channel = 'ask_question',

    [Parameter()]
    [switch]$NoAudit
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
. (Join-Path $PSScriptRoot 'interaction-catalog.ps1')

$sessionDir = Join-Path $RepoRoot ".sky\sessions\$Slug"
$journeyPath = Join-Path $sessionDir 'journey.yaml'
if (-not (Test-Path $journeyPath)) {
    throw "Sessao nao encontrada: $Slug (faltando journey.yaml)"
}

$rec = Join-Path $PSScriptRoot 'record-agent-event.ps1'

if ($Clear) {
    Clear-SkyJourneyPendingInteraction -JourneyPath $journeyPath
    if (-not $NoAudit -and (Test-Path $rec)) {
        & $rec -Slug $Slug -AgentId 'sky-host' -Action 'human.interaction.cleared' -Outcome 'ok' -AutonomyLevel 'route' -Details 'pending_interaction cleared' -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Host "OK: pending_interaction limpo em $Slug" -ForegroundColor Green
    return
}

$catalog = Get-SkyInteractionCatalog

if ($Resolve) {
    if (-not $ChoiceId) { throw 'Resolve requer -ChoiceId' }
    $raw = Get-Content $journeyPath -Raw
    $existingId = 'unknown'
    if ($raw -match '(?m)^pending_interaction:\s*\r?\n(?:  .*\r?\n)*?  id:\s*(\S+)') {
        $existingId = $Matches[1]
    }
    $choiceLabel = $ChoiceId
    $pointKey = if ($PointId) { $PointId } else { $existingId }
    if ($catalog.ContainsKey($pointKey)) {
        $match = $catalog[$pointKey].options | Where-Object { $_.id -eq $ChoiceId } | Select-Object -First 1
        if ($match) { $choiceLabel = $match.label }
        $Prompt = $catalog[$pointKey].prompt
        $opts = $catalog[$pointKey].options
    } elseif ($OptionsJson) {
        $opts = $OptionsJson | ConvertFrom-Json
    } else {
        $opts = @(@{ id = $ChoiceId; label = $ChoiceId })
    }
    if (-not $Prompt) { $Prompt = 'Decisao registrada.' }
    $now = (Get-Date).ToUniversalTime().ToString('o')
    $block = Format-SkyPendingInteractionYaml -PointId $pointKey -Prompt $Prompt -Options $opts `
        -Status 'resolved' -Channel $Channel -ChoiceId $ChoiceId -ChoiceLabel $choiceLabel `
        -CreatedAt $now -ResolvedAt $now
    Set-SkyJourneyPendingInteraction -JourneyPath $journeyPath -PendingYamlBlock $block
    if (-not $NoAudit -and (Test-Path $rec)) {
        & $rec -Slug $Slug -AgentId 'sky-host' -Action 'human.interaction.answered' -Outcome 'ok' `
            -AutonomyLevel 'route' -Details "point=$pointKey choice=$ChoiceId" -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Host "OK: interacao resolvida ($pointKey -> $ChoiceId)" -ForegroundColor Green
    $payload = [ordered]@{
        slug = $Slug
        point_id = $pointKey
        status = 'resolved'
        choice_id = $ChoiceId
        choice_label = $choiceLabel
        agent_instruction = 'Seguir routes_to/comando do option escolhido; uma acao apenas.'
    }
    $payload | ConvertTo-Json -Depth 5
    return
}

if (-not $PointId -and -not $Prompt) {
    throw 'Informe -PointId (catalogo) ou -Prompt + -OptionsJson'
}

$opts = $null
if ($PointId) {
    if (-not $catalog.ContainsKey($PointId)) {
        throw "PointId desconhecido: $PointId. Veja .agents/interaction-points.yaml"
    }
    $entry = $catalog[$PointId]
    if (-not $Prompt) { $Prompt = $entry.prompt }
    $opts = $entry.options
}
if ($OptionsJson) {
    $opts = @($OptionsJson | ConvertFrom-Json)
}
if (-not $opts -or $opts.Count -eq 0) {
    throw 'Nenhuma opcao para a interacao'
}

$now = (Get-Date).ToUniversalTime().ToString('o')
$block = Format-SkyPendingInteractionYaml -PointId $(if ($PointId) { $PointId } else { 'custom' }) `
    -Prompt $Prompt -Options $opts -Status 'pending' -Channel $Channel -CreatedAt $now

$nextLines = @()
$i = 0
foreach ($opt in $opts) {
    $i++
    $nextLines += "  - id: $($opt.id)"
    $nextLines += "    label: `"$($opt.label -replace '"', '''')`""
    if ($opt.routes_to) { $nextLines += "    agent: $($opt.routes_to)" }
}

Set-SkyJourneyPendingInteraction -JourneyPath $journeyPath -PendingYamlBlock $block -NextActionsYamlLines $nextLines

if (-not $NoAudit -and (Test-Path $rec)) {
    & $rec -Slug $Slug -AgentId 'sky-host' -Action 'human.interaction.requested' -Outcome 'pending' `
        -AutonomyLevel 'route' -Details "point=$PointId" -ErrorAction SilentlyContinue | Out-Null
}

Write-Host "OK: pending_interaction=$PointId em $Slug" -ForegroundColor Green
Write-Host ""
Write-Host "=== ASK_QUESTION_PAYLOAD (para o agente Cursor) ===" -ForegroundColor Cyan
$askPayload = [ordered]@{
    tool = 'AskQuestion'
    slug = $Slug
    point_id = $PointId
    prompt = $Prompt
    options = @($opts | ForEach-Object {
            [ordered]@{ id = $_.id; label = $_.label }
        })
    fallback = [ordered]@{
        format = 'numbered_chat'
        instruction = 'Se AskQuestion indisponivel, listar 1..N no chat sky-host e pedir o numero.'
    }
    agent_instruction = 'Chamar AskQuestion AGORA com este prompt/options. Nao prosseguir side effects ate o usuario responder.'
}
$askPayload | ConvertTo-Json -Depth 6
