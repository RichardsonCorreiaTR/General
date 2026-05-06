# setup-odbc.ps1
# Configura o DSN ODBC pbcvs9 para acesso ao banco PBCVS (Sybase ASA 9.0)
# Requer execucao como Administrador para DSN de sistema

param(
    [string]$DSN = "pbcvs9",
    [string]$Server = "pbcvs9",
    [string]$DatabaseFile = "",
    [string]$Usuario = "",
    [switch]$Verificar
)

$ErrorActionPreference = "Stop"

Write-Host "=== Setup ODBC - PBCVS ===" -ForegroundColor Cyan
Write-Host ""

if ($Verificar) {
    Write-Host "Verificando DSNs ODBC existentes..." -ForegroundColor Yellow
    $dsns = Get-OdbcDsn -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*pbcvs*" -or $_.Name -like "*sybase*" }
    if ($dsns) {
        Write-Host "DSNs encontrados:" -ForegroundColor Green
        $dsns | Format-Table Name, DriverName, DsnType, Platform -AutoSize
    } else {
        Write-Host "Nenhum DSN PBCVS/Sybase encontrado." -ForegroundColor Red
        Write-Host "Voce precisa:"
        Write-Host "  1. Instalar o driver ODBC do SQL Anywhere 9.0"
        Write-Host "  2. Rodar este script sem -Verificar para configurar o DSN"
    }
    
    Write-Host ""
    Write-Host "Drivers ODBC disponiveis:" -ForegroundColor Yellow
    Get-OdbcDriver | Where-Object { $_.Name -like "*SQL Anywhere*" -or $_.Name -like "*Sybase*" -or $_.Name -like "*Adaptive*" } | Format-Table Name, Platform -AutoSize
    exit 0
}

# Verificar driver
$driver = Get-OdbcDriver | Where-Object { $_.Name -like "*SQL Anywhere*" } | Select-Object -First 1
if (-not $driver) {
    Write-Host "ERRO: Driver SQL Anywhere nao encontrado." -ForegroundColor Red
    Write-Host "Instale o driver ODBC do SQL Anywhere 9.0 primeiro."
    Write-Host "Consulte o time de infra para o instalador."
    exit 1
}

Write-Host "Driver encontrado: $($driver.Name)" -ForegroundColor Green
Write-Host ""
Write-Host "Para configurar o DSN, use o Administrador de Fonte de Dados ODBC:"
Write-Host "  1. Abra: odbcad32.exe"
Write-Host "  2. Aba 'DSN de Sistema' ou 'DSN de Usuario'"
Write-Host "  3. Adicionar > selecione '$($driver.Name)'"
Write-Host "  4. Nome do DSN: $DSN"
Write-Host "  5. Configure servidor e banco conforme sua rede"
Write-Host ""
Write-Host "Ou peca ao colega que ja tem o ODBC configurado para exportar o DSN."
