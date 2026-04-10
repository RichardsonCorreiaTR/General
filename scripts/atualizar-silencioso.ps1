# atualizar-silencioso.ps1
# Execucao autonoma e silenciosa do pipeline de importacao + indices.
# Projetado para rodar via Task Scheduler sem interacao do usuario.
# Sem popup, sem Read-Host, sem pause.
#
# Uso: powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File atualizar-silencioso.ps1

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir
$atualizacaoDir = Join-Path $projetoDir "atualizacao"
$statusFile = Join-Path $atualizacaoDir "status.json"
$logFile = Join-Path $atualizacaoDir "log-importacao.txt"
$statsTemp = Join-Path $atualizacaoDir ".stats-temp.json"

New-Item -ItemType Directory -Path $atualizacaoDir -Force | Out-Null

$agora = Get-Date
$inicio = $agora
$resultado = "sucesso"
$erro = $null
$detalhes = ""

function Log-Linha($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $linha = "[$ts] $msg"
    Add-Content -Path $logFile -Value $linha -Encoding UTF8
}

try {
    # --- PRE-CHECK 1: OneDrive rodando? ---
    $oneDrive = Get-Process OneDrive -ErrorAction SilentlyContinue
    if (-not $oneDrive) {
        $erro = "OneDrive nao esta rodando"
        $resultado = "falha"
        Log-Linha "FALHA | Pre-check | $erro"
        throw $erro
    }

    # --- PRE-CHECK 2: ODBC DSN disponivel? ---
    $configOdbc = Join-Path $projetoDir "config\conexao-odbc.json"
    $dsnDisponivel = $false
    if (Test-Path $configOdbc) {
        $dsnName = (Get-Content $configOdbc -Raw -Encoding UTF8 | ConvertFrom-Json).odbc.dsn
        $dsnExiste = Get-OdbcDsn -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $dsnName }
        if ($dsnExiste) { $dsnDisponivel = $true }
    }

    if (-not $dsnDisponivel) {
        $buscaSaiPaths = @(
            "C:\1 - A\B\Programas\BuscaSAI",
            (Join-Path $env:USERPROFILE "OneDrive - Thomson Reuters Incorporated\Aplicacoes Cursor\BuscaSAI"),
            "C:\Users\$($env:USERNAME)\OneDrive - Thomson Reuters Incorporated\Aplicacoes Cursor\BuscaSAI"
        )
        $temFallback = $false
        foreach ($p in $buscaSaiPaths) {
            if (-not $p) { continue }
            $dc = Join-Path $p "data\cache"
            if (-not (Test-Path $dc)) { continue }
            if ((Get-ChildItem $dc -Filter "sai-psai-*.json" -ErrorAction SilentlyContinue).Count -gt 0) {
                $temFallback = $true; break
            }
        }
        if (-not $temFallback) {
            $erro = "ODBC indisponivel e BuscaSAI (nenhum data/cache/sai-psai-*.json)"
            $resultado = "falha"
            Log-Linha "FALHA | Pre-check | $erro"
            throw $erro
        }
    }

    # --- EXECUTAR ---
    Log-Linha "INICIO | Modo: $(if ($dsnDisponivel) {'ODBC multi-area'} else {'BuscaSAI mesclado'})"

    $importarScript = Join-Path $scriptDir "importar-sais.ps1"
    & $importarScript -Incremental

    # --- POS-CHECK ---
    $psaiDir = Join-Path $projetoDir "banco-dados\dados-brutos\psai"
    $saiDir = Join-Path $projetoDir "banco-dados\dados-brutos\sai"
    $indicesDir = Join-Path $projetoDir "banco-dados\sais\indices"
    $cacheFile = Join-Path $scriptDir "cache\sai-psai-escrita.json"

    $psaiCount = if (Test-Path $psaiDir) { (Get-ChildItem $psaiDir -Filter "*.json" | Measure-Object).Count } else { 0 }
    $saiCount = if (Test-Path $saiDir) { (Get-ChildItem $saiDir -Filter "*.json" | Measure-Object).Count } else { 0 }
    $mdCount = if (Test-Path $indicesDir) { (Get-ChildItem $indicesDir -Filter "*.md" -Recurse | Measure-Object).Count } else { 0 }
    $cacheMB = if (Test-Path $cacheFile) { [math]::Round((Get-Item $cacheFile).Length / 1MB, 1) } else { 0 }

    if ($psaiCount -eq 0) {
        $erro = "Pos-check: nenhum fracionado PSAI encontrado"
        $resultado = "falha"
    }

    $stats = @{ smartEscritos=0; smartPulados=0; totalRegistros=0; indicesMD=0; psaiMaisRecente=0; dataMaisRecente=$null; defasagemHoras=-1 }
    if (Test-Path $statsTemp) {
        $stats = Get-Content $statsTemp -Raw -Encoding UTF8 | ConvertFrom-Json
        Remove-Item $statsTemp -Force -ErrorAction SilentlyContinue
    }

    $extStats = @{ totalNoBanco=0; totalExtraido=0; divergencia=$false }
    $extStatsFile = Join-Path $atualizacaoDir ".extracao-temp.json"
    if (Test-Path $extStatsFile) {
        $extStats = Get-Content $extStatsFile -Raw -Encoding UTF8 | ConvertFrom-Json
        Remove-Item $extStatsFile -Force -ErrorAction SilentlyContinue
    }

    $maxPsaiInfo = if ($stats.psaiMaisRecente -gt 0) { " | max PSAI $($stats.psaiMaisRecente) de $($stats.dataMaisRecente)" } else { "" }
    $detalhes = "$($stats.totalRegistros) reg${maxPsaiInfo} | $psaiCount psai | $mdCount md | $($stats.smartEscritos) escritos, $($stats.smartPulados) pulados"

} catch {
    if (-not $erro) {
        $erro = $_.Exception.Message
        $resultado = "falha"
    }
    $detalhes = $erro
}

$fim = Get-Date
$tempoSeg = [math]::Round(($fim - $inicio).TotalSeconds, 0)

# --- GERAR ALERTAS ---
$alertas = @()
$defH = if ($stats.defasagemHoras) { [double]$stats.defasagemHoras } else { -1 }
if ($defH -gt 48) {
    $alertas += "DEFASAGEM: dados mais recentes tem ${defH}h (> 48h)"
}
if ($extStats.totalNoBanco -gt 0) {
    $totalFracionado = 0
    if (Test-Path $psaiDir) {
        foreach ($f in (Get-ChildItem $psaiDir -Filter "*.json")) {
            $reader = [System.IO.StreamReader]::new($f.FullName, [System.Text.Encoding]::UTF8)
            $buf = New-Object char[] 200
            [void]$reader.Read($buf, 0, 200)
            $reader.Close()
            $header = [string]::new($buf)
            if ($header -match '"total"\s*:\s*(\d+)') { $totalFracionado += [int]$Matches[1] }
        }
    }
    if ($totalFracionado -gt 0 -and $totalFracionado -lt $extStats.totalNoBanco) {
        $diff = [int]$extStats.totalNoBanco - $totalFracionado
        $alertas += "DIVERGENCIA: banco=$($extStats.totalNoBanco) vs fracionados=$totalFracionado (faltam $diff)"
    }
}
if ($psaiCount -eq 0) {
    $alertas += "SEM_FRACIONADOS: nenhum arquivo PSAI encontrado"
}

# --- GRAVAR STATUS ---
$status = [ordered]@{
    ultimaExecucao = $fim.ToString("o")
    resultado = $resultado
    tempoSegundos = $tempoSeg
    registrosProcessados = [int]$stats.totalRegistros
    totalNoBanco = [int]$extStats.totalNoBanco
    psaiMaisRecente = [int]$stats.psaiMaisRecente
    dataPsaiMaisRecente = $stats.dataMaisRecente
    defasagemHoras = $defH
    fracionadosPSAI = [int]$psaiCount
    fracionadosSAI = [int]$saiCount
    indicesMD = [int]$stats.indicesMD
    smartWriteEscritos = [int]$stats.smartEscritos
    smartWritePulados = [int]$stats.smartPulados
    cacheMB = $cacheMB
    alertas = $alertas
    erro = $erro
}
$status | ConvertTo-Json -Depth 2 | Set-Content $statusFile -Encoding UTF8

$alertasTxt = if ($alertas.Count -gt 0) { " | ALERTAS: $($alertas -join '; ')" } else { "" }
$logMsg = if ($resultado -eq "sucesso") {
    "SUCESSO | $detalhes | ${tempoSeg}s${alertasTxt}"
} else {
    "FALHA | $detalhes${alertasTxt}"
}
Log-Linha $logMsg

exit $(if ($resultado -eq "sucesso") { 0 } else { 1 })
