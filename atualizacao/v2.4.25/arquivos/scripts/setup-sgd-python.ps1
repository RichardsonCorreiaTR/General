#Requires -Version 5.1
<#
.SYNOPSIS
  Cria .venv em scripts/sgd_consulta e instala dependencias (Playwright) para consulta PSAI no SGD.

.DESCRIPTION
  Exige Python 3.10+ no PATH (`python`). Depois deste script, Consultar-PSAI-SGD.ps1 usa automaticamente
  .venv\Scripts\python.exe.

.EXAMPLE
  .\scripts\setup-sgd-python.ps1
#>
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir
. (Join-Path $scriptDir "lib-sgd-caminhos.ps1")
$pkg = Get-SgdConsultaPkgDir -ProjetoFilhoRoot $projetoDir
$req = if ($pkg) { Join-Path $pkg "requirements.txt" } else { "" }

if (-not $pkg -or -not (Test-Path -LiteralPath $req)) {
    Write-Error @"
Nao foi encontrada a pasta scripts\sgd_consulta com requirements.txt.

Atualize o projeto-filho (.\scripts\atualizar-projeto.ps1) ou coloque o repositorio General ao lado do filho.
"@
}

$pyCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pyCmd) {
    Write-Error "Python nao esta no PATH. Instale Python 3.10 ou superior (https://www.python.org/downloads/) e marque 'Add python.exe to PATH'."
}

Write-Host ""
Write-Host "Ambiente SGD (Python) em: $pkg" -ForegroundColor Cyan
Write-Host ""

Push-Location $pkg
try {
    $venvPy = Join-Path $pkg ".venv\Scripts\python.exe"
    $venvPip = Join-Path $pkg ".venv\Scripts\pip.exe"
    if (-not (Test-Path -LiteralPath $venvPy)) {
        Write-Host "Criando ambiente virtual .venv..." -ForegroundColor Yellow
        & python -m venv .venv
        if (-not (Test-Path -LiteralPath $venvPy)) {
            Write-Error "Falha ao criar .venv. Verifique se 'python -m venv' funciona nesta maquina."
        }
    }
    Write-Host "pip install -r requirements.txt ..." -ForegroundColor Yellow
    & $venvPip install -r requirements.txt --disable-pip-version-check
    Write-Host "playwright install chromium ..." -ForegroundColor Yellow
    & $venvPy -m playwright install chromium
    Write-Host ""
    Write-Host "Concluido. Execute: .\scripts\Consultar-PSAI-SGD.ps1 <numero-psai>" -ForegroundColor Green
}
finally {
    Pop-Location
}
