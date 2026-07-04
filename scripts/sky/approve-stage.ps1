#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)]
    [string]$Slug,

    [Parameter(Mandatory = $true)]
    [ValidateSet('brief', 'research', 'elevation', 'architecture', 'package')]
    [string]$Stage
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$SessionDir = Join-Path $RepoRoot ".sky\sessions\$Slug"
$approvalsPath = Join-Path $SessionDir 'approvals.yaml'

if (-not (Test-Path $SessionDir)) {
    throw "Sessao nao encontrada: $Slug"
}

$now = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$entry = "${Stage}: approved at $now"

if (-not (Test-Path $approvalsPath)) {
    "stages:`n  ${Stage}: $now" | Set-Content $approvalsPath -Encoding UTF8
} else {
    Add-Content -Path $approvalsPath -Value "  ${Stage}: $now" -Encoding UTF8
}

$maturityPath = Join-Path $SessionDir 'maturity.yaml'
if (Test-Path $maturityPath) {
    $content = Get-Content $maturityPath -Raw
    if ($content -match "pipeline_unlock:\s*") {
        $content = $content -replace "($Stage:\s*\r?\n\s*requires:[^\r\n]+\r?\n\s*)approved: false", "`${1}approved: true"
        # fallback simples para stages conhecidos
        switch ($Stage) {
            'brief' { $content = $content -replace '(market_research:\s*\r?\n\s*requires:[^\r\n]+\r?\n\s*)approved: false', '${1}approved: true' }
        }
    }
    Set-Content -Path $maturityPath -Value $content -Encoding UTF8 -NoNewline
}

Write-Host "Aprovado: $Stage para sessao $Slug em $now" -ForegroundColor Green
