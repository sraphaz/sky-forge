#Requires -Version 5.1
<#
.SYNOPSIS
  Catálogo embutido de pontos de interação (espelho de .agents/interaction-points.yaml).
  Dot-source: . (Join-Path $PSScriptRoot 'interaction-catalog.ps1')
#>

function Get-SkyInteractionCatalog {
    return @{
        'arrival.intent' = @{
            prompt = 'O que você quer fazer no Sky-Forge agora?'
            options = @(
                @{ id = 'new_idea'; label = 'Começar ideia nova (intake)'; routes_to = 'intake-conductor' }
                @{ id = 'resume'; label = 'Retomar sessão existente'; routes_to = 'sky-host' }
                @{ id = 'brownfield_repo'; label = 'Analisar / anexar repositório existente'; routes_to = 'intake-conductor' }
                @{ id = 'status_only'; label = 'Só ver status de um projeto'; routes_to = 'sky-host' }
            )
        }
        'brownfield.path_confirm' = @{
            prompt = 'Qual repositório devemos usar?'
            options = @(
                @{ id = 'current_workspace'; label = 'Este workspace aberto no Cursor' }
                @{ id = 'paste_path'; label = 'Vou informar o caminho' }
                @{ id = 'cancel'; label = 'Cancelar por agora' }
            )
        }
        'brownfield.after_attach' = @{
            prompt = 'Host plugin anexado. Próximo passo?'
            options = @(
                @{ id = 'run_assess'; label = 'Rodar assessment do repositório' }
                @{ id = 'deepen_problem'; label = 'Contar o problema de evolução (intake)'; routes_to = 'intake-conductor' }
                @{ id = 'status'; label = 'Ver maturidade / status' }
                @{ id = 'later'; label = 'Parar por aqui' }
            )
        }
        'assess.next_action' = @{
            prompt = 'Assessment pronto. O que prefere agora?'
            options = @(
                @{ id = 'deepen_top_gap'; label = 'Aprofundar a principal lacuna detectada'; routes_to = 'intake-conductor' }
                @{ id = 'seed_roadmap'; label = 'Gerar roadmap de evolução (draft)' }
                @{ id = 'elevate'; label = 'Explorar elevação / índices SKY'; routes_to = 'sky-elevator' }
                @{ id = 'status'; label = 'Só revisar o status' }
            )
        }
        'intake.deepen_gap' = @{
            prompt = 'Qual lacuna quer aprofundar agora?'
            options = @(
                @{ id = 'business'; label = 'Negócio / problema / stakeholders' }
                @{ id = 'product'; label = 'Produto / jornadas / requisitos' }
                @{ id = 'ux'; label = 'UX / acessibilidade' }
                @{ id = 'something_else'; label = 'Outra coisa (vou digitar)' }
            )
        }
        'elevate.confirm' = @{
            prompt = 'Quer explorar conexões de elevação (opcional)?'
            options = @(
                @{ id = 'explore'; label = 'Sim, explorar sugestões'; routes_to = 'sky-elevator' }
                @{ id = 'skip'; label = 'Não agora — seguir no produto'; routes_to = 'intake-conductor' }
                @{ id = 'disable'; label = 'Prefiro não elevar neste projeto' }
            )
        }
        'gate.approve_stage' = @{
            prompt = 'Há um gate humano pendente. Como seguir?'
            options = @(
                @{ id = 'approve'; label = 'Aprovar este stage agora' }
                @{ id = 'explain'; label = 'Explicar o que o gate protege' }
                @{ id = 'defer'; label = 'Deixar para depois' }
            )
        }
        'deliver.export_scope' = @{
            prompt = 'Como quer o pacote de entrega?'
            options = @(
                @{ id = 'partial'; label = 'Parcial (pronto para handoff cedo)' }
                @{ id = 'full'; label = 'Completo (quando readiness permitir)' }
                @{ id = 'for_ai'; label = 'Pacote para IA (-ForAI)' }
                @{ id = 'cancel'; label = 'Ainda não exportar' }
            )
        }
        'showcase.privacy' = @{
            prompt = 'Sobre privacidade do preview público…'
            options = @(
                @{ id = 'private_only'; label = 'Manter privado (só máquina / pasta externa)' }
                @{ id = 'public_ok'; label = 'Autorizo publish -Public no showcase' }
                @{ id = 'ask_later'; label = 'Decidir depois' }
            )
        }
        'implement.agentic_repo' = @{
            prompt = 'Recomendamos ARAH Harness neste repo. Quer instalar antes do scaffold/link?'
            options = @(
                @{ id = 'install_arah'; label = 'Sim — orientar instalação do ARAH Harness' }
                @{ id = 'skip_arah'; label = 'Seguir sem ARAH por agora' }
                @{ id = 'explain'; label = 'Explicar o que é o ARAH Harness' }
            )
        }
    }
}

function Format-SkyPendingInteractionYaml {
    param(
        [Parameter(Mandatory = $true)][string]$PointId,
        [Parameter(Mandatory = $true)][string]$Prompt,
        [Parameter(Mandatory = $true)]$Options,
        [string]$Status = 'pending',
        [string]$Channel = 'ask_question',
        [string]$ChoiceId = '',
        [string]$ChoiceLabel = '',
        [string]$CreatedAt = '',
        [string]$ResolvedAt = ''
    )
    if (-not $CreatedAt) {
        $CreatedAt = (Get-Date).ToUniversalTime().ToString('o')
    }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('pending_interaction:')
    [void]$sb.AppendLine("  id: $PointId")
    [void]$sb.AppendLine("  status: $Status")
    [void]$sb.AppendLine("  channel: $Channel")
    [void]$sb.AppendLine("  created_at: `"$CreatedAt`"")
    if ($ResolvedAt) {
        [void]$sb.AppendLine("  resolved_at: `"$ResolvedAt`"")
    } else {
        [void]$sb.AppendLine('  resolved_at: null')
    }
    if ($ChoiceId) {
        [void]$sb.AppendLine("  choice_id: $ChoiceId")
    } else {
        [void]$sb.AppendLine('  choice_id: null')
    }
    if ($ChoiceLabel) {
        $safe = $ChoiceLabel -replace '"', ''''
        [void]$sb.AppendLine("  choice_label: `"$safe`"")
    } else {
        [void]$sb.AppendLine('  choice_label: null')
    }
    $promptSafe = ($Prompt -replace '"', '''')
    [void]$sb.AppendLine("  prompt: `"$promptSafe`"")
    [void]$sb.AppendLine('  options:')
    foreach ($opt in $Options) {
        [void]$sb.AppendLine("    - id: $($opt.id)")
        $lbl = ($opt.label -replace '"', '''')
        [void]$sb.AppendLine("      label: `"$lbl`"")
        if ($opt.routes_to) {
            [void]$sb.AppendLine("      routes_to: $($opt.routes_to)")
        }
        if ($opt.command) {
            [void]$sb.AppendLine("      command: `"$($opt.command)`"")
        }
    }
    return $sb.ToString().TrimEnd()
}

function Set-SkyJourneyPendingInteraction {
    param(
        [Parameter(Mandatory = $true)][string]$JourneyPath,
        [Parameter(Mandatory = $true)][string]$PendingYamlBlock,
        [string[]]$NextActionsYamlLines = @()
    )
    if (-not (Test-Path $JourneyPath)) {
        throw "journey.yaml nao encontrado: $JourneyPath"
    }
    $now = (Get-Date).ToUniversalTime().ToString('o')
    $lines = @(Get-Content $JourneyPath)
    $out = New-Object System.Collections.Generic.List[string]
    $i = 0
    $skipBlock = $null
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        if ($line -match '^pending_interaction\s*:') {
            $i++
            while ($i -lt $lines.Count -and ($lines[$i] -match '^\s' -or $lines[$i] -match '^\s*$')) {
                if ($lines[$i] -match '^\s*$') {
                    $j = $i + 1
                    while ($j -lt $lines.Count -and $lines[$j] -match '^\s*$') { $j++ }
                    if ($j -lt $lines.Count -and $lines[$j] -match '^[a-zA-Z_]') { break }
                }
                $i++
            }
            continue
        }
        if ($line -match '^next_suggested_actions\s*:' -and $NextActionsYamlLines.Count -gt 0) {
            $i++
            while ($i -lt $lines.Count -and ($lines[$i] -match '^\s' -or $lines[$i] -match '^\s*$')) {
                if ($lines[$i] -match '^\s*$') {
                    $j = $i + 1
                    while ($j -lt $lines.Count -and $lines[$j] -match '^\s*$') { $j++ }
                    if ($j -lt $lines.Count -and $lines[$j] -match '^[a-zA-Z_]') { break }
                }
                $i++
            }
            $out.Add('next_suggested_actions:')
            foreach ($l in $NextActionsYamlLines) { $out.Add($l) }
            $out.Add('')
            continue
        }
        if ($line -match '^updated_at:') {
            $out.Add("updated_at: $now")
            $i++
            continue
        }
        $out.Add($line)
        $i++
    }

    $hasNext = $false
    foreach ($l in $out) { if ($l -match '^next_suggested_actions:') { $hasNext = $true; break } }
    if ($NextActionsYamlLines.Count -gt 0 -and -not $hasNext) {
        $insertAt = $out.Count
        for ($k = 0; $k -lt $out.Count; $k++) {
            if ($out[$k] -match '^notes:') { $insertAt = $k; break }
        }
        $block = New-Object System.Collections.Generic.List[string]
        $block.Add('next_suggested_actions:')
        foreach ($l in $NextActionsYamlLines) { $block.Add($l) }
        $block.Add('')
        $out.InsertRange($insertAt, $block)
    }

    while ($out.Count -gt 0 -and $out[$out.Count - 1] -match '^\s*$') {
        $out.RemoveAt($out.Count - 1)
    }
    $out.Add('')
    foreach ($l in ($PendingYamlBlock -split '\r?\n')) {
        $out.Add($l)
    }
    $text = (($out -join "`n").TrimEnd() + "`n")
    Set-Content -Path $JourneyPath -Value $text -Encoding UTF8
}

function Clear-SkyJourneyPendingInteraction {
    param([Parameter(Mandatory = $true)][string]$JourneyPath)
    if (-not (Test-Path $JourneyPath)) { return }
    $now = (Get-Date).ToUniversalTime().ToString('o')
    $lines = @(Get-Content $JourneyPath)
    $out = New-Object System.Collections.Generic.List[string]
    $i = 0
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        if ($line -match '^pending_interaction\s*:') {
            $i++
            while ($i -lt $lines.Count -and ($lines[$i] -match '^\s' -or $lines[$i] -match '^\s*$')) {
                if ($lines[$i] -match '^\s*$') {
                    $j = $i + 1
                    while ($j -lt $lines.Count -and $lines[$j] -match '^\s*$') { $j++ }
                    if ($j -lt $lines.Count -and $lines[$j] -match '^[a-zA-Z_]') { break }
                }
                $i++
            }
            continue
        }
        if ($line -match '^updated_at:') {
            $out.Add("updated_at: $now")
            $i++
            continue
        }
        $out.Add($line)
        $i++
    }
    Set-Content -Path $JourneyPath -Value (($out -join "`n").TrimEnd() + "`n") -Encoding UTF8
}
