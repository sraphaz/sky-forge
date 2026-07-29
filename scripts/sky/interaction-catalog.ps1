#Requires -Version 5.1
<#
.SYNOPSIS
  Catálogo de pontos de interação — fonte: .agents/interaction-points.yaml
  Dot-source: . (Join-Path $PSScriptRoot 'interaction-catalog.ps1')
#>

function Escape-SkyYamlDoubleQuoted {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return '' }
    # String.Replace — um '\' vira '\\' no scalar YAML entre aspas duplas
    $t = $Text.Replace('\', '\\')
    $t = $t.Replace('"', '\"')
    $t = $t.Replace("`r`n", '\n').Replace("`n", '\n').Replace("`r", '\n')
    return $t
}

function Unescape-SkyYamlDoubleQuoted {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return '' }
    # Passo unico L→R: \\n nao vira newline apos expandir \\
    $sb = New-Object System.Text.StringBuilder
    $chars = $Text.ToCharArray()
    $i = 0
    while ($i -lt $chars.Length) {
        if ($chars[$i] -eq '\' -and ($i + 1) -lt $chars.Length) {
            $next = $chars[$i + 1]
            if ($next -eq 'n') { [void]$sb.Append("`n"); $i += 2; continue }
            if ($next -eq '"') { [void]$sb.Append('"'); $i += 2; continue }
            if ($next -eq '\') { [void]$sb.Append('\'); $i += 2; continue }
        }
        [void]$sb.Append($chars[$i])
        $i++
    }
    return $sb.ToString()
}

function Skip-SkyYamlTopLevelKeyBlock {
    <#
    .SYNOPSIS
      Avanca o indice apos um bloco YAML top-level (chave + linhas indentadas).
    #>
    param(
        [Parameter(Mandatory = $true)][string[]]$Lines,
        [Parameter(Mandatory = $true)][int]$Index
    )
    $i = $Index + 1
    while ($i -lt $Lines.Count -and ($Lines[$i] -match '^\s' -or $Lines[$i] -match '^\s*$')) {
        if ($Lines[$i] -match '^\s*$') {
            $j = $i + 1
            while ($j -lt $Lines.Count -and $Lines[$j] -match '^\s*$') { $j++ }
            if ($j -lt $Lines.Count -and $Lines[$j] -match '^[a-zA-Z_]') { break }
        }
        $i++
    }
    return $i
}

function ConvertFrom-SkyInteractionPointsYaml {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    $lines = @(Get-Content -Path $Path -Encoding UTF8)
    $catalog = @{}
    $inPoints = $false
    $pointId = $null
    $prompt = $null
    $optList = @()
    $inOptions = $false
    $curOpt = $null

    foreach ($line in $lines) {
        if ($line -match '^\s*#') { continue }
        if (-not $inPoints) {
            if ($line -match '^points\s*:') { $inPoints = $true }
            continue
        }
        if ($line -match '^  - id:\s*(\S+)\s*$') {
            if ($pointId) {
                if ($null -ne $curOpt) { $optList += $curOpt; $curOpt = $null }
                $catalog[$pointId] = @{ prompt = $(if ($prompt) { $prompt } else { '' }); options = @($optList) }
            }
            $pointId = $Matches[1]
            $prompt = $null
            $optList = @()
            $inOptions = $false
            $curOpt = $null
            continue
        }
        if (-not $pointId) { continue }
        if ($line -match '^\s+prompt:\s*(.+)\s*$') {
            $prompt = $Matches[1].Trim().Trim('"').Trim("'")
            continue
        }
        if ($line -match '^\s+options(_fallback)?\s*:') {
            if ($null -ne $curOpt) { $optList += $curOpt; $curOpt = $null }
            $inOptions = $true
            continue
        }
        if ($inOptions -and $line -match '^\s+- id:\s*(\S+)\s*$') {
            if ($null -ne $curOpt) { $optList += $curOpt }
            $curOpt = @{ id = $Matches[1]; label = $Matches[1] }
            continue
        }
        if ($inOptions -and $null -ne $curOpt) {
            if ($line -match '^\s+label:\s*(.+)\s*$') {
                $curOpt.label = $Matches[1].Trim().Trim('"').Trim("'")
                continue
            }
            if ($line -match '^\s+routes_to:\s*(\S+)\s*$') {
                $curOpt.routes_to = $Matches[1]
                continue
            }
            if ($line -match '^\s+command:\s*(.+)\s*$') {
                $curOpt.command = $Matches[1].Trim().Trim('"').Trim("'")
                continue
            }
            if ($line -match '^\s+sets:\s*(.+)\s*$') {
                $curOpt.sets = $Matches[1].Trim().Trim('"').Trim("'")
                continue
            }
            if ($line -match '^\s+requires_gate:\s*(\S+)\s*$') {
                $curOpt.requires_gate = $Matches[1]
                continue
            }
        }
        if ($inOptions -and $line -match '^    [a-z_]' -and $line -notmatch '^\s+- ' -and $line -notmatch '^\s+(label|routes_to|command|sets|requires_gate):') {
            if ($null -ne $curOpt) { $optList += $curOpt; $curOpt = $null }
            $inOptions = $false
        }
    }
    if ($pointId) {
        if ($null -ne $curOpt) { $optList += $curOpt }
        $catalog[$pointId] = @{ prompt = $(if ($prompt) { $prompt } else { '' }); options = @($optList) }
    }
    if ($catalog.Count -eq 0) { return $null }
    return $catalog
}

function Get-SkyInteractionCatalogFallback {
    # Usado só se o YAML estiver ausente/ilegível
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
        'assess.next_action' = @{
            prompt = 'Assessment pronto. O que prefere agora?'
            options = @(
                @{ id = 'deepen_top_gap'; label = 'Aprofundar a principal lacuna detectada'; routes_to = 'intake-conductor' }
                @{ id = 'seed_roadmap'; label = 'Gerar roadmap de evolução (draft)'; command = './scripts/sky/sky.ps1 seed-roadmap -Slug {slug}' }
                @{ id = 'elevate'; label = 'Explorar elevação / índices SKY'; routes_to = 'sky-elevator' }
                @{ id = 'status'; label = 'Só revisar o status'; command = './scripts/sky/sky.ps1 status -Slug {slug}' }
            )
        }
        'brownfield.after_attach' = @{
            prompt = 'Host plugin anexado. Próximo passo?'
            options = @(
                @{ id = 'run_assess'; label = 'Rodar assessment do repositório'; command = './scripts/sky/sky.ps1 assess -Slug {slug} -WorkspacePath {workspace}' }
                @{ id = 'deepen_problem'; label = 'Contar o problema de evolução (intake)'; routes_to = 'intake-conductor' }
                @{ id = 'status'; label = 'Ver maturidade / status'; command = './scripts/sky/sky.ps1 status -Slug {slug}' }
                @{ id = 'later'; label = 'Parar por aqui' }
            )
        }
    }
}

function Get-SkyInteractionCatalog {
    $repoRoot = $null
    if ($PSScriptRoot) {
        $repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..') -ErrorAction SilentlyContinue
    }
    if ($repoRoot) {
        $yamlPath = Join-Path $repoRoot.Path '.agents\interaction-points.yaml'
        $fromYaml = ConvertFrom-SkyInteractionPointsYaml -Path $yamlPath
        if ($fromYaml -and $fromYaml.Count -gt 0) {
            return $fromYaml
        }
    }
    return Get-SkyInteractionCatalogFallback
}

function Get-SkyPendingInteractionSnapshot {
    <#
    .SYNOPSIS
      Lê campos do bloco pending_interaction atual em journey.yaml (texto bruto).
    #>
    param([Parameter(Mandatory = $true)][string]$JourneyRaw)

    $snap = @{
        id         = $null
        status     = $null
        prompt     = $null
        created_at = $null
        channel    = $null
        option_ids = @()
        options    = @()
    }

    if ($JourneyRaw -notmatch '(?m)^pending_interaction\s*:') { return $snap }

    $pendingChunk = $null
    if ($JourneyRaw -match '(?ms)^pending_interaction:\r?\n(.*?)(?=^[a-zA-Z_]|\z)') {
        $pendingChunk = $Matches[1]
    }
    if (-not $pendingChunk) { return $snap }

    if ($pendingChunk -match '(?m)^  id:\s*(\S+)') { $snap.id = $Matches[1].Trim() }
    if ($pendingChunk -match '(?m)^  status:\s*(\S+)') { $snap.status = $Matches[1].Trim() }
    if ($pendingChunk -match '(?m)^  channel:\s*(\S+)') { $snap.channel = $Matches[1].Trim() }
    if ($pendingChunk -match '(?m)^  created_at:\s*"([^"]+)"') {
        $snap.created_at = $Matches[1]
    } elseif ($pendingChunk -match '(?m)^  created_at:\s*(\S+)') {
        $snap.created_at = $Matches[1].Trim().Trim('"')
    }
    if ($pendingChunk -match '(?m)^  prompt:\s*"((?:\\.|[^"])*)"') {
        $snap.prompt = Unescape-SkyYamlDoubleQuoted $Matches[1]
    } elseif ($pendingChunk -match '(?m)^  prompt:\s*(.+)$') {
        $snap.prompt = $Matches[1].Trim().Trim('"')
    }

    $optList = @()
    $cur = $null
    foreach ($line in ($pendingChunk -split '\r?\n')) {
        if ($line -match '^    - id:\s*(\S+)') {
            if ($null -ne $cur) { $optList += $cur }
            $cur = @{ id = $Matches[1]; label = $Matches[1] }
            continue
        }
        if ($null -eq $cur) { continue }
        if ($line -match '^      label:\s*"((?:\\.|[^"])*)"') {
            $cur.label = Unescape-SkyYamlDoubleQuoted $Matches[1]
            continue
        }
        if ($line -match '^      label:\s*(.+)$') {
            $cur.label = $Matches[1].Trim().Trim('"')
            continue
        }
        if ($line -match '^      routes_to:\s*(\S+)') { $cur.routes_to = $Matches[1]; continue }
        if ($line -match '^      command:\s*"((?:\\.|[^"])*)"') {
            $cur.command = Unescape-SkyYamlDoubleQuoted $Matches[1]
            continue
        }
        if ($line -match '^      command:\s*(.+)$') {
            $cur.command = $Matches[1].Trim().Trim('"')
            continue
        }
        if ($line -match '^      sets:\s*"((?:\\.|[^"])*)"') {
            $cur.sets = Unescape-SkyYamlDoubleQuoted $Matches[1]
            continue
        }
        if ($line -match '^      sets:\s*(.+)$') {
            $cur.sets = $Matches[1].Trim().Trim('"')
            continue
        }
    }
    if ($null -ne $cur) { $optList += $cur }
    $snap.options = @($optList)
    $snap.option_ids = @($optList | ForEach-Object { $_.id })
    return $snap
}

function Expand-SkyCommandPlaceholders {
    param(
        [string]$Command,
        [string]$Slug = '',
        [string]$Workspace = '',
        [string]$Stage = ''
    )
    if ([string]::IsNullOrWhiteSpace($Command)) { return $Command }
    $cmd = $Command
    if ($Slug) { $cmd = $cmd.Replace('{slug}', $Slug) }
    if ($Workspace) { $cmd = $cmd.Replace('{workspace}', $Workspace) }
    if ($Stage) { $cmd = $cmd.Replace('{stage}', $Stage) }
    return $cmd
}

function Resolve-SkyInteractWorkspacePath {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$Slug,
        [string]$Explicit = ''
    )
    if ($Explicit) { return $Explicit }
    $gitPath = Join-Path $RepoRoot ".sky\sessions\$Slug\git.yaml"
    if (Test-Path $gitPath) {
        $raw = Get-Content $gitPath -Raw
        if ($raw -match '(?m)^workspace_path:\s*(.+)$') {
            $p = $Matches[1].Trim().Trim('"').Trim("'")
            if ($p -and $p -ne 'null') { return $p }
        }
    }
    return ''
}

function Resolve-SkyInteractStage {
    param(
        [string]$SessionDir,
        [string]$Explicit = ''
    )
    if ($Explicit) { return $Explicit }
    $approvals = Join-Path $SessionDir 'approvals.yaml'
    $order = @('brief', 'elevation', 'architecture', 'package', 'public_showcase')
    if (-not (Test-Path $approvals)) {
        return 'brief'
    }
    $raw = Get-Content $approvals -Raw
    # Isolar bloco stages: — nao confundir com outras chaves homonimas
    $stagesBlock = $raw
    if ($raw -match '(?ms)^stages:\s*\r?\n(.*?)(?=^[a-z_][a-z0-9_]*:\s*$|\z)') {
        $stagesBlock = $Matches[1]
    }
    foreach ($s in $order) {
        $approved = $false
        if ($stagesBlock -match "(?m)^\s+$([regex]::Escape($s)):\s*(.+)$") {
            $val = $Matches[1].Trim().Trim('"').Trim("'")
            # approve-stage.ps1 grava timestamp ISO; legado pode usar "approved …"
            if ($val -match 'approved' -or $val -match '\d{4}-\d{2}-\d{2}T') {
                $approved = $true
            }
        }
        if (-not $approved) { return $s }
    }
    # Todos aprovados — ultimo stage da fila (nao default "package")
    return 'public_showcase'
}

function Get-SkyMaturityTopGapOptions {
    param([Parameter(Mandatory = $true)][string]$MaturityPath)
    if (-not (Test-Path $MaturityPath)) { return @() }
    $raw = Get-Content $MaturityPath -Raw
    # Isolar bloco dimensions: para nao ancorar em weights.<dim>
    $dimsSection = $null
    if ($raw -match '(?ms)^dimensions:\s*\r?\n(.*?)(?=^[a-z_][a-z0-9_]*:\s*$|\z)') {
        $dimsSection = $Matches[1]
    }
    if (-not $dimsSection) { return @() }

    $dimOrder = @('business', 'product', 'ux_design', 'technical', 'sustainability', 'elevation')
    $labels = @{
        business = 'Negócio'
        product = 'Produto'
        ux_design = 'UX'
        technical = 'Técnico'
        sustainability = 'Sustentação'
        elevation = 'Elevação'
    }
    $scored = @()
    foreach ($dim in $dimOrder) {
        $block = $null
        # Indent do nome da dimensao; propriedades devem ser mais indentadas (nao o proximo dim)
        $dimPat = "(?ms)^([ \t]+)$([regex]::Escape($dim)):\s*\r?\n((?:^\1[ \t]+.+\r?\n)*)"
        if ($dimsSection -match $dimPat) {
            $block = $Matches[2]
        }
        if (-not $block) { continue }
        $score = 1.0
        if ($block -match '(?m)^\s+score:\s*([0-9.]+)') {
            $score = [double]$Matches[1]
        }
        $gap = $null
        if ($block -match '(?m)^\s+gaps:\s*\[([^\]]*)\]') {
            $inner = $Matches[1]
            if ($inner -match '"([^"]+)"') { $gap = $Matches[1] }
            elseif ($inner -match "'([^']+)'") { $gap = $Matches[1] }
        }
        if (-not $gap) { continue }
        $scored += [PSCustomObject]@{ id = $dim; score = $score; gap = $gap; title = $labels[$dim] }
    }
    $top = @($scored | Sort-Object score | Select-Object -First 4)
    $opts = @()
    foreach ($t in $top) {
        $opts += @{
            id = $t.id
            label = "$($t.title): $($t.gap)"
        }
    }
    return $opts
}

function Apply-SkyOptionSets {
    param(
        [Parameter(Mandatory = $true)][string]$SessionDir,
        [string]$Sets
    )
    if ([string]::IsNullOrWhiteSpace($Sets)) { return }
    # policies.open_to_elevation=false
    if ($Sets -match '^policies\.([A-Za-z0-9_]+)=(.+)$') {
        $key = $Matches[1]
        $val = $Matches[2].Trim()
        $merits = Join-Path $SessionDir 'sky-merits.yaml'
        if (-not (Test-Path $merits)) { return }
        $raw = Get-Content $merits -Raw
        if ($raw -match "(?m)^(\s+)$([regex]::Escape($key)):\s*.+$") {
            $raw = [regex]::Replace($raw, "(?m)^(\s+)$([regex]::Escape($key)):\s*.+$", "`${1}${key}: $val")
        } elseif ($raw -match '(?m)^policies\s*:') {
            $raw = [regex]::Replace($raw, '(?m)^(policies\s*:)', "`$1`r`n  ${key}: $val")
        }
        Set-Content -Path $merits -Value $raw -Encoding UTF8
        Write-Host "OK: policies.$key = $val (sky-merits.yaml)" -ForegroundColor DarkCyan
    }
}

function Format-SkyOptionNextActionLines {
    param(
        [Parameter(Mandatory = $true)]$Option,
        [string]$Slug = '',
        [string]$Workspace = '',
        [string]$Stage = ''
    )
    $lines = @()
    $lines += "  - id: $($Option.id)"
    $lbl = Escape-SkyYamlDoubleQuoted $Option.label
    $lines += "    label: `"$lbl`""
    if ($Option.routes_to) { $lines += "    agent: $($Option.routes_to)" }
    if ($Option.command) {
        $cmd = Expand-SkyCommandPlaceholders -Command $Option.command -Slug $Slug -Workspace $Workspace -Stage $Stage
        $lines += "    command: `"$(Escape-SkyYamlDoubleQuoted $cmd)`""
    }
    return $lines
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
        $safe = Escape-SkyYamlDoubleQuoted $ChoiceLabel
        [void]$sb.AppendLine("  choice_label: `"$safe`"")
    } else {
        [void]$sb.AppendLine('  choice_label: null')
    }
    $promptSafe = Escape-SkyYamlDoubleQuoted $Prompt
    [void]$sb.AppendLine("  prompt: `"$promptSafe`"")
    [void]$sb.AppendLine('  options:')
    foreach ($opt in $Options) {
        [void]$sb.AppendLine("    - id: $($opt.id)")
        $lbl = Escape-SkyYamlDoubleQuoted $opt.label
        [void]$sb.AppendLine("      label: `"$lbl`"")
        if ($opt.routes_to) {
            [void]$sb.AppendLine("      routes_to: $($opt.routes_to)")
        }
        if ($opt.command) {
            $cmd = Escape-SkyYamlDoubleQuoted $opt.command
            [void]$sb.AppendLine("      command: `"$cmd`"")
        }
        if ($opt.sets) {
            $sets = Escape-SkyYamlDoubleQuoted $opt.sets
            [void]$sb.AppendLine("      sets: `"$sets`"")
        }
        if ($opt.requires_gate) {
            [void]$sb.AppendLine("      requires_gate: $($opt.requires_gate)")
        }
    }
    return $sb.ToString().TrimEnd()
}

function Set-SkyJourneyPendingInteraction {
    param(
        [Parameter(Mandatory = $true)][string]$JourneyPath,
        [Parameter(Mandatory = $true)][string]$PendingYamlBlock,
        [string[]]$NextActionsYamlLines = @(),
        [switch]$ReplaceNextActions
    )
    if (-not (Test-Path $JourneyPath)) {
        throw "journey.yaml nao encontrado: $JourneyPath"
    }
    $now = (Get-Date).ToUniversalTime().ToString('o')
    $lines = @(Get-Content $JourneyPath)
    $out = New-Object System.Collections.Generic.List[string]
    $i = 0
    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        if ($line -match '^pending_interaction\s*:') {
            $i = Skip-SkyYamlTopLevelKeyBlock -Lines $lines -Index $i
            continue
        }
        if ($line -match '^next_suggested_actions\s*:' -and $ReplaceNextActions -and $NextActionsYamlLines.Count -gt 0) {
            $i = Skip-SkyYamlTopLevelKeyBlock -Lines $lines -Index $i
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

    if ($ReplaceNextActions -and $NextActionsYamlLines.Count -gt 0) {
        $hasNext = $false
        foreach ($l in $out) { if ($l -match '^next_suggested_actions:') { $hasNext = $true; break } }
        if (-not $hasNext) {
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
            $i = Skip-SkyYamlTopLevelKeyBlock -Lines $lines -Index $i
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
