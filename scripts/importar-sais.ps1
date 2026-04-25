# importar-sais.ps1
# Importa SAIs/PSAIs e gera indices.
# Fonte primaria: extracao direta do banco via ODBC (extrair-sais.ps1)
# Fallback: BuscaSAI — mescla todos os data/cache/sai-psai-*.json (Escrita, Importacao, Onvio Escrita, etc.)
#
# IMPORTANTE: Rodar em terminal SEPARADO (fora do Cursor)
#
# Exemplos:
#   .\importar-sais.ps1                                      Incremental via ODBC (todas as areas do config)
#   .\importar-sais.ps1 -Completo                            Extracao completa via ODBC
#   .\importar-sais.ps1 -SomenteAreas "Contabil" -Completo  Extrai so a area indicada e mescla com cache existente
#   .\importar-sais.ps1 -FonteBuscaSai "C:\..."              Fallback para pasta BuscaSAI

param(
    [switch]$Incremental,
    [switch]$Completo,
    [string]$FonteBuscaSai = "",
    [string[]]$SomenteAreas = @()
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir
$dadosBrutosDir = Join-Path $projetoDir "banco-dados\dados-brutos"
$indicesDir = Join-Path $projetoDir "banco-dados\sais\indices"
$metaFile = Join-Path $projetoDir "banco-dados\sais\cache\importacao-meta.json"
$cacheDir = Join-Path $scriptDir "cache"
New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
$destinoJson = Join-Path $cacheDir "sai-psai-escrita.json"

. (Join-Path $scriptDir "lib-lock.ps1")
if (-not (Request-Lock $projetoDir "importar-sais")) { exit 1 }

New-Item -ItemType Directory -Path $dadosBrutosDir -Force | Out-Null

Write-Host "=== Importador de SAIs/PSAIs ===" -ForegroundColor Cyan
Write-Host "Cache local: $cacheDir"
Write-Host "Fracionados (OneDrive): $dadosBrutosDir"
Write-Host "Indices (OneDrive): $indicesDir"
Write-Host ""

# ── Funcoes auxiliares ────────────────────────────────────────────────

function Merge-BuscaSaiJsons {
    param([string]$dirCache)
    $arquivos = @(Get-ChildItem -Path $dirCache -Filter "sai-psai-*.json" -File -ErrorAction SilentlyContinue | Sort-Object Name)
    if ($arquivos.Count -eq 0) { return $null }
    if ($arquivos.Count -eq 1) {
        $j = Get-Content $arquivos[0].FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not $j.dados) { return $null }
        return @{
            wrapper = [ordered]@{
                geradoEm = if ($j.geradoEm) { $j.geradoEm } else { (Get-Date -Format o) }
                totalRegistros = $j.dados.Count
                dados = @($j.dados)
                fontesMescladas = @($arquivos[0].Name)
            }
            situacoesPath = Join-Path $dirCache "situacoes.json"
        }
    }
    Write-Host "  Mesclando $($arquivos.Count) arquivos sai-psai-*.json..." -ForegroundColor Yellow
    $porPsai = @{}
    $nomes = @()
    foreach ($f in $arquivos) {
        $nomes += $f.Name
        $j = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not $j.dados) { continue }
        foreach ($item in $j.dados) {
            $k = [string]$item.i_psai
            if (-not $k) { continue }
            $porPsai[$k] = $item
        }
    }
    $lista = [System.Collections.ArrayList]::new()
    foreach ($v in $porPsai.Values) { [void]$lista.Add($v) }
    return @{
        wrapper = [ordered]@{
            geradoEm = (Get-Date -Format o)
            totalRegistros = $lista.Count
            dados = $lista.ToArray()
            fontesMescladas = $nomes
        }
        situacoesPath = Join-Path $dirCache "situacoes.json"
    }
}

# ── Fonte primaria: ODBC direto ──────────────────────────────────────

$extrairScript = Join-Path $scriptDir "extrair-sais.ps1"
$configOdbc = Join-Path $projetoDir "config\conexao-odbc.json"
$usouOdbc = $false

if (-not $FonteBuscaSai -and (Test-Path $extrairScript) -and (Test-Path $configOdbc)) {
    $dsnName = (Get-Content $configOdbc -Raw | ConvertFrom-Json).odbc.dsn
    $dsnExiste = Get-OdbcDsn -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $dsnName }
    if ($dsnExiste) {
        Write-Host "[ODBC] DSN '$dsnName' encontrado. Extraindo direto do banco..." -ForegroundColor Green

        # Modo -SomenteAreas: extrai areas especificas e mescla com cache existente
        if ($SomenteAreas.Count -gt 0) {
            Write-Host "[ODBC] Modo SomenteAreas: $($SomenteAreas -join ', ')" -ForegroundColor Cyan
            $nomeAreasSlug = ($SomenteAreas | ForEach-Object { $_ -replace '\s+','-' -replace '[^a-zA-Z0-9\-]','' }) -join '-'
            $cacheNovasAreas = Join-Path $cacheDir "sai-psai-novas-areas.json"
            $cacheOriginal = Join-Path $cacheDir "sai-psai-original.json"

            try {
                # 1. Backup do cache existente
                if (Test-Path $destinoJson) {
                    Write-Host "  Backup do cache existente -> sai-psai-original.json" -ForegroundColor DarkCyan
                    Copy-Item $destinoJson $cacheOriginal -Force
                }

                # 2. Extrair apenas as novas areas (resultado salvo em sai-psai-escrita.json temporariamente)
                Write-Host "  Extraindo somente: $($SomenteAreas -join ', ')..." -ForegroundColor DarkCyan
                if ($Completo) {
                    & $extrairScript -SemLock -Completo -AreasOverride $SomenteAreas
                } else {
                    & $extrairScript -SemLock -AreasOverride $SomenteAreas
                }
                if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
                    throw "extrair-sais.ps1 retornou exit code $LASTEXITCODE"
                }

                # 3. Renomear resultado da extracao para arquivo de novas areas
                if (Test-Path $destinoJson) {
                    Move-Item $destinoJson $cacheNovasAreas -Force
                    Write-Host "  Extracao das novas areas: OK" -ForegroundColor DarkCyan
                } else {
                    throw "Extracao nao gerou sai-psai-escrita.json"
                }

                # 4. Mesclar: sai-psai-original.json + sai-psai-novas-areas.json -> sai-psai-escrita.json
                if (Test-Path $cacheOriginal) {
                    Write-Host "  Mesclando original + novas areas..." -ForegroundColor DarkCyan
                    $merged = Merge-BuscaSaiJsons -dirCache $cacheDir
                    if ($merged) {
                        $jsonOut = $merged.wrapper | ConvertTo-Json -Depth 5 -Compress
                        Set-Content -Path $destinoJson -Value $jsonOut -Encoding UTF8
                        $tamanho = [math]::Round((Get-Item $destinoJson).Length / 1MB, 1)
                        Write-Host "  Merged: $($merged.wrapper.totalRegistros) registros | $tamanho MB" -ForegroundColor Green
                    } else {
                        Write-Host "  AVISO: Merge falhou. Usando apenas novas areas." -ForegroundColor Yellow
                        Move-Item $cacheNovasAreas $destinoJson -Force
                    }
                } else {
                    # Nao havia cache original — apenas renomear
                    Move-Item $cacheNovasAreas $destinoJson -Force
                    Write-Host "  Sem cache anterior. Usando apenas novas areas." -ForegroundColor Yellow
                }

                # 6. Limpar temporarios
                Remove-Item $cacheOriginal -ErrorAction SilentlyContinue
                Remove-Item $cacheNovasAreas -ErrorAction SilentlyContinue

                $usouOdbc = $true
            } catch {
                Write-Host "[ODBC] Falha na extracao das areas extras: $($_.Exception.Message)" -ForegroundColor Red
                # Restaurar backup se disponivel
                if ((Test-Path $cacheOriginal) -and -not (Test-Path $destinoJson)) {
                    Copy-Item $cacheOriginal $destinoJson -Force
                    Write-Host "  Cache original restaurado." -ForegroundColor Yellow
                }
                Remove-Item $cacheOriginal -ErrorAction SilentlyContinue
                Remove-Item $cacheNovasAreas -ErrorAction SilentlyContinue
            }
        } else {
            # Modo normal: extrai todas as areas do config
            try {
                if ($Completo) {
                    & $extrairScript -SemLock -Completo
                } else {
                    & $extrairScript -SemLock
                }
                if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
                    throw "extrair-sais.ps1 retornou exit code $LASTEXITCODE"
                }
                $cacheCheck = Join-Path $cacheDir "sai-psai-escrita.json"
                if (-not (Test-Path $cacheCheck)) {
                    Write-Host "[ODBC] AVISO: Cache nao gerado apos extracao" -ForegroundColor Yellow
                }
                $usouOdbc = $true
            } catch {
                Write-Host "[ODBC] Falha na extracao: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "[ODBC] Tentando fallback BuscaSAI..." -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "[ODBC] DSN '$dsnName' nao encontrado. Usando fallback BuscaSAI..." -ForegroundColor Yellow
    }
}

# ── Fallback: BuscaSAI (mescla sai-psai-*.json de data/cache) ─────────

if (-not $usouOdbc) {
    $possiveisCaminhos = @(
        $FonteBuscaSai,
        "C:\1 - A\B\Programas\BuscaSAI",
        (Join-Path $env:USERPROFILE "OneDrive - Thomson Reuters Incorporated\Aplicacoes Cursor\BuscaSAI"),
        "C:\Users\$($env:USERNAME)\OneDrive - Thomson Reuters Incorporated\Aplicacoes Cursor\BuscaSAI"
    )
    $buscaSaiDir = $null
    foreach ($caminho in $possiveisCaminhos) {
        if (-not $caminho) { continue }
        $dirCache = Join-Path $caminho "data\cache"
        if (-not (Test-Path $dirCache)) { continue }
        $tem = @(Get-ChildItem -Path $dirCache -Filter "sai-psai-*.json" -File -ErrorAction SilentlyContinue)
        if ($tem.Count -gt 0) { $buscaSaiDir = $caminho; break }
    }
    if (-not $buscaSaiDir) {
        Write-Host "ERRO: Nem ODBC nem BuscaSAI (nenhum data/cache/sai-psai-*.json)." -ForegroundColor Red
        Write-Host "Opcoes:" -ForegroundColor Yellow
        Write-Host "  1. Configure o ODBC DSN pbcvs9 (rode setup-odbc.ps1)" -ForegroundColor White
        Write-Host "  2. No clone BuscaSAI, rode: cd tools\extrair-escrita && npm install && node extrair.mjs --completa" -ForegroundColor White
        Write-Host "  3. Use: .\importar-sais.ps1 -FonteBuscaSai 'C:\caminho\BuscaSAI'" -ForegroundColor White
        Release-Lock $projetoDir
        exit 1
    }

    $dirCacheFonte = Join-Path $buscaSaiDir "data\cache"
    $destinoSituacoes = Join-Path $dadosBrutosDir "situacoes.json"

    Write-Host "[Fallback] Usando BuscaSAI: $buscaSaiDir" -ForegroundColor Yellow

    $merged = Merge-BuscaSaiJsons -dirCache $dirCacheFonte
    if (-not $merged) {
        Write-Host "ERRO: Nao foi possivel ler dados dos JSONs em $dirCacheFonte" -ForegroundColor Red
        Release-Lock $projetoDir
        exit 1
    }

    if ($Incremental -and (Test-Path $destinoJson)) {
        $maxFonte = ($merged.wrapper.fontesMescladas | ForEach-Object {
            $p = Join-Path $dirCacheFonte $_
            if (Test-Path $p) { (Get-Item $p).LastWriteTime } else { [datetime]::MinValue }
        } | Measure-Object -Maximum).Maximum
        $destinoData = (Get-Item $destinoJson).LastWriteTime
        if ($maxFonte -le $destinoData) {
            Write-Host "Cache ja esta atualizado (fontes <= destino $destinoData)"
            Write-Host "Nada a fazer."
            Release-Lock $projetoDir
            exit 0
        }
        Write-Host "Fonte mais recente. Atualizando..."
    }

    Write-Host "[1/2] Gravando cache mesclado de SAIs/PSAIs..." -ForegroundColor Yellow
    $jsonOut = $merged.wrapper | ConvertTo-Json -Depth 5 -Compress
    Set-Content -Path $destinoJson -Value $jsonOut -Encoding UTF8
    $tamanho = [math]::Round((Get-Item $destinoJson).Length / 1MB, 1)
    Write-Host "  Registros: $($merged.wrapper.totalRegistros) | Fontes: $($merged.wrapper.fontesMescladas -join ', ')"
    Write-Host "  Gravado: $tamanho MB -> $destinoJson"
    if (Test-Path $merged.situacoesPath) {
        Copy-Item -Path $merged.situacoesPath -Destination $destinoSituacoes -Force
    }

    # Fracionados obrigatorios para gerar-indices-sais.ps1 (ODBC ja gera no extrair-sais.ps1)
    Write-Host "[2/2] Gerando fracionados (psai/sai) a partir do monolitico..." -ForegroundColor Yellow
    & (Join-Path $scriptDir "restaurar-fracionados.ps1") -UsarMonolitico $destinoJson -PularIndices
}

# ── Metadados ─────────────────────────────────────────────────────────

Write-Host "[Meta] Salvando metadados..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path (Split-Path $metaFile) -Force | Out-Null
$tamanhoAtual = if (Test-Path $destinoJson) { [math]::Round((Get-Item $destinoJson).Length / 1MB, 1) } else { 0 }
$psaiCount = if (Test-Path (Join-Path $dadosBrutosDir "psai")) { (Get-ChildItem (Join-Path $dadosBrutosDir "psai") -Filter "*.json" | Measure-Object).Count } else { 0 }
$meta = @{
    importadoEm = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    importadoPor = $env:USERNAME
    fonte = if ($usouOdbc) { "ODBC multi-area" } else { "BuscaSAI (sai-psai mesclado)" }
    cacheMB = $tamanhoAtual
    cacheLocal = $destinoJson
    fracionados = $psaiCount
    modo = if ($Completo) { "completa" } else { "incremental" }
} | ConvertTo-Json -Depth 2
Set-Content -Path $metaFile -Value $meta -Encoding UTF8

# ── Gerar indices ─────────────────────────────────────────────────────

Write-Host "[Indices] Gerando indices Markdown..." -ForegroundColor Yellow
& (Join-Path $scriptDir "gerar-indices-sais.ps1")

Release-Lock $projetoDir

Write-Host ""
Write-Host "=== Importacao concluida! ===" -ForegroundColor Green
Write-Host "  Cache local: $destinoJson ($tamanhoAtual MB)"
Write-Host "  Fracionados: $psaiCount arquivos PSAI + SAI no OneDrive"
Write-Host "  Fonte: $(if ($usouOdbc) { 'ODBC multi-area' } else { 'BuscaSAI (JSONs mesclados)' })"
Write-Host "  Indices: $indicesDir"
Write-Host ""
Write-Host "Fracionados e indices no OneDrive - sincroniza automaticamente."
Write-Host "Monolitico em cache local (nao sincroniza)."
