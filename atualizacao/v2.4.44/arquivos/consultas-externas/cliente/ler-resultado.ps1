#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)]
    [string]$FilhoRoot,
    [Parameter(Mandatory = $true)]
    [string]$Id,
    [int]$TimeoutSegundos = 120
)

$ErrorActionPreference = "Stop"
$saida = Join-Path $FilhoRoot "consultas-externas\saida\$Id.json"
$deadline = (Get-Date).AddSeconds($TimeoutSegundos)
while ((Get-Date) -lt $deadline) {
    if (Test-Path $saida) {
        Get-Content $saida -Raw -Encoding UTF8
        exit 0
    }
    Start-Sleep -Seconds 2
}
Write-Error "Timeout: resultado nao apareceu em $saida. Rode processar-consultas-externas.ps1 no projeto-filho."
