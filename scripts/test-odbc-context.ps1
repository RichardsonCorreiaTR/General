$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$cfg = Get-Content (Join-Path $root "config\conexao-odbc.json") -Raw | ConvertFrom-Json
if ($cfg.extracao.areas -and @($cfg.extracao.areas).Count -gt 0) {
    $areas = @($cfg.extracao.areas)
} elseif ($cfg.extracao.area) {
    $areas = @($cfg.extracao.area)
} else {
    $areas = @("Escrita")
}
$parts = $areas | ForEach-Object { "'" + ($_.ToString().Replace("'", "''")) + "'" }
$inList = $parts -join ", "
Write-Host "Areas no config: $($areas -join ', ')"

$connStr = "DSN=$($cfg.odbc.dsn);UID=$($cfg.odbc.usuario);PWD=$($cfg.odbc.senha);CS=iso_1"
$conn = New-Object System.Data.Odbc.OdbcConnection($connStr)
$conn.Open()
Write-Host "Conexao OK"

$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT COUNT(*) as total FROM UP.SAI_PSAI WHERE nomeArea IN ($inList)"
$r = $cmd.ExecuteReader()
while ($r.Read()) { Write-Host "TOTAL_UP (IN): $($r['total'])" }
$r.Close(); $cmd.Dispose()

$cmd2 = $conn.CreateCommand()
$cmd2.CommandText = "SELECT COUNT(*) as total FROM UP.SAI_PSAI WHERE nomeArea IN ($inList) AND YEAR(CadastroPSAI) >= 2002"
$cmd2.CommandTimeout = 120
$r2 = $cmd2.ExecuteReader()
while ($r2.Read()) { Write-Host "TOTAL_YEAR: $($r2['total'])" }
$r2.Close(); $cmd2.Dispose()

$conn.Close()
