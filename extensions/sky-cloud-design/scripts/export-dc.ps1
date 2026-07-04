#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
. (Join-Path $RepoRoot 'scripts\sky\get-sky-config.ps1')
$OutputDir = Get-SkyOutputDirForSlug $Slug
$TemplatePath = Join-Path $PSScriptRoot '..\templates\handoff.dc.html'
$OutPath = Join-Path $OutputDir 'cloud-design\handoff.dc.html'

if (-not (Test-Path $TemplatePath)) {
    Write-Warning "Template Cloud Design nao encontrado."
    exit 0
}

New-Item -ItemType Directory -Path (Split-Path $OutPath) -Force | Out-Null

$brief = ''
$title = $Slug
if (Test-Path (Join-Path $OutputDir 'brief.yaml')) {
    $brief = Get-Content (Join-Path $OutputDir 'brief.yaml') -Raw
    if ($brief -match 'title:\s*(.+)') { $title = $Matches[1].Trim() }
}

$maturity = ''
if (Test-Path (Join-Path $OutputDir 'maturity.yaml')) {
    $maturity = Get-Content (Join-Path $OutputDir 'maturity.yaml') -Raw
}

$rfMust = ''
if (Test-Path (Join-Path $OutputDir 'functional-requirements.yaml')) {
    $rfMust = Get-Content (Join-Path $OutputDir 'functional-requirements.yaml') -Raw
}

$html = Get-Content $TemplatePath -Raw
$html = $html -replace '\{\{PROJECT_TITLE\}\}', [System.Net.WebUtility]::HtmlEncode($title)
$html = $html -replace '\{\{SLUG\}\}', [System.Net.WebUtility]::HtmlEncode($Slug)
$html = $html -replace '\{\{GENERATED_AT\}\}', (Get-Date).ToUniversalTime().ToString('o')
$briefSnippet = if ($brief.Length -gt 0) { $brief.Substring(0, [Math]::Min(2000, $brief.Length)) } else { '(vazio)' }
$maturitySnippet = if ($maturity.Length -gt 0) { $maturity.Substring(0, [Math]::Min(1500, $maturity.Length)) } else { '(vazio)' }
$rfSnippet = if ($rfMust.Length -gt 0) { $rfMust.Substring(0, [Math]::Min(1500, $rfMust.Length)) } else { '(vazio)' }
$html = $html -replace '\{\{BRIEF_SUMMARY\}\}', [System.Net.WebUtility]::HtmlEncode($briefSnippet)
$html = $html -replace '\{\{MATURITY_SUMMARY\}\}', [System.Net.WebUtility]::HtmlEncode($maturitySnippet)
$html = $html -replace '\{\{RF_MUST\}\}', [System.Net.WebUtility]::HtmlEncode($rfSnippet)

Set-Content -Path $OutPath -Value $html -Encoding UTF8
Write-Host "Cloud Design: $OutPath" -ForegroundColor Cyan
