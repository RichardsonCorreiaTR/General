#Requires -Version 5.1
<#
.SYNOPSIS
  Consulta o SGD e preenche em banco-dados/dados-brutos/psai/*.json os campos
  vazios: comportamento, definicao e (se vazio) psai_descricao.

.DESCRIPTION
  Usa o mesmo login que Consultar-PSAI-SGD.ps1. Requer Playwright + venv em
  scripts/sgd_consulta ou Python no PATH.

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

$pkg = Join-Path $PSScriptRoot "sgd_consulta"
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
    Remove-Item Env:SGD_USERNAME -ErrorAction SilentlyContinue
    Remove-Item Env:SGD_PASSWORD -ErrorAction SilentlyContinue
}
