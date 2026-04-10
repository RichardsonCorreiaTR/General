$ErrorActionPreference = "Stop"
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# Measure initial RAM
$proc = Get-Process -Id $PID
$initialRAM = $proc.PeakWorkingSet64

# Run the script
& "C:\Users\6038243\Thomson Reuters Incorporated\CursorFolha - General\scripts\gerar-indices-sais.ps1"

# Measure final RAM
$proc = Get-Process -Id $PID
$peakRAM = $proc.PeakWorkingSet64
$peakMB = [math]::Round($peakRAM / 1MB, 1)
$sw.Stop()

Write-Host ""
Write-Host "=== METRICAS ===" -ForegroundColor Magenta
Write-Host "Tempo total: $([math]::Round($sw.Elapsed.TotalSeconds, 1)) segundos"
Write-Host "RAM pico: $peakMB MB"
