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
    $snap = Get-SkyPendingInteractionSnapshot -JourneyRaw $raw
    $pointKey = if ($PointId) { $PointId } elseif ($snap.id) { $snap.id } else { 'unknown' }

    $opts = @()
    if ($OptionsJson) {
        $opts = @($OptionsJson | ConvertFrom-Json)
    } elseif ($catalog.ContainsKey($pointKey)) {
        $opts = @($catalog[$pointKey].options)
    }

    $match = $null
    if ($opts.Count -gt 0) {
        $match = $opts | Where-Object { $_.id -eq $ChoiceId } | Select-Object -First 1
    }
    if (-not $match) {
        $known = if ($opts.Count -gt 0) {
            ($opts | ForEach-Object { $_.id }) -join ', '
        } elseif ($snap.option_ids.Count -gt 0) {
            $snap.option_ids -join ', '
        } else {
            '(nenhuma)'
        }
        throw "ChoiceId invalido: '$ChoiceId' para o ponto '$pointKey'. Opcoes: $known"
    }

    $choiceLabel = $match.label
    # Preservar prompt e created_at do pending em disco (ex.: override do assess)
    $resolvedPrompt = if ($snap.prompt) { $snap.prompt } elseif ($catalog.ContainsKey($pointKey)) { $catalog[$pointKey].prompt } else { 'Decisao registrada.' }
    $createdAt = if ($snap.created_at) { $snap.created_at } else { (Get-Date).ToUniversalTime().ToString('o') }
    $resolvedChannel = if ($snap.channel) { $snap.channel } else { $Channel }
    $now = (Get-Date).ToUniversalTime().ToString('o')

    # Opcoes no bloco resolved: preferir catalogo (com command) se o ponto existir
    if ($catalog.ContainsKey($pointKey)) {
        $opts = @($catalog[$pointKey].options)
    }

    $block = Format-SkyPendingInteractionYaml -PointId $pointKey -Prompt $resolvedPrompt -Options $opts `
        -Status 'resolved' -Channel $resolvedChannel -ChoiceId $ChoiceId -ChoiceLabel $choiceLabel `
        -CreatedAt $createdAt -ResolvedAt $now

    $nextLines = Format-SkyOptionNextActionLines -Option $match -Slug $Slug
    Set-SkyJourneyPendingInteraction -JourneyPath $journeyPath -PendingYamlBlock $block `
        -NextActionsYamlLines $nextLines -ReplaceNextActions

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
        created_at = $createdAt
        resolved_at = $now
        routes_to = $(if ($match.routes_to) { $match.routes_to } else { $null })
        command = $(if ($match.command) { ($match.command -replace '\{slug\}', $Slug) } else { $null })
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

# Nao substituir next_suggested_actions ao abrir pending — preserva hints da sessao
Set-SkyJourneyPendingInteraction -JourneyPath $journeyPath -PendingYamlBlock $block

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
            $o = [ordered]@{ id = $_.id; label = $_.label }
            if ($_.routes_to) { $o.routes_to = $_.routes_to }
            if ($_.command) { $o.command = $_.command }
            $o
        })
    fallback = [ordered]@{
        format = 'numbered_chat'
        instruction = 'Se AskQuestion indisponivel, listar 1..N no chat sky-host e pedir o numero.'
    }
    agent_instruction = 'Chamar AskQuestion AGORA com este prompt/options. Nao prosseguir side effects ate o usuario responder.'
}
$askPayload | ConvertTo-Json -Depth 6
