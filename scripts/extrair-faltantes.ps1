# extrair-faltantes.ps1
# Extrai APENAS os registros que existem no ODBC mas NAO existem nos fracionados locais.
# Muito mais rapido que uma extracao completa.

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir

# ── Config ──
$configFile = Join-Path $projetoDir "config\conexao-odbc.json"
$cfg = Get-Content $configFile -Raw | ConvertFrom-Json
$DSN = $cfg.odbc.dsn
$UID = $cfg.odbc.usuario
$PWD_DB = $cfg.odbc.senha
$ENCODING = $cfg.odbc.encoding
$AREA = $cfg.extracao.area
$MAX_RETRIES = $cfg.extracao.max_retries
$AnoInicial = $cfg.extracao.ano_inicial

$enc = [System.Text.Encoding]::GetEncoding($ENCODING)
$connStr = "DSN=$DSN;UID=$UID;PWD=$PWD_DB;CS=iso_1"

$psaiDir = Join-Path $projetoDir "banco-dados\dados-brutos\psai"
$saiDir = Join-Path $projetoDir "banco-dados\dados-brutos\sai"

# ── Funcoes ODBC ──
$conn = $null

function Abrir-Conexao {
    $script:conn = New-Object System.Data.Odbc.OdbcConnection($connStr)
    $script:conn.ConnectionTimeout = $cfg.odbc.timeout_conexao_seg
    $script:conn.Open()
    Write-Host "  [conexao] Pool ODBC aberto" -ForegroundColor DarkGray
}

function Fechar-Conexao {
    if ($script:conn -and $script:conn.State -eq 'Open') {
        $script:conn.Close(); $script:conn.Dispose(); $script:conn = $null
    }
}

function Reconectar {
    Write-Host "  [conexao] Reconectando..." -ForegroundColor DarkYellow
    Fechar-Conexao; Abrir-Conexao
}

function Executar-Query {
    param([string]$sql, [int]$tentativa = 1)
    try {
        $cmd = $script:conn.CreateCommand()
        $cmd.CommandText = $sql
        $cmd.CommandTimeout = $cfg.odbc.timeout_query_seg
        $reader = $cmd.ExecuteReader([System.Data.CommandBehavior]::SequentialAccess)
        $resultados = [System.Collections.ArrayList]::new()
        $colunas = @()
        $colTipos = @()
        for ($i = 0; $i -lt $reader.FieldCount; $i++) {
            $colunas += $reader.GetName($i)
            try { $colTipos += $reader.GetDataTypeName($i) } catch { $colTipos += "unknown" }
        }
        while ($reader.Read()) {
            $row = [ordered]@{}
            for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                $nome = $colunas[$i]
                $isBlob = $colTipos[$i] -match 'binary|blob|long'
                if ($isBlob) {
                    try {
                        $bufSize = 8192
                        $buf = New-Object byte[] $bufSize
                        $stream = New-Object System.IO.MemoryStream
                        $offset2 = 0
                        do {
                            $read = $reader.GetBytes($i, $offset2, $buf, 0, $bufSize)
                            if ($read -gt 0) { $stream.Write($buf, 0, $read); $offset2 += $read }
                        } while ($read -eq $bufSize)
                        $allBytes = $stream.ToArray(); $stream.Dispose()
                        $row[$nome] = if ($allBytes.Length -gt 0) { $enc.GetString($allBytes) } else { $null }
                    } catch { $row[$nome] = $null }
                } else {
                    try {
                        $val = $reader.GetValue($i)
                        $row[$nome] = if ($val -eq [System.DBNull]::Value) { $null } else { $val }
                    } catch { $row[$nome] = $null }
                }
            }
            [void]$resultados.Add($row)
        }
        $reader.Close(); $cmd.Dispose()
        return ,$resultados
    } catch {
        $msg = $_.Exception.Message
        if (($msg -match 'conex|connection|terminat|timeout|communicat|reset|closed|broken|socket') -and $tentativa -le $MAX_RETRIES) {
            $delaySec = @(10,30,60,120,180)[[math]::Min($tentativa-1, 4)]
            Write-Host "  [retry] Tentativa $tentativa/$MAX_RETRIES. Aguardando ${delaySec}s..." -ForegroundColor Yellow
            Start-Sleep -Seconds $delaySec
            try { Reconectar } catch { Write-Host "  [retry] Falha: $($_.Exception.Message)" -ForegroundColor Red }
            return Executar-Query -sql $sql -tentativa ($tentativa + 1)
        }
        throw
    }
}

function Limpar-Html {
    param([string]$texto)
    if (-not $texto) { return $null }
    $t = $texto -replace '<br\s*/?>', "`n"
    $t = $t -replace '</?(?:div|p|li|ol|ul|tr|td|th|table|strong|em|b|i|span|font|a|h[1-6])[^>]*>', ' '
    $t = $t -replace '<[^>]+>', ''
    $t = [System.Net.WebUtility]::HtmlDecode($t)
    $t = $t -replace '[ \t]+', ' '
    $t = $t -replace '\n\s*\n', "`n"
    return $t.Trim()
}

# ── Carregar situacoes para enriquecer ──
$situacoesFile = Join-Path $projetoDir "banco-dados\dados-brutos\situacoes.json"
$mapSituacaoSai = @{}
$mapSituacaoPsai = @{}
if (Test-Path $situacoesFile) {
    $sit = Get-Content $situacoesFile -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($s in $sit.sai) { $mapSituacaoSai[[string]$s.i_sai_situacoes] = $s.descricao }
    foreach ($s in $sit.psai) { $mapSituacaoPsai[[string]$s.i_situacoes] = $s.descricao }
}

# ══════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  EXTRACAO INTELIGENTE -- Somente registros faltantes" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# ── PASSO 1: Contagem e IDs no banco (paginado para Sybase ASA 9.0) ──
Write-Host ""
Write-Host "[1/5] Consultando banco ODBC (paginado, sem BLOBs)..." -ForegroundColor Yellow
Abrir-Conexao

$sqlCount = "SELECT COUNT(*) as total FROM UP.SAI_PSAI sp WHERE sp.nomeArea = '$AREA' AND YEAR(sp.CadastroPSAI) >= $AnoInicial"
$countResult = Executar-Query $sqlCount
$totalNoBanco = [int]$countResult[0]['total']
Write-Host "  Total no banco: $totalNoBanco" -ForegroundColor Green

$chavesBanco = [System.Collections.Generic.HashSet[string]]::new()
$regsBanco = [System.Collections.ArrayList]::new()
$PAGE_SIZE = 200
$totalPaginas = [math]::Ceiling($totalNoBanco / $PAGE_SIZE)
for ($pg = 0; $pg -lt $totalPaginas; $pg++) {
    $offset = ($pg * $PAGE_SIZE) + 1
    $sqlPage = "SELECT TOP $PAGE_SIZE START AT $offset sp.i_sai, sp.i_psai, sp.tipoSAI, sp.CadastroPSAI, sp.Liberacao, sp.Descarte FROM UP.SAI_PSAI sp WHERE sp.nomeArea = '$AREA' AND YEAR(sp.CadastroPSAI) >= $AnoInicial ORDER BY sp.CadastroPSAI, sp.i_sai"
    $pageResult = Executar-Query $sqlPage
    foreach ($r in $pageResult) {
        $chave = "$($r.i_sai)-$($r.i_psai)"
        if ($chavesBanco.Add($chave)) {
            [void]$regsBanco.Add(@{ chave=$chave; i_sai=[int]$r.i_sai; i_psai=[int]$r.i_psai; tipoSAI=$r.tipoSAI; CadastroPSAI=$r.CadastroPSAI; Liberacao=$r.Liberacao; Descarte=$r.Descarte })
        }
    }
    if (($pg+1) % 10 -eq 0 -or ($pg+1) -eq $totalPaginas) {
        Write-Host "  Pagina $($pg+1)/${totalPaginas}: $($chavesBanco.Count) registros coletados" -ForegroundColor DarkGray
    }
    if ($pg % 30 -eq 29) { Reconectar }
}
Write-Host "  Registros no banco: $($chavesBanco.Count)" -ForegroundColor Green

# ── PASSO 2: Chaves nos fracionados locais ──
Write-Host "[2/5] Lendo chaves dos fracionados locais..." -ForegroundColor Yellow
$chavesLocais = [System.Collections.Generic.HashSet[string]]::new()
$tiposTodos = @("NE","SAM","SAL","SAIL")
foreach ($tp in $tiposTodos) {
    foreach ($status in @("pendentes","liberadas","descartadas")) {
        $arquivo = Join-Path $psaiDir "$($tp.ToLower())-$status.json"
        if (-not (Test-Path $arquivo)) { continue }
        $fileJson = Get-Content $arquivo -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($item in $fileJson.dados) { [void]$chavesLocais.Add("$($item.i_sai)-$($item.i_psai)") }
        $fileJson = $null
    }
}
[GC]::Collect()
Write-Host "  Registros locais: $($chavesLocais.Count)" -ForegroundColor Green

# ── PASSO 3: Calcular faltantes ──
Write-Host "[3/5] Calculando diferenca..." -ForegroundColor Yellow
$faltantes = [System.Collections.ArrayList]::new()
foreach ($reg in $regsBanco) {
    if (-not $chavesLocais.Contains($reg.chave)) { [void]$faltantes.Add($reg) }
}
Write-Host "  Faltantes: $($faltantes.Count) registros" -ForegroundColor $(if ($faltantes.Count -gt 0) { "Red" } else { "Green" })

if ($faltantes.Count -eq 0) {
    Write-Host ""
    Write-Host "=== Nenhum registro faltante! Base local esta completa. ===" -ForegroundColor Green
    Fechar-Conexao
    exit 0
}

$comPsai = ($faltantes | Where-Object { $_.i_psai -gt 0 }).Count
$semPsai = $faltantes.Count - $comPsai
Write-Host "  Com PSAI (i_psai > 0): $comPsai"
Write-Host "  Sem PSAI (i_psai = 0): $semPsai (SAIs antigas)"

# ── PASSO 4: Extrair faltantes em lotes ──
Write-Host "[4/5] Extraindo $($faltantes.Count) registros faltantes..." -ForegroundColor Yellow
$BATCH_SIZE = 25
$totalLotes = [math]::Ceiling($faltantes.Count / $BATCH_SIZE)
$registrosExtraidos = [System.Collections.ArrayList]::new()
$inicio = Get-Date
$loteNum = 0

for ($i = 0; $i -lt $faltantes.Count; $i += $BATCH_SIZE) {
    $loteNum++
    $loteRegs = $faltantes[$i..([math]::Min($i + $BATCH_SIZE - 1, $faltantes.Count - 1))]
    if ($loteRegs -isnot [array]) { $loteRegs = @($loteRegs) }
    $idList = ($loteRegs | ForEach-Object { $_.i_sai }) -join ","

    $sql = @"
SELECT sp.i_sai, sp.i_psai, sp.tipoSAI, sp.nomeArea, sp.nomeVersao,
    sp.CadastroPSAI, sp.CadastroSAI, sp.Liberacao, sp.Descarte,
    sp.dataFinalizada, sp.gravidade_ne, sp.tempoPrevistoTotal,
    sp.tempoRealizadoTotal, sp.ne_prevencao, sp.i_sai_situacoes,
    sp.i_psai_situacoes, sp.i_sistemas, sp.i_modulos,
    sp.ultima_modificacao, sp.liberacaoOficial, sp.qtde_ssc,
    sp.qtde_sane, s.pontuacao, p.nivel_alteracao, p.i_produto_grupo,
    CAST(s.descricao AS LONG BINARY) as sai_descricao,
    CAST(s.comportamento AS LONG BINARY) as comportamento,
    CAST(s.definicao AS LONG BINARY) as definicao,
    CAST(s.descricao_destaque AS LONG BINARY) as sai_destaque,
    CAST(p.descricao AS LONG BINARY) as psai_descricao,
    CAST(p.descricao_destaque AS LONG BINARY) as psai_destaque
FROM UP.SAI_PSAI sp
LEFT JOIN bethadba.sai s ON sp.i_sai = s.i_sai
LEFT JOIN bethadba.psai p ON sp.i_psai = p.i_psai
WHERE sp.i_sai IN ($idList) AND sp.nomeArea = '$AREA'
ORDER BY sp.i_psai ASC
"@

    $loteResult = Executar-Query $sql
    foreach ($r in $loteResult) {
        foreach ($campo in @("sai_descricao","comportamento","definicao","sai_destaque","psai_descricao","psai_destaque")) {
            if ($r[$campo]) { $r[$campo] = Limpar-Html $r[$campo] }
        }
        if ($mapSituacaoSai.ContainsKey([string]$r.i_sai_situacoes)) { $r["situacaoSai"] = $mapSituacaoSai[[string]$r.i_sai_situacoes] }
        if ($mapSituacaoPsai.ContainsKey([string]$r.i_psai_situacoes)) { $r["situacaoPsai"] = $mapSituacaoPsai[[string]$r.i_psai_situacoes] }
        [void]$registrosExtraidos.Add($r)
    }

    $extraidosAteAgora = $registrosExtraidos.Count
    $elapsed = ((Get-Date) - $inicio).TotalMinutes
    $vel = if ($elapsed -gt 0) { [math]::Round($extraidosAteAgora / $elapsed, 0) } else { 0 }
    $restante = $faltantes.Count - $extraidosAteAgora
    $etaMin = if ($vel -gt 0) { [math]::Round($restante / $vel, 0) } else { 0 }
    Write-Host "  Lote $loteNum/$totalLotes OK ($extraidosAteAgora/$($faltantes.Count) = $([math]::Round($extraidosAteAgora/$faltantes.Count*100,1))% | vel: ${vel}/min | ETA: ${etaMin}min)" -ForegroundColor DarkGray

    if ($loteNum % 20 -eq 0) { Reconectar }
    Start-Sleep -Milliseconds 200
}

Fechar-Conexao
Write-Host "  Extraidos: $($registrosExtraidos.Count) registros em $([math]::Round(((Get-Date)-$inicio).TotalMinutes,1)) min" -ForegroundColor Green

# ── PASSO 5: Merge nos fracionados ──
Write-Host "[5/5] Mergeando nos fracionados existentes..." -ForegroundColor Yellow

function Classificar-Status($r) {
    if ($r.Descarte) { return "descartadas" }
    if ($r.Liberacao) { return "liberadas" }
    return "pendentes"
}

$mergeCount = @{}
foreach ($r in $registrosExtraidos) {
    $tipo = $r.tipoSAI
    $status = Classificar-Status $r
    $key = "$($tipo.ToLower())-$status"
    if (-not $mergeCount[$key]) { $mergeCount[$key] = [System.Collections.ArrayList]::new() }
    [void]$mergeCount[$key].Add($r)
}

foreach ($key in $mergeCount.Keys) {
    $novos = $mergeCount[$key]
    $psaiFile = Join-Path $psaiDir "$key.json"
    $saiFile = Join-Path $saiDir "$key.json"

    # Merge PSAI
    if (Test-Path $psaiFile) {
        $existing = Get-Content $psaiFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $existingKeys = [System.Collections.Generic.HashSet[string]]::new()
        foreach ($d in $existing.dados) { [void]$existingKeys.Add("$($d.i_sai)-$($d.i_psai)") }
        foreach ($n in $novos) {
            $nk = "$($n.i_sai)-$($n.i_psai)"
            if (-not $existingKeys.Contains($nk)) {
                $existing.dados += $n
            }
        }
        $existing | ConvertTo-Json -Depth 4 -Compress | Set-Content $psaiFile -Encoding UTF8
        Write-Host "  PSAI ${key}: +$($novos.Count) (total: $($existing.dados.Count))" -ForegroundColor Green
        $existing = $null
    }

    # Merge SAI
    if (Test-Path $saiFile) {
        $existing = Get-Content $saiFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $existingKeys = [System.Collections.Generic.HashSet[string]]::new()
        foreach ($d in $existing.dados) { [void]$existingKeys.Add("$($d.i_sai)-$($d.i_psai)") }
        $saiCampos = @("i_sai","i_psai","tipoSAI","nomeArea","nomeVersao","CadastroPSAI","CadastroSAI","Liberacao","Descarte","gravidade_ne","situacaoSai")
        foreach ($n in $novos) {
            $nk = "$($n.i_sai)-$($n.i_psai)"
            if (-not $existingKeys.Contains($nk)) {
                $saiRow = [ordered]@{}
                foreach ($c in $saiCampos) { $saiRow[$c] = $n[$c] }
                $existing.dados += $saiRow
            }
        }
        $existing | ConvertTo-Json -Depth 4 -Compress | Set-Content $saiFile -Encoding UTF8
        Write-Host "  SAI  ${key}: +$($novos.Count) (total: $($existing.dados.Count))" -ForegroundColor Green
        $existing = $null
    }
}

[GC]::Collect()

# Regenerar indices
Write-Host ""
Write-Host "Regenerando indices..." -ForegroundColor Yellow
$indicesScript = Join-Path $scriptDir "gerar-indices-sais.ps1"
& $indicesScript

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  CONCLUIDO!" -ForegroundColor Green
Write-Host "  Faltantes extraidos: $($registrosExtraidos.Count)" -ForegroundColor Green
Write-Host "  Tempo total: $([math]::Round(((Get-Date)-$inicio).TotalMinutes,1)) min" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
