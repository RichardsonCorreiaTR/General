# test-areas-pbcvs.ps1 — Lista todos os nomeArea distintos no PBCVS
$conn = New-Object System.Data.Odbc.OdbcConnection("DSN=pbcvs9;UID=marcelo;PWD=marcelo")
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT DISTINCT sp.nomeArea, COUNT(*) as total FROM UP.SAI_PSAI sp GROUP BY sp.nomeArea ORDER BY sp.nomeArea"
$cmd.CommandTimeout = 60
$reader = $cmd.ExecuteReader()
Write-Host "=== nomeArea disponiveis no PBCVS ===" -ForegroundColor Cyan
Write-Host ""
while ($reader.Read()) {
    Write-Host ("  {0,-35} {1,6} registros" -f $reader["nomeArea"], $reader["total"])
}
$reader.Close()
$conn.Close()
Write-Host ""
Write-Host "Concluido." -ForegroundColor Green
