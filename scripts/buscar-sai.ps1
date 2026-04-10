# buscar-sai.ps1
# Busca SAIs/PSAIs nos JSONs fracionados (arquivos leves por tipo+status).
# Se especificar -Tipo e/ou -Pendentes, carrega apenas o arquivo relevante.
#
# COMPORTAMENTO PADRAO: Busca nos PSAIs (campos completos com BLOBs), mas
# agrupa por SAI e mostra apenas a PSAI mais recente de cada SAI. Isso evita
# duplicidade quando uma PSAI ja tem SAI gerada. Use -VerPSAIs para ver todas.
#
# IMPORTANTE: Rodar em terminal SEPARADO (fora do Cursor)
#
# Exemplos:
#   .\buscar-sai.ps1 -Termo "INSS"
#   .\buscar-sai.ps1 -Termo "ferias" -Tipo NE -Pendentes
#   .\buscar-sai.ps1 -SAI 12345
#   .\buscar-sai.ps1 -Termo "rescisao" -VerPSAIs
#   .\buscar-sai.ps1 -Termo "sped" -Modulo "Escrita"
#   .\buscar-sai.ps1 -Rubrica 8214
#   .\buscar-sai.ps1 -Termo "FGTS" -Resumido -Max 50

param(
    [string]$Termo = "",
    [int]$SAI = 0,
    [int]$PSAI = 0,
    [string]$Tipo = "",
    [string]$Modulo = "",
    [int]$Rubrica = 0,
    [switch]$Pendentes,
    [switch]$VerPSAIs,
    [switch]$VisualizarSai,
    [switch]$Resumido,
    [int]$Max = 30
)

function SafeStr($v) { if ($null -eq $v) { return "" }; return [string]$v }

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir
if ($env:BUSCAR_SAI_DADOS_DIR -and (Test-Path $env:BUSCAR_SAI_DADOS_DIR)) {
    $dadosBrutosDir = $env:BUSCAR_SAI_DADOS_DIR
} else {
    $dadosBrutosDir = Join-Path $projetoDir "banco-dados\dados-brutos"
}
$psaiDir = Join-Path $dadosBrutosDir "psai"
$saiDir = Join-Path $dadosBrutosDir "sai"
$cacheCompleto = Join-Path $dadosBrutosDir "sai-psai-escrita.json"

if (-not $Termo -and $SAI -eq 0 -and $PSAI -eq 0 -and -not $Modulo -and $Rubrica -eq 0) {
    Write-Host "=== Busca de SAIs/PSAIs ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Uso:" -ForegroundColor White
    Write-Host "  .\buscar-sai.ps1 -Termo 'palavra'                Busca em todos os campos (14 campos + BLOBs)"
    Write-Host "  .\buscar-sai.ps1 -Termo 'INSS' -Tipo NE          Filtra por tipo"
    Write-Host "  .\buscar-sai.ps1 -Termo 'ferias' -Pendentes       So pendentes"
    Write-Host "  .\buscar-sai.ps1 -Termo 'rescisao' -VerPSAIs      Mostra todas as PSAIs (sem agrupar)"
    Write-Host "  .\buscar-sai.ps1 -SAI 12345                       Busca por numero de SAI"
    Write-Host "  .\buscar-sai.ps1 -PSAI 67890                      Busca por numero de PSAI"
    Write-Host "  .\buscar-sai.ps1 -Modulo 'Escrita'                Filtra nomeArea/descricao (ex.: Escrita, Importacao)"
    Write-Host "  .\buscar-sai.ps1 -Rubrica 8214                    Busca por rubrica na descricao"
    Write-Host "  .\buscar-sai.ps1 -Termo 'FGTS' -Resumido          Saida compacta"
    Write-Host ""
    Write-Host "Parametros:" -ForegroundColor White
    Write-Host "  -Tipo NE|SAM|SAL|SAIL   Filtrar por tipo"
    Write-Host "  -Modulo 'nome'          Filtrar por nomeArea/descricao (parcial; ex: 'Escrita', 'Onvio')"
    Write-Host "  -Rubrica 8214           Buscar por numero de rubrica na descricao"
    Write-Host "  -Pendentes              Somente pendentes"
    Write-Host "  -VerPSAIs               Mostrar todas as PSAIs individuais (padrao: agrupa por SAI)"
    Write-Host "  -VisualizarSai          Usar arquivos SAI resumidos (sem BLOBs)"
    Write-Host "  -Resumido               Saida compacta (1 linha por resultado)"
    Write-Host "  -Max 30                 Limite de resultados (padrao: 30)"
    Write-Host ""
    Write-Host "Comportamento padrao:" -ForegroundColor Yellow
    Write-Host "  Busca nos PSAIs (todos os campos). Agrupa por SAI e mostra"
    Write-Host "  apenas a PSAI mais recente de cada SAI. Se a SAI ja existe,"
    Write-Host "  mostra a SAI. Use -VerPSAIs para ver todas as PSAIs."
    exit 0
}

$baseDir = if ($VisualizarSai) { $saiDir } else { $psaiDir }
$usarFracionado = (Test-Path $baseDir) -and (Get-ChildItem $baseDir -Filter "*.json" -ErrorAction SilentlyContinue)

if ($usarFracionado) {
    $arquivos = @()
    $tiposCarregar = if ($Tipo) { @($Tipo.ToLower()) } else { @("ne","sam","sal","sail") }
    $statusCarregar = if ($Pendentes) { @("pendentes") } else { @("pendentes","liberadas","descartadas") }

    foreach ($t in $tiposCarregar) {
        foreach ($st in $statusCarregar) {
            $arq = Join-Path $baseDir "$t-$st.json"
            if (Test-Path $arq) { $arquivos += $arq }
        }
    }

    Write-Host "Buscando em $($arquivos.Count) arquivo(s) fracionado(s)..." -ForegroundColor Yellow
    $todosRegistros = @()
    foreach ($arq in $arquivos) {
        $sizeMB = [math]::Round((Get-Item $arq).Length / 1MB, 1)
        $nomeArq = Split-Path -Leaf $arq
        Write-Host "  $nomeArq ($($sizeMB)MB)" -ForegroundColor Gray
        $conteudo = Get-Content $arq -Raw -Encoding UTF8 | ConvertFrom-Json
        $todosRegistros += $conteudo.dados
    }
    Write-Host "  $($todosRegistros.Count) registros carregados" -ForegroundColor Green
} else {
    if (-not (Test-Path $cacheCompleto)) {
        Write-Host "ERRO: Nenhum dado encontrado." -ForegroundColor Red
        Write-Host "Rode 'scripts\atualizar-tudo.bat' primeiro."
        exit 1
    }
    Write-Host "JSONs fracionados nao encontrados. Usando cache completo..." -ForegroundColor Yellow
    Write-Host "Carregando (pode demorar ~30s)..."
    $conteudo = Get-Content $cacheCompleto -Raw -Encoding UTF8 | ConvertFrom-Json
    $todosRegistros = $conteudo.dados
    Write-Host "  $($conteudo.totalRegistros) registros carregados" -ForegroundColor Green
}

$resultado = $todosRegistros

# Filtro por numero exato
if ($SAI -ne 0) {
    $resultado = @($resultado | Where-Object { $_.i_sai -eq $SAI })
} elseif ($PSAI -ne 0) {
    $campo = if ($VisualizarSai) { "ultimaPsai" } else { "i_psai" }
    $resultado = @($resultado | Where-Object { $_.$campo -eq $PSAI })
} else {
    # Filtro por termo (busca em 14 campos: texto + BLOBs + metadados)
    if ($Termo) {
        $termoLower = $Termo.ToLower()
        $resultado = @($resultado | Where-Object {
            (SafeStr $_.sai_descricao).ToLower().Contains($termoLower) -or
            (SafeStr $_.comportamento).ToLower().Contains($termoLower) -or
            (SafeStr $_.definicao).ToLower().Contains($termoLower) -or
            (SafeStr $_.psai_descricao).ToLower().Contains($termoLower) -or
            (SafeStr $_.sai_destaque).ToLower().Contains($termoLower) -or
            (SafeStr $_.psai_destaque).ToLower().Contains($termoLower) -or
            (SafeStr $_.textoCompleto).ToLower().Contains($termoLower) -or
            (SafeStr $_.nomeArea).ToLower().Contains($termoLower) -or
            (SafeStr $_.nomeVersao).ToLower().Contains($termoLower) -or
            (SafeStr $_.tipoSAI).ToLower().Contains($termoLower) -or
            (SafeStr $_.gravidade_ne).ToLower().Contains($termoLower) -or
            (SafeStr $_.situacaoSai).ToLower().Contains($termoLower) -or
            (SafeStr $_.situacaoPsai).ToLower().Contains($termoLower) -or
            (SafeStr $_.nivel_alteracao).ToLower().Contains($termoLower)
        })
    }

    # Filtro por modulo (busca em nomeArea e sai_descricao)
    if ($Modulo) {
        $moduloLower = $Modulo.ToLower()
        $resultado = @($resultado | Where-Object {
            (SafeStr $_.nomeArea).ToLower().Contains($moduloLower) -or
            (SafeStr $_.sai_descricao).ToLower().Contains($moduloLower)
        })
    }

    # Filtro por rubrica (busca o numero na descricao e no textoCompleto)
    if ($Rubrica -ne 0) {
        $rubricaStr = $Rubrica.ToString()
        $resultado = @($resultado | Where-Object {
            ((SafeStr $_.sai_descricao) -match "\b$rubricaStr\b") -or
            ((SafeStr $_.textoCompleto) -match "\b$rubricaStr\b")
        })
    }
}

# --- DEDUPLICACAO POR SAI (padrao: mostra 1 resultado por SAI) ---
if (-not $VerPSAIs -and -not $VisualizarSai -and $SAI -eq 0 -and $PSAI -eq 0) {
    $porSai = @{}
    foreach ($r in $resultado) {
        $chave = [string]$r.i_sai
        if (-not $porSai.ContainsKey($chave)) {
            $porSai[$chave] = $r
        } else {
            $existente = $porSai[$chave]
            $psaiAtual = if ($r.i_psai) { [int]$r.i_psai } else { 0 }
            $psaiExist = if ($existente.i_psai) { [int]$existente.i_psai } else { 0 }
            if ($r.Liberacao -and -not $existente.Liberacao) {
                $porSai[$chave] = $r
            } elseif ($psaiAtual -gt $psaiExist) {
                $porSai[$chave] = $r
            }
        }
    }
    $totalAntes = $resultado.Count
    $resultado = @($porSai.Values)
    $dedup = $totalAntes - $resultado.Count
    if ($dedup -gt 0) {
        Write-Host "(Agrupado por SAI: $($resultado.Count) SAIs unicas de $totalAntes PSAIs. Use -VerPSAIs para ver todas)" -ForegroundColor DarkYellow
    }
}

$totalResultados = $resultado.Count
Write-Host ""
Write-Host "=== $totalResultados resultado(s) ===" -ForegroundColor Cyan
if ($totalResultados -eq 0) { exit 0 }

$resultado | Select-Object -First $Max | ForEach-Object {
    if ($Resumido) {
        # Saida compacta: 1 linha por resultado
        $saiNum = if ($VisualizarSai) { $_.i_sai } else { "$($_.i_sai)/$($_.i_psai)" }
        $status = if ($VisualizarSai) { $_.situacaoSai } else {
            if ($_.Liberacao) { "Lib" } elseif ($_.Descarte) { "Desc" } else { "Pend" }
        }
        $grav = if ($_.gravidade_ne) { $g = SafeStr $_.gravidade_ne; $g.Substring(0, [Math]::Min(4, $g.Length)) } else { "-" }
        $desc = if ($_.sai_descricao) {
            $d = SafeStr $_.sai_descricao; $d.Substring(0, [Math]::Min(80, $d.Length)) -replace "`r|`n", " "
        } else { "-" }
        Write-Host "  $saiNum | $($_.tipoSAI) | $status | $grav | $desc" -ForegroundColor Gray
    } elseif ($VisualizarSai) {
        $dt = if ($_.ultimoCadastro) { try { ([datetime]$_.ultimoCadastro).ToString("dd/MM/yyyy") } catch { "-" } } else { "-" }
        $desc = if ($_.sai_descricao) {
            $d = SafeStr $_.sai_descricao; $d.Substring(0, [Math]::Min(120, $d.Length)) -replace "`r|`n", " "
        } else { "-" }
        Write-Host ""
        Write-Host "--- SAI $($_.i_sai) ($($_.totalPsais) PSAIs) ---" -ForegroundColor White
        Write-Host "  Tipo: $($_.tipoSAI) | Versao: $($_.nomeVersao) | Status: $($_.situacaoSai)" -ForegroundColor Gray
        Write-Host "  Ultima PSAI: $($_.ultimaPsai) | Cadastro: $dt | Gravidade: $($_.gravidade_ne)" -ForegroundColor Gray
        Write-Host "  $desc"
    } else {
        $status = if ($_.Liberacao) { "Liberada" } elseif ($_.Descarte) { "Descartada" } else { "Pendente" }
        $dt = if ($_.CadastroPSAI) { try { ([datetime]$_.CadastroPSAI).ToString("dd/MM/yyyy") } catch { "-" } } else { "-" }
        $desc = if ($_.sai_descricao) {
            $d = SafeStr $_.sai_descricao; $d.Substring(0, [Math]::Min(120, $d.Length)) -replace "`r|`n", " "
        } else { "-" }
        $rotulo = if ($_.Liberacao) { "SAI $($_.i_sai) (PSAI $($_.i_psai) - Liberada)" }
                  elseif ([int]$_.i_psai -eq 0) { "SAI $($_.i_sai) (sem PSAI)" }
                  else { "SAI $($_.i_sai) / PSAI $($_.i_psai)" }
        $area = if ($_.nomeArea) { " | Area: $($_.nomeArea)" } else { "" }
        Write-Host ""
        Write-Host "--- $rotulo ---" -ForegroundColor White
        Write-Host "  Tipo: $($_.tipoSAI) | Versao: $($_.nomeVersao) | Status: ${status}${area}" -ForegroundColor Gray
        Write-Host "  Cadastro: $dt | Gravidade: $($_.gravidade_ne)" -ForegroundColor Gray
        Write-Host "  $desc"

        if ($Termo) {
            $tl = $Termo.ToLower()
            $camposBLOB = @(
                @{ nome = "comportamento";  valor = $_.comportamento },
                @{ nome = "definicao";      valor = $_.definicao },
                @{ nome = "psai_descricao"; valor = $_.psai_descricao },
                @{ nome = "sai_destaque";   valor = $_.sai_destaque },
                @{ nome = "psai_destaque";  valor = $_.psai_destaque },
                @{ nome = "textoCompleto";  valor = $_.textoCompleto },
                @{ nome = "nomeArea";       valor = $_.nomeArea }
            )
            foreach ($cb in $camposBLOB) {
                $sv = SafeStr $cb.valor
                if ($sv -and $sv.ToLower().Contains($tl)) {
                    $idx = $sv.ToLower().IndexOf($tl)
                    $ini = [Math]::Max(0, $idx - 50)
                    $fim = [Math]::Min($sv.Length, $idx + $Termo.Length + 50)
                    $trecho = $sv.Substring($ini, $fim - $ini) -replace "`r|`n", " "
                    if ($ini -gt 0) { $trecho = "...$trecho" }
                    if ($fim -lt $sv.Length) { $trecho = "${trecho}..." }
                    Write-Host "  >> $($cb.nome): $trecho" -ForegroundColor DarkCyan
                }
            }
        }
    }
}

if ($totalResultados -gt $Max) {
    Write-Host ""
    Write-Host "(Mostrando $Max de $totalResultados. Use -Max $totalResultados para ver todos)" -ForegroundColor DarkYellow
}
