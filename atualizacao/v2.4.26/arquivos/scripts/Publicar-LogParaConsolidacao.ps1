#Requires -Version 5.1
<#
.SYNOPSIS
  Copia o diario de referencia/logs para o clone General (logs/analistas/<slug>/).

.DESCRIPTION
  Wrapper que chama General/scripts/Publicar-LogAnalista.ps1 com -ProjetoFilhoRoot
  apontando para esta pasta projeto-filho.

.PARAMETER AnalistaSlug
  Obrigatorio. Nome da pasta em logs/analistas/ no General (ex.: rafaela-gubert-ribeiro).

.PARAMETER Data
  Dia yyyy-MM-dd. Predefinido: hoje.

.PARAMETER GeneralRoot
  Raiz do repositorio General. Se omitido: irmao projeto-filho (..\) ou variavel GENERAL_REPO_ROOT.

.PARAMETER SimularApenas
  Repassado ao script do General.

.EXAMPLE
  .\Publicar-LogParaConsolidacao.ps1 -AnalistaSlug rafaela-gubert-ribeiro

.EXAMPLE
  .\Publicar-LogParaConsolidacao.ps1 -AnalistaSlug rafaela-gubert-ribeiro -GeneralRoot "D:\OneDrive\General" -Data 2026-04-29
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$AnalistaSlug,

    [string]$Data = (Get-Date -Format "yyyy-MM-dd"),

    [string]$GeneralRoot = "",

    [switch]$SimularApenas
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoFilhoRoot = Split-Path -Parent $scriptDir

if (-not $GeneralRoot) {
    $parent = Split-Path -Parent $projetoFilhoRoot
    # Monorepo: .../General/projeto-filho -> scripts ficam em .../General/scripts
    $pubMono = Join-Path $parent "scripts\Publicar-LogAnalista.ps1"
    # Instalacao tipica: .../CursorEscrita/projeto-filho e .../CursorEscrita/General
    $pubSibling = Join-Path $parent "General\scripts\Publicar-LogAnalista.ps1"
    if (Test-Path -LiteralPath $pubMono) {
        $GeneralRoot = (Resolve-Path -LiteralPath $parent).Path
    }
    elseif (Test-Path -LiteralPath $pubSibling) {
        $GeneralRoot = (Resolve-Path -LiteralPath (Join-Path $parent "General")).Path
    }
    elseif ($env:GENERAL_REPO_ROOT) {
        $g = $env:GENERAL_REPO_ROOT.Trim()
        if (-not (Test-Path -LiteralPath (Join-Path $g "scripts\Publicar-LogAnalista.ps1"))) {
            Write-Error "GENERAL_REPO_ROOT definido mas nao contem scripts\Publicar-LogAnalista.ps1: $g"
        }
        $GeneralRoot = (Resolve-Path -LiteralPath $g).Path
    }
    else {
        Write-Error @"
Nao foi encontrado o repositorio General (irmao de projeto-filho).
Passe -GeneralRoot com a raiz do clone General (onde existe scripts\Publicar-LogAnalista.ps1)
ou defina a variavel de ambiente GENERAL_REPO_ROOT.
"@
    }
}

$publicar = Join-Path $GeneralRoot "scripts\Publicar-LogAnalista.ps1"
if (-not (Test-Path -LiteralPath $publicar)) {
    Write-Error "Script nao encontrado: $publicar"
}

$params = @{
    AnalistaSlug     = $AnalistaSlug
    Data             = $Data
    ProjetoFilhoRoot = $projetoFilhoRoot
    GeneralRoot      = $GeneralRoot
}
if ($SimularApenas) { $params["SimularApenas"] = $true }

& $publicar @params
