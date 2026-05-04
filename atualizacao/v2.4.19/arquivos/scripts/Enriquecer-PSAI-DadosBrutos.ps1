#Requires -Version 5.1
<#
.SYNOPSIS
  Enriquece JSON em banco-dados/dados-brutos/psai/ via script Python do repositório General
  (igual conceito ao script na raiz Admin). Só útil quem tem escrita no clone General/OneDrive.

.EXAMPLE
  .\Enriquecer-PSAI-DadosBrutos.ps1 130475
  .\Enriquecer-PSAI-DadosBrutos.ps1 130475 --dry-run
#>
param(
    [switch]$DryRun,
    [switch]$ArquivoSgd,
    [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
    [int[]]$Numeros
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir
. (Join-Path $scriptDir "lib-sgd-caminhos.ps1")
$pkg = Get-SgdConsultaPkgDir -ProjetoFilhoRoot $projetoDir
$pyScript = if ($pkg) { Join-Path $pkg "enriquecer_psai_dados_brutos.py" } else { "" }

if (-not (Test-Path -LiteralPath $pyScript)) {
    Write-Error @"
Nao foi encontrado enriquecer_psai_dados_brutos.py (modulo SGD).

Defina GENERAL_REPO_ROOT, ou atualize o projeto-filho para incluir scripts\sgd_consulta,
ou use o clone General ao lado do filho. Ver mensagem de Consultar-PSAI-SGD.ps1 para a mesma ordem de pastas.
"@
}

$dataRoot = Join-Path $projetoDir "data\sgd-psai-consultas"
New-Item -ItemType Directory -Force -Path $dataRoot | Out-Null
$env:SGD_SGD_DATA_ROOT = $dataRoot

$credFromShell = $false
if (Test-SgdCredentialsLocalFile -DataRootSgd $dataRoot) {
    Write-Host ""
    Write-Host "Credenciais SGD: a usar ficheiro local." -ForegroundColor DarkGray
}
else {
    Write-Host ""
    Write-Host "SGD — indique utilizador e senha (primeira vez ou sem ficheiro .sgd-credentials.local)." -ForegroundColor Cyan
    $u = Read-Host "Utilizador SGD"
    if ([string]::IsNullOrWhiteSpace($u)) { Write-Error "Utilizador vazio." }
    $sec = Read-Host "Senha SGD" -AsSecureString
    if ($null -eq $sec -or $sec.Length -eq 0) { Write-Error "Senha vazia." }
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    try { $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    $env:SGD_USERNAME = $u.Trim()
    $env:SGD_PASSWORD = $plain
    $credFromShell = $true
    $save = Read-Host "Gravar neste PC para não voltar a pedir? (S/N)"
    if ($save -eq "S" -or $save -eq "s") {
        Save-SgdCredentialsLocalFile -DataRootSgd $dataRoot -UserName $env:SGD_USERNAME -PlainPassword $plain
        Write-Host "Credenciais gravadas em data\sgd-psai-consultas\.sgd-credentials.local" -ForegroundColor Green
    }
}
Write-Host ""

$pkg = Split-Path -Parent $pyScript
$venvPy = Join-Path $pkg ".venv\Scripts\python.exe"
$pythonDisponivel = (Test-Path -LiteralPath $venvPy) -or [bool](Get-Command python -ErrorAction SilentlyContinue)
if (-not $pythonDisponivel) {
    Write-Error @'
Python nao encontrado. Instale Python 3.10+ no PATH e rode: .\scripts\setup-sgd-python.ps1
'@
}
$args = @()
foreach ($n in $Numeros) { $args += "$n" }
if ($DryRun) { $args += "--dry-run" }
if ($ArquivoSgd) { $args += "--arquivo-sgd" }

Write-Host "A usar modulo SGD em: $pkg" -ForegroundColor DarkGray
Write-Host ""

try {
    if (Test-Path $venvPy) { & $venvPy $pyScript @args }
    else { & python $pyScript @args }
}
finally {
    if ($credFromShell) {
        Remove-Item Env:SGD_USERNAME -ErrorAction SilentlyContinue
        Remove-Item Env:SGD_PASSWORD -ErrorAction SilentlyContinue
    }
    Remove-Item Env:SGD_SGD_DATA_ROOT -ErrorAction SilentlyContinue
}
