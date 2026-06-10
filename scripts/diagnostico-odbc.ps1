Start-Transcript -Path "C:\1 - A\B\Programas\General\scripts\diagnostico-odbc-resultado.txt" -Force
Set-Location "C:\1 - A\B\Programas\General"
$cfg = Get-Content "config\conexao-odbc.json" -Raw | ConvertFrom-Json
$connStr = "DSN=$($cfg.odbc.dsn);UID=$($cfg.odbc.usuario);PWD=$($cfg.odbc.senha);CS=iso_1"
$conn = New-Object System.Data.Odbc.OdbcConnection($connStr)
$conn.ConnectionTimeout = 30
$conn.Open()
Write-Host "Conexao OK" -ForegroundColor Green

function RunQ($label, $sql) {
    Write-Host ""
    Write-Host "=== $label ===" -ForegroundColor Yellow
    $sw = [Diagnostics.Stopwatch]::StartNew()
    try {
        $cmd = $conn.CreateCommand(); $cmd.CommandText = $sql; $cmd.CommandTimeout = 30
        $reader = $cmd.ExecuteReader()
        $n = 0; while ($reader.Read()) { $n++ }; $reader.Close(); $cmd.Dispose()
        $sw.Stop()
        Write-Host "OK: $n linhas em $($sw.Elapsed.TotalSeconds.ToString('0.0'))s" -ForegroundColor Green
    } catch {
        $sw.Stop()
        Write-Host "ERRO em $($sw.Elapsed.TotalSeconds.ToString('0.0'))s: $($_.Exception.Message)" -ForegroundColor Red
    }
}

try {
    RunQ "1-Situacoes SAI" "SELECT i_sai_situacoes FROM bethadba.sai_situacoes ORDER BY i_sai_situacoes"
    RunQ "2-Situacoes PSAI" "SELECT i_situacoes FROM bethadba.psai_situacoes ORDER BY i_situacoes"
    RunQ "3-Sistemas Escrita" "SELECT DISTINCT i_sistemas FROM UP.SAI_PSAI WHERE nomeArea = 'Escrita' ORDER BY i_sistemas"
    RunQ "4-Count Escrita/sis1" "SELECT COUNT(*) FROM UP.SAI_PSAI sp WHERE sp.nomeArea='Escrita' AND sp.i_sistemas=1 AND YEAR(sp.CadastroPSAI)>=2002"
    RunQ "5-TOP1 SEM JOIN" "SELECT TOP 1 sp.i_sai, sp.i_psai FROM UP.SAI_PSAI sp WHERE sp.nomeArea='Escrita' AND sp.i_sistemas=1 AND sp.i_psai>4066 ORDER BY sp.i_psai ASC"
    RunQ "6-TOP1 JOIN psai" "SELECT TOP 1 sp.i_psai, CAST(SUBSTRING(p.descricao,1,100) AS VARCHAR(100)) FROM UP.SAI_PSAI sp LEFT JOIN bethadba.psai p ON sp.i_psai>0 AND sp.i_psai=p.i_psai WHERE sp.nomeArea='Escrita' AND sp.i_sistemas=1 AND sp.i_psai>4066 ORDER BY sp.i_psai ASC"
    RunQ "7-TOP1 JOIN sai" "SELECT TOP 1 sp.i_psai, CAST(SUBSTRING(s.comportamento,1,100) AS VARCHAR(100)) FROM UP.SAI_PSAI sp LEFT JOIN bethadba.sai s ON sp.i_sai>0 AND sp.i_sai=s.i_sai WHERE sp.nomeArea='Escrita' AND sp.i_sistemas=1 AND sp.i_psai>4066 ORDER BY sp.i_psai ASC"
    RunQ "8-TOP20 AMBOS JOINs" "SELECT TOP 20 sp.i_psai, sp.i_sai FROM UP.SAI_PSAI sp LEFT JOIN bethadba.sai s ON sp.i_sai>0 AND sp.i_sai=s.i_sai LEFT JOIN bethadba.psai p ON sp.i_psai>0 AND sp.i_psai=p.i_psai WHERE sp.nomeArea='Escrita' AND sp.i_sistemas=1 AND sp.i_psai>4066 ORDER BY sp.i_psai ASC"
} catch {
    Write-Host "ERRO FATAL: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    $conn.Close()
    Write-Host ""
    Write-Host "=== Diagnostico concluido ===" -ForegroundColor Cyan
}
Stop-Transcript
