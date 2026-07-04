#Requires -Version 5.1
# Hook Cursor stop — auditoria passiva da sessão ativa
$ErrorActionPreference = 'SilentlyContinue'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')

$slug = $env:SKY_ACTIVE_SLUG
if (-not $slug) {
    $sessions = Join-Path $RepoRoot '.sky\sessions'
    if (Test-Path $sessions) {
        $latest = Get-ChildItem $sessions -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latest) { $slug = $latest.Name }
    }
}
if (-not $slug) { exit 0 }

$rec = Join-Path $RepoRoot 'scripts\sky\record-agent-event.ps1'
if (Test-Path $rec) {
    & $rec -Slug $slug -AgentId 'orchestrator' -Action 'session.read' -Outcome 'ok' -AutonomyLevel 'observe' -Details 'hook_stop' | Out-Null
}

$choreo = Join-Path $RepoRoot 'scripts\agents\choreograph-agents.ps1'
if (Test-Path $choreo) {
    & $choreo -Slug $slug -Trigger hook_stop -ErrorAction SilentlyContinue | Out-Null
}

exit 0
