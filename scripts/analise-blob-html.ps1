# Analise de BLOBs nos fracionados SAI/PSAI - HTML, imagens, hiperlinks
# Executar FORA do Cursor (terminal PowerShell separado) para arquivos grandes
param(
    [string]$Arquivo = "banco-dados\dados-brutos\psai\ne-liberadas.json"
)

$ErrorActionPreference = "Stop"
$base = Split-Path -Parent $PSScriptRoot
Set-Location $base

Write-Host "=== Analise BLOB - $Arquivo ===" -ForegroundColor Cyan
$json = Get-Content $Arquivo -Raw -Encoding UTF8 | ConvertFrom-Json
$regs = if ($json.dados) { $json.dados } elseif ($json.registros) { $json.registros } else { $json }
$total = $regs.Count
Write-Host "Total de registros: $total"

# 2. Amostra de comportamento grande
Write-Host "`n=== Amostra (3 registros com comportamento > 500 chars) ===" -ForegroundColor Cyan
$grandes = $regs | Where-Object { $_.comportamento -and $_.comportamento.Length -gt 500 } | Select-Object -First 3
foreach ($r in $grandes) {
    Write-Host "`n--- SAI $($r.i_sai) / PSAI $($r.i_psai) (comp: $($r.comportamento.Length) chars) ---"
    $len = [Math]::Min(500, $r.comportamento.Length)
    Write-Host $r.comportamento.Substring(0, $len)
}

# 3. HTML e imagens
Write-Host "`n=== Presenca de HTML e imagens ===" -ForegroundColor Cyan
$comHTML = @($regs | Where-Object { 
    ($_.comportamento -and $_.comportamento -match '<[a-zA-Z][^>]*>') -or 
    ($_.definicao -and $_.definicao -match '<[a-zA-Z][^>]*>') -or 
    ($_.psai_descricao -and $_.psai_descricao -match '<[a-zA-Z][^>]*>') 
})
$comImg = @($regs | Where-Object { 
    ($_.comportamento -and $_.comportamento -match '<img|\.png|\.jpg|\.gif|\.bmp|data:image') -or 
    ($_.definicao -and $_.definicao -match '<img|\.png|\.jpg|\.gif|\.bmp|data:image') 
})
if ($total -gt 0) {
    Write-Host "Registros com HTML: $($comHTML.Count) de $total ($([math]::Round(100*$comHTML.Count/$total,2))%)"
    Write-Host "Registros com imagens: $($comImg.Count) de $total ($([math]::Round(100*$comImg.Count/$total,2))%)"
}

if ($comHTML.Count -gt 0) {
    Write-Host "`nExemplo de HTML encontrado:"
    $ex = $comHTML[0]
    $campo = if ($ex.comportamento -match '<[a-zA-Z][^>]*>') { 'comportamento' } 
             elseif ($ex.definicao -match '<[a-zA-Z][^>]*>') { 'definicao' } 
             else { 'psai_descricao' }
    $texto = $ex.$campo
    $match = [regex]::Match($texto, '<[a-zA-Z][^>]*>')
    $ini = [Math]::Max(0, $match.Index - 50)
    $fim = [Math]::Min($texto.Length, $match.Index + 200)
    Write-Host $texto.Substring($ini, $fim - $ini)
}

# 4. Tamanho medio dos campos BLOB
Write-Host "`n=== Tamanho medio/max dos campos BLOB ===" -ForegroundColor Cyan
foreach ($campo in @('comportamento','definicao','psai_descricao','sai_descricao','sai_destaque','psai_destaque')) {
    $vals = @($regs | Where-Object { $_.$campo } | ForEach-Object { $_.$campo.Length })
    if ($vals.Count -gt 0) {
        $avg = [math]::Round(($vals | Measure-Object -Average).Average)
        $max = ($vals | Measure-Object -Maximum).Maximum
        Write-Host ("{0}: {1} registros, media={2} chars, max={3} chars" -f $campo, $vals.Count, $avg, $max)
    } else {
        Write-Host ("{0}: 0 registros" -f $campo)
    }
}
