#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

function Parse-ChoreographyRules {
    param([string]$Raw)
    $rules = @()
    $blocks = [regex]::Matches($Raw, '(?ms)^  - id:\s*(\S+)\s*\r?\n(.*?)(?=^  - id:|\z)')
    foreach ($b in $blocks) {
        $id = $b.Groups[1].Value
        $body = $b.Groups[2].Value
        $rule = [ordered]@{
            id = $id
            when = @()
            paths = @()
            maturity_min = $null
            agents = @()
        }
        if ($body -match 'when:\s*\[([^\]]+)\]') {
            $rule.when = ($Matches[1] -split ',') | ForEach-Object { $_.Trim() }
        }
        $pathMatches = [regex]::Matches($body, '(?m)^\s+-\s+(.+)$')
        $inPaths = $false
        foreach ($pm in $pathMatches) {
            $line = $pm.Groups[1].Value
            if ($body.Substring(0, $pm.Index) -match 'paths:\s*$' -or $inPaths) {
                if ($line -notmatch ':') { $rule.paths += $line.Trim(); $inPaths = $true }
            }
        }
        if ($rule.paths.Count -eq 0) {
            $pm2 = [regex]::Matches($body, '(?m)paths:\s*\r?\n((?:\s+-\s+.+\r?\n?)+)')
            if ($pm2.Count -gt 0) {
                $rule.paths = [regex]::Matches($pm2[0].Groups[1].Value, '-\s*(.+)') | ForEach-Object { $_.Groups[1].Value.Trim() }
            }
        }
        if ($body -match 'maturity_min:\s*([0-9.]+)') { $rule.maturity_min = [double]$Matches[1] }
        $agentBlocks = [regex]::Matches($body, '(?ms)^      - id:\s*(\S+)\s*\r?\n(.*?)(?=^      - id:|\s+-\s+id:\s|\z)')
        foreach ($ab in $agentBlocks) {
            $abody = $ab.Groups[2].Value
            $agent = [ordered]@{
                id = $ab.Groups[1].Value
                type = 'operational'
                autonomy = @()
                max_autonomy = $null
                skills = @()
                requires_gate = @()
            }
            if ($abody -match 'type:\s*(\S+)') { $agent.type = $Matches[1] }
            if ($abody -match 'autonomy:\s*\[([^\]]+)\]') {
                $agent.autonomy = ($Matches[1] -split ',') | ForEach-Object { $_.Trim() }
            }
            if ($abody -match 'max_autonomy:\s*(\S+)') { $agent.max_autonomy = $Matches[1] }
            if ($abody -match 'skills:\s*\[([^\]]+)\]') {
                $agent.skills = ($Matches[1] -split ',') | ForEach-Object { $_.Trim() }
            }
            if ($abody -match 'requires_gate:\s*\[([^\]]+)\]') {
                $agent.requires_gate = ($Matches[1] -split ',') | ForEach-Object { $_.Trim() }
            }
            $rule.agents += $agent
        }
        if ($rule.agents.Count -gt 0) { $rules += $rule }
    }
    return $rules
}

function Parse-CoActivation {
    param([string]$Raw)
    $items = @()
    $blocks = [regex]::Matches($Raw, '(?ms)^  - primary:\s*(\S+)\s*\r?\n(.*?)(?=^  - primary:|\nparty_mode:|\z)')
    foreach ($b in $blocks) {
        $body = $b.Groups[2].Value
        $item = [ordered]@{
            primary = $b.Groups[1].Value
            consult = @()
            on_phase = @()
            party = $null
            route_after = $null
        }
        if ($body -match 'consult:\s*\[([^\]]+)\]') {
            $item.consult = ($Matches[1] -split ',') | ForEach-Object { $_.Trim() }
        }
        if ($body -match 'on_phase:\s*\[([^\]]+)\]') {
            $item.on_phase = ($Matches[1] -split ',') | ForEach-Object { $_.Trim() }
        }
        if ($body -match 'party:\s*(\S+)') { $item.party = $Matches[1] }
        if ($body -match 'route_after:\s*(\S+)') { $item.route_after = $Matches[1] }
        $items += $item
    }
    return $items
}

function Parse-PartyMode {
    param([string]$Raw)
    $result = [ordered]@{ policy = ''; sessions = @() }
    if ($Raw -notmatch '(?ms)^party_mode:\s*\r?\n(.*)$') { return $result }
    $section = $Matches[1]
    if ($section -match '(?ms)^  policy:\s*\|\s*\r?\n((?:    .+\r?\n)+)') {
        $result.policy = ($Matches[1] -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ }) -join ' '
    }
    $sessionsBlock = ''
    if ($section -match '(?ms)^  sessions:\s*\r?\n(.*)$') { $sessionsBlock = $Matches[1] }
    $blocks = [regex]::Matches($sessionsBlock, '(?ms)^    - id:\s*(\S+)\s*\r?\n(.*?)(?=^    - id:|\z)')
    foreach ($b in $blocks) {
        $body = $b.Groups[2].Value
        $session = [ordered]@{
            id = $b.Groups[1].Value
            label = ''
            host = 'sky-host'
            primary = ''
            consult = @()
            on_phase = @()
        }
        if ($body -match 'label:\s*(.+)') { $session.label = $Matches[1].Trim() }
        if ($body -match 'host:\s*(\S+)') { $session.host = $Matches[1] }
        if ($body -match 'primary:\s*(\S+)') { $session.primary = $Matches[1] }
        if ($body -match 'consult:\s*\[([^\]]+)\]') {
            $session.consult = ($Matches[1] -split ',') | ForEach-Object { $_.Trim() }
        }
        if ($body -match 'on_phase:\s*\[([^\]]+)\]') {
            $session.on_phase = ($Matches[1] -split ',') | ForEach-Object { $_.Trim() }
        }
        $result.sessions += $session
    }
    return $result
}

function Resolve-ActiveParty {
    param(
        $PartyMode,
        $CoActivation,
        [string]$JourneyPhase
    )
    if (-not $JourneyPhase) { return $null }
    foreach ($s in $PartyMode.sessions) {
        if ($s.on_phase -contains $JourneyPhase) { return $s }
    }
    foreach ($c in $CoActivation) {
        if ($c.on_phase -contains $JourneyPhase -and $c.party) {
            $match = $PartyMode.sessions | Where-Object { $_.id -eq $c.party } | Select-Object -First 1
            if ($match) { return $match }
        }
    }
    return $null
}

function Test-PathMatchesGlob {
    param([string]$FilePath, [string]$Pattern)
    $normalized = $FilePath.Replace('\', '/')
    $glob = $Pattern.Replace('\', '/')
    if ($glob -eq '**' -or $glob -eq '**/*') { return $true }
    $re = [regex]::Escape($glob)
    $re = $re -replace '\\\*\\\*/', '(?:.*/)?'
    $re = $re -replace '\\\*\\\*', '.*'
    $re = $re -replace '\\\*', '[^/]*'
    return $normalized -match ('^' + $re + '$')
}

function Get-AutonomyRanks {
    param([string]$RepoRoot)
    $path = Join-Path $RepoRoot '.agents\autonomy.yaml'
    $ranks = @{}
    if (-not (Test-Path $path)) { return $ranks }
    $raw = Get-Content $path -Raw
    $matches = [regex]::Matches($raw, '(?m)^  (\w+):\s*\r?\n\s+rank:\s*(\d+)')
    foreach ($m in $matches) { $ranks[$m.Groups[1].Value] = [int]$m.Groups[2].Value }
    return $ranks
}

function Test-AutonomyAllowed {
    param(
        [string]$Action,
        [string]$MaxAutonomy,
        [hashtable]$Ranks
    )
    $actionRank = @{
        'session.read' = 'observe'
        'domain.consult' = 'consult'
        'route.handoff' = 'route'
        'session.write' = 'activate'
        'skill.invoke' = 'invoke_skill'
        'export.package' = 'side_effect'
        'publish.preview' = 'side_effect'
        'publish.public' = 'public'
    }
    $needed = $actionRank[$Action]
    if (-not $needed) { return $true }
    if (-not $Ranks.ContainsKey($needed) -or -not $Ranks.ContainsKey($MaxAutonomy)) { return $false }
    return $Ranks[$MaxAutonomy] -ge $Ranks[$needed]
}
