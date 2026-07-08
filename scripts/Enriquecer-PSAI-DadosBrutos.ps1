#Requires -Version 5.1
<#
.SYNOPSIS
  Consulta o SGD e preenche em banco-dados/dados-brutos/psai/*.json os campos
  vazios: comportamento, definicao e (se vazio) psai_descricao.

.DESCRIPTION
  Mesma ordem de credenciais que Consultar-PSAI-SGD.ps1 (ambiente, .sgd-credentials.local
  nos caminhos do env.py, ou Read-Host na primeira vez).

.EXAMPLE
  .\Enriquecer-PSAI-DadosBrutos.ps1 130475
  .\Enriquecer-PSAI-DadosBrutos.ps1 130475 130476 -DryRun
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
if (-not $pkg) {
    Write-Error "Nao foi encontrado scripts\sgd_consulta (consultar_psai). Verifique o clone do General."
}

$dataRoot = Join-Path $projetoDir "data\sgd-psai-consultas"
$credFromShell = $false
$envUser = $env:SGD_USERNAME
$envPass = $env:SGD_PASSWORD
$envCred = (-not [string]::IsNullOrWhiteSpace($envUser)) -and (-not [string]::IsNullOrWhiteSpace($envPass))

if ($envCred) {
    Write-Host "Credenciais SGD: variaveis de ambiente." -ForegroundColor DarkGray
}
elseif (Test-SgdCredentialsLocalFileAny -GeneralRoot $projetoDir -PkgDir $pkg) {
    Write-Host "Credenciais SGD: .sgd-credentials.local (ficheiro local)." -ForegroundColor DarkGray
}
else {
    if ([Console]::IsInputRedirected) {
        Write-Error @"
Credenciais SGD nao configuradas (execucao nao-interativa).

Defina SGD_USERNAME/SGD_PASSWORD ou crie .sgd-credentials.local (ver scripts\sgd_consulta\.sgd-credentials.local.example).
"@
    }
    Write-Host ""
    Write-Host "Enriquecer PSAI — credenciais SGD (nao lidas do .env geral)." -ForegroundColor Cyan
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
    New-Item -ItemType Directory -Force -Path $dataRoot | Out-Null
    $save = Read-Host "Gravar credenciais em data\sgd-psai-consultas\.sgd-credentials.local? (S/N)"
    if ($save -eq "S" -or $save -eq "s") {
        Save-SgdCredentialsLocalFile -DataRootSgd $dataRoot -UserName $env:SGD_USERNAME -PlainPassword $plain
        Write-Host "Credenciais gravadas." -ForegroundColor Green
    }
}

$script = Join-Path $pkg "enriquecer_psai_dados_brutos.py"
$venvPy = Join-Path $pkg ".venv\Scripts\python.exe"
$args = @()
foreach ($n in $Numeros) { $args += "$n" }
if ($DryRun) { $args += "--dry-run" }
if ($ArquivoSgd) { $args += "--arquivo-sgd" }

try {
    if (Test-Path $venvPy) { & $venvPy $script @args }
    else { & python $script @args }
}
finally {
    if ($credFromShell) {
        Remove-Item Env:SGD_USERNAME -ErrorAction SilentlyContinue
        Remove-Item Env:SGD_PASSWORD -ErrorAction SilentlyContinue
    }
}
