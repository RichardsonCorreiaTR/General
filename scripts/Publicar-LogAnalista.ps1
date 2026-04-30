#Requires -Version 5.1
<#
.SYNOPSIS
  Copia diarios de log (projeto-filho referencia/logs ou pasta explicita) para General/logs/analistas/<slug>/.

.DESCRIPTION
  Publica ficheiros do dia (AAAA-MM-DD.md, AAAA-MM-DD-2.md, ...) para o gerente poder correr consolidar-logs.ps1.

.PARAMETER AnalistaSlug
  Nome da pasta sob logs/analistas/ (ex.: rafaela-gubert-ribeiro).

.PARAMETER Data
  Dia no formato yyyy-MM-dd. Predefinido: hoje (UTC local).

.PARAMETER ProjetoFilhoRoot
  Raiz do clone projeto-filho; origem = <root>\referencia\logs. Omitir se usar -OrigemDir.

.PARAMETER OrigemDir
  Pasta que contem os ficheiros .md do dia. Omitir se usar -ProjetoFilhoRoot.

.PARAMETER GeneralRoot
  Raiz do repositorio General. Predefinido: pasta pai de scripts\ (este script vive em General\scripts).

.PARAMETER SimularApenas
  Lista origens e destinos sem copiar.

.EXAMPLE
  .\Publicar-LogAnalista.ps1 -AnalistaSlug rafaela-gubert-ribeiro -ProjetoFilhoRoot "C:\CursorEscrita\projeto-filho"

.EXAMPLE
  .\Publicar-LogAnalista.ps1 -AnalistaSlug rafaela-gubert-ribeiro -OrigemDir "C:\CursorEscrita\projeto-filho\referencia\logs" -Data 2026-04-29
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$AnalistaSlug,

    [string]$Data = (Get-Date -Format "yyyy-MM-dd"),

    [string]$ProjetoFilhoRoot = "",

    [string]$OrigemDir = "",

    [string]$GeneralRoot = "",

    [switch]$SimularApenas
)

$ErrorActionPreference = "Stop"

if ($Data -notmatch '^\d{4}-\d{2}-\d{2}$') {
    Write-Error "Parametro -Data deve ser yyyy-MM-dd (recebido: '$Data')."
}

if ($GeneralRoot) {
    $GeneralRoot = (Resolve-Path -LiteralPath $GeneralRoot).Path
}
else {
    $GeneralRoot = Split-Path -Parent $PSScriptRoot
}

$destDir = Join-Path $GeneralRoot "logs\analistas\$AnalistaSlug"

# Resolver pasta de origem
$origemResolved = ""
if ($OrigemDir) {
    if (-not (Test-Path -LiteralPath $OrigemDir)) {
        Write-Error "OrigemDir nao existe: $OrigemDir"
    }
    $origemResolved = (Resolve-Path -LiteralPath $OrigemDir).Path
}
elseif ($ProjetoFilhoRoot) {
    if (-not (Test-Path -LiteralPath $ProjetoFilhoRoot)) {
        Write-Error "ProjetoFilhoRoot nao existe: $ProjetoFilhoRoot"
    }
    $p = (Resolve-Path -LiteralPath $ProjetoFilhoRoot).Path
    $origemResolved = Join-Path $p "referencia\logs"
    if (-not (Test-Path -LiteralPath $origemResolved)) {
        Write-Error "Pasta referencia\logs nao encontrada em: $p"
    }
}
elseif ($env:PROJETO_FILHO_ROOT -and (Test-Path -LiteralPath (Join-Path $env:PROJETO_FILHO_ROOT "referencia\logs"))) {
    $origemResolved = Join-Path ((Resolve-Path -LiteralPath $env:PROJETO_FILHO_ROOT).Path) "referencia\logs"
}
else {
    $siblingFilho = Join-Path (Split-Path -Parent $GeneralRoot) "projeto-filho\referencia\logs"
    if (Test-Path -LiteralPath $siblingFilho) {
        $origemResolved = (Resolve-Path -LiteralPath $siblingFilho).Path
    }
}

if (-not $origemResolved) {
    Write-Error @"
Nao foi possivel determinar a pasta de origem.
Indique -ProjetoFilhoRoot (raiz do projeto-filho) ou -OrigemDir (pasta dos .md),
ou defina a variavel de ambiente PROJETO_FILHO_ROOT apontando para a raiz do projeto-filho.
"@
}

$esc = [regex]::Escape($Data)
$arquivos = Get-ChildItem -LiteralPath $origemResolved -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match "^$esc(-\d+)?\.md$" }

if (-not $arquivos -or $arquivos.Count -eq 0) {
    Write-Error "Nenhum ficheiro encontrado em '$origemResolved' com padrao ${Data}*.md (ex.: ${Data}.md, ${Data}-2.md)."
}

Write-Host ""
Write-Host "Publicar log analista -> consolidacao" -ForegroundColor Cyan
Write-Host "  Origem:  $origemResolved"
Write-Host "  Destino: $destDir"
Write-Host "  Ficheiros: $($arquivos.Count)"
Write-Host ""

if ($SimularApenas) {
    foreach ($f in $arquivos) {
        Write-Host "  [SIMULAR] $($f.Name) -> $(Join-Path $destDir $f.Name)" -ForegroundColor Yellow
    }
    return
}

New-Item -ItemType Directory -Force -Path $destDir | Out-Null

foreach ($f in $arquivos) {
    $dest = Join-Path $destDir $f.Name
    Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
    Write-Host "  Copiado: $($f.Name)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Concluido. No General: .\scripts\consolidar-logs.ps1 -Periodo semana" -ForegroundColor DarkGray
