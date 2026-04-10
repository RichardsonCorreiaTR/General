# gerar-mapa-pbl-escrita.ps1
# Varre brtap-dominio\escrita\pbcvsexp (ou -CodigoDir) e gera:
#   - banco-dados/mapa-sistema/pbl-area-escrita.json  (hashtable PBL -> Area, chaves reais)
#   - banco-dados/mapa-sistema/mapa-escrita-lista-pbls.md (tabela navegavel)
# Regras de area: scripts/lib/escrita-pbl-area-rules.ps1 (alinhado a mapa-escrita.md)
#
# Rode apos atualizar o codigo PB ou quando entrarem PBLs novas.

param(
    [string]$CodigoDir = ""
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir
$mapaDir = Join-Path $projetoDir "banco-dados\mapa-sistema"
$jsonOut = Join-Path $mapaDir "pbl-area-escrita.json"
$mdOut = Join-Path $mapaDir "mapa-escrita-lista-pbls.md"

. (Join-Path $scriptDir "lib\escrita-pbl-area-rules.ps1")

if (-not $CodigoDir) {
    $caminhosFile = Join-Path $projetoDir "projeto-filho\config\caminhos.json"
    if (Test-Path $caminhosFile) {
        $config = Get-Content $caminhosFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($config.codigo_local) { $CodigoDir = $config.codigo_local }
    }
}
if (-not $CodigoDir) { $CodigoDir = "C:\CursorEscrita\codigo-sistema\versao-atual" }

$pbcvsexpDir = Join-Path $CodigoDir "pbcvsexp"
if (-not (Test-Path $pbcvsexpDir)) {
    $repoEscrita = "C:\1 - A\B\Programas\brtap-dominio\escrita"
    if (Test-Path (Join-Path $repoEscrita "pbcvsexp")) {
        $CodigoDir = $repoEscrita
        $pbcvsexpDir = Join-Path $CodigoDir "pbcvsexp"
    }
}
if (-not (Test-Path $pbcvsexpDir)) {
    Write-Host "ERRO: pbcvsexp nao encontrado em $pbcvsexpDir" -ForegroundColor Red
    exit 1
}

Write-Host "=== Mapa PBL Escrita (chaves reais) ===" -ForegroundColor Cyan
Write-Host "Origem: $pbcvsexpDir"
Write-Host ""

$pbls = Get-ChildItem $pbcvsexpDir -Directory | Sort-Object Name
$map = [ordered]@{}
$semArea = [System.Collections.Generic.List[string]]::new()

foreach ($pbl in $pbls) {
    $area = Get-EscritaAreaPbl $pbl.Name
    if (-not $area) {
        $semArea.Add($pbl.Name) | Out-Null
        $area = "(nao classificado)"
    }
    $map[$pbl.Name] = $area
}

if ($semArea.Count -gt 0) {
    Write-Host "AVISO: PBLs sem regra de area (ajuste escrita-pbl-area-rules.ps1):" -ForegroundColor Yellow
    $semArea | ForEach-Object { Write-Host "  $_" }
    Write-Host ""
}

# JSON estavel (ordenado por nome PBL)
$jsonObj = @{}
foreach ($k in ($map.Keys | Sort-Object)) { $jsonObj[$k] = $map[$k] }
$jsonText = $jsonObj | ConvertTo-Json -Depth 3 -Compress:$false
New-Item -ItemType Directory -Path $mapaDir -Force | Out-Null
Set-Content -Path $jsonOut -Value $jsonText -Encoding UTF8

Write-Host "JSON: $jsonOut ($($map.Count) PBLs)"

# Markdown: tabela + agrupamento por area
$fecha = Get-Date -Format "dd/MM/yyyy HH:mm"
$md = @"
# Lista de PBLs - Modulo Escrita (pbcvsexp)

> Gerado em: $fecha
> Origem: ``$CodigoDir\pbcvsexp``
> Total: $($map.Count) bibliotecas
> Dados: ``pbl-area-escrita.json`` (mesmas chaves usadas em ``gerar-indice-codigo.ps1``)
> Regras: ``scripts/lib/escrita-pbl-area-rules.ps1`` - alinhado a ``mapa-escrita.md``

## Tabela (ordenada por PBL)

| PBL | Area |
|-----|------|

"@
foreach ($k in ($map.Keys | Sort-Object)) {
    $md += "| ``$k`` | $($map[$k]) |`n"
}

$md += @"

---

## Por area (contagem)

"@
$porArea = $map.Values | Group-Object | Sort-Object Name
foreach ($g in $porArea) {
    $md += "- **$($g.Name)**: $($g.Count) PBLs`n"
}

Set-Content -Path $mdOut -Value $md -Encoding UTF8
Write-Host "MD:   $mdOut"
Write-Host ""
Write-Host "=== Concluido ===" -ForegroundColor Green
