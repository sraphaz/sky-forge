#Requires -Version 5.1
<#
.SYNOPSIS
  Cria stub .dc.html mínimo para inventário Cloud Design.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$DestPath,
    [Parameter(Mandatory = $true)]
    [string]$Id,
    [Parameter(Mandatory = $true)]
    [string]$Title
)

$dir = Split-Path $DestPath -Parent
if ($dir) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

$html = @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$Id — $Title</title>
</head>
<body>
<x-dc>
<helmet>
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:wght@600&family=Mulish:wght@400;500;600&display=swap" rel="stylesheet">
<style>
:root {
  --font-display: "Cormorant Garamond", serif;
  --font-body: "Mulish", sans-serif;
  --color-primary: #6E2024;
  --color-accent: #A98247;
  --color-bg: #F7F3EE;
  --color-surface: #FFFFFF;
  --color-text: #1a1a1a;
  --color-muted: #5c5c5c;
  --radius-md: 12px;
}
body { margin: 0; font-family: var(--font-body); background: var(--color-bg); color: var(--color-text); padding: 2rem; }
h1 { font-family: var(--font-display); color: var(--color-primary); }
.stub { background: var(--color-surface); padding: 1.5rem; border-radius: var(--radius-md); border: 1px dashed var(--color-accent); }
</style>
</helmet>
<div class="stub">
  <h1>$Id — $Title</h1>
  <p>Stub · aguardando Claude Design · ciclo 28</p>
</div>
</x-dc>
</body>
</html>
"@
Set-Content -Path $DestPath -Value $html -Encoding UTF8
