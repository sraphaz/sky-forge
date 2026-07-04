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
    foreach ($i in @('SPI', 'HCE', 'GAP', 'CWB', 'UXD', 'MPI')) {
        if ($Merits -match "(?ms)$i`:\s*\r?\n\s+score:\s*(\d+)") {
            $idx[$i] = [int]$Matches[1]
        }
    }
    return $idx
}

function Read-IndicesMeta([string]$Merits) {
    # Evidência e confiança por índice — "SPI 81 · 6 evidências" (SKY_INDICES_METHOD.md §3)
    $meta = @{}
    foreach ($i in @('SPI', 'HCE', 'GAP', 'CWB', 'UXD', 'MPI')) {
        if ($Merits -notmatch "(?m)^  $i`:\s*$\r?\n((?:[ \t]{4,}[^\r\n]*\r?\n?)*)") { continue }
        $block = $Matches[1]
        $entry = @{}
        if ($block -match '(?m)^\s+confidence:\s*(\S+)') { $entry['confidence'] = $Matches[1] }
        if ($block -match '(?m)^\s{4}evidence:\s*$\r?\n((?:[ \t]{6,}[^\r\n]*\r?\n?)*)') {
            $entry['evidence_count'] = @([regex]::Matches($Matches[1], '(?m)^\s+- ')).Count
        }
        if ($entry.Count -gt 0) { $meta[$i] = $entry }
    }
    return $meta
}

function Read-MarketBenchmark([string]$Benchmark) {
    # Resumo sanitizado do market-benchmark.yaml: MPI + nomes/urls e vereditos.
    # Notas de sobreposição e método ficam no artefato privado da sessão.
    if (-not $Benchmark) { return $null }
    $market = [ordered]@{}
    if ($Benchmark -match '(?ms)^mpi:\s*\r?\n\s+score:\s*(\d+)') { $market['mpi'] = [int]$Matches[1] }
    if ($Benchmark -match '(?ms)^mpi:.*?confidence:\s*(\S+)') { $market['confidence'] = $Matches[1] }
    if ($Benchmark -match '(?ms)^mpi:.*?band:\s*(\d+)') { $market['band'] = [int]$Matches[1] }

    $competitors = @()
    foreach ($m in [regex]::Matches($Benchmark, '(?ms)^  - name:\s*(.+?)\s*\r?\n\s+type:\s*(\S+)\s*\r?\n\s+url:\s*(\S+)')) {
        $competitors += @{
            name = $m.Groups[1].Value.Trim()
            type = $m.Groups[2].Value
            url = $m.Groups[3].Value
        }
    }
    if ($competitors.Count -gt 0) { $market['competitors'] = @($competitors) }

    $verdicts = @()
    foreach ($m in [regex]::Matches($Benchmark, '(?ms)^  - axis:\s*(.+?)\s*\r?\n\s+verdict:\s*(\S+)')) {
        $verdicts += @{
            axis = $m.Groups[1].Value.Trim()
            verdict = $m.Groups[2].Value
        }
    }
    if ($verdicts.Count -gt 0) { $market['verdicts'] = @($verdicts) }

    if ($market.Count -eq 0) { return $null }
    return $market
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

function Truncate-Text([string]$Text, [int]$Max = 280) {
    if (-not $Text) { return $null }
    $clean = ($Text -replace '\s+', ' ').Trim()
    if ($clean.Length -le $Max) { return $clean }
    return $clean.Substring(0, $Max - 3) + '...'
}

function Test-ArtifactPath([string]$OutputDir, [string]$RelativePath) {
    if (-not $OutputDir) { return $false }
    $full = Join-Path $OutputDir $RelativePath
    return Test-Path $full
}

function Read-TextHead([string]$OutputDir, [string]$RelativePath, [int]$Lines = 6) {
    if (-not (Test-ArtifactPath $OutputDir $RelativePath)) { return $null }
    $full = Join-Path $OutputDir $RelativePath
    $raw = Get-Content $full -Raw -ErrorAction SilentlyContinue
    if (-not $raw) { return $null }
    if ($RelativePath -match '\.(md|yaml|yml)$') {
        $picked = @($raw -split "`r?`n" | Where-Object {
            $line = $_.Trim()
            $line -ne '' -and
            $line -notmatch '^\s*#' -and
            $line -notmatch '^\|' -and
            $line -notmatch '^[-|:]+$'
        } | Select-Object -First $Lines)
        $head = ($picked -join ' ') -replace '\*\*([^*]+)\*\*', '$1'
        return Truncate-Text $head 320
    }
    return $null
}

function Read-ArtifactFile([string]$OutputDir, [string]$RelativePath) {
    if (-not (Test-ArtifactPath $OutputDir $RelativePath)) { return $null }
    $full = Join-Path $OutputDir $RelativePath
    $raw = Get-Content $full -Raw -ErrorAction SilentlyContinue
    if (-not $raw) { return $null }
    $max = 80000
    if ($raw.Length -gt $max) {
        return ($raw.Substring(0, $max - 20) + "`n`n<!-- truncado -->")
    }
    return $raw.Trim()
}

function Sanitize-HtmlPreview([string]$Html) {
    if (-not $Html) { return $null }
    $clean = $Html -replace '(?is)<script[^>]*>.*?</script>', ''
    $clean = $clean -replace '(?is)<script[^>]*/>', ''
    $max = 150000
    if ($clean.Length -gt $max) {
        return ($clean.Substring(0, $max - 30) + '<!-- truncado -->')
    }
    return $clean
}

function Build-YamlArtifactMarkdown([string]$DefId, [string]$OutputDir, [hashtable]$Context) {
    switch ($DefId) {
        'brief' {
            $raw = Resolve-SkyDataFile $Context.slug 'brief.yaml' 'brief-draft.yaml'
            if (-not $raw) { $raw = Read-ArtifactFile $OutputDir 'brief.yaml' }
            if (-not $raw) { return $null }
            $title = Read-YamlField $raw 'title'
            $lines = [System.Collections.Generic.List[string]]::new()
            if ($title) { $lines.Add("# $title"); $lines.Add('') }
            foreach ($pair in @(
                    @{ h = 'Problema'; f = 'problem' },
                    @{ h = 'Motivação'; f = 'motivation' },
                    @{ h = 'Proposta de valor'; f = 'value_proposition' },
                    @{ h = 'Escopo MVP'; f = 'mvp_scope' }
                )) {
                $block = Read-YamlBlock $raw $pair.f
                if ($block) {
                    $lines.Add("## $($pair.h)")
                    $lines.Add('')
                    $lines.Add($block)
                    $lines.Add('')
                }
            }
            $users = Read-YamlList $raw 'primary_users'
            if ($users.Count -gt 0) {
                $lines.Add('## Usuários principais')
                $lines.Add('')
                foreach ($u in $users) { $lines.Add("- $u") }
                $lines.Add('')
            }
            $out = Read-YamlList $raw 'out_of_scope'
            if ($out.Count -gt 0) {
                $lines.Add('## Fora do escopo')
                $lines.Add('')
                foreach ($o in $out) { $lines.Add("- $o") }
            }
            return ($lines -join "`n").Trim()
        }
        'functional-requirements' {
            $lines = [System.Collections.Generic.List[string]]::new()
            $lines.Add('# Requisitos funcionais')
            $lines.Add('')
            foreach ($r in @($Context.functional_reqs)) {
                $mvp = if ($r.mvp) { ' · **MVP**' } else { ' · pós-MVP' }
                $lines.Add("## $($r.id) — $($r.title)$mvp")
                $lines.Add('')
                if ($r.description) { $lines.Add($r.description); $lines.Add('') }
                $lines.Add("*Épico:* $($r.epic) · *Prioridade:* $($r.priority)")
                $lines.Add('')
            }
            return ($lines -join "`n").Trim()
        }
        'nfr' {
            $lines = [System.Collections.Generic.List[string]]::new()
            $lines.Add('# Requisitos não funcionais')
            $lines.Add('')
            foreach ($r in @($Context.nfr_reqs)) {
                $lines.Add("## $($r.id)$(if ($r.category) { " ($($r.category))" })")
                $lines.Add('')
                if ($r.statement) { $lines.Add($r.statement); $lines.Add('') }
            }
            return ($lines -join "`n").Trim()
        }
        'integrations' {
            $lines = [System.Collections.Generic.List[string]]::new()
            $lines.Add('# Integrações')
            $lines.Add('')
            foreach ($i in @($Context.integrations)) {
                $req = if ($i.required) { 'obrigatório' } else { 'opcional' }
                $lines.Add("## $($i.id)")
                $lines.Add('')
                $lines.Add("- **Tipo:** $($i.type)")
                if ($i.provider) { $lines.Add("- **Provedor:** $($i.provider)") }
                $lines.Add("- **Obrigatoriedade:** $req")
                if ($i.reason) { $lines.Add("- **Motivo:** $($i.reason)") }
                $lines.Add('')
            }
            return ($lines -join "`n").Trim()
        }
        'ux-spec' {
            $raw = Read-ArtifactFile $OutputDir 'ux-spec.yaml'
            if (-not $raw) { return $null }
            $ux = Read-UxSummary $raw
            $lines = [System.Collections.Generic.List[string]]::new()
            $lines.Add('# Especificação UX')
            $lines.Add('')
            if ($ux.principles.Count -gt 0) {
                $lines.Add('## Princípios')
                $lines.Add('')
                foreach ($p in $ux.principles) { $lines.Add("- $($p -replace '_', ' ')") }
                $lines.Add('')
            }
            if ($ux.key_screens.Count -gt 0) {
                $lines.Add('## Telas principais')
                $lines.Add('')
                foreach ($s in $ux.key_screens) { $lines.Add("- **$($s.id)** — $($s.title)") }
            }
            return ($lines -join "`n").Trim()
        }
        'maturity' {
            $raw = Read-ArtifactFile $OutputDir 'maturity.yaml'
            if (-not $raw) { return $null }
            $readiness = Read-YamlField $raw 'overall_readiness'
            $lines = [System.Collections.Generic.List[string]]::new()
            $lines.Add('# Maturidade')
            $lines.Add('')
            if ($readiness) { $lines.Add("**Readiness geral:** $([math]::Round([double]$readiness * 100))%"); $lines.Add('') }
            foreach ($d in @('business', 'product', 'ux_design', 'technical', 'sustainability', 'elevation')) {
                if ($raw -match "(?ms)$d`:\s*\r?\n(?:[^\r\n]+\r?\n)*?\s+score:\s*([0-9.]+)") {
                    $lines.Add("- **${d}:** $([math]::Round([double]$Matches[1] * 100))%")
                }
            }
            return ($lines -join "`n").Trim()
        }
        'roadmap' {
            $lines = [System.Collections.Generic.List[string]]::new()
            $lines.Add('# Roadmap')
            $lines.Add('')
            foreach ($p in @($Context.phases)) {
                $lines.Add("## $($p.id) — $($p.title)")
                $lines.Add('')
                $lines.Add("*Status:* $($p.status)")
                $lines.Add('')
            }
            return ($lines -join "`n").Trim()
        }
        default {
            $raw = Read-ArtifactFile $OutputDir $DefId
            return $null
        }
    }
}

function Build-ArtifactContent([string]$OutputDir, [hashtable]$Def, [hashtable]$Context) {
    if (-not $OutputDir) { return $null }
    if ($Def.type -eq 'cloud-design') { return $null }
    if ($Def.path -match '/$') { return $null }

    switch ($Def.type) {
        'markdown' {
            return Read-ArtifactFile $OutputDir $Def.path
        }
        'yaml' {
            $md = Build-YamlArtifactMarkdown $Def.id $OutputDir $Context
            if ($md) { return $md }
            $raw = Read-ArtifactFile $OutputDir $Def.path
            if ($raw) { return ('```yaml' + "`n" + $raw + "`n" + '```') }
            return $null
        }
        default { return Read-ArtifactFile $OutputDir $Def.path }
    }
}

function Get-CloudDesignEntries([string]$OutputDir, [switch]$MetadataOnly) {
    $dir = Join-Path $OutputDir 'cloud-design'
    if (-not (Test-Path $dir)) { return @() }
    $labels = @{
        'aplicacao-mockup.dc.html' = 'Mockup navegável da aplicação principal'
        'arquitetura.dc.html' = 'Diagramas C4 e decisões arquiteturais'
        'handoff-desenvolvimento.dc.html' = 'Handoff completo de desenvolvimento'
        'handoff.dc.html' = 'Handoff resumido'
        'site-bonomi.dc.html' = 'Site institucional white-label (referência)'
    }
    return @(Get-ChildItem $dir -File | ForEach-Object {
        $entry = @{
            id = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
            filename = $_.Name
            label = if ($labels.ContainsKey($_.Name)) { $labels[$_.Name] } else { $_.BaseName -replace '-', ' ' }
            type = 'cloud-design-file'
            available = $true
        }
        if (-not $MetadataOnly -and $_.Extension -eq '.html') {
            $html = Sanitize-HtmlPreview (Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue)
            if ($html) { $entry['content_html'] = $html }
        }
        $entry
    })
}

function Get-ArchitectureFolderEntries([string]$OutputDir, [string]$SubPath, [string]$Type) {
    $dir = Join-Path $OutputDir "architecture\$SubPath"
    if (-not (Test-Path $dir)) { return @() }
    return @(Get-ChildItem $dir -File -Filter '*.md' -ErrorAction SilentlyContinue | ForEach-Object {
        @{
            id = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
            filename = $_.Name
            label = ($_.BaseName -replace '-', ' ')
            type = $Type
            available = $true
            content = (Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue).Trim()
        }
    })
}

function Build-Artifacts([string]$OutputDir, [hashtable]$Context) {
    $defs = @(
        @{
            id = 'brief'
            label = 'Brief'
            type = 'yaml'
            stage = 'brief'
            path = 'brief.yaml'
            description = 'Visão, problema, proposta de valor, usuários e escopo MVP'
        },
        @{
            id = 'functional-requirements'
            label = 'Requisitos funcionais'
            type = 'yaml'
            stage = 'requirements'
            path = 'functional-requirements.yaml'
            description = 'Funcionalidades agrupadas por épico com prioridade e escopo MVP'
        },
        @{
            id = 'nfr'
            label = 'Requisitos não funcionais'
            type = 'yaml'
            stage = 'requirements'
            path = 'nfr.yaml'
            description = 'Segurança, LGPD, acessibilidade, performance e manutenibilidade'
        },
        @{
            id = 'integrations'
            label = 'Integrações'
            type = 'yaml'
            stage = 'architecture'
            path = 'integrations.yaml'
            description = 'Stack, auth, storage, e-mail e conectores externos'
        },
        @{
            id = 'ux-spec'
            label = 'Especificação UX'
            type = 'yaml'
            stage = 'architecture'
            path = 'ux-spec.yaml'
            description = 'Princípios de baixa excitação, telas-chave e tokens de design'
        },
        @{
            id = 'architecture'
            label = 'Arquitetura — resumo C4'
            type = 'markdown'
            stage = 'architecture'
            path = 'architecture/c4-summary.md'
            description = 'Resumo C4 sanitizado — containers, domínios e diferencial'
        },
        @{
            id = 'c4-context'
            label = 'C4 — Contexto (L1)'
            type = 'markdown'
            stage = 'architecture'
            path = 'architecture/c4-context.md'
            description = 'Sistema IAutos no ecossistema externo — atores e integrações'
        },
        @{
            id = 'c4-containers'
            label = 'C4 — Containers (L2)'
            type = 'markdown'
            stage = 'architecture'
            path = 'architecture/c4-containers.md'
            description = 'Aplicações, APIs, serviços e stores'
        },
        @{
            id = 'c4-components'
            label = 'C4 — Componentes (L3)'
            type = 'markdown'
            stage = 'architecture'
            path = 'architecture/c4-components.md'
            description = 'Componentes internos dos containers críticos'
        },
        @{
            id = 'domains'
            label = 'Domínios'
            type = 'markdown'
            stage = 'architecture'
            path = 'architecture/domains.md'
            description = 'Bounded contexts e context map'
        },
        @{
            id = 'context-flow'
            label = 'Fluxograma de contexto'
            type = 'markdown'
            stage = 'architecture'
            path = 'architecture/context-flow.md'
            description = 'Fluxo end-to-end do onboarding ao valor entregue'
        },
        @{
            id = 'sequences'
            label = 'Jornadas — sequência'
            type = 'markdown'
            stage = 'architecture'
            path = 'architecture/sequences/'
            description = 'Diagramas de sequência Mermaid das jornadas principais'
        },
        @{
            id = 'craft-review'
            label = 'Craft review'
            type = 'markdown'
            stage = 'architecture'
            path = 'architecture/craft-review.md'
            description = 'Revisão Uncle Bob — SOLID, boundaries, smells (consultivo)'
        },
        @{
            id = 'adrs'
            label = 'ADRs'
            type = 'markdown'
            stage = 'architecture'
            path = 'architecture/adrs/'
            description = 'Architecture Decision Records'
        },
        @{
            id = 'maturity'
            label = 'Maturidade'
            type = 'yaml'
            stage = 'brief'
            path = 'maturity.yaml'
            description = 'Readiness por dimensão e gates do pipeline Sky-Forge'
        },
        @{
            id = 'roadmap'
            label = 'Roadmap'
            type = 'yaml'
            stage = 'requirements'
            path = 'roadmap/phases.yaml'
            description = 'Épicos E1–E6, dependências e próximo passo imediato'
        },
        @{
            id = 'prompts'
            label = 'Prompts avançados'
            type = 'markdown'
            stage = 'prompts'
            path = 'prompts/'
            description = 'Instruções de implementação para agentes de código'
        },
        @{
            id = 'scaffold'
            label = 'Scaffold do repositório'
            type = 'markdown'
            stage = 'scaffold'
            path = 'scaffold/AGENTS.md'
            description = 'AGENTS.md inicial e convenções do app a implementar'
        },
        @{
            id = 'cloud-design'
            label = 'Cloud Design'
            type = 'cloud-design'
            stage = 'cloud-design'
            path = 'cloud-design/'
            description = 'Protótipos visuais proprietários — apenas metadados no showcase público'
        }
    )

    $artifacts = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($def in $defs) {
        $available = if ($def.path -match '/$') {
            Test-Path (Join-Path $OutputDir ($def.path.TrimEnd('/')))
        } else {
            Test-ArtifactPath $OutputDir $def.path
        }
        if ($def.id -eq 'prompts' -and $available) {
            $promptFile = Get-ChildItem (Join-Path $OutputDir 'prompts') -Filter '*.md' -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($promptFile) { $def.path = "prompts/$($promptFile.Name)" }
            else { $available = $false }
        }
        if ($def.id -eq 'prompts' -and -not $available) { continue }

        $summary = $null
        switch ($def.id) {
            'brief' { $summary = Truncate-Text $Context.value_proposition 280 }
            'functional-requirements' {
                $count = @($Context.functional_reqs).Count
                $mvp = @($Context.functional_reqs | Where-Object { $_.mvp }).Count
                $summary = "$count requisitos funcionais · $mvp no MVP"
            }
            'nfr' {
                $count = @($Context.nfr_reqs).Count
                $summary = if ($count) { "$count requisitos não funcionais" } else { $null }
            }
            'integrations' {
                $count = @($Context.integrations).Count
                $summary = if ($count) { "$count integrações mapeadas" } else { $null }
            }
            'ux-spec' {
                $screens = @($Context.ux_screens).Count
                $principles = @($Context.ux_principles).Count
                $summary = if ($screens) { "$screens telas · $principles princípios UX" } else { $null }
            }
            'architecture' { $summary = Read-TextHead $OutputDir $def.path 4 }
            'c4-context' { $summary = 'Nível 1 — contexto do sistema' }
            'c4-containers' { $summary = 'Nível 2 — containers e responsabilidades' }
            'c4-components' { $summary = 'Nível 3 — Case, Agent, Copilot' }
            'domains' { $summary = Read-TextHead $OutputDir $def.path 3 }
            'context-flow' { $summary = 'Fluxo end-to-end onboarding → HITL' }
            'sequences' {
                $entries = Get-ArchitectureFolderEntries $OutputDir 'sequences' 'sequence-diagram'
                $summary = if ($entries.Count) { "$($entries.Count) jornadas modeladas" } else { $null }
            }
            'craft-review' { $summary = Read-TextHead $OutputDir $def.path 3 }
            'adrs' {
                $entries = Get-ArchitectureFolderEntries $OutputDir 'adrs' 'adr'
                $summary = if ($entries.Count) { "$($entries.Count) decisões registradas" } else { $null }
            }
            'maturity' {
                if ($Context.readiness) { $summary = "Readiness geral: $([math]::Round([double]$Context.readiness * 100))%" }
            }
            'roadmap' {
                $count = @($Context.phases).Count
                $summary = if ($count) { "$count épicos no roadmap" } else { $null }
            }
            'prompts' { $summary = Read-TextHead $OutputDir $def.path 3 }
            'scaffold' { $summary = Read-TextHead $OutputDir $def.path 3 }
            'cloud-design' {
                $entries = Get-CloudDesignEntries $OutputDir -MetadataOnly
                $summary = if ($entries.Count) { "$($entries.Count) protótipos Sky Cloud Design (metadados)" } else { $null }
            }
        }

        $item = @{
            id = $def.id
            label = $def.label
            type = $def.type
            stage = $def.stage
            path = $def.path
            description = $def.description
            summary = $summary
            available = [bool]$available
        }
        if ($available -and $OutputDir) {
            $body = Build-ArtifactContent $OutputDir $def $Context
            if ($body) {
                $item['content'] = $body
                $item['content_format'] = if ($def.type -eq 'yaml') { 'markdown' } else { 'markdown' }
            }
        }
        if ($def.id -eq 'cloud-design' -and $available) {
            $item['children'] = @(Get-CloudDesignEntries $OutputDir -MetadataOnly)
        }
        if ($def.id -eq 'sequences' -and $available) {
            $item['children'] = @(Get-ArchitectureFolderEntries $OutputDir 'sequences' 'sequence-diagram')
        }
        if ($def.id -eq 'adrs' -and $available) {
            $item['children'] = @(Get-ArchitectureFolderEntries $OutputDir 'adrs' 'adr')
        }
        $artifacts.Add($item)
    }
    return @($artifacts)
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
$marketBenchmark = Resolve-SkyDataFile $Slug 'market-benchmark.yaml' 'market-benchmark.yaml'

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
$specVersion = Read-YamlField $merits 'spec_version'
if ($specVersion) { $specVersion = $specVersion.Trim('"').Trim("'") }
$scoreKind = Read-YamlField $merits 'score_kind'
if (-not $scoreKind) { $scoreKind = 'intent' }
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
        description = $_.description
        epic = $_.epic
        priority = $_.priority
        mvp = [bool]$_.mvp
    }
}

$epics = @()
if ($roadmap) {
    $epics = @(Read-Phases $roadmap | ForEach-Object {
        @{
            id = $_.id
            title = $_.title
            status = $_.status
        }
    })
}

$nfrReqs = Read-YamlRequirementItems $nfr | ForEach-Object {
    @{
        id = $_.id
        category = $_.category
        statement = $_.statement
    }
}

$uxSummary = Read-UxSummary $uxSpec
$integrationsList = @(Read-Integrations $integrations)
$phasesList = Read-Phases $roadmap

$artifactContext = @{
    slug = $Slug
    value_proposition = $vision.value_proposition
    functional_reqs = $functionalReqs
    nfr_reqs = $nfrReqs
    integrations = $integrationsList
    ux_screens = $uxSummary.key_screens
    ux_principles = $uxSummary.principles
    readiness = $readiness
    phases = $phasesList
}
$artifactsList = if ($OutputDir) { Build-Artifacts $OutputDir $artifactContext } else { @() }

# Opt-in é pegajoso: republicar sem -Public não despublica (despublicar é ação explícita)
$registryDir = Get-SkyRegistryDir
$indexPath = Join-Path $registryDir 'index.json'
$index = @{ version = '1.0'; projects = @() }
if (Test-Path $indexPath) {
    $index = Get-Content $indexPath -Raw | ConvertFrom-Json
    if (-not $index.projects) { $index.projects = @() }
}
$prev = @($index.projects | Where-Object { $_.slug -eq $Slug } | Select-Object -First 1)
$isPublic = [bool]$Public
if (-not $Public -and $prev -and $prev.public -eq $true) { $isPublic = $true }

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
        epics = @($epics)
    }
    architecture = @{
        integrations = $integrationsList
        ux = $uxSummary
    }
    indices = Read-Indices $merits
    indices_meta = Read-IndicesMeta $merits
    market = Read-MarketBenchmark $marketBenchmark
    spec_version = $specVersion
    score_kind = $scoreKind
    dimensions = Read-DimensionScores $maturity
    phases = Read-Phases $roadmap
    pipeline = Read-Pipeline $maturity
    artifacts = @($artifactsList)
    public = $isPublic
    published_at = (Get-Date).ToUniversalTime().ToString('o')
    outputs_dir = $OutputDir
}

New-Item -ItemType Directory -Path $registryDir -Force | Out-Null
$previewPath = Join-Path $registryDir "$Slug.preview.json"
$preview | ConvertTo-Json -Depth 10 | Set-Content $previewPath -Encoding UTF8

# Atualizar index.json
$existing = @($index.projects | Where-Object { $_.slug -ne $Slug })
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
