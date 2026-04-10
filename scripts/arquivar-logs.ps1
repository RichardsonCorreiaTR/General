<#
.SYNOPSIS
    Arquiva logs antigos para manter o diretorio de logs leve.
.DESCRIPTION
    Move logs com mais de N dias para pasta arquivo/{AAAA-MM}/.
    Gera um resumo de contagem antes de mover.
.PARAMETER DiasReter
    Numero de dias para manter no diretorio ativo (padrao: 30).
.PARAMETER SimularApenas
    Se presente, mostra o que seria movido sem mover.
.EXAMPLE
    .\arquivar-logs.ps1
    .\arquivar-logs.ps1 -DiasReter 60
    .\arquivar-logs.ps1 -SimularApenas
#>
param(
    [int]$DiasReter = 30,
    [switch]$SimularApenas
)

$ErrorActionPreference = "Stop"
$projetoDir = Split-Path -Parent $PSScriptRoot
$logsDir = Join-Path $projetoDir "logs\analistas"
$arquivoDir = Join-Path $projetoDir "logs\arquivo"

if (-not (Test-Path $logsDir)) {
    Write-Host "ERRO: Pasta de logs nao encontrada: $logsDir" -ForegroundColor Red
    exit 1
}

$dataLimite = (Get-Date).AddDays(-$DiasReter)
$hoje = Get-Date -Format "yyyy-MM-dd"

Write-Host "=== Arquivamento de Logs ===" -ForegroundColor Cyan
Write-Host "Reter: ultimos $DiasReter dias (ate $($dataLimite.ToString('yyyy-MM-dd')))"
if ($SimularApenas) { Write-Host "MODO SIMULACAO -- nada sera movido" -ForegroundColor Yellow }
Write-Host ""

$analistas = Get-ChildItem $logsDir -Directory -ErrorAction SilentlyContinue
$totalMovidos = 0
$totalKB = 0

foreach ($dir in $analistas) {
    $nome = $dir.Name
    $logsAntigos = Get-ChildItem $dir.FullName -File -Filter "*.md" -ErrorAction SilentlyContinue |
        Where-Object {
            if ($_.BaseName -match '^(\d{4}-\d{2}-\d{2})') {
                [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd', $null) -lt $dataLimite
            } else { $false }
        }

    if ($logsAntigos.Count -eq 0) { continue }

    $kb = [math]::Round(($logsAntigos | Measure-Object -Property Length -Sum).Sum / 1024, 1)
    Write-Host "  $nome : $($logsAntigos.Count) logs antigos ($kb KB)" -ForegroundColor Yellow

    foreach ($log in $logsAntigos) {
        if ($log.BaseName -match '^(\d{4}-\d{2})') {
            $mesDir = Join-Path $arquivoDir "$nome\$($Matches[1])"
        } else {
            $mesDir = Join-Path $arquivoDir "$nome\outros"
        }

        if (-not $SimularApenas) {
            New-Item -ItemType Directory -Path $mesDir -Force | Out-Null
            Move-Item -Path $log.FullName -Destination (Join-Path $mesDir $log.Name) -Force
        }
        $totalMovidos++
    }
    $totalKB += $kb
}

Write-Host ""
if ($SimularApenas) {
    Write-Host "SIMULACAO: $totalMovidos logs seriam movidos ($totalKB KB)" -ForegroundColor Yellow
} else {
    Write-Host "=== Concluido ===" -ForegroundColor Green
    Write-Host "Movidos: $totalMovidos logs ($totalKB KB) para logs/arquivo/"

    $resumo = @"
# Arquivamento -- $hoje

> Executado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm')
> Criterio: logs anteriores a $($dataLimite.ToString('yyyy-MM-dd'))
> Total movido: $totalMovidos arquivos ($totalKB KB)
> Destino: logs/arquivo/{analista}/{AAAA-MM}/
"@
    $resumoPath = Join-Path $arquivoDir "ultimo-arquivamento.md"
    New-Item -ItemType Directory -Path $arquivoDir -Force | Out-Null
    Set-Content -Path $resumoPath -Value $resumo -Encoding UTF8
}
