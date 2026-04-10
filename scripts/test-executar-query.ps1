$ErrorActionPreference = "Stop"
$projetoDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$cfg = Get-Content (Join-Path $projetoDir "config\conexao-odbc.json") -Raw | ConvertFrom-Json
$AREA = $cfg.extracao.area
$AnoInicial = $cfg.extracao.ano_inicial
$enc = [System.Text.Encoding]::GetEncoding($cfg.odbc.encoding)
$connStr = "DSN=$($cfg.odbc.dsn);UID=$($cfg.odbc.usuario);PWD=$($cfg.odbc.senha);CS=iso_1"

Write-Host "AREA='$AREA' AnoInicial=$AnoInicial"

$conn = New-Object System.Data.Odbc.OdbcConnection($connStr)
$conn.Open()
Write-Host "Conexao OK"

$sql = "SELECT COUNT(*) as total FROM UP.SAI_PSAI sp WHERE sp.nomeArea = '$AREA' AND YEAR(sp.CadastroPSAI) >= $AnoInicial"
Write-Host "SQL: $sql"

$cmd = $conn.CreateCommand()
$cmd.CommandText = $sql
$cmd.CommandTimeout = 120
$reader = $cmd.ExecuteReader([System.Data.CommandBehavior]::SequentialAccess)

$colName = $reader.GetName(0)
try { $colType = $reader.GetDataTypeName(0) } catch { $colType = "unknown" }
Write-Host "Coluna: '$colName' | Tipo: '$colType'"
Write-Host "Blob check: $($colType -match 'binary|blob|long')"

while ($reader.Read()) {
    $val = $reader.GetValue(0)
    Write-Host "Valor bruto: '$val' (tipo .NET: $($val.GetType().Name))"
    Write-Host "Int cast: $([int]$val)"
}
$reader.Close()
$conn.Close()
