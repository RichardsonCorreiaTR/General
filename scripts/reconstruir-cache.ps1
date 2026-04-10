# reconstruir-cache.ps1
# Reconstroi o cache monolitico a partir dos fracionados (que estao completos)
$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir
$psaiDir = Join-Path $projetoDir "banco-dados\dados-brutos\psai"
$destino = Join-Path $scriptDir "cache\sai-psai-escrita.json"

Write-Host "=== Reconstruindo cache monolitico a partir dos fracionados ==="
Write-Host "Fracionados: $psaiDir"
Write-Host "Destino: $destino"
Write-Host ""

$arquivos = Get-ChildItem $psaiDir -Filter "*.json" | Sort-Object Name
Write-Host "Arquivos encontrados: $($arquivos.Count)"

$todosRegistros = [System.Collections.ArrayList]::new()

foreach ($arq in $arquivos) {
    Write-Host "  Lendo $($arq.Name)..." -NoNewline
    $json = Get-Content $arq.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    $count = $json.dados.Count
    foreach ($r in $json.dados) {
        [void]$todosRegistros.Add($r)
    }
    Write-Host " $count registros (acumulado: $($todosRegistros.Count))"
    $json = $null
    [GC]::Collect()
}

Write-Host ""
Write-Host "Total de registros: $($todosRegistros.Count)"
Write-Host "Salvando cache..."

$wrapper = [ordered]@{
    geradoEm = (Get-Date -Format o)
    totalRegistros = $todosRegistros.Count
    dados = $todosRegistros
}
$wrapper | ConvertTo-Json -Depth 5 -Compress | Set-Content -Path $destino -Encoding UTF8

$tamanhoMB = [math]::Round((Get-Item $destino).Length / 1MB, 1)
Write-Host "Cache reconstruido: $destino ($tamanhoMB MB, $($todosRegistros.Count) registros)"
Write-Host "=== Concluido! ==="
