# dashboard-extracao.ps1
# Gera dashboard HTML com estado da extracao, comparacao de fontes e historico.
# Uso: .\scripts\dashboard-extracao.ps1
#       .\scripts\dashboard-extracao.ps1 -Watch   (atualiza a cada 30s)

param([switch]$Watch, [int]$IntervaloSeg = 30)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir
$atualizacaoDir = Join-Path $projetoDir "atualizacao"
$dashFile = Join-Path $atualizacaoDir "dashboard-extracao.html"

function Coletar-Dados {
    $dados = [ordered]@{ geradoEm = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") }

    # 1. status.json
    $statusFile = Join-Path $atualizacaoDir "status.json"
    if (Test-Path $statusFile) {
        $dados.status = Get-Content $statusFile -Raw -Encoding UTF8 | ConvertFrom-Json
    } else {
        $dados.status = @{ resultado = "desconhecido"; ultimaExecucao = "N/A" }
    }

    # 2. Extracao em andamento (log mais recente)
    $logs = Get-ChildItem "$atualizacaoDir\extracao-*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    $dados.extracaoAtiva = $false
    if ($logs.Count -gt 0) {
        $logFile = $logs[0].FullName
        $dados.logArquivo = $logs[0].Name
        $linhas = Get-Content $logFile -Encoding UTF8
        $ultimoOk = $linhas | Where-Object { $_ -match 'OK \((\d+)/(\d+) = ([\d.]+)% \| vel: (\d+)/min \| ETA: (\d+)min\)' } | Select-Object -Last 1
        if ($ultimoOk -and $ultimoOk -match 'OK \((\d+)/(\d+) = ([\d.]+)% \| vel: (\d+)/min \| ETA: (\d+)min\)') {
            $dados.extracaoAtiva = $true
            $dados.progresso = [ordered]@{
                extraidos = [int]$Matches[1]
                total = [int]$Matches[2]
                percentual = [double]$Matches[3]
                velocidade = [int]$Matches[4]
                etaMinutos = [int]$Matches[5]
                etaHoras = [math]::Round([int]$Matches[5] / 60, 1)
            }
        }
        $concluido = $linhas | Where-Object { $_ -match 'Extracao finalizada|Contagem OK|ALERTA.*Banco tem|CONCLUIDO' } | Select-Object -Last 1
        if ($concluido) {
            $dados.extracaoAtiva = $false
            $dados.extracaoConcluida = $concluido.Trim()
        }
    }

    # 3. Fracionados atuais
    $psaiDir = Join-Path $projetoDir "banco-dados\dados-brutos\psai"
    $saiDir = Join-Path $projetoDir "banco-dados\dados-brutos\sai"
    $psaiFiles = Get-ChildItem "$psaiDir\*.json" -ErrorAction SilentlyContinue
    $saiFiles = Get-ChildItem "$saiDir\*.json" -ErrorAction SilentlyContinue
    $psaiTotalKB = ($psaiFiles | Measure-Object -Property Length -Sum).Sum / 1KB
    $saiTotalKB = ($saiFiles | Measure-Object -Property Length -Sum).Sum / 1KB
    $dados.fracionados = [ordered]@{
        psaiArquivos = $psaiFiles.Count
        saiArquivos = $saiFiles.Count
        psaiTotalMB = [math]::Round($psaiTotalKB / 1024, 1)
        saiTotalMB = [math]::Round($saiTotalKB / 1024, 1)
        detalhesPsai = @($psaiFiles | ForEach-Object { [ordered]@{ nome=$_.Name; kb=[math]::Round($_.Length/1KB,1); data=$_.LastWriteTime.ToString("MM/dd HH:mm") } })
        detalhesSai = @($saiFiles | ForEach-Object { [ordered]@{ nome=$_.Name; kb=[math]::Round($_.Length/1KB,1); data=$_.LastWriteTime.ToString("MM/dd HH:mm") } })
    }

    # 4. BuscaSAI (Escrita) — padrao: clone em Programas
    $bsfBase = "C:\1 - A\B\Programas\BuscaSAI\data"
    if (-not (Test-Path $bsfBase)) {
        $bsfBase = Join-Path $env:USERPROFILE "OneDrive - Thomson Reuters Incorporated\Aplicacoes Cursor\BuscaSAI\data"
    }
    $bsfCache = Join-Path $bsfBase "cache\sai-psai-escrita.json"
    $dados.buscaSaiEscrita = [ordered]@{
        cacheMB = if (Test-Path $bsfCache) { [math]::Round((Get-Item $bsfCache).Length/1MB,1) } else { 0 }
        cacheData = if (Test-Path $bsfCache) { (Get-Item $bsfCache).LastWriteTime.ToString("yyyy-MM-dd HH:mm") } else { "N/A" }
        NE = (Get-ChildItem "$bsfBase\sais\NE\*.md" -ErrorAction SilentlyContinue).Count
        SAIL = (Get-ChildItem "$bsfBase\sais\SAIL\*.md" -ErrorAction SilentlyContinue).Count
        SAL = (Get-ChildItem "$bsfBase\sais\SAL\*.md" -ErrorAction SilentlyContinue).Count
        SAM = (Get-ChildItem "$bsfBase\sais\SAM\*.md" -ErrorAction SilentlyContinue).Count
    }
    $dados.buscaSaiEscrita.totalMDs = $dados.buscaSaiEscrita.NE + $dados.buscaSaiEscrita.SAIL + $dados.buscaSaiEscrita.SAL + $dados.buscaSaiEscrita.SAM

    # 5. Mapeamento de SAIs
    $mapBase = "C:\Users\6038243\OneDrive - Thomson Reuters Incorporated\Aplicacoes Cursor\Mapeamento de SAIs\data"
    $mapCaches = Get-ChildItem "$mapBase\cache\*.json" -ErrorAction SilentlyContinue
    $dados.mapeamento = [ordered]@{
        caches = @($mapCaches | ForEach-Object { [ordered]@{ nome=$_.Name; mb=[math]::Round($_.Length/1MB,1); data=$_.LastWriteTime.ToString("yyyy-MM-dd") } })
        preTrabalho = (Get-ChildItem "$mapBase\pre-trabalho" -Recurse -File -ErrorAction SilentlyContinue).Count
    }

    # 6. Historico
    $logImport = Join-Path $atualizacaoDir "log-importacao.txt"
    if (Test-Path $logImport) {
        $dados.historico = @(Get-Content $logImport -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() })
    } else {
        $dados.historico = @()
    }

    return $dados
}

function Gerar-HTML($dados) {
    $json = $dados | ConvertTo-Json -Depth 5 -Compress
    $html = @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta http-equiv="refresh" content="30">
<title>Dashboard Extracao SAI/PSAI</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&family=DM+Sans:wght@400;500;700&display=swap');
  :root { --bg:#0f1117; --card:#1a1d27; --border:#2a2d3a; --text:#e0e0e0; --dim:#888; --accent:#4fc3f7; --ok:#66bb6a; --warn:#ffa726; --err:#ef5350; --bar:#4fc3f7; }
  * { margin:0; padding:0; box-sizing:border-box; }
  body { font-family:'DM Sans',sans-serif; background:var(--bg); color:var(--text); padding:24px; min-height:100vh; }
  h1 { font-family:'JetBrains Mono',monospace; font-size:1.4rem; color:var(--accent); margin-bottom:4px; letter-spacing:-0.5px; }
  .subtitle { color:var(--dim); font-size:0.85rem; margin-bottom:24px; }
  .grid { display:grid; grid-template-columns:1fr 1fr; gap:16px; margin-bottom:16px; }
  .card { background:var(--card); border:1px solid var(--border); border-radius:10px; padding:20px; }
  .card-title { font-family:'JetBrains Mono',monospace; font-size:0.75rem; text-transform:uppercase; color:var(--dim); letter-spacing:1px; margin-bottom:12px; }
  .big-number { font-family:'JetBrains Mono',monospace; font-size:2.4rem; font-weight:700; line-height:1; }
  .big-label { font-size:0.8rem; color:var(--dim); margin-top:4px; }
  .progress-bar { background:#2a2d3a; border-radius:6px; height:20px; overflow:hidden; margin:8px 0; position:relative; }
  .progress-fill { background:linear-gradient(90deg,#4fc3f7,#29b6f6); height:100%; border-radius:6px; transition:width 0.5s; }
  .progress-text { position:absolute; top:0; left:0; right:0; text-align:center; line-height:20px; font-size:0.7rem; font-family:'JetBrains Mono',monospace; color:#fff; }
  .stat-row { display:flex; justify-content:space-between; padding:6px 0; border-bottom:1px solid var(--border); font-size:0.85rem; }
  .stat-row:last-child { border:none; }
  .stat-label { color:var(--dim); }
  .stat-val { font-family:'JetBrains Mono',monospace; font-weight:700; }
  .badge { display:inline-block; padding:2px 8px; border-radius:4px; font-size:0.7rem; font-weight:700; text-transform:uppercase; font-family:'JetBrains Mono',monospace; }
  .badge-ok { background:#1b3a1b; color:var(--ok); }
  .badge-warn { background:#3a2e1b; color:var(--warn); }
  .badge-err { background:#3a1b1b; color:var(--err); }
  .badge-run { background:#1b2e3a; color:var(--accent); animation:pulse 2s infinite; }
  @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.5} }
  table { width:100%; border-collapse:collapse; font-size:0.8rem; }
  th { text-align:left; padding:8px 6px; border-bottom:2px solid var(--border); color:var(--dim); font-family:'JetBrains Mono',monospace; font-size:0.7rem; text-transform:uppercase; }
  td { padding:6px; border-bottom:1px solid var(--border); }
  .full-width { grid-column:1/-1; }
  .log-line { font-family:'JetBrains Mono',monospace; font-size:0.72rem; padding:3px 0; border-bottom:1px solid #1f2230; color:var(--dim); }
  .log-line:last-child { border:none; }
  .compare-bar { display:flex; height:28px; border-radius:4px; overflow:hidden; margin:4px 0; }
  .compare-seg { display:flex; align-items:center; justify-content:center; font-size:0.65rem; font-family:'JetBrains Mono',monospace; color:#fff; font-weight:700; }
  .alert-box { background:#3a2e1b; border:1px solid var(--warn); border-radius:6px; padding:10px 14px; margin-bottom:8px; font-size:0.8rem; }
</style>
</head>
<body>
<h1>EXTRACAO SAI/PSAI -- DASHBOARD</h1>
<div class="subtitle" id="subtitle"></div>
<div id="alerts"></div>
<div class="grid">
  <div class="card" id="card-progress"></div>
  <div class="card" id="card-status"></div>
  <div class="card full-width" id="card-compare"></div>
  <div class="card" id="card-fracionados"></div>
  <div class="card" id="card-fontes"></div>
  <div class="card full-width" id="card-historico"></div>
</div>
<script>
const D = $json;

document.getElementById('subtitle').textContent = 'Gerado em: ' + D.geradoEm + ' | Para atualizar: .\\scripts\\dashboard-extracao.ps1';

// Alerts
const alertsEl = document.getElementById('alerts');
if (D.status && D.status.alertas && D.status.alertas.length > 0) {
  D.status.alertas.forEach(a => { alertsEl.innerHTML += '<div class="alert-box">' + a + '</div>'; });
}

// Progress
const cp = document.getElementById('card-progress');
if (D.extracaoAtiva && D.progresso) {
  const p = D.progresso;
  cp.innerHTML = '<div class="card-title">Extracao em Andamento</div>' +
    '<div class="big-number" style="color:var(--accent)">' + p.percentual.toFixed(1) + '%</div>' +
    '<div class="big-label">' + p.extraidos.toLocaleString() + ' de ' + p.total.toLocaleString() + ' registros</div>' +
    '<div class="progress-bar"><div class="progress-fill" style="width:' + p.percentual + '%"></div>' +
    '<div class="progress-text">' + p.extraidos + '/' + p.total + '</div></div>' +
    '<div class="stat-row"><span class="stat-label">Velocidade</span><span class="stat-val">' + p.velocidade + '/min</span></div>' +
    '<div class="stat-row"><span class="stat-label">ETA</span><span class="stat-val">' + p.etaHoras + 'h (' + p.etaMinutos + 'min)</span></div>' +
    '<div class="stat-row"><span class="stat-label">Status</span><span class="badge badge-run">EXTRAINDO</span></div>';
} else if (D.extracaoConcluida) {
  cp.innerHTML = '<div class="card-title">Extracao</div>' +
    '<div class="big-number" style="color:var(--ok)">100%</div>' +
    '<div class="big-label">Concluida</div>' +
    '<div style="margin-top:8px;font-size:0.8rem;color:var(--dim)">' + D.extracaoConcluida + '</div>';
} else {
  cp.innerHTML = '<div class="card-title">Extracao</div>' +
    '<div class="big-number" style="color:var(--dim)">--</div>' +
    '<div class="big-label">Nenhuma extracao em andamento</div>';
}

// Status
const cs = document.getElementById('card-status');
const s = D.status || {};
const resBadge = s.resultado === 'sucesso' ? 'badge-ok' : s.resultado === 'falha' ? 'badge-err' : 'badge-warn';
cs.innerHTML = '<div class="card-title">Ultimo Status (status.json)</div>' +
  '<div class="stat-row"><span class="stat-label">Resultado</span><span class="badge ' + resBadge + '">' + (s.resultado||'?') + '</span></div>' +
  '<div class="stat-row"><span class="stat-label">Ultima execucao</span><span class="stat-val">' + (s.ultimaExecucao ? new Date(s.ultimaExecucao).toLocaleString('pt-BR') : 'N/A') + '</span></div>' +
  '<div class="stat-row"><span class="stat-label">Registros processados</span><span class="stat-val">' + (s.registrosProcessados||0).toLocaleString() + '</span></div>' +
  '<div class="stat-row"><span class="stat-label">Total no banco</span><span class="stat-val">' + (s.totalNoBanco||0).toLocaleString() + '</span></div>' +
  '<div class="stat-row"><span class="stat-label">PSAI mais recente</span><span class="stat-val">' + (s.psaiMaisRecente||'?') + ' (' + (s.dataPsaiMaisRecente||'?') + ')</span></div>' +
  '<div class="stat-row"><span class="stat-label">Defasagem</span><span class="stat-val">' + (s.defasagemHoras||'?') + 'h</span></div>' +
  '<div class="stat-row"><span class="stat-label">Cache</span><span class="stat-val">' + (s.cacheMB||0) + ' MB</span></div>';

// Compare
const cc = document.getElementById('card-compare');
const odbc = s.totalNoBanco || 35307;
const frac = s.registrosProcessados || 0;
const bsf = D.buscaSaiEscrita ? D.buscaSaiEscrita.totalMDs : 0;
const maxV = Math.max(odbc, frac, bsf, 1);
cc.innerHTML = '<div class="card-title">Comparacao de Fontes</div>' +
  '<table><tr><th>Fonte</th><th>Registros</th><th>Cobertura vs ODBC</th><th>Status</th></tr>' +
  '<tr><td>Banco ODBC (Sybase)</td><td class="stat-val">' + odbc.toLocaleString() + '</td><td><div class="progress-bar" style="height:14px"><div class="progress-fill" style="width:100%;background:var(--accent)"></div></div></td><td><span class="badge badge-ok">REFERENCIA</span></td></tr>' +
  '<tr><td>Fracionados (cache local)</td><td class="stat-val">' + frac.toLocaleString() + '</td><td><div class="progress-bar" style="height:14px"><div class="progress-fill" style="width:' + (frac/odbc*100).toFixed(1) + '%;background:var(--ok)"></div></div></td><td><span class="badge ' + (frac>=odbc?'badge-ok':'badge-warn') + '">' + (frac/odbc*100).toFixed(1) + '%</span></td></tr>' +
  '<tr><td>BuscaSAI Escrita (MDs)</td><td class="stat-val">' + bsf.toLocaleString() + '</td><td><div class="progress-bar" style="height:14px"><div class="progress-fill" style="width:' + (bsf/odbc*100).toFixed(1) + '%;background:#ab47bc"></div></div></td><td><span class="badge ' + (bsf>=odbc?'badge-ok':'badge-warn') + '">' + (bsf/odbc*100).toFixed(1) + '%</span></td></tr>' +
  '</table>';

// Fracionados
const cf = document.getElementById('card-fracionados');
let fhtml = '<div class="card-title">Fracionados Locais</div>' +
  '<div class="stat-row"><span class="stat-label">PSAI</span><span class="stat-val">' + D.fracionados.psaiArquivos + ' arq (' + D.fracionados.psaiTotalMB + ' MB)</span></div>' +
  '<div class="stat-row"><span class="stat-label">SAI</span><span class="stat-val">' + D.fracionados.saiArquivos + ' arq (' + D.fracionados.saiTotalMB + ' MB)</span></div>';
function renderFileTable(label, items) {
  let h = '<div style="font-size:0.8rem;font-weight:700;margin:10px 0 4px;color:var(--accent)">' + label + '</div>';
  h += '<table><tr><th>Arquivo</th><th>KB</th><th>Data</th></tr>';
  (items||[]).forEach(d => { h += '<tr><td>' + d.nome + '</td><td class="stat-val">' + d.kb + '</td><td>' + d.data + '</td></tr>'; });
  return h + '</table>';
}
fhtml += renderFileTable('PSAI', D.fracionados.detalhesPsai);
fhtml += renderFileTable('SAI', D.fracionados.detalhesSai);
cf.innerHTML = fhtml;

// Fontes externas
const cfe = document.getElementById('card-fontes');
const b = D.buscaSaiEscrita || {};
let fehtml = '<div class="card-title">Fontes Externas</div>' +
  '<div style="font-size:0.8rem;font-weight:700;margin-bottom:6px">BuscaSAI Escrita</div>' +
  '<div class="stat-row"><span class="stat-label">Cache</span><span class="stat-val">' + (b.cacheMB||0) + ' MB (' + (b.cacheData||'?') + ')</span></div>' +
  '<div class="stat-row"><span class="stat-label">NE</span><span class="stat-val">' + (b.NE||0).toLocaleString() + '</span></div>' +
  '<div class="stat-row"><span class="stat-label">SAIL</span><span class="stat-val">' + (b.SAIL||0).toLocaleString() + '</span></div>' +
  '<div class="stat-row"><span class="stat-label">SAL</span><span class="stat-val">' + (b.SAL||0).toLocaleString() + '</span></div>' +
  '<div class="stat-row"><span class="stat-label">SAM</span><span class="stat-val">' + (b.SAM||0).toLocaleString() + '</span></div>';
if (D.mapeamento) {
  fehtml += '<div style="font-size:0.8rem;font-weight:700;margin:10px 0 6px">Mapeamento de SAIs</div>';
  (D.mapeamento.caches||[]).forEach(c => { fehtml += '<div class="stat-row"><span class="stat-label">' + c.nome + '</span><span class="stat-val">' + c.mb + ' MB</span></div>'; });
  fehtml += '<div class="stat-row"><span class="stat-label">Pre-trabalho</span><span class="stat-val">' + (D.mapeamento.preTrabalho||0) + ' arq</span></div>';
}
cfe.innerHTML = fehtml;

// Historico
const ch = document.getElementById('card-historico');
let hhtml = '<div class="card-title">Historico de Execucoes</div>';
(D.historico||[]).slice().reverse().forEach(l => {
  const cls = l.includes('SUCESSO') ? 'color:var(--ok)' : l.includes('FALHA') ? 'color:var(--err)' : l.includes('REVISAO') ? 'color:var(--accent)' : '';
  hhtml += '<div class="log-line" style="' + cls + '">' + l + '</div>';
});
ch.innerHTML = hhtml;
</script>
</body>
</html>
"@
    Set-Content -Path $dashFile -Value $html -Encoding UTF8
}

# --- MAIN ---
do {
    Write-Host "Coletando dados..." -ForegroundColor Yellow
    $dados = Coletar-Dados
    Write-Host "Gerando dashboard..." -ForegroundColor Yellow
    Gerar-HTML $dados
    Write-Host "Dashboard salvo em: $dashFile" -ForegroundColor Green

    if (-not $Watch) {
        Start-Process $dashFile
        Write-Host "Aberto no navegador." -ForegroundColor Cyan
    } else {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Atualizado. Proximo em ${IntervaloSeg}s..." -ForegroundColor Cyan
        Start-Sleep -Seconds $IntervaloSeg
    }
} while ($Watch)
