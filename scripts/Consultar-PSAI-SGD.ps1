#Requires -Version 5.1
<#
.SYNOPSIS
  Consulta uma PSAI no SGD (Playwright). Pede **sempre** o utilizador e a senha SGD
  (o mesmo fluxo do projeto-filho; não usa credenciais do ficheiro .env).

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
Write-Host ""

$pkg = Join-Path $PSScriptRoot "sgd_consulta"
$script = Join-Path $pkg "consultar_psai.py"
$venvPy = Join-Path $pkg ".venv\Scripts\python.exe"

try {
    if (Test-Path $venvPy) {
        & $venvPy $script @ArgumentList
    }
    else {
        & python $script @ArgumentList
    }
}
finally {
    Remove-Item Env:SGD_USERNAME -ErrorAction SilentlyContinue
    Remove-Item Env:SGD_PASSWORD -ErrorAction SilentlyContinue
}
