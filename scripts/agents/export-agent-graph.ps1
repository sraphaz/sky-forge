#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')

. (Join-Path $PSScriptRoot 'choreography-parser.ps1')

$choreoRaw = Get-Content (Join-Path $RepoRoot '.agents\choreography.yaml') -Raw
$rules = Parse-ChoreographyRules -Raw $choreoRaw

$agents = @()
Get-ChildItem (Join-Path $RepoRoot '.agents') -Recurse -Filter '*.agent.yaml' | ForEach-Object {
    $raw = Get-Content $_.FullName -Raw
    $id = if ($raw -match '(?m)^id:\s*(.+)') { $Matches[1].Trim() } else { $_.BaseName }
    $agents += [ordered]@{ id = $id; manifest = $_.FullName.Replace("$RepoRoot\", '').Replace('\', '/') }
}

$skills = @()
Get-ChildItem (Join-Path $RepoRoot '.skills') -Filter '*.skill.yaml' | ForEach-Object {
    $raw = Get-Content $_.FullName -Raw
    $id = if ($raw -match '(?m)^id:\s*(.+)') { $Matches[1].Trim() } else { $_.BaseName }
    $skills += [ordered]@{ id = $id; manifest = $_.FullName.Replace("$RepoRoot\", '').Replace('\', '/') }
}

$edges = @()
foreach ($rule in $rules) {
    foreach ($agent in $rule.agents) {
        $edges += [ordered]@{ from = "rule:$($rule.id)"; to = "agent:$($agent.id)"; type = 'activates_agent' }
        foreach ($sk in $agent.skills) {
            $edges += [ordered]@{ from = "agent:$($agent.id)"; to = "skill:$sk"; type = 'may_invoke_skill' }
        }
        foreach ($g in $agent.requires_gate) {
            $edges += [ordered]@{ from = "agent:$($agent.id)"; to = "gate:$g"; type = 'requires_gate' }
        }
        if ($agent.max_autonomy) {
            $edges += [ordered]@{ from = "agent:$($agent.id)"; to = "autonomy:$($agent.max_autonomy)"; type = 'max_autonomy' }
        }
    }
}

$graph = [ordered]@{
    version = 1
    generated_at = (Get-Date).ToUniversalTime().ToString('o')
    repo = 'sky-forge'
    nodes = [ordered]@{
        agents = $agents
        skills = $skills
        rules = @($rules | ForEach-Object { [ordered]@{ id = $_.id; paths = $_.paths; agents = @($_.agents | ForEach-Object { $_.id }) } })
        autonomy_levels = @('observe', 'consult', 'route', 'activate', 'invoke_skill', 'side_effect', 'public')
        gates = @('brief', 'elevation', 'package', 'public_showcase')
    }
    edges = $edges
}

$outDir = Join-Path $RepoRoot 'docs\_meta'
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
$outPath = Join-Path $outDir 'agent-graph.generated.json'
$graph | ConvertTo-Json -Depth 10 | Set-Content $outPath -Encoding UTF8
Write-Host "Graph exportado: $outPath" -ForegroundColor Green
