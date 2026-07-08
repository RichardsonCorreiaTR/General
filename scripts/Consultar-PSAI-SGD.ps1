#Requires -Version 5.1
<#
.SYNOPSIS
  Consulta PSAI no SGD (Playwright) a partir do pacote em scripts/sgd_consulta.

.DESCRIPTION
  Credenciais (por ordem): variaveis de ambiente SGD_USERNAME/SGD_PASSWORD;
  ficheiro .sgd-credentials.local em projeto-filho/data/sgd-psai-consultas,
  data/sgd-psai-consultas (raiz do General) ou scripts/sgd_consulta;
  ou pedido interativo na primeira vez.

  Define SGD_SGD_DATA_ROOT para data/sgd-psai-consultas na raiz do clone (JSON,
  arquivo HTML, logs, sessao Playwright), alinhado ao pacote distribuido.

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

Atualize o projeto (.\scripts\atualizar-projeto.ps1 no filho) ou defina GENERAL_REPO_ROOT.
"@
}

$dataRoot = Join-Path $projetoDir "data\sgd-psai-consultas"
New-Item -ItemType Directory -Force -Path $dataRoot | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $dataRoot "consultas") | Out-Null
$env:SGD_SGD_DATA_ROOT = $dataRoot

$credFromShell = $false
$envUser = $env:SGD_USERNAME
$envPass = $env:SGD_PASSWORD
$envCred = (-not [string]::IsNullOrWhiteSpace($envUser)) -and (-not [string]::IsNullOrWhiteSpace($envPass))

if ($envCred) {
    Write-Host ""
    Write-Host "Credenciais SGD: a usar variaveis de ambiente SGD_USERNAME/SGD_PASSWORD." -ForegroundColor DarkGray
    Write-Host "Dados locais (JSON, arquivo, logs, sessao): $dataRoot" -ForegroundColor DarkGray
    Write-Host ""
}
elseif (Test-SgdCredentialsLocalFileAny -GeneralRoot $projetoDir -PkgDir $pkg) {
    Write-Host ""
    Write-Host "Credenciais SGD: a usar .sgd-credentials.local (projeto-filho/data, data/ ou scripts/sgd_consulta)." -ForegroundColor DarkGray
    Write-Host "Dados locais (JSON, arquivo, logs, sessao): $dataRoot" -ForegroundColor DarkGray
    Write-Host ""
}
else {
    if ([Console]::IsInputRedirected) {
        Write-Error @"
Credenciais SGD nao configuradas e execucao nao-interativa detectada.

Configure um destes:
  - Variaveis de ambiente SGD_USERNAME e SGD_PASSWORD, ou
  - Ficheiro .sgd-credentials.local (ver scripts\sgd_consulta\.sgd-credentials.local.example)

Ou execute UMA VEZ manualmente no terminal para gravar credenciais:

    cd <raiz-do-General>
    .\scripts\Consultar-PSAI-SGD.ps1 <numero-psai> --json
"@
    }
    Write-Host ""
    Write-Host "SGD - primeira consulta neste clone (ou sem credenciais gravadas)." -ForegroundColor Cyan
    Write-Host "Indique o seu utilizador e senha do SGD (nao vem do .env geral do projeto)." -ForegroundColor Cyan
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
    $save = Read-Host "Gravar neste PC para nao voltar a pedir? (S/N)"
    if ($save -eq "S" -or $save -eq "s") {
        Save-SgdCredentialsLocalFile -DataRootSgd $dataRoot -UserName $env:SGD_USERNAME -PlainPassword $plain
        Write-Host "Credenciais gravadas em data\sgd-psai-consultas\.sgd-credentials.local" -ForegroundColor Green
    }
    Write-Host "A consultar o SGD como: $($env:SGD_USERNAME)" -ForegroundColor Green
    Write-Host "Dados locais (JSON, arquivo, logs, sessao): $dataRoot" -ForegroundColor DarkGray
    Write-Host ""
}

$pkg = Split-Path -Parent $consultar
$venvPy = Join-Path $pkg ".venv\Scripts\python.exe"
$pythonDisponivel = (Test-Path -LiteralPath $venvPy) -or [bool](Get-Command python -ErrorAction SilentlyContinue)
if (-not $pythonDisponivel) {
    Write-Error @'
Python nao encontrado (nem .venv em scripts\sgd_consulta).

1) Instale Python 3.10+ (https://www.python.org/downloads/) e marque a opcao de adicionar ao PATH.
2) Depois rode: .\scripts\setup-sgd-python.ps1
'@
}
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
