#Requires -Version 5.1
<#
.SYNOPSIS
  Sincroniza spec/ no repo da app ligado quando sync_mode = after_export.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'resolve-sky-link.ps1')

$ctx = Get-SkyLinkContext -Slug $Slug
if (-not $ctx.WorkspacePath) {
    Write-Host "sync-linked: nenhum workspace ligado para $Slug" -ForegroundColor DarkGray
    return
}
if ($ctx.SyncMode -ne 'after_export') {
    Write-Host "sync-linked: sync_mode=$($ctx.SyncMode) — pulando pull-spec automatico" -ForegroundColor DarkGray
    return
}

Write-Host "== pull-spec (after_export) → $($ctx.WorkspacePath) ==" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'pull-spec.ps1') -Slug $Slug -WorkspacePath $ctx.WorkspacePath

$rec = Join-Path $PSScriptRoot 'record-agent-event.ps1'
if (Test-Path $rec) {
    & $rec -Slug $Slug -AgentId 'repo-scaffolder' -Action 'workspace.sync_after_export' -Outcome 'ok' -AutonomyLevel 'invoke_skill' -Details $ctx.WorkspacePath -ErrorAction SilentlyContinue | Out-Null
}
