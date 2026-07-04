#Requires -Version 5.1
param(
    [string]$Query = '',
    [string]$Dimension = 'technical'
)
Write-Host "forge-rag-query: planejado na PR 4. Query='$Query' Dimension=$Dimension" -ForegroundColor Yellow
Write-Host "MVP: leia docs/patterns/ diretamente."
