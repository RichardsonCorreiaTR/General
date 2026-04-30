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

Write-Host ""
Write-Host "Enriquecer PSAI — credenciais SGD (não lidas do .env geral)." -ForegroundColor Cyan
$u = Read-Host "Utilizador SGD"
if ([string]::IsNullOrWhiteSpace($u)) { Write-Error "Utilizador vazio." }
$sec = Read-Host "Senha SGD" -AsSecureString
if ($null -eq $sec -or $sec.Length -eq 0) { Write-Error "Senha vazia." }
$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
try { $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr) }
finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
$env:SGD_USERNAME = $u.Trim()
$env:SGD_PASSWORD = $plain

$pkg = Split-Path -Parent $pyScript
$venvPy = Join-Path $pkg ".venv\Scripts\python.exe"
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
    Remove-Item Env:SGD_USERNAME -ErrorAction SilentlyContinue
    Remove-Item Env:SGD_PASSWORD -ErrorAction SilentlyContinue
}
