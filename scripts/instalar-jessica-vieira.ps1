# Instalacao do projeto filho - Jéssica Vieira
# Executa o instalador com nome, email e ZIP do codigo fonte.
# Logs sao criados no OneDrive e sincronizados automaticamente no drive.

$ErrorActionPreference = "Stop"
$baseDir = Split-Path -Parent $PSScriptRoot
$scriptInstalar = Join-Path $PSScriptRoot "instalar-projeto-filho.ps1"
$zipPath = Join-Path $env:USERPROFILE "Downloads\brtap-dominio_contabil-VC106A02.zip"

if (-not (Test-Path $scriptInstalar)) {
    Write-Host "ERRO: instalar-projeto-filho.ps1 nao encontrado em: $scriptInstalar" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $zipPath)) {
    Write-Host "AVISO: ZIP nao encontrado em $zipPath" -ForegroundColor Yellow
    Write-Host "Coloque brtap-dominio_contabil-VC106A02.zip na pasta Downloads ou informe o caminho." -ForegroundColor Yellow
    $zipPath = Read-Host "Caminho completo do ZIP (ou Enter para pular e usar Git)"
    if ([string]::IsNullOrWhiteSpace($zipPath)) { $zipPath = $null }
}

Set-Location $baseDir
& $scriptInstalar -Nome "Jéssica Vieira" -Email "jessica.maximiano@thomsonreuters.com" -ZipPath $zipPath
