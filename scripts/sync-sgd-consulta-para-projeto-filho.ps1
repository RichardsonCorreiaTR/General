#Requires -Version 5.1
<#
.SYNOPSIS
  Copia o modulo Python de consulta SGD (Admin) para projeto-filho/scripts/sgd_consulta.

.DESCRIPTION
  Fonte de verdade: General/scripts/sgd_consulta. Preserva .venv e .sgd-credentials.local no destino.
  Chamado por gerar-atualizacao.ps1 antes de empacotar; pode rodar sozinho apos alterar o Python no Admin.

.EXAMPLE
  .\scripts\sync-sgd-consulta-para-projeto-filho.ps1
#>
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot
$adminSgd = Join-Path $repoRoot "scripts\sgd_consulta"
$filhoSgd = Join-Path $repoRoot "projeto-filho\scripts\sgd_consulta"

if (-not (Test-Path -LiteralPath $adminSgd)) {
    Write-Error "Pasta Admin nao encontrada: $adminSgd"
}

New-Item -ItemType Directory -Force -Path $filhoSgd | Out-Null

Get-ChildItem -LiteralPath $filhoSgd -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne ".sgd-credentials.local" } |
    Remove-Item -Force

Get-ChildItem -LiteralPath $adminSgd -File |
    Where-Object { $_.Name -notmatch "^\.sgd-credentials\.local$" } |
    ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $filhoSgd $_.Name) -Force
    }

$dataDir = Join-Path $filhoSgd "data"
New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
$gitkeep = Join-Path $dataDir ".gitkeep"
if (-not (Test-Path -LiteralPath $gitkeep)) {
    Set-Content -Path $gitkeep -Value "" -Encoding UTF8
}

Write-Host "sync-sgd-consulta: $adminSgd -> $filhoSgd" -ForegroundColor Green
