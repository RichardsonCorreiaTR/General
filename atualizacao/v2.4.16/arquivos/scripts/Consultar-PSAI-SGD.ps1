#Requires -Version 5.1
<#
.SYNOPSIS
  Consulta PSAI no SGD via o script do repositório General.

  Na **primeira** utilização (sem `data/sgd-psai-consultas/.sgd-credentials.local` com utilizador),
  pede utilizador e senha SGD; opcionalmente pode gravar nesse ficheiro para não voltar a pedir.
  Se o ficheiro já existir (ex.: após instalação ou gravação anterior), as credenciais vêm dele
  (não usa o .env geral do projeto).

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
. (Join-Path $scriptDir "lib-sgd-caminhos.ps1")
$pkg = Get-SgdConsultaPkgDir -ProjetoFilhoRoot $projetoDir
$consultar = if ($pkg) { Join-Path $pkg "consultar_psai.py" } else { "" }

if (-not (Test-Path -LiteralPath $consultar)) {
    Write-Error @"
Nao foi encontrado consultar_psai.py (modulo SGD).

Ordem de procura:
  1) variavel de ambiente GENERAL_REPO_ROOT (raiz do clone General) + scripts\sgd_consulta
  2) projeto-filho\scripts\sgd_consulta (pacote completo)
  3) pasta irma do projeto-filho: ..\scripts\sgd_consulta (monorepo)
  4) ..\General\scripts\sgd_consulta (instalacao CursorEscrita\General + projeto-filho)

Atualize o projeto-filho (.\scripts\atualizar-projeto.ps1) para a ultima versao do pacote (inclui scripts\sgd_consulta),
ou defina GENERAL_REPO_ROOT apontando para a raiz do repositorio General.
"@
}

$dataRoot = Join-Path $projetoDir "data\sgd-psai-consultas"
New-Item -ItemType Directory -Force -Path $dataRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $dataRoot "consultas") | Out-Null
$env:SGD_SGD_DATA_ROOT = $dataRoot

$credFromShell = $false
if (Test-SgdCredentialsLocalFile -DataRootSgd $dataRoot) {
    Write-Host ""
    Write-Host "Credenciais SGD: a usar ficheiro local (primeira consulta já configurada)." -ForegroundColor DarkGray
    Write-Host "Dados locais (JSON, arquivo, logs, sessão): $dataRoot" -ForegroundColor DarkGray
    Write-Host ""
}
else {
    Write-Host ""
    Write-Host "SGD — primeira consulta neste projeto (ou sem credenciais gravadas)." -ForegroundColor Cyan
    Write-Host "Indique o seu utilizador e senha do SGD para aceder à PSAI (não vêm do .env do projeto)." -ForegroundColor Cyan
    Write-Host ""
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
    $credFromShell = $true
    $save = Read-Host "Gravar neste PC para não voltar a pedir? (S/N)"
    if ($save -eq "S" -or $save -eq "s") {
        Save-SgdCredentialsLocalFile -DataRootSgd $dataRoot -UserName $env:SGD_USERNAME -PlainPassword $plain
        Write-Host "Credenciais gravadas em data\sgd-psai-consultas\.sgd-credentials.local" -ForegroundColor Green
    }
    Write-Host "A consultar o SGD como: $($env:SGD_USERNAME)" -ForegroundColor Green
    Write-Host "Dados locais (JSON, arquivo, logs, sessão): $dataRoot" -ForegroundColor DarkGray
    Write-Host ""
}

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
    if ($credFromShell) {
        Remove-Item Env:SGD_USERNAME -ErrorAction SilentlyContinue
        Remove-Item Env:SGD_PASSWORD -ErrorAction SilentlyContinue
    }
    Remove-Item Env:SGD_SGD_DATA_ROOT -ErrorAction SilentlyContinue
}
