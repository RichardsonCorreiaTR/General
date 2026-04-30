#Requires -Version 5.1
<#
.SYNOPSIS
  Consulta PSAI no SGD via o script do repositório General. Pede **sempre** utilizador e senha SGD
  (igual ao script na pasta scripts do General; não usa credenciais do ficheiro .env).

  Define SGD_SGD_DATA_ROOT para gravar consultas, arquivo (HTML/grids), logs e sessão Playwright em
  projeto-filho/data/sgd-psai-consultas/ (dados por analista nesta cópia do projeto-filho).

.EXAMPLE
  .\Consultar-PSAI-SGD.ps1 130298
  .\Consultar-PSAI-SGD.ps1 130298 --json
  .\Consultar-PSAI-SGD.ps1 130298 --json --quiet
#>
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ArgumentList = @()
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir
$generalRoot = Split-Path -Parent $projetoDir
$consultar = Join-Path $generalRoot "scripts\sgd_consulta\consultar_psai.py"

if (-not (Test-Path $consultar)) {
    Write-Error "Não encontrado: $consultar (esperado General/scripts/sgd_consulta a partir de projeto-filho)."
}

$dataRoot = Join-Path $projetoDir "data\sgd-psai-consultas"
New-Item -ItemType Directory -Force -Path $dataRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $dataRoot "consultas") | Out-Null
$env:SGD_SGD_DATA_ROOT = $dataRoot

Write-Host ""
Write-Host "Consulta SGD — indique as SUAS credenciais (não são lidas do .env)." -ForegroundColor Cyan
$u = Read-Host "Utilizador SGD"
if ([string]::IsNullOrWhiteSpace($u)) {
    Write-Error "Utilizador vazio."
}
$sec = Read-Host "Senha SGD" -AsSecureString
if ($null -eq $sec -or $sec.Length -eq 0) {
    Write-Error "Senha vazia."
}
$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
try {
    $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
}
finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
}
$env:SGD_USERNAME = $u.Trim()
$env:SGD_PASSWORD = $plain

Write-Host "A consultar o SGD como: $($env:SGD_USERNAME)" -ForegroundColor Green
Write-Host "Dados locais (JSON, arquivo, logs, sessão): $dataRoot" -ForegroundColor DarkGray
Write-Host ""

$pkg = Split-Path -Parent $consultar
$venvPy = Join-Path $pkg ".venv\Scripts\python.exe"
try {
    if (Test-Path $venvPy) {
        & $venvPy $consultar @ArgumentList
    }
    else {
        & python $consultar @ArgumentList
    }
}
finally {
    Remove-Item Env:SGD_USERNAME -ErrorAction SilentlyContinue
    Remove-Item Env:SGD_PASSWORD -ErrorAction SilentlyContinue
    Remove-Item Env:SGD_SGD_DATA_ROOT -ErrorAction SilentlyContinue
}
