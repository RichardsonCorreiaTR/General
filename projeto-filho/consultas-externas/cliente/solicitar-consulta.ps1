#Requires -Version 5.1
param(
    [Parameter(Mandatory = $true)]
    [string]$FilhoRoot,
    [Parameter(Mandatory = $true)]
    [ValidateSet("sai", "codigo", "ler-arquivo", "sai-sgd", "psai-sgd")]
    [string]$Tipo,
    [string]$Origem = "projeto-externo",
    [string]$Termo = "",
    [string]$Query = "",
    [string]$Arquivo = "",
    [int]$Sai = 0,
    [int]$Psai = 0,
    [int]$Numero = 0,
    [int]$Max = 20,
    [string]$TipoSai = "",
    [string]$ConceitoBranch = "vigente",
    [string]$Pergunta = "",
    [string]$Id = ""
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path $FilhoRoot)) { throw "projeto-filho nao encontrado: $FilhoRoot" }
$entrada = Join-Path $FilhoRoot "consultas-externas\entrada"
New-Item -ItemType Directory -Path $entrada -Force | Out-Null
if (-not $Id) { $Id = "p-" + (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + (Get-Random -Maximum 9999) }
$pedido = [pscustomobject]@{
    id        = $Id
    origem    = $Origem
    tipo      = $Tipo
    criadoEm  = (Get-Date).ToString("o")
    pergunta  = $Pergunta
    parametros = [pscustomobject]@{
        termo           = $Termo
        tipoSai         = $TipoSai
        sai             = $Sai
        psai            = $Psai
        max             = $Max
        modulo          = ""
        pendentes       = $false
        query           = $Query
        arquivo         = $Arquivo
        conceitoBranch  = $ConceitoBranch
        numero          = $Numero
    }
}
$path = Join-Path $entrada "$Id.json"
$pedido | ConvertTo-Json -Depth 6 | Set-Content -Path $path -Encoding UTF8
Write-Host "Pedido gravado: $path"
Write-Host "Id: $Id"
Write-Host "Processe no filho: powershell -File `"$FilhoRoot\scripts\processar-consultas-externas.ps1`""
