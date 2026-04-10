# gerar-indice-codigo.ps1
# Gera indice navegavel (Markdown) de todos os arquivos do codigo-fonte
# Resultado: banco-dados/mapa-sistema/indice-arquivos.md
#
# Coluna "Area": hashtable em mapa-sistema/pbl-area-escrita.json (PBLs reais do pbcvsexp).
# Regenerar JSON: scripts/gerar-mapa-pbl-escrita.ps1 (regras em scripts/lib/escrita-pbl-area-rules.ps1).
# PBL nova sem entrada no JSON: fallback via Get-EscritaAreaPbl no mesmo lib.
# Pode ser rodado diretamente ou e chamado automaticamente pelo atualizar-codigo.ps1

param(
    [string]$CodigoDir = ""
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir
$mapaDir = Join-Path $projetoDir "banco-dados\mapa-sistema"
$indiceFile = Join-Path $mapaDir "indice-arquivos.md"

# Determinar diretorio do codigo
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
    $legadoEscrita = Join-Path $env:USERPROFILE "EscritaSDD-dados-pesados\versao-atual\pbcvsexp"
    $legadoFolha = Join-Path $env:USERPROFILE "FolhaSDD-dados-pesados\versao-atual\pbcvsexp"
    if (Test-Path $legadoEscrita) {
        $pbcvsexpDir = $legadoEscrita
        $CodigoDir = Join-Path $env:USERPROFILE "EscritaSDD-dados-pesados\versao-atual"
    } elseif (Test-Path $legadoFolha) {
        $pbcvsexpDir = $legadoFolha
        $CodigoDir = Join-Path $env:USERPROFILE "FolhaSDD-dados-pesados\versao-atual"
    } else {
        Write-Host "ERRO: Diretorio de codigo nao encontrado." -ForegroundColor Red
        Write-Host "  Tentei: $pbcvsexpDir"
        Write-Host "  Tentei: $legadoEscrita e $legadoFolha"
        Write-Host "Rode atualizar-codigo.ps1 primeiro."
        exit 1
    }
}

Write-Host "=== Gerador de Indice de Codigo-Fonte ===" -ForegroundColor Cyan
Write-Host "Codigo: $pbcvsexpDir"
Write-Host "Indice: $indiceFile"
Write-Host ""

$pblAreaJsonPath = Join-Path $mapaDir "pbl-area-escrita.json"
$libRules = Join-Path $scriptDir "lib\escrita-pbl-area-rules.ps1"
$pblArea = @{}
if (Test-Path $pblAreaJsonPath) {
    $rawJson = Get-Content $pblAreaJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($prop in $rawJson.PSObject.Properties) {
        $pblArea[$prop.Name] = [string]$prop.Value
    }
    Write-Host "Mapa PBL carregado: $($pblArea.Count) entradas em pbl-area-escrita.json" -ForegroundColor DarkGray
} else {
    Write-Host "AVISO: pbl-area-escrita.json nao encontrado. Rode scripts\gerar-mapa-pbl-escrita.ps1" -ForegroundColor Yellow
}
if (Test-Path $libRules) {
    . $libRules
} else {
    function Get-EscritaAreaPbl { param([string]$PblName) return "" }
}

function Get-AreaParaPbl {
    param([string]$NomePbl)
    if ($pblArea.ContainsKey($NomePbl)) { return $pblArea[$NomePbl] }
    return (Get-EscritaAreaPbl $NomePbl)
}

$tiposPB = @{
    ".srw" = "Window"
    ".sru" = "UserObject"
    ".srd" = "DataWindow"
    ".srm" = "Menu"
    ".srf" = "Function"
    ".srj" = "Project"
    ".srs" = "Structure"
    ".srp" = "Pipeline"
    ".sr?" = "Outro"
}

# Varrer pastas PBL
Write-Host "Varrendo PBLs..." -ForegroundColor Yellow
$pbls = Get-ChildItem $pbcvsexpDir -Directory | Sort-Object Name
$totalArquivos = 0
$pblData = @()

foreach ($pbl in $pbls) {
    $arquivos = Get-ChildItem $pbl.FullName -File -ErrorAction SilentlyContinue | Sort-Object Name
    $area = Get-AreaParaPbl $pbl.Name
    $pblData += @{
        nome = $pbl.Name
        area = $area
        arquivos = $arquivos
        total = $arquivos.Count
    }
    $totalArquivos += $arquivos.Count
    Write-Host "  $($pbl.Name): $($arquivos.Count) arquivos $(if ($area) { "($area)" })"
}

# Gerar Markdown
Write-Host ""
Write-Host "Gerando indice..." -ForegroundColor Yellow

$md = @"
# Indice de Arquivos -- Codigo-Fonte Escrita

> Gerado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm')
> Codigo: $CodigoDir
> Total: $totalArquivos arquivos em $($pbls.Count) PBLs
> Areas (coluna Area): ``mapa-sistema/pbl-area-escrita.json`` + fallback ``scripts/lib/escrita-pbl-area-rules.ps1``

## Resumo por PBL

| PBL | Area | Arquivos | Windows | UserObjects | DataWindows | Outros |
|-----|------|----------|---------|-------------|-------------|--------|

"@

foreach ($p in $pblData) {
    $wins = @($p.arquivos | Where-Object { $_.Extension -eq ".srw" }).Count
    $uos = @($p.arquivos | Where-Object { $_.Extension -eq ".sru" }).Count
    $dws = @($p.arquivos | Where-Object { $_.Extension -eq ".srd" }).Count
    $outros = $p.total - $wins - $uos - $dws
    $md += "| $($p.nome) | $($p.area) | $($p.total) | $wins | $uos | $dws | $outros |`n"
}

$md += "`n---`n"

foreach ($p in $pblData) {
    if ($p.total -eq 0) { continue }
    $areaLabel = if ($p.area) { " -- $($p.area)" } else { "" }
    $md += "`n## $($p.nome)$areaLabel ($($p.total) arquivos)`n`n"
    $md += "| Arquivo | Tipo | Tamanho |`n"
    $md += "|---------|------|---------|`n"
    foreach ($arq in $p.arquivos) {
        $ext = $arq.Extension.ToLower()
        $tipo = if ($tiposPB.ContainsKey($ext)) { $tiposPB[$ext] } else { $ext }
        $size = if ($arq.Length -gt 1024*1024) { "$([math]::Round($arq.Length/1MB,1))MB" }
               elseif ($arq.Length -gt 1024) { "$([math]::Round($arq.Length/1KB,0))KB" }
               else { "$($arq.Length)B" }
        $md += "| $($arq.Name) | $tipo | $size |`n"
    }
}

New-Item -ItemType Directory -Path $mapaDir -Force | Out-Null
Set-Content -Path $indiceFile -Value $md -Encoding UTF8

Write-Host ""
Write-Host "=== Concluido! ===" -ForegroundColor Green
Write-Host "Indice gerado: $indiceFile"
Write-Host "Total: $totalArquivos arquivos em $($pbls.Count) PBLs"
