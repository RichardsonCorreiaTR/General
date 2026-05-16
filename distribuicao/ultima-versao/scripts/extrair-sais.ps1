# extrair-sais.ps1
# Extrator de SAIs/PSAIs direto do banco pbcvs9 via ODBC (System.Data.Odbc).
# Substitui o fallback BuscaSAI (Node) por PowerShell puro quando ODBC disponivel.
#
# IMPORTANTE: Rodar em terminal SEPARADO (fora do Cursor).
# O JSON final tem ~165 MB e o processo consome bastante memoria.
#
# Exemplos:
#   .\extrair-sais.ps1                        Incremental (padrao)
#   .\extrair-sais.ps1 -Completo              Extracao completa (~20 min)
#   .\extrair-sais.ps1 -Completo -AnoInicial 2020   So a partir de 2020

param(
    [switch]$Completo,
    [switch]$GerarMonolitico,
    [switch]$SemLock,
    [int]$AnoInicial = 0,
    [string[]]$AreasOverride = @()
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir

. (Join-Path $scriptDir "lib-lock.ps1")
if (-not $SemLock) {
    if (-not (Request-Lock $projetoDir "extrair-sais")) { exit 1 }
}

# ── Config ────────────────────────────────────────────────────────────

$configFile = Join-Path $projetoDir "config\conexao-odbc.json"
if (-not (Test-Path $configFile)) {
    Write-Host "ERRO: config\conexao-odbc.json nao encontrado." -ForegroundColor Red
    Release-Lock $projetoDir
    exit 1
}
$cfg = Get-Content $configFile -Raw | ConvertFrom-Json
$DSN = $cfg.odbc.dsn
$UID = $cfg.odbc.usuario
$PWD_DB = $cfg.odbc.senha
$ENCODING = $cfg.odbc.encoding
# Areas PBCVS (coluna nomeArea). Compat: extracao.areas[] ou extracao.area (string)
if ($AreasOverride.Count -gt 0) {
    $script:AREAS = @($AreasOverride)
    Write-Host "  [Areas] Override: $($script:AREAS -join ', ')" -ForegroundColor DarkCyan
} elseif ($cfg.extracao.areas -and @($cfg.extracao.areas).Count -gt 0) {
    $script:AREAS = @($cfg.extracao.areas)
} elseif ($cfg.extracao.area) {
    $script:AREAS = @($cfg.extracao.area)
} else {
    $script:AREAS = @("Escrita")
}
function Get-SqlNomeAreaPredicate {
    if ($script:AREAS.Count -eq 1) {
        $a = $script:AREAS[0].ToString().Replace("'", "''")
        return "sp.nomeArea = '$a'"
    }
    $parts = $script:AREAS | ForEach-Object { "'" + ($_.ToString().Replace("'", "''")) + "'" }
    return "sp.nomeArea IN (" + ($parts -join ", ") + ")"
}
$BATCH = $cfg.extracao.batch_size
if ($AnoInicial -eq 0) { $AnoInicial = $cfg.extracao.ano_inicial }
$DELAY_MS = $cfg.extracao.delay_entre_lotes_ms
$RECONECTAR_N = $cfg.extracao.reconectar_a_cada_n_lotes
$MAX_RETRIES = $cfg.extracao.max_retries

$dadosBrutosDir = Join-Path $projetoDir $cfg.destino.dados_brutos
$cacheDir = Join-Path $scriptDir "cache"
New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
$destinoJson = Join-Path $cacheDir "sai-psai-escrita.json"
$destinoJsonOneDrive = Join-Path $dadosBrutosDir "sai-psai-escrita.json"
$destinoSituacoes = Join-Path $dadosBrutosDir "situacoes.json"
# Lotes temporarios no cache local (fora do OneDrive e do TEMP do sistema).
# - OneDrive: trava arquivos durante sync, impede delete entre runs.
# - $env:TEMP: limpeza automatica do SO durante runs longas (>1h) apaga lotes.
$lotesDir = Join-Path $cacheDir "lotes-temp"
$progressoFile = Join-Path $dadosBrutosDir "progresso-extracao.json"

New-Item -ItemType Directory -Path $dadosBrutosDir -Force | Out-Null

$enc = [System.Text.Encoding]::GetEncoding($ENCODING)

# ── Conexao ODBC ──────────────────────────────────────────────────────

$connStr = "DSN=$DSN;UID=$UID;PWD=$PWD_DB;CS=iso_1"
$conn = $null

function Abrir-Conexao {
    $script:conn = New-Object System.Data.Odbc.OdbcConnection($connStr)
    $script:conn.ConnectionTimeout = $cfg.odbc.timeout_conexao_seg
    $script:conn.Open()
    Write-Host "  [conexao] Pool ODBC aberto (DSN: $DSN)" -ForegroundColor DarkGray
}

function Fechar-Conexao {
    if ($script:conn -and $script:conn.State -eq 'Open') {
        $script:conn.Close()
        $script:conn.Dispose()
        $script:conn = $null
    }
}

function Reconectar {
    Write-Host "  [conexao] Reconectando..." -ForegroundColor DarkYellow
    Fechar-Conexao
    Abrir-Conexao
}

function Executar-Query {
    param([string]$sql, [int]$tentativa = 1)
    try {
        $cmd = $script:conn.CreateCommand()
        $cmd.CommandText = $sql
        $cmd.CommandTimeout = $cfg.odbc.timeout_query_seg
        # Sem SequentialAccess: o driver Sybase ODBC faz round-trips extras ao
        # servidor para cada chunk GetBytes() com SequentialAccess, tornando
        # cada lote com BLOBs ~100x mais lento. GetValue() retorna byte[] em
        # uma unica transferencia, sem streaming extra.

        # Timer de cancelamento real: o driver SQL Anywhere ignora CommandTimeout.
        # System.Threading.Timer chama cmd.Cancel() apos timeout_query_seg segundos,
        # desbloqueando o ExecuteReader() com uma excecao tratada pelo bloco catch.
        $timeoutMs = $cfg.odbc.timeout_query_seg * 1000
        $cmdRef = $cmd
        $cancelTimer = [System.Threading.Timer]::new(
            [System.Threading.TimerCallback]{
                param($state)
                try { $state.Cancel() } catch {}
            },
            $cmdRef,
            $timeoutMs,
            [System.Threading.Timeout]::Infinite
        )

        $reader = $cmd.ExecuteReader()
        $cancelTimer.Dispose()

        $resultados = [System.Collections.ArrayList]::new()
        $colunas = @()
        for ($i = 0; $i -lt $reader.FieldCount; $i++) {
            $colunas += $reader.GetName($i)
        }

        while ($reader.Read()) {
            $row = [ordered]@{}
            for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                $nome = $colunas[$i]
                try {
                    $val = $reader.GetValue($i)
                    if ($val -eq $null -or $val -eq [System.DBNull]::Value) {
                        $row[$nome] = $null
                    } elseif ($val -is [byte[]]) {
                        $row[$nome] = if ($val.Length -gt 0) { $enc.GetString($val) } else { $null }
                    } else {
                        $row[$nome] = $val
                    }
                } catch {
                    $row[$nome] = $null
                }
            }
            [void]$resultados.Add($row)
        }
        $reader.Close()
        $cmd.Dispose()
        return ,$resultados
    } catch {
        if ($cancelTimer) { try { $cancelTimer.Dispose() } catch {} }
        $msg = $_.Exception.Message
        $isConexao = $msg -match 'conex|connection|terminat|timeout|communicat|reset|closed|broken|socket|cancel|encontrado'
        if ($isConexao -and $tentativa -le $MAX_RETRIES) {
            $delays = @(10, 30, 60, 120, 180)
            $delaySec = $delays[[math]::Min($tentativa - 1, $delays.Count - 1)]
            Write-Host "  [retry] Conexao perdida (tentativa $tentativa/$MAX_RETRIES). Aguardando ${delaySec}s..." -ForegroundColor Yellow
            Start-Sleep -Seconds $delaySec
            try { Reconectar } catch {
                Write-Host "  [retry] Falha na reconexao: $($_.Exception.Message)" -ForegroundColor Red
            }
            return Executar-Query -sql $sql -tentativa ($tentativa + 1)
        }
        # Retries esgotados por problema de conexao: pausar e aguardar intervencao manual
        if ($isConexao) {
            while ($true) {
                Write-Host ""
                Write-Host "  ============================================================" -ForegroundColor Red
                Write-Host "  CONEXAO PERDIDA apos $MAX_RETRIES tentativas." -ForegroundColor Red
                Write-Host "  Possivel causa: zScaler / VPN desconectado." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "  1. Reconecte o zScaler / VPN" -ForegroundColor Cyan
                Write-Host "  2. Pressione ENTER para tentar reconectar e continuar" -ForegroundColor Cyan
                Write-Host "  3. Pressione Ctrl+C para cancelar (progresso salvo)" -ForegroundColor DarkGray
                Write-Host "  ============================================================" -ForegroundColor Red
                $null = Read-Host
                Write-Host "  [reconexao] Tentando..." -ForegroundColor Yellow
                try {
                    Reconectar
                    Write-Host "  [reconexao] Conexao restabelecida! Continuando..." -ForegroundColor Green
                    return Executar-Query -sql $sql -tentativa 1
                } catch {
                    Write-Host "  [reconexao] Ainda sem conexao: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "  Verifique o zScaler e tente novamente." -ForegroundColor Yellow
                }
            }
        }
        throw
    }
}

# ── Limpeza HTML ──────────────────────────────────────────────────────

function Limpar-Html {
    param([string]$texto)
    if (-not $texto) { return $null }
    $t = $texto
    # 1. Remover todos os src base64 em passo unico (Replace global = O(n), sem while loop)
    $t = [regex]::Replace($t, [string]"src\s*=\s*`"data:[^`"]*`"", [string]"src=`"`"")
    # 2. Remover tags <img> inteiras
    $t = $t -replace '<img[^>]*/?>', ''
    # 3. Remover blocos <style> e <script> que tambem podem ser grandes
    $t = $t -replace '(?s)<style[^>]*>.*?</style>', ''
    $t = $t -replace '(?s)<script[^>]*>.*?</script>', ''
    $t = $t -replace '<br\s*/?>', "`n"
    $t = $t -replace '</?(?:div|p|li|ol|ul|tr|td|th|table|strong|em|b|i|span|font|a|h[1-6])[^>]*>', ' '
    $t = $t -replace '<[^>]+>', ''
    $t = [System.Net.WebUtility]::HtmlDecode($t)
    $t = $t -replace '[ \t]+', ' '
    $t = $t -replace '\n\s*\n', "`n"
    return $t.Trim()
}

# ── Queries SQL ───────────────────────────────────────────────────────

$SQL_SITUACOES_SAI = @"
SELECT i_sai_situacoes, CAST(SUBSTRING(descricao, 1, 500) AS VARCHAR(500)) as descricao
FROM bethadba.sai_situacoes ORDER BY i_sai_situacoes
"@

$SQL_SITUACOES_PSAI = @"
SELECT i_situacoes, CAST(SUBSTRING(descricao, 1, 500) AS VARCHAR(500)) as descricao
FROM bethadba.psai_situacoes ORDER BY i_situacoes
"@

function Get-SqlSegmentoPredicate([string]$area, [int]$sistema) {
    $a = $area.Replace("'", "''")
    return "sp.nomeArea = '$a' AND sp.i_sistemas = $sistema"
}

function Sql-ContarSistemas([string]$area) {
    $a = $area.Replace("'", "''")
    return "SELECT DISTINCT sp.i_sistemas FROM UP.SAI_PSAI sp WHERE sp.nomeArea = '$a' ORDER BY sp.i_sistemas"
}

function Sql-ContarPorSegmento([string]$area, [int]$sistema, [int]$ano) {
    $pred = Get-SqlSegmentoPredicate $area $sistema
    return "SELECT COUNT(*) as total FROM UP.SAI_PSAI sp WHERE $pred AND YEAR(sp.CadastroPSAI) >= $ano"
}

$SQL_SELECT_COLUNAS = @"
    sp.i_sai, sp.i_psai, sp.tipoSAI, sp.nomeArea, sp.nomeVersao,
    sp.CadastroPSAI, sp.CadastroSAI, sp.Liberacao, sp.Descarte,
    sp.dataFinalizada, sp.gravidade_ne, sp.tempoPrevistoTotal,
    sp.tempoRealizadoTotal, sp.ne_prevencao, sp.i_sai_situacoes,
    sp.i_psai_situacoes, sp.i_sistemas, sp.i_modulos,
    sp.ultima_modificacao, sp.liberacaoOficial, sp.qtde_ssc,
    sp.qtde_sane, s.pontuacao, p.nivel_alteracao, p.i_produto_grupo,
    CAST(SUBSTRING(s.descricao, 1, 2000) AS VARCHAR(2000)) as sai_descricao,
    CAST(SUBSTRING(s.comportamento, 1, 20000) AS VARCHAR(20000)) as comportamento,
    CAST(SUBSTRING(s.definicao, 1, 30000) AS VARCHAR(30000)) as definicao,
    CAST(SUBSTRING(s.descricao_destaque, 1, 10000) AS VARCHAR(10000)) as sai_destaque,
    CAST(SUBSTRING(p.descricao, 1, 2000) AS VARCHAR(2000)) as psai_descricao,
    CAST(SUBSTRING(p.descricao_destaque, 1, 10000) AS VARCHAR(10000)) as psai_destaque
"@

$SQL_JOINS = @"
LEFT JOIN bethadba.sai s ON sp.i_sai > 0 AND sp.i_sai = s.i_sai
LEFT JOIN bethadba.psai p ON sp.i_psai > 0 AND sp.i_psai = p.i_psai
"@

function Sql-ExtrairPorSegmento([string]$area, [int]$sistema, [int]$ano, [int]$lastPsai) {
    $pred = Get-SqlSegmentoPredicate $area $sistema
    return "SELECT TOP $BATCH`n$SQL_SELECT_COLUNAS`nFROM UP.SAI_PSAI sp`n$SQL_JOINS`nWHERE $pred AND YEAR(sp.CadastroPSAI) >= $ano AND sp.i_psai > $lastPsai`nORDER BY sp.i_psai ASC"
}

function Sql-ContarNovosPorSegmento([string]$area, [int]$sistema, [string]$desde) {
    $pred = Get-SqlSegmentoPredicate $area $sistema
    return "SELECT COUNT(*) as total FROM UP.SAI_PSAI sp WHERE $pred AND sp.CadastroPSAI > '$desde'"
}

function Sql-ExtrairNovosPorSegmento([string]$area, [int]$sistema, [string]$desde, [int]$lastPsai) {
    $pred = Get-SqlSegmentoPredicate $area $sistema
    return "SELECT TOP $BATCH`n$SQL_SELECT_COLUNAS`nFROM UP.SAI_PSAI sp`n$SQL_JOINS`nWHERE $pred AND sp.CadastroPSAI > '$desde' AND sp.i_psai > $lastPsai`nORDER BY sp.i_psai ASC"
}

function Sql-ContarMudancasStatusPorSegmento([string]$area, [int]$sistema, [string]$desde) {
    $pred = Get-SqlSegmentoPredicate $area $sistema
    return "SELECT COUNT(*) as total FROM UP.SAI_PSAI sp WHERE $pred AND ((sp.Liberacao IS NOT NULL AND sp.Liberacao > '$desde') OR (sp.Descarte IS NOT NULL AND sp.Descarte > '$desde'))"
}

function Sql-ExtrairMudancasStatusPorSegmento([string]$area, [int]$sistema, [string]$desde, [int]$lastPsai) {
    $pred = Get-SqlSegmentoPredicate $area $sistema
    return "SELECT TOP $BATCH`n$SQL_SELECT_COLUNAS`nFROM UP.SAI_PSAI sp`n$SQL_JOINS`nWHERE $pred AND ((sp.Liberacao IS NOT NULL AND sp.Liberacao > '$desde') OR (sp.Descarte IS NOT NULL AND sp.Descarte > '$desde')) AND sp.i_psai > $lastPsai`nORDER BY sp.i_psai ASC"
}

function Sql-Contar([int]$ano) {
    $pred = Get-SqlNomeAreaPredicate
    return "SELECT COUNT(*) as total FROM UP.SAI_PSAI sp WHERE $pred AND YEAR(sp.CadastroPSAI) >= $ano"
}

function Sql-ContarDistinto([int]$ano) {
    $pred = Get-SqlNomeAreaPredicate
    return "SELECT COUNT(DISTINCT sp.i_psai) as total FROM UP.SAI_PSAI sp WHERE $pred AND YEAR(sp.CadastroPSAI) >= $ano"
}

function Sql-Extrair([int]$ano, [int]$lastPsai) {
    $pred = Get-SqlNomeAreaPredicate
    # Keyset pagination: i_psai > lastPsai usa o indice clustered diretamente,
    # sem varrer registros anteriores (O(1) por pagina vs O(n) do START AT).
    return @"
SELECT TOP $BATCH
    sp.i_sai, sp.i_psai, sp.tipoSAI, sp.nomeArea, sp.nomeVersao,
    sp.CadastroPSAI, sp.CadastroSAI, sp.Liberacao, sp.Descarte,
    sp.dataFinalizada, sp.gravidade_ne, sp.tempoPrevistoTotal,
    sp.tempoRealizadoTotal, sp.ne_prevencao, sp.i_sai_situacoes,
    sp.i_psai_situacoes, sp.i_sistemas, sp.i_modulos,
    sp.ultima_modificacao, sp.liberacaoOficial, sp.qtde_ssc,
    sp.qtde_sane, s.pontuacao, p.nivel_alteracao, p.i_produto_grupo,
    CAST(SUBSTRING(s.descricao, 1, 2000) AS VARCHAR(2000)) as sai_descricao,
    CAST(SUBSTRING(s.comportamento, 1, 20000) AS VARCHAR(20000)) as comportamento,
    CAST(SUBSTRING(s.definicao, 1, 30000) AS VARCHAR(30000)) as definicao,
    CAST(SUBSTRING(s.descricao_destaque, 1, 10000) AS VARCHAR(10000)) as sai_destaque,
    CAST(SUBSTRING(p.descricao, 1, 2000) AS VARCHAR(2000)) as psai_descricao,
    CAST(SUBSTRING(p.descricao_destaque, 1, 10000) AS VARCHAR(10000)) as psai_destaque
FROM UP.SAI_PSAI sp
LEFT JOIN bethadba.sai s ON sp.i_sai > 0 AND sp.i_sai = s.i_sai
LEFT JOIN bethadba.psai p ON sp.i_psai > 0 AND sp.i_psai = p.i_psai
WHERE $pred AND YEAR(sp.CadastroPSAI) >= $ano AND sp.i_psai > $lastPsai
ORDER BY sp.i_psai ASC
"@
}

function Sql-ContarNovos([string]$desde) {
    $pred = Get-SqlNomeAreaPredicate
    return "SELECT COUNT(*) as total FROM UP.SAI_PSAI sp WHERE $pred AND sp.CadastroPSAI > '$desde'"
}

function Sql-ContarMudancasStatus([string]$desde) {
    $pred = Get-SqlNomeAreaPredicate
    return @"
SELECT COUNT(*) as total FROM UP.SAI_PSAI sp
WHERE $pred AND (
    (sp.Liberacao IS NOT NULL AND sp.Liberacao > '$desde') OR
    (sp.Descarte  IS NOT NULL AND sp.Descarte  > '$desde')
)
"@
}

function Sql-ExtrairNovos([string]$desde, [int]$lastPsai) {
    $pred = Get-SqlNomeAreaPredicate
    return @"
SELECT TOP $BATCH
    sp.i_sai, sp.i_psai, sp.tipoSAI, sp.nomeArea, sp.nomeVersao,
    sp.CadastroPSAI, sp.CadastroSAI, sp.Liberacao, sp.Descarte,
    sp.dataFinalizada, sp.gravidade_ne, sp.tempoPrevistoTotal,
    sp.tempoRealizadoTotal, sp.ne_prevencao, sp.i_sai_situacoes,
    sp.i_psai_situacoes, sp.i_sistemas, sp.i_modulos,
    sp.ultima_modificacao, sp.liberacaoOficial, sp.qtde_ssc,
    sp.qtde_sane, s.pontuacao, p.nivel_alteracao, p.i_produto_grupo,
    CAST(SUBSTRING(s.descricao, 1, 2000) AS VARCHAR(2000)) as sai_descricao,
    CAST(SUBSTRING(s.comportamento, 1, 20000) AS VARCHAR(20000)) as comportamento,
    CAST(SUBSTRING(s.definicao, 1, 30000) AS VARCHAR(30000)) as definicao,
    CAST(SUBSTRING(s.descricao_destaque, 1, 10000) AS VARCHAR(10000)) as sai_destaque,
    CAST(SUBSTRING(p.descricao, 1, 2000) AS VARCHAR(2000)) as psai_descricao,
    CAST(SUBSTRING(p.descricao_destaque, 1, 10000) AS VARCHAR(10000)) as psai_destaque
FROM UP.SAI_PSAI sp
LEFT JOIN bethadba.sai s ON sp.i_sai > 0 AND sp.i_sai = s.i_sai
LEFT JOIN bethadba.psai p ON sp.i_psai > 0 AND sp.i_psai = p.i_psai
WHERE $pred AND sp.CadastroPSAI > '$desde' AND sp.i_psai > $lastPsai
ORDER BY sp.i_psai ASC
"@
}

function Sql-ExtrairMudancasStatus([string]$desde, [int]$lastPsai) {
    $pred = Get-SqlNomeAreaPredicate
    return @"
SELECT TOP $BATCH
    sp.i_sai, sp.i_psai, sp.tipoSAI, sp.nomeArea, sp.nomeVersao,
    sp.CadastroPSAI, sp.CadastroSAI, sp.Liberacao, sp.Descarte,
    sp.dataFinalizada, sp.gravidade_ne, sp.tempoPrevistoTotal,
    sp.tempoRealizadoTotal, sp.ne_prevencao, sp.i_sai_situacoes,
    sp.i_psai_situacoes, sp.i_sistemas, sp.i_modulos,
    sp.ultima_modificacao, sp.liberacaoOficial, sp.qtde_ssc,
    sp.qtde_sane, s.pontuacao, p.nivel_alteracao, p.i_produto_grupo,
    CAST(SUBSTRING(s.descricao, 1, 2000) AS VARCHAR(2000)) as sai_descricao,
    CAST(SUBSTRING(s.comportamento, 1, 20000) AS VARCHAR(20000)) as comportamento,
    CAST(SUBSTRING(s.definicao, 1, 30000) AS VARCHAR(30000)) as definicao,
    CAST(SUBSTRING(s.descricao_destaque, 1, 10000) AS VARCHAR(10000)) as sai_destaque,
    CAST(SUBSTRING(p.descricao, 1, 2000) AS VARCHAR(2000)) as psai_descricao,
    CAST(SUBSTRING(p.descricao_destaque, 1, 10000) AS VARCHAR(10000)) as psai_destaque
FROM UP.SAI_PSAI sp
LEFT JOIN bethadba.sai s ON sp.i_sai > 0 AND sp.i_sai = s.i_sai
LEFT JOIN bethadba.psai p ON sp.i_psai > 0 AND sp.i_psai = p.i_psai
WHERE $pred AND sp.i_psai > $lastPsai AND (
    (sp.Liberacao IS NOT NULL AND sp.Liberacao > '$desde') OR
    (sp.Descarte  IS NOT NULL AND sp.Descarte  > '$desde')
)
ORDER BY sp.i_psai ASC
"@
}

# ── Enriquecer registro ───────────────────────────────────────────────

function Enriquecer-Registro {
    param($reg, $sitSai, $sitPsai)
    $reg['comportamento'] = Limpar-Html $reg['comportamento']
    $reg['definicao'] = Limpar-Html $reg['definicao']
    $reg['sai_descricao'] = Limpar-Html $reg['sai_descricao']
    $reg['sai_destaque'] = Limpar-Html $reg['sai_destaque']
    $reg['psai_descricao'] = Limpar-Html $reg['psai_descricao']
    $reg['psai_destaque'] = Limpar-Html $reg['psai_destaque']

    $idSitSai = [string]$reg['i_sai_situacoes']
    $idSitPsai = [string]$reg['i_psai_situacoes']
    $reg['situacaoSai'] = if ($sitSai.ContainsKey($idSitSai)) { $sitSai[$idSitSai] } else { "ID $idSitSai" }
    $reg['situacaoPsai'] = if ($sitPsai.ContainsKey($idSitPsai)) { $sitPsai[$idSitPsai] } else { "ID $idSitPsai" }

    return $reg
}

# ── Progresso e Lotes ─────────────────────────────────────────────────

function Salvar-Progresso($dados) {
    $dados | ConvertTo-Json -Depth 3 | Set-Content -Path $progressoFile -Encoding UTF8
}

function Carregar-Progresso {
    if (Test-Path $progressoFile) {
        try { return Get-Content $progressoFile -Raw | ConvertFrom-Json } catch { return $null }
    }
    return $null
}

function Salvar-Lote([int]$num, $registros) {
    New-Item -ItemType Directory -Path $lotesDir -Force | Out-Null
    $arquivo = Join-Path $lotesDir ("lote-{0:D5}.json" -f $num)
    $registros | ConvertTo-Json -Depth 4 -Compress | Set-Content -Path $arquivo -Encoding UTF8
}

function Merge-Lotes {
    if (-not (Test-Path $lotesDir)) { return @() }
    $arquivos = Get-ChildItem $lotesDir -Filter "lote-*.json" | Sort-Object Name
    $todos = [System.Collections.ArrayList]::new()
    foreach ($arq in $arquivos) {
        $loteData = Get-Content $arq.FullName -Raw | ConvertFrom-Json
        if ($loteData -is [array]) {
            foreach ($item in $loteData) { [void]$todos.Add($item) }
        } else {
            [void]$todos.Add($loteData)
        }
    }
    return $todos
}

function Limpar-Lotes {
    if (Test-Path $lotesDir) { Remove-Item $lotesDir -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path $progressoFile) { Remove-Item $progressoFile -Force -ErrorAction SilentlyContinue }
}

# ── Extrair Situacoes ─────────────────────────────────────────────────

function Extrair-Situacoes {
    Write-Host "  Extraindo situacoes SAI..." -ForegroundColor DarkGray
    $sitSaiList = Executar-Query $SQL_SITUACOES_SAI
    Write-Host "  Extraindo situacoes PSAI..." -ForegroundColor DarkGray
    $sitPsaiList = Executar-Query $SQL_SITUACOES_PSAI

    $sitSai = @{}; $sitPsai = @{}
    foreach ($s in $sitSaiList) { $sitSai[[string]$s['i_sai_situacoes']] = $s['descricao'] }
    foreach ($s in $sitPsaiList) { $sitPsai[[string]$s['i_situacoes']] = $s['descricao'] }

    $situacoes = @{ sai = $sitSai; psai = $sitPsai }
    $situacoes | ConvertTo-Json -Depth 3 | Set-Content -Path $destinoSituacoes -Encoding UTF8
    Write-Host "  $($sitSai.Count) situacoes SAI, $($sitPsai.Count) situacoes PSAI" -ForegroundColor DarkGray
    return $situacoes
}

# ── Formatar data para Sybase ─────────────────────────────────────────

function Formatar-DataSybase([string]$iso) {
    $d = [DateTime]::Parse($iso)
    return $d.ToString("yyyy-MM-dd HH:mm:ss")
}

# ── Extracao Completa ─────────────────────────────────────────────────

function Salvar-ProgressoSegmento([string]$area, [int]$sistema, [int]$lastPsai, [int]$loteGlobal, [int]$extraidosGeral, [int]$totalGeral, [bool]$concluido) {
    $p = [ordered]@{
        tipo           = 'completo-segmento'
        area           = $area
        sistema        = $sistema
        ultimoPsai     = $lastPsai
        loteGlobal     = $loteGlobal
        extraidosGeral = $extraidosGeral
        totalGeral     = $totalGeral
        concluido      = $concluido
        atualizadoEm   = (Get-Date -Format o)
    }
    $p | ConvertTo-Json | Set-Content $progressoFile -Encoding UTF8
}

function Extrair-Segmento([string]$area, [int]$sistema, [int]$loteGlobalRef, [ref]$extraidosGeralRef, [int]$totalGeral, [object]$situacoes, [System.DateTime]$inicioGeral, [int]$retomadaLastPsai = 0, [int]$retomadaLote = 1) {
    $contagemSeg = Executar-Query (Sql-ContarPorSegmento $area $sistema $AnoInicial)
    $totalSeg = [int]$contagemSeg[0]['total']
    if ($totalSeg -eq 0) { Write-Host "    Nenhum registro." -ForegroundColor DarkGray; return $loteGlobalRef }

    $totalLotesSeg = [math]::Ceiling($totalSeg / $BATCH)

    # Retomada: ajustar contagem e posicao
    if ($retomadaLastPsai -gt 0) {
        Write-Host "    RETOMANDO do lote $retomadaLote (ultimo i_psai=$retomadaLastPsai)" -ForegroundColor Yellow
    }
    Write-Host "    $totalSeg registros | $totalLotesSeg lotes" -ForegroundColor Yellow

    $lastPsai = $retomadaLastPsai; $loteSeg = $retomadaLote; $extraidosSeg = ($retomadaLote - 1) * $BATCH; $inicioSeg = Get-Date

    while ($true) {
        Write-Host "  Lote $loteSeg/$totalLotesSeg - extraindo apos i_psai=$lastPsai de $totalSeg..." -ForegroundColor White -NoNewline
        try {
            $registros = Executar-Query (Sql-ExtrairPorSegmento $area $sistema $AnoInicial $lastPsai)
            if ($registros.Count -eq 0) { Write-Host " (vazio, fim)"; break }

            $enriquecidos = @()
            foreach ($r in $registros) { $enriquecidos += Enriquecer-Registro $r $situacoes.sai $situacoes.psai }
            Salvar-Lote $loteGlobalRef $enriquecidos
            $lastPsai = [int]$registros[-1]['i_psai']
            $extraidosSeg += $registros.Count
            $extraidosGeralRef.Value += $registros.Count

            $elapsed = ((Get-Date) - $inicioSeg).TotalSeconds
            $vel = if ($extraidosSeg -gt 0 -and $elapsed -gt 5) { [math]::Round($extraidosSeg / $elapsed * 60) } else { 0 }
            $eta = if ($vel -gt 0) { [math]::Round(($totalSeg - $extraidosSeg) / $vel) } else { 0 }
            $pct = [math]::Round($extraidosSeg / $totalSeg * 100, 1)
            $pctGeral = [math]::Round($extraidosGeralRef.Value / $totalGeral * 100, 1)
            Write-Host " OK ($extraidosSeg/$totalSeg = ${pct}% | vel: $vel/min | ETA: ${eta}min | geral: $($extraidosGeralRef.Value)/$totalGeral = ${pctGeral}%)" -ForegroundColor Green

            $loteGlobalRef++; $loteSeg++

            # Salvar progresso apos cada lote (permite retomada se cair zScaler/energia)
            Salvar-ProgressoSegmento $area $sistema $lastPsai $loteGlobalRef $extraidosGeralRef.Value $totalGeral $false

            if ($loteSeg % $RECONECTAR_N -eq 0) {
                Write-Host "  [reconexao preventiva]" -ForegroundColor DarkGray
                try { Reconectar } catch { Write-Host "  Aviso: reconexao preventiva falhou" -ForegroundColor DarkYellow }
            }
            Start-Sleep -Milliseconds $DELAY_MS
        } catch {
            $msg = $_.Exception.Message
            # Com batch_size=1: registrar o PSAI problematico e continuar
            if ($BATCH -eq 1) {
                Write-Host " [SKIP] i_psai=$lastPsai ERRO: $($msg.Substring(0,[Math]::Min(120,$msg.Length)))" -ForegroundColor Red
                $script:psaisComErro += $lastPsai
                $lastPsai++   # avanca para o proximo
                $loteSeg++
                Start-Sleep -Milliseconds $DELAY_MS
                continue
            }
            Write-Host " FALHA: $msg" -ForegroundColor Red
            Salvar-ProgressoSegmento $area $sistema $lastPsai $loteGlobalRef $extraidosGeralRef.Value $totalGeral $false
            throw
        }
    }
    $minSeg = [math]::Round(((Get-Date) - $inicioSeg).TotalMinutes, 1)
    Write-Host "    Concluido: $extraidosSeg reg em ${minSeg}min" -ForegroundColor Cyan
    Salvar-ProgressoSegmento $area $sistema $lastPsai $loteGlobalRef $extraidosGeralRef.Value $totalGeral $true
    return $loteGlobalRef
}

function Extrair-Completo {
    # Verificar se existe progresso de uma extracao anterior interrompida
    $progresso = $null
    $retomar = $false
    if (Test-Path $progressoFile) {
        $prog = Get-Content $progressoFile -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction SilentlyContinue
        $areaProgNoAreas = $script:AREAS -contains $prog.area
        if ($prog -and $prog.tipo -eq 'completo-segmento' -and -not $prog.concluido -and $prog.ultimoPsai -gt 0 -and $areaProgNoAreas) {
            Write-Host ""
            Write-Host "  Progresso anterior encontrado:" -ForegroundColor Yellow
            Write-Host "    Area: $($prog.area) | Sistema: $($prog.sistema) | Ultimo i_psai: $($prog.ultimoPsai)" -ForegroundColor Yellow
            Write-Host "    Lote global: $($prog.loteGlobal) | Extraidos: $($prog.extraidosGeral)/$($prog.totalGeral)" -ForegroundColor Yellow
            Write-Host ""
            $resp = Read-Host "  Retomar de onde parou? (S/N, padrao=S)"
            if ($resp -eq '' -or $resp -match '^[Ss]') {
                $progresso = $prog
                $retomar = $true
                Write-Host "  Retomando extracao..." -ForegroundColor Green
            } else {
                Write-Host "  Iniciando do zero..." -ForegroundColor DarkYellow
                Limpar-Lotes
            }
        } else {
            Limpar-Lotes
        }
    } else {
        Limpar-Lotes
    }

    $situacoes = Extrair-Situacoes

    Write-Host "  Contando registros totais (ano >= $AnoInicial)..." -ForegroundColor Cyan
    $totalGeral = [int](Executar-Query (Sql-Contar $AnoInicial))[0]['total']
    Write-Host "  Total geral encontrado: $totalGeral registros em $($script:AREAS.Count) area(s)" -ForegroundColor Cyan

    $loteGlobal = if ($retomar) { $progresso.loteGlobal } else { 1 }
    $extraidosGeralInicial = if ($retomar) { $progresso.extraidosGeral } else { 0 }
    $extraidosGeral = [ref]$extraidosGeralInicial
    $inicioGeral = Get-Date

    foreach ($area in $script:AREAS) {
        Write-Host ""
        Write-Host ("  " + ("=" * 55)) -ForegroundColor Magenta
        Write-Host "  Area: $area" -ForegroundColor Magenta
        Write-Host ("  " + ("=" * 55)) -ForegroundColor Magenta

        $sistemasResult = Executar-Query (Sql-ContarSistemas $area)
        $sistemas = @($sistemasResult | ForEach-Object { [int]$_['i_sistemas'] } | Sort-Object)

        if ($sistemas.Count -eq 0) {
            Write-Host "  Nenhum sistema encontrado para esta area." -ForegroundColor DarkGray
            continue
        }

        $pluralSis = if ($sistemas.Count -eq 1) { "1 sistema" } else { "$($sistemas.Count) sistemas" }
        Write-Host "  $($pluralSis): $($sistemas -join ', ')" -ForegroundColor DarkGray

        foreach ($sistema in $sistemas) {
            # Verificar se este segmento ja foi concluido na retomada
            if ($retomar -and $progresso) {
                $areasOrdem = $script:AREAS
                $idxAreaAtual = [array]::IndexOf($areasOrdem, $area)
                $idxAreaProg  = [array]::IndexOf($areasOrdem, $progresso.area)
                $mesmaSeg = ($area -eq $progresso.area -and $sistema -eq [int]$progresso.sistema)
                $segAnterior = ($idxAreaAtual -lt $idxAreaProg) -or
                               ($area -eq $progresso.area -and $sistema -lt [int]$progresso.sistema)
                if ($segAnterior) {
                    Write-Host "    [ja concluido — pulando]" -ForegroundColor DarkGray
                    continue
                }
            }

            if ($sistemas.Count -gt 1) {
                Write-Host ""
                Write-Host "  --- Sistema $sistema ---" -ForegroundColor Cyan
            }

            $resumePsai = 0; $resumeLote = 1
            if ($retomar -and $progresso -and $area -eq $progresso.area -and $sistema -eq [int]$progresso.sistema) {
                $resumePsai = [int]$progresso.ultimoPsai
                $resumeLote = [int]$progresso.loteGlobal - $loteGlobal + 1
                if ($resumeLote -lt 1) { $resumeLote = 1 }
            }

            $loteGlobal = Extrair-Segmento $area $sistema $loteGlobal $extraidosGeral $totalGeral $situacoes $inicioGeral $resumePsai $resumeLote
        }
    }

    $minTotal = [math]::Round(((Get-Date) - $inicioGeral).TotalMinutes, 1)
    Write-Host ""
    Write-Host "  Total extraido: $($extraidosGeral.Value) registros em ${minTotal}min" -ForegroundColor Green
    Write-Host "  Fazendo merge de lotes..." -ForegroundColor Cyan
    $todosRegistros = Merge-Lotes
    Salvar-CacheFinal $todosRegistros
    Limpar-Lotes
    Write-Host "  Extracao completa: $($todosRegistros.Count) registros salvos." -ForegroundColor Green
    return $todosRegistros.Count
}

# ── Extracao Incremental ──────────────────────────────────────────────

function Ler-GeradoEm {
    # Le apenas o timestamp geradoEm sem carregar o JSON de 400-500 MB na memoria.
    # Ordem de tentativa: sidecar leve -> meta externo -> stream dos primeiros bytes do cache.
    $sidecar = $destinoJson -replace '\.json$', '.gerado.json'
    if (Test-Path $sidecar) {
        try { $v = (Get-Content $sidecar -Raw | ConvertFrom-Json).geradoEm; if ($v) { return $v } } catch {}
    }
    if (Test-Path $metaFile) {
        try { $v = (Get-Content $metaFile -Raw | ConvertFrom-Json).importadoEm; if ($v) { return $v } } catch {}
    }
    if (Test-Path $destinoJson) {
        try {
            $fs = [System.IO.File]::OpenRead($destinoJson)
            $buf = New-Object byte[] 512
            [void]$fs.Read($buf, 0, 512)
            $fs.Close()
            $m = [regex]::Match([System.Text.Encoding]::UTF8.GetString($buf), '"geradoEm"\s*:\s*"([^"]+)"')
            if ($m.Success) { return $m.Groups[1].Value }
        } catch {}
    }
    return $null
}

function Gravar-Sidecar-GeradoEm {
    $sidecar = $destinoJson -replace '\.json$', '.gerado.json'
    @{ geradoEm = (Get-Date -Format o) } | ConvertTo-Json | Set-Content $sidecar -Encoding UTF8
}

function Aplicar-Delta-Fracionados($delta, $situacoes) {
    # Aplica registros delta nos fracionados PSAI/SAI sem carregar o monolitico.
    # Processa um arquivo por vez para manter uso de RAM baixo.
    $psaiOutDir = Join-Path $dadosBrutosDir "psai"
    $saiOutDir  = Join-Path $dadosBrutosDir "sai"
    New-Item -ItemType Directory -Path $psaiOutDir -Force | Out-Null
    New-Item -ItemType Directory -Path $saiOutDir  -Force | Out-Null

    # Index dos registros delta por i_psai para lookup O(1)
    $deltaIdx = @{}
    foreach ($r in $delta) { $deltaIdx[[string]$r.i_psai] = $r }

    $tiposTodos = @("NE","SAM","SAL","SAIL")
    $statusDef  = @(
        @{ nome="pendentes";   test={ param($r) -not $r.Liberacao -and -not $r.Descarte } },
        @{ nome="liberadas";   test={ param($r) $r.Liberacao } },
        @{ nome="descartadas"; test={ param($r) $r.Descarte } }
    )
    $escritos = 0; $pulados = 0

    foreach ($tp in $tiposTodos) {
        foreach ($sd in $statusDef) {
            $arquivo    = Join-Path $psaiOutDir "$($tp.ToLower())-$($sd.nome).json"
            $saiArquivo = Join-Path $saiOutDir  "$($tp.ToLower())-$($sd.nome).json"

            # Carregar arquivo existente (ou array vazio)
            $existente = [System.Collections.ArrayList]::new()
            if (Test-Path $arquivo) {
                try {
                    $j = Get-Content $arquivo -Raw -Encoding UTF8 | ConvertFrom-Json
                    if ($j.dados) { foreach ($d in $j.dados) { [void]$existente.Add($d) } }
                } catch {}
            }

            # Remover registros que estao no delta (podem ter mudado de bucket)
            $existente = [System.Collections.ArrayList]@($existente | Where-Object { -not $deltaIdx.ContainsKey([string]$_.i_psai) })

            # Adicionar registros delta que pertencem a este bucket
            foreach ($r in $delta) {
                if ($r.tipoSAI -eq $tp -and (& $sd.test $r)) {
                    [void]$existente.Add($r)
                }
            }

            # Escrever PSAI fracionado
            $psaiObj     = @{ tipo=$tp; status=$sd.nome; total=$existente.Count; dados=$existente.ToArray() }
            $psaiContent = $psaiObj | ConvertTo-Json -Depth 5 -Compress
            if (Smart-Write $arquivo $psaiContent) { $escritos++ } else { $pulados++ }

            # Escrever SAI fracionado (nivel SAI, 1 por i_sai)
            $gruposSaiD = $existente | Group-Object -Property i_sai
            $saiRegs = [System.Collections.ArrayList]::new()
            foreach ($g in $gruposSaiD) {
                $mr = $g.Group | Sort-Object {
                    if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue }
                } -Descending | Select-Object -First 1
                [void]$saiRegs.Add([PSCustomObject]@{
                    i_sai = $mr.i_sai; tipoSAI = $mr.tipoSAI; sai_descricao = $mr.sai_descricao
                    nomeVersao = $mr.nomeVersao; gravidade_ne = $mr.gravidade_ne; situacaoSai = $mr.situacaoSai
                    ultimaPsai = $mr.i_psai; ultimoCadastro = $mr.CadastroPSAI; totalPsais = $g.Count
                })
            }
            $saiObj = @{ tipo=$tp; status=$sd.nome; totalSais=$saiRegs.Count; dados=$saiRegs.ToArray() }
            if (Smart-Write $saiArquivo ($saiObj | ConvertTo-Json -Depth 5 -Compress)) { $escritos++ } else { $pulados++ }

            # Liberar memoria antes do proximo arquivo
            $existente = $null; $j = $null; [GC]::Collect()
        }
    }
    Write-Host "  Fracionados patch: $escritos escritos, $pulados pulados (identicos)" -ForegroundColor Green
}

function Extrair-Incremental {
    # Le geradoEm via metodo leve (sem carregar o cache de 400-500 MB)
    $geradoEm = Ler-GeradoEm
    if (-not $geradoEm) {
        Write-Host "  Sem referencia de data. Executando extracao completa..." -ForegroundColor Yellow
        return Extrair-Completo
    }

    $desde = Formatar-DataSybase $geradoEm
    Write-Host "  Buscando registros alterados desde $desde..." -ForegroundColor Cyan

    $situacoes = Extrair-Situacoes

    # Coleta delta por area/sistema (evita queries lentas sobre todas as areas de uma vez)
    $delta = [System.Collections.ArrayList]::new()
    $deltaIdx = @{}

    function Coletar-Segmento-Incremental([string]$area, [int]$sistema, [string]$sqlContar, [scriptblock]$sqlExtrair, [string]$descricao) {
        $cnt = Executar-Query $sqlContar
        $totalLocal = [int]$cnt[0]['total']
        if ($totalLocal -eq 0) { Write-Host "    ${descricao}: nenhum" -ForegroundColor DarkGray; return }
        $totalLotesLocal = [math]::Ceiling($totalLocal / $BATCH)
        Write-Host "    ${descricao}: $totalLocal registros | $totalLotesLocal lotes" -ForegroundColor Yellow
        $lastPsaiLocal = 0; $lt = 1
        while ($true) {
            Write-Host "  Lote $lt/$totalLotesLocal (apos i_psai=$lastPsaiLocal)..." -ForegroundColor White -NoNewline
            $regs = Executar-Query (& $sqlExtrair $area $sistema $desde $lastPsaiLocal)
            if ($regs.Count -eq 0) { Write-Host " (vazio, fim)"; break }
            $lastPsaiLocal = [int]$regs[-1]['i_psai']
            foreach ($r in $regs) {
                $enr = Enriquecer-Registro $r $situacoes.sai $situacoes.psai
                $k   = [string]$enr['i_psai']
                if (-not $deltaIdx.ContainsKey($k)) { [void]$delta.Add($enr); $deltaIdx[$k] = $true }
            }
            Write-Host " OK ($($delta.Count) acumulados)" -ForegroundColor Green
            $lt++
            Start-Sleep -Milliseconds $DELAY_MS
        }
    }

    foreach ($area in $script:AREAS) {
        Write-Host ""
        Write-Host ("  " + ("=" * 55)) -ForegroundColor Magenta
        Write-Host "  Area: $area" -ForegroundColor Magenta
        Write-Host ("  " + ("=" * 55)) -ForegroundColor Magenta

        $sistemasResult = Executar-Query (Sql-ContarSistemas $area)
        $sistemas = @($sistemasResult | ForEach-Object { [int]$_['i_sistemas'] } | Sort-Object)
        if ($sistemas.Count -eq 0) { Write-Host "  Nenhum sistema." -ForegroundColor DarkGray; continue }
        Write-Host "  $($sistemas.Count) sistema(s): $($sistemas -join ', ')" -ForegroundColor DarkGray

        foreach ($sistema in $sistemas) {
            if ($sistemas.Count -gt 1) {
                Write-Host ""
                Write-Host "  --- Sistema $sistema ---" -ForegroundColor Cyan
            }
            Coletar-Segmento-Incremental $area $sistema `
                (Sql-ContarNovosPorSegmento $area $sistema $desde) `
                { param($a,$s,$d,$lp) Sql-ExtrairNovosPorSegmento $a $s $d $lp } `
                "Novos (CadastroPSAI)"

            Coletar-Segmento-Incremental $area $sistema `
                (Sql-ContarMudancasStatusPorSegmento $area $sistema $desde) `
                { param($a,$s,$d,$lp) Sql-ExtrairMudancasStatusPorSegmento $a $s $d $lp } `
                "Mudancas status (Liberacao/Descarte)"
        }
    }

    if ($delta.Count -eq 0) {
        Write-Host "  Nenhum registro alterado. Cache esta atualizado." -ForegroundColor Green
        return 0
    }

    Write-Host "  Total delta: $($delta.Count) registros coletados" -ForegroundColor Yellow

    # Aplica delta nos fracionados (um arquivo por vez, sem carregar o monolitico)
    Write-Host "  Aplicando $($delta.Count) registros nos fracionados..." -ForegroundColor Cyan
    Aplicar-Delta-Fracionados $delta $situacoes

    # Atualiza timestamp de referencia para o proximo incremental
    Gravar-Sidecar-GeradoEm

    Write-Host "  Incremental: $($delta.Count) registros delta aplicados. Fracionados atualizados." -ForegroundColor Green
    return $delta.Count
}

# ── Smart-Write (so reescreve se conteudo mudou) ─────────────────────

function Smart-Write($path, $content) {
    if (Test-Path $path) {
        $existing = (Get-Content $path -Raw -Encoding UTF8).TrimEnd()
        $novo = $content.TrimEnd()
        if ($existing -eq $novo) { return $false }
    }
    Set-Content -Path $path -Value $content -Encoding UTF8
    return $true
}

# ── Salvar cache final ────────────────────────────────────────────────

function Salvar-CacheFinal($registros) {
    $wrapper = [ordered]@{
        geradoEm = (Get-Date -Format o)
        totalRegistros = $registros.Count
        dados = $registros
        areasPbcvs = $script:AREAS
    }
    Write-Host "  Salvando cache em scripts/cache/ ($($registros.Count) registros)..." -ForegroundColor Cyan
    $wrapper | ConvertTo-Json -Depth 5 -Compress | Set-Content -Path $destinoJson -Encoding UTF8
    $tamanhoMB = [math]::Round((Get-Item $destinoJson).Length / 1MB, 1)
    Write-Host "  Cache salvo: $destinoJson ($tamanhoMB MB)" -ForegroundColor Green

    if ($GerarMonolitico) {
        Write-Host "  Salvando monolitico em OneDrive (--GerarMonolitico)..." -ForegroundColor Yellow
        $wrapper | ConvertTo-Json -Depth 5 -Compress | Set-Content -Path $destinoJsonOneDrive -Encoding UTF8
        Write-Host "  Monolitico: $destinoJsonOneDrive" -ForegroundColor Green
    }

    Gravar-Fracionados $registros
    # Grava sidecar leve com geradoEm para ser usado pelo modo incremental
    Gravar-Sidecar-GeradoEm
}

# ── Gravar fracionados direto no OneDrive ─────────────────────────────

function Gravar-Fracionados($registros) {
    Write-Host "  Gerando fracionados (smart rewrite)..." -ForegroundColor Cyan
    $psaiOutDir = Join-Path $dadosBrutosDir "psai"
    $saiOutDir = Join-Path $dadosBrutosDir "sai"
    New-Item -ItemType Directory -Path $psaiOutDir -Force | Out-Null
    New-Item -ItemType Directory -Path $saiOutDir -Force | Out-Null

    $tiposTodos = @("NE","SAM","SAL","SAIL")
    $escritos = 0; $pulados = 0

    # Modo merge: quando extraindo areas especificas (-AreasOverride / -SomenteAreas),
    # preservar registros das outras areas nos fracionados existentes.
    $todasAreasConhecidas = @("Escrita","Contabil","Importacao","Importa??o","ONVIO ESCRITA","ONVIO CONTABIL")
    $modoMerge = ($AreasOverride.Count -gt 0) -or ($script:AREAS.Count -lt $todasAreasConhecidas.Count)
    $existentes = @{}

    if ($modoMerge) {
        Write-Host "  [merge] Preservando fracionados das demais areas ($($script:AREAS -join ', ') sendo atualizada(s))..." -ForegroundColor DarkCyan
        foreach ($tp in $tiposTodos) {
            foreach ($statusNome in @("pendentes","liberadas","descartadas")) {
                $arq = Join-Path $psaiOutDir "$($tp.ToLower())-$statusNome.json"
                if (Test-Path $arq) {
                    $j = Get-Content $arq -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if ($j -and $j.dados) {
                        $key = "$tp|$statusNome"
                        # Manter apenas registros de areas que NAO estao sendo atualizadas agora
                        $existentes[$key] = @($j.dados | Where-Object { $script:AREAS -notcontains $_.nomeArea })
                    }
                }
            }
        }
    }

    # Agrupa em uma unica passagem em vez de Where-Object por tipo+status
    $grupos = @{}
    foreach ($tp in $tiposTodos) {
        $grupos[$tp] = @{ pendentes = [System.Collections.ArrayList]::new(); liberadas = [System.Collections.ArrayList]::new(); descartadas = [System.Collections.ArrayList]::new() }
    }
    foreach ($r in $registros) {
        $tp = $r.tipoSAI
        if (-not $grupos.ContainsKey($tp)) { continue }
        if ($r.Liberacao) { [void]$grupos[$tp].liberadas.Add($r) }
        elseif ($r.Descarte) { [void]$grupos[$tp].descartadas.Add($r) }
        else { [void]$grupos[$tp].pendentes.Add($r) }
    }

    foreach ($tp in $tiposTodos) {
        $pendentes = $grupos[$tp].pendentes
        $liberadas = $grupos[$tp].liberadas
        $descartadas = $grupos[$tp].descartadas
        $tpLower = $tp.ToLower()

        $splits = @(
            @{ nome="pendentes"; itens=$pendentes },
            @{ nome="liberadas"; itens=$liberadas },
            @{ nome="descartadas"; itens=$descartadas }
        )

        foreach ($s in $splits) {
            $arquivo = "$tpLower-$($s.nome).json"
            $regs = $s.itens

            # Em modo merge: combinar com registros existentes de outras areas
            $key = "$tp|$($s.nome)"
            $regsFinais = if ($modoMerge -and $existentes[$key] -and $existentes[$key].Count -gt 0) {
                @($existentes[$key]) + @($regs)
            } else {
                @($regs)
            }

            $psaiObj = @{ tipo=$tp; status=$s.nome; total=$regsFinais.Count; dados=$regsFinais }
            $psaiContent = $psaiObj | ConvertTo-Json -Depth 5 -Compress
            if (Smart-Write (Join-Path $psaiOutDir $arquivo) $psaiContent) { $escritos++ } else { $pulados++ }

            $gruposSai = $regsFinais | Group-Object -Property i_sai
            $saiRegistros = @()
            foreach ($g in $gruposSai) {
                $maisRecente = $g.Group | Sort-Object {
                    if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue }
                } -Descending | Select-Object -First 1
                $saiRegistros += [PSCustomObject]@{
                    i_sai = $maisRecente.i_sai
                    tipoSAI = $maisRecente.tipoSAI
                    sai_descricao = $maisRecente.sai_descricao
                    nomeVersao = $maisRecente.nomeVersao
                    gravidade_ne = $maisRecente.gravidade_ne
                    situacaoSai = $maisRecente.situacaoSai
                    ultimaPsai = $maisRecente.i_psai
                    ultimoCadastro = $maisRecente.CadastroPSAI
                    totalPsais = $g.Count
                }
            }
            $saiObj = @{ tipo=$tp; status=$s.nome; totalSais=$saiRegistros.Count; dados=$saiRegistros }
            $saiContent = $saiObj | ConvertTo-Json -Depth 5 -Compress
            if (Smart-Write (Join-Path $saiOutDir $arquivo) $saiContent) { $escritos++ } else { $pulados++ }
        }
    }
    Write-Host "  Fracionados: $escritos escritos, $pulados pulados (identicos)" -ForegroundColor Green
}

# ── Execucao ──────────────────────────────────────────────────────────

$script:psaisComErro = @()
$modo = if ($Completo) { "COMPLETO" } else { "INCREMENTAL" }

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "  EXTRATOR SAI/PSAI - Multi-area (BuscaSAI alinhado)" -ForegroundColor Cyan
$areasTxt = $script:AREAS -join ", "
Write-Host "  Modo: $modo | DSN: $DSN | Areas PBCVS: $areasTxt" -ForegroundColor Cyan
if ($Completo) { Write-Host "  Ano inicial: $AnoInicial" -ForegroundColor Cyan }
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""

try {
    Abrir-Conexao

    Write-Host "[1/2] Testando conexao..." -ForegroundColor Yellow
    $teste = Executar-Query "SELECT 1 AS ok"
    if ($teste[0]['ok'] -eq 1) {
        Write-Host "  Conexao OK" -ForegroundColor Green
    }

    Write-Host "[2/3] Extraindo..." -ForegroundColor Yellow
    if ($Completo) {
        $totalExtraido = Extrair-Completo
    } else {
        $totalExtraido = Extrair-Incremental
    }

    Write-Host "[3/3] Verificando contagem (PSAIs distintos)..." -ForegroundColor Yellow
    $contagemBanco = Executar-Query (Sql-ContarDistinto $AnoInicial)
    $totalNoBanco = [int]$contagemBanco[0]['total']
    $totalNoCache = $totalExtraido
    if ($totalExtraido -eq 0 -and (Test-Path $destinoJson)) {
        $cacheTemp = Get-Content $destinoJson -Raw | ConvertFrom-Json
        $totalNoCache = $cacheTemp.totalRegistros
        $cacheTemp = $null
    }

    if ($totalNoBanco -ne $totalNoCache) {
        $diff = $totalNoBanco - $totalNoCache
        Write-Host "  ALERTA: Banco tem $totalNoBanco, cache tem $totalNoCache (diferenca: $diff)" -ForegroundColor Red
    } else {
        Write-Host "  Contagem OK: $totalNoBanco no banco = $totalNoCache no cache" -ForegroundColor Green
    }

    $extracaoStatsFile = Join-Path $projetoDir "atualizacao\.extracao-temp.json"
    @{
        totalNoBanco = $totalNoBanco
        totalExtraido = $totalNoCache
        divergencia = ($totalNoBanco -ne $totalNoCache)
    } | ConvertTo-Json | Set-Content $extracaoStatsFile -Encoding UTF8

    if ($script:psaisComErro.Count -gt 0) {
        Write-Host ""
        Write-Host "=== PSAIs com erro (batch_size=1, pulados) ===" -ForegroundColor Red
        Write-Host "Total: $($script:psaisComErro.Count)"
        Write-Host "i_psai: $($script:psaisComErro -join ', ')"
    }
    Write-Host ""
    Write-Host "=== Extracao finalizada! ===" -ForegroundColor Green
    Write-Host "  JSON: $destinoJson"
    Write-Host "  Situacoes: $destinoSituacoes"
    Write-Host "  Total extraido: $totalExtraido"
    Write-Host "  Total no banco: $totalNoBanco"
} catch {
    Write-Host ""
    Write-Host "ERRO na extracao: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Execute novamente para continuar de onde parou." -ForegroundColor Yellow
    if (-not $SemLock) { Release-Lock $projetoDir }
    exit 1
} finally {
    Fechar-Conexao
}

if (-not $SemLock) { Release-Lock $projetoDir }






