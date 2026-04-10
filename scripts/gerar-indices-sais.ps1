# gerar-indices-sais.ps1
# Gera indices Markdown a partir de JSONs fracionados (psai/)
# Fracionamento agora feito por extrair-sais.ps1 (v1.1.0)
#
# IMPORTANTE: Rodar em terminal SEPARADO (fora do Cursor)
# Pico de RAM: ~550 MB (carrega fracionados sequencialmente)

param(
    [int]$MaxPorArquivo = 99999
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir
$dadosBrutosDir = Join-Path $projetoDir "banco-dados\dados-brutos"
$indicesDir = Join-Path $projetoDir "banco-dados\sais\indices"
$psaiOutDir = Join-Path $dadosBrutosDir "psai"
$saiOutDir = Join-Path $dadosBrutosDir "sai"

# --- Smart-Write: so reescreve se conteudo mudou ---
$script:smartEscritos = 0
$script:smartPulados = 0
function Smart-Write($path, $content) {
    if (Test-Path $path) {
        $existing = (Get-Content $path -Raw -Encoding UTF8).TrimEnd()
        $novo = $content.TrimEnd()
        if ($existing -eq $novo) {
            $script:smartPulados++
            return $false
        }
    }
    Set-Content -Path $path -Value $content -Encoding UTF8
    $script:smartEscritos++
    return $true
}

if (-not (Test-Path $psaiOutDir)) {
    Write-Host "ERRO: Fracionados PSAI nao encontrados em: $psaiOutDir" -ForegroundColor Red
    Write-Host "Rode importar-sais.ps1 primeiro."
    exit 1
}

Write-Host "=== Gerador de Indices Markdown ===" -ForegroundColor Cyan
Write-Host "Fracionados: $psaiOutDir"
Write-Host "Indices MD: $indicesDir"
New-Item -ItemType Directory -Path $indicesDir -Force | Out-Null

# --- Carregar fracionados sequencialmente (economia de RAM) ---
Write-Host "Carregando fracionados (lightweight)..." -ForegroundColor Yellow
$dados = [System.Collections.ArrayList]::new()
$total = 0
$tiposTodos = @("NE","SAM","SAL","SAIL")

foreach ($tp in $tiposTodos) {
    foreach ($status in @("pendentes","liberadas","descartadas")) {
        $arquivo = Join-Path $psaiOutDir "$($tp.ToLower())-$status.json"
        if (-not (Test-Path $arquivo)) {
            Write-Host "  AVISO: $arquivo nao encontrado" -ForegroundColor Yellow
            continue
        }
        $fileJson = Get-Content $arquivo -Raw -Encoding UTF8 | ConvertFrom-Json
        $fileDados = $fileJson.dados
        foreach ($item in $fileDados) {
            [void]$dados.Add([PSCustomObject]@{
                i_sai = $item.i_sai
                i_psai = $item.i_psai
                tipoSAI = $item.tipoSAI
                sai_descricao = $item.sai_descricao
                nomeVersao = $item.nomeVersao
                gravidade_ne = $item.gravidade_ne
                CadastroPSAI = $item.CadastroPSAI
                Liberacao = $item.Liberacao
                Descarte = $item.Descarte
                situacaoSai = $item.situacaoSai
            })
        }
        $total += $fileDados.Count
        $fileDados = $null; $fileJson = $null
    }
}
[GC]::Collect()

$psaiMaisRecente = 0
$dataMaisRecente = $null
foreach ($d in $dados) {
    $id = [int]$d.i_psai
    if ($id -gt $psaiMaisRecente) { $psaiMaisRecente = $id }
    if ($d.CadastroPSAI) {
        try {
            $dt = [datetime]$d.CadastroPSAI
            if (-not $dataMaisRecente -or $dt -gt $dataMaisRecente) { $dataMaisRecente = $dt }
        } catch {}
    }
}
$defasagemHoras = if ($dataMaisRecente) { [math]::Round(((Get-Date) - $dataMaisRecente).TotalHours, 1) } else { -1 }

Write-Host "  $total registros carregados (lightweight)"
Write-Host "  PSAI mais recente: $psaiMaisRecente | Data: $dataMaisRecente | Defasagem: ${defasagemHoras}h"

$dataAtualizacao = (Get-ChildItem $psaiOutDir -Filter "*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime.ToString("dd/MM/yyyy HH:mm")
Write-Host "  Data fonte: $dataAtualizacao"

# --- FASE B: Gerar indices Markdown ---
Write-Host ""
Write-Host "[B] Gerando indices Markdown..." -ForegroundColor Cyan

# --- Funcoes auxiliares ---
function Format-NERow($item) {
    $desc = if ($item.sai_descricao) { $item.sai_descricao.Substring(0, [Math]::Min(80, $item.sai_descricao.Length)).Replace("|","").Replace("`n"," ").Replace("`r"," ") } else { "-" }
    $dt = if ($item.CadastroPSAI) { ([datetime]$item.CadastroPSAI).ToString("dd/MM/yyyy") } else { "-" }
    return "| $($item.i_sai) | $($item.i_psai) | $($item.nomeVersao) | $($item.gravidade_ne) | $dt | $($item.situacaoSai) | $desc |"
}

function Format-SARow($item) {
    $desc = if ($item.sai_descricao) { $item.sai_descricao.Substring(0, [Math]::Min(80, $item.sai_descricao.Length)).Replace("|","").Replace("`n"," ").Replace("`r"," ") } else { "-" }
    $dt = if ($item.CadastroPSAI) { ([datetime]$item.CadastroPSAI).ToString("dd/MM/yyyy") } else { "-" }
    return "| $($item.i_sai) | $($item.i_psai) | $($item.nomeVersao) | $dt | $($item.situacaoSai) | $desc |"
}

$headerNE = "| SAI | PSAI | Versao | Gravidade | Cadastro | Situacao | Descricao (resumo) |`n|-----|------|--------|-----------|----------|----------|-------------------|"
$headerSA = "| SAI | PSAI | Versao | Cadastro | Situacao | Descricao (resumo) |`n|-----|------|--------|----------|----------|-------------------|"

# --- NEs pendentes (dividido por periodo) ---
Write-Host "[B1a] Gerando indices de NEs pendentes..." -ForegroundColor Yellow
$pendentesNE = $dados | Where-Object { $_.tipoSAI -eq "NE" -and -not $_.Liberacao -and -not $_.Descarte } | Sort-Object { [datetime]$_.CadastroPSAI }
$neRecentes = $pendentesNE | Where-Object { $_.CadastroPSAI -and ([datetime]$_.CadastroPSAI).Year -ge 2025 }
$neAntigas = $pendentesNE | Where-Object { -not $_.CadastroPSAI -or ([datetime]$_.CadastroPSAI).Year -lt 2025 }

$mdRecentes = "# NEs Pendentes - Recentes (2025+)`n`n> Atualizado em: $dataAtualizacao`n> Total: $($neRecentes.Count) NEs`n`n$headerNE`n"
$neRecentes | Select-Object -First $MaxPorArquivo | ForEach-Object { $mdRecentes += (Format-NERow $_) + "`n" }
$null = Smart-Write (Join-Path $indicesDir "pendentes-ne-recentes.md") $mdRecentes

$mdAntigas = "# NEs Pendentes - Anteriores a 2025`n`n> Atualizado em: $dataAtualizacao`n> Total: $($neAntigas.Count) NEs`n`n$headerNE`n"
$neAntigas | Select-Object -First $MaxPorArquivo | ForEach-Object { $mdAntigas += (Format-NERow $_) + "`n" }
$null = Smart-Write (Join-Path $indicesDir "pendentes-ne-antigas.md") $mdAntigas
Write-Host "  $($pendentesNE.Count) NEs pendentes (dividido em 2 arquivos)"

# --- NEs liberadas (dividido por periodo, nivel SAI) ---
Write-Host "[B1b] Gerando indices de NEs liberadas..." -ForegroundColor Yellow
$liberadasNE = @($dados | Where-Object { $_.tipoSAI -eq "NE" -and $_.Liberacao })
$gruposLibNE = $liberadasNE | Group-Object -Property i_sai
$saiLibNE = @($gruposLibNE | ForEach-Object {
    $_.Group | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | Select-Object -First 1
})
$neLibRecentes = @($saiLibNE | Where-Object { $_.CadastroPSAI -and ([datetime]$_.CadastroPSAI).Year -ge 2022 })
$neLibAntigas = @($saiLibNE | Where-Object { -not $_.CadastroPSAI -or ([datetime]$_.CadastroPSAI).Year -lt 2022 })

$mdLibRecentes = "# NEs Liberadas - Recentes (2022+)`n`n> Atualizado em: $dataAtualizacao`n> Total SAIs unicas: $($neLibRecentes.Count)`n`n| SAI | PSAI | Versao | Gravidade | Cadastro | Situacao | Descricao (resumo) |`n|-----|------|--------|-----------|----------|----------|-------------------|`n"
$neLibRecentes | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | ForEach-Object { $mdLibRecentes += (Format-NERow $_) + "`n" }
$null = Smart-Write (Join-Path $indicesDir "liberadas-ne-recentes.md") $mdLibRecentes

$mdLibAntigas = "# NEs Liberadas - Anteriores a 2022`n`n> Atualizado em: $dataAtualizacao`n> Total SAIs unicas: $($neLibAntigas.Count)`n`n| SAI | PSAI | Versao | Gravidade | Cadastro | Situacao | Descricao (resumo) |`n|-----|------|--------|-----------|----------|----------|-------------------|`n"
$neLibAntigas | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | ForEach-Object { $mdLibAntigas += (Format-NERow $_) + "`n" }
$null = Smart-Write (Join-Path $indicesDir "liberadas-ne-antigas.md") $mdLibAntigas
Write-Host "  $($saiLibNE.Count) SAIs NE liberadas ($($neLibRecentes.Count) recentes + $($neLibAntigas.Count) antigas)"

# --- NEs descartadas (nivel SAI) ---
Write-Host "[B1c] Gerando indice de NEs descartadas..." -ForegroundColor Yellow
$descartadasNE = @($dados | Where-Object { $_.tipoSAI -eq "NE" -and $_.Descarte })
$gruposDescNE = $descartadasNE | Group-Object -Property i_sai
$saiDescNE = @($gruposDescNE | ForEach-Object {
    $_.Group | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | Select-Object -First 1
})
$mdDescNE = "# NEs Descartadas`n`n> Atualizado em: $dataAtualizacao`n> Total SAIs unicas: $($saiDescNE.Count)`n`n| SAI | PSAI | Versao | Gravidade | Cadastro | Situacao | Descricao (resumo) |`n|-----|------|--------|-----------|----------|----------|-------------------|`n"
$saiDescNE | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | ForEach-Object { $mdDescNE += (Format-NERow $_) + "`n" }
$null = Smart-Write (Join-Path $indicesDir "descartadas-ne.md") $mdDescNE
Write-Host "  $($saiDescNE.Count) SAIs NE descartadas"

# --- SAs pendentes (dividido por tipo) ---
Write-Host "[B2a] Gerando indices de SAs pendentes..." -ForegroundColor Yellow
$pendentesSA = $dados | Where-Object { $_.tipoSAI -ne "NE" -and -not $_.Liberacao -and -not $_.Descarte }
$tipos = @("SAM","SAL","SAIL")
foreach ($tipo in $tipos) {
    $itens = $pendentesSA | Where-Object { $_.tipoSAI -eq $tipo }
    $md = "# $tipo Pendentes - Escrita Fiscal`n`n> Atualizado em: $dataAtualizacao`n> Total pendentes: $($itens.Count)`n`n$headerSA`n"
    $itens | Sort-Object { [datetime]$_.CadastroPSAI } -Descending | Select-Object -First $MaxPorArquivo | ForEach-Object { $md += (Format-SARow $_) + "`n" }
    $null = Smart-Write (Join-Path $indicesDir "pendentes-$($tipo.ToLower()).md") $md
}
Write-Host "  $($pendentesSA.Count) SAs pendentes (3 arquivos por tipo)"

# --- SAs liberadas (por tipo, nivel SAI) ---
Write-Host "[B2b] Gerando indices de SAs liberadas..." -ForegroundColor Yellow
$liberadasSA = @($dados | Where-Object { $_.tipoSAI -ne "NE" -and $_.Liberacao })
foreach ($tipo in $tipos) {
    $itensTipo = @($liberadasSA | Where-Object { $_.tipoSAI -eq $tipo })
    $gruposTipo = $itensTipo | Group-Object -Property i_sai
    $saiTipo = @($gruposTipo | ForEach-Object {
        $_.Group | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | Select-Object -First 1
    })
    $md = "# $tipo Liberadas - Escrita Fiscal`n`n> Atualizado em: $dataAtualizacao`n> Total SAIs unicas: $($saiTipo.Count)`n`n$headerSA`n"
    $saiTipo | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | ForEach-Object { $md += (Format-SARow $_) + "`n" }
    $null = Smart-Write (Join-Path $indicesDir "liberadas-$($tipo.ToLower()).md") $md
}
Write-Host "  $($liberadasSA.Count) PSAIs de SAs liberadas (3 arquivos por tipo)"

# --- SAs descartadas (por tipo, nivel SAI) ---
Write-Host "[B2c] Gerando indices de SAs descartadas..." -ForegroundColor Yellow
$descartadasSA = @($dados | Where-Object { $_.tipoSAI -ne "NE" -and $_.Descarte })
foreach ($tipo in $tipos) {
    $itensTipo = @($descartadasSA | Where-Object { $_.tipoSAI -eq $tipo })
    $gruposTipo = $itensTipo | Group-Object -Property i_sai
    $saiTipo = @($gruposTipo | ForEach-Object {
        $_.Group | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | Select-Object -First 1
    })
    $md = "# $tipo Descartadas - Escrita Fiscal`n`n> Atualizado em: $dataAtualizacao`n> Total SAIs unicas: $($saiTipo.Count)`n`n$headerSA`n"
    $saiTipo | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | ForEach-Object { $md += (Format-SARow $_) + "`n" }
    $null = Smart-Write (Join-Path $indicesDir "descartadas-$($tipo.ToLower()).md") $md
}
Write-Host "  $($descartadasSA.Count) PSAIs de SAs descartadas (3 arquivos por tipo)"

# --- Por versao (ultimas 5) ---
Write-Host "[B3] Gerando indices por versao..." -ForegroundColor Yellow
$versaoDir = Join-Path $indicesDir "por-versao"
New-Item -ItemType Directory -Path $versaoDir -Force | Out-Null
$versoes = $dados | Group-Object -Property nomeVersao | Sort-Object { $_.Group[0].nomeVersao } -Descending | Select-Object -First 5
foreach ($v in $versoes) {
    $nome = $v.Name -replace '[^\w\-\.]', '_'
    $md = "# SAIs da Versao $($v.Name)`n`n> Total: $($v.Count) registros`n`n| SAI | PSAI | Tipo | Gravidade | Status | Cadastro | Descricao |`n|-----|------|------|-----------|--------|----------|-----------|`n"
    $v.Group | Select-Object -First $MaxPorArquivo | ForEach-Object {
        $status = if ($_.Liberacao) { "Liberada" } elseif ($_.Descarte) { "Descartada" } else { "Pendente" }
        $desc = if ($_.sai_descricao) { $_.sai_descricao.Substring(0, [Math]::Min(80, $_.sai_descricao.Length)).Replace("|","").Replace("`n"," ").Replace("`r"," ") } else { "-" }
        $dt = if ($_.CadastroPSAI) { ([datetime]$_.CadastroPSAI).ToString("dd/MM/yyyy") } else { "-" }
        $md += "| $($_.i_sai) | $($_.i_psai) | $($_.tipoSAI) | $($_.gravidade_ne) | $status | $dt | $desc |`n"
    }
    $null = Smart-Write (Join-Path $versaoDir "$nome.md") $md
}
Write-Host "  $($versoes.Count) versoes geradas"

# --- Estatisticas ---
Write-Host "[B4] Gerando resumo estatistico..." -ForegroundColor Yellow
$porAno = $dados | Group-Object -Property { if ($_.CadastroPSAI) { ([datetime]$_.CadastroPSAI).Year } else { "?" } } | Sort-Object Name -Descending | Select-Object -First 5
$mdStats = "# Estatisticas de SAIs - Escrita Fiscal`n`n> Atualizado em: $dataAtualizacao`n> Total geral: $total registros`n`n## Por ano (ultimos 5)`n`n| Ano | Total | NE | SAM | SAL | SAIL | Liberadas | Descartadas | Pendentes |`n|-----|-------|----|-----|-----|------|-----------|-------------|-----------|`n"
foreach ($a in $porAno) {
    $ne = ($a.Group | Where-Object { $_.tipoSAI -eq 'NE' } | Measure-Object).Count
    $sam = ($a.Group | Where-Object { $_.tipoSAI -eq 'SAM' } | Measure-Object).Count
    $sal = ($a.Group | Where-Object { $_.tipoSAI -eq 'SAL' } | Measure-Object).Count
    $sail = ($a.Group | Where-Object { $_.tipoSAI -eq 'SAIL' } | Measure-Object).Count
    $lib = ($a.Group | Where-Object { $_.Liberacao } | Measure-Object).Count
    $desc2 = ($a.Group | Where-Object { $_.Descarte } | Measure-Object).Count
    $pend = ($a.Group | Where-Object { -not $_.Liberacao -and -not $_.Descarte } | Measure-Object).Count
    $mdStats += "| $($a.Name) | $($a.Count) | $ne | $sam | $sal | $sail | $lib | $desc2 | $pend |`n"
}
$mdStats += "`n## Por gravidade (NEs)`n`n| Gravidade | Total | Pendentes | Liberadas |`n|-----------|-------|-----------|-----------|`n"
$neAll = $dados | Where-Object { $_.tipoSAI -eq 'NE' }
$neAll | Group-Object -Property gravidade_ne | Sort-Object Count -Descending | ForEach-Object {
    $pend = ($_.Group | Where-Object { -not $_.Liberacao -and -not $_.Descarte } | Measure-Object).Count
    $lib = ($_.Group | Where-Object { $_.Liberacao } | Measure-Object).Count
    $mdStats += "| $($_.Name) | $($_.Count) | $pend | $lib |`n"
}
$null = Smart-Write (Join-Path $indicesDir "estatisticas.md") $mdStats

# --- Carregar keywords de arquivo externo (AC4/D13) ---
Write-Host "[B5] Carregando classificacao por dominio (modulos-keywords.json)..." -ForegroundColor Yellow
$kwFile = Join-Path $projetoDir "banco-dados\config\modulos-keywords.json"
$moduloKeywords = @{}
$moduloNomes = @{}
if (Test-Path $kwFile) {
    $kwJson = Get-Content $kwFile -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($prop in $kwJson.modulos.PSObject.Properties) {
        $moduloKeywords[$prop.Name] = @($prop.Value.keywords)
        $moduloNomes[$prop.Name] = $prop.Value.nome_exibicao
    }
    Write-Host "  $($moduloKeywords.Count) dominios carregados de modulos-keywords.json"
} else {
    Write-Host "  AVISO: modulos-keywords.json nao encontrado, usando fallback Escrita" -ForegroundColor Red
    $moduloKeywords = @{
        "apuracao-impostos"             = @("inss","irrf","fgts","apuracao","icms","gps")
        "escrituracao-movimento-fiscal" = @("calculo","folha","ferias","escrituracao","cfop")
        "sped-documentos-eletronicos"   = @("esocial","sped","nfe","xml","layout")
        "integracoes-canais-digitais"   = @("integracao","webservice","api","portal federal")
        "obrigacoes-relatorios-estaduais" = @("sefaz","relatorio","rais","dirf","dctf")
        "parcelamento-planejamento"     = @("parcelamento","provisao","e-cac","planejamento")
        "onvio-importacao-dados"        = @("onvio","importacao","rpa")
        "utilitarios-rotinas"           = @("utilitario","certificado","rotina")
    }
    $moduloNomes = @{
        "apuracao-impostos" = "Apuracao de impostos"
        "escrituracao-movimento-fiscal" = "Escrituracao e movimento fiscal"
        "sped-documentos-eletronicos" = "SPED e documentos eletronicos"
        "integracoes-canais-digitais" = "Integracoes e canais digitais"
        "obrigacoes-relatorios-estaduais" = "Obrigacoes, relatorios e declaracoes"
        "parcelamento-planejamento" = "Parcelamento e planejamento tributario"
        "onvio-importacao-dados" = "Onvio, importacao e dados"
        "utilitarios-rotinas" = "Utilitarios e rotinas"
    }
}

# --- Classificacao multi-modulo (Nivel B / D9) ---
Write-Host "  Classificando SAIs (multi-dominio)..." -ForegroundColor Yellow
$saiModulos = @{}
foreach ($item in $dados) {
    $d = $item.sai_descricao
    if (-not $d) { continue }
    $dLower = $d.ToLower()
    foreach ($modSlug in $moduloKeywords.Keys) {
        foreach ($kw in $moduloKeywords[$modSlug]) {
            if ($dLower.Contains($kw.ToLower())) {
                if (-not $saiModulos.ContainsKey($item.i_psai)) {
                    $saiModulos[$item.i_psai] = @()
                }
                if ($saiModulos[$item.i_psai] -notcontains $modSlug) {
                    $saiModulos[$item.i_psai] += $modSlug
                }
                break
            }
        }
    }
}
$classificadosCount = ($saiModulos.Keys | Measure-Object).Count
$naoClassificadosList = @($dados | Where-Object { -not $saiModulos.ContainsKey($_.i_psai) })
Write-Host "  $classificadosCount PSAIs classificadas, $($naoClassificadosList.Count) nao classificadas"

# --- por-modulo.md (indice agregado por dominio) ---
Write-Host "  Gerando por-modulo.md..."
$mdModulo = "# SAIs por dominio - Escrita Fiscal`n`n> Atualizado em: $dataAtualizacao`n> Classificacao por palavras-chave (multi-dominio) | $($moduloKeywords.Count) dominios (`modulos-keywords.json`)`n"
foreach ($modSlug in ($moduloKeywords.Keys | Sort-Object)) {
    $nomeExib = if ($moduloNomes[$modSlug]) { $moduloNomes[$modSlug] } else { $modSlug }
    $itens = @($dados | Where-Object { $saiModulos.ContainsKey($_.i_psai) -and ($saiModulos[$_.i_psai] -contains $modSlug) })
    if ($itens.Count -eq 0) { continue }
    $pendentes = @($itens | Where-Object { -not $_.Liberacao -and -not $_.Descarte })
    $mdModulo += "`n## $nomeExib ($($itens.Count) total, $($pendentes.Count) pendentes)`n`n"
    $mdModulo += "| SAI | PSAI | Tipo | Status | Resumo |`n|-----|------|------|--------|--------|`n"
    $gruposMod = $itens | Group-Object -Property i_sai
    $saiMod = @($gruposMod | ForEach-Object {
        $_.Group | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | Select-Object -First 1
    })
    $saiMod | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | ForEach-Object {
        $status = if ($_.Liberacao) { "Lib" } elseif ($_.Descarte) { "Desc" } else { "Pend" }
        $desc = if ($_.sai_descricao) { $_.sai_descricao.Substring(0, [Math]::Min(70, $_.sai_descricao.Length)).Replace("|","").Replace("`n"," ").Replace("`r"," ") } else { "-" }
        $mdModulo += "| $($_.i_sai) | $($_.i_psai) | $($_.tipoSAI) | $status | $desc |`n"
    }
}
if ($naoClassificadosList.Count -gt 0) {
    $gruposNC = $naoClassificadosList | Group-Object -Property i_sai
    $saiNC = @($gruposNC | ForEach-Object {
        $_.Group | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | Select-Object -First 1
    })
    $pendNC = @($saiNC | Where-Object { -not $_.Liberacao -and -not $_.Descarte })
    $mdModulo += "`n## Nao Classificado ($($saiNC.Count) SAIs unicas, $($pendNC.Count) pendentes)`n`n"
    $mdModulo += "| SAI | PSAI | Tipo | Status | Resumo |`n|-----|------|------|--------|--------|`n"
    $saiNC | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | ForEach-Object {
        $status = if ($_.Liberacao) { "Lib" } elseif ($_.Descarte) { "Desc" } else { "Pend" }
        $desc = if ($_.sai_descricao) { $_.sai_descricao.Substring(0, [Math]::Min(70, $_.sai_descricao.Length)).Replace("|","").Replace("`n"," ").Replace("`r"," ") } else { "-" }
        $mdModulo += "| $($_.i_sai) | $($_.i_psai) | $($_.tipoSAI) | $status | $desc |`n"
    }
}
$null = Smart-Write (Join-Path $indicesDir "por-modulo.md") $mdModulo
Write-Host "  por-modulo.md gerado ($($naoClassificadosList.Count) nao classificados)"

# --- B5b: Um arquivo .md por dominio (indices/modulos/) ---
Write-Host "[B5b] Gerando indices/modulos por dominio..." -ForegroundColor Yellow
$modulosDir = Join-Path $indicesDir "modulos"
New-Item -ItemType Directory -Path $modulosDir -Force | Out-Null

function Get-SaiUnicas($registros) {
    if ($registros.Count -eq 0) { return @() }
    $grupos = $registros | Group-Object -Property i_sai
    @($grupos | ForEach-Object {
        $_.Group | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | Select-Object -First 1
    })
}

$allModSlugs = @($moduloKeywords.Keys | Sort-Object) + @("nao-classificado")
$moduloStats = @{}

foreach ($modSlug in $allModSlugs) {
    if ($modSlug -eq "nao-classificado") {
        $nomeExib = "Nao Classificado"
        $modItens = $naoClassificadosList
    } else {
        $nomeExib = if ($moduloNomes[$modSlug]) { $moduloNomes[$modSlug] } else { $modSlug }
        $modItens = @($dados | Where-Object { $saiModulos.ContainsKey($_.i_psai) -and ($saiModulos[$_.i_psai] -contains $modSlug) })
    }

    $saiUnicas = Get-SaiUnicas $modItens
    $modPend = @($saiUnicas | Where-Object { -not $_.Liberacao -and -not $_.Descarte })
    $modLib = @($saiUnicas | Where-Object { $_.Liberacao })
    $modDesc = @($saiUnicas | Where-Object { $_.Descarte })

    $moduloStats[$modSlug] = @{ nome=$nomeExib; pendentes=$modPend.Count; liberadas=$modLib.Count; descartadas=$modDesc.Count; total=$saiUnicas.Count }

    if ($saiUnicas.Count -eq 0) { continue }

    $md = "# $nomeExib`n`n"
    $md += "> Dominio Escrita Fiscal | slug ``$modSlug```n"
    $md += "> Atualizado em: $dataAtualizacao`n"
    $md += "> Pendentes: $($modPend.Count) | Liberadas: $($modLib.Count) | Descartadas: $($modDesc.Count) | Total SAIs: $($saiUnicas.Count)`n"

    $md += "`n## Pendentes ($($modPend.Count))`n`n"
    if ($modPend.Count -gt 0) {
        $md += "| SAI | PSAI | Tipo | Gravidade | Cadastro | Resumo |`n|-----|------|------|-----------|----------|--------|`n"
        $modPend | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | ForEach-Object {
            $desc = if ($_.sai_descricao) { $_.sai_descricao.Substring(0, [Math]::Min(80, $_.sai_descricao.Length)).Replace("|","").Replace("`n"," ").Replace("`r"," ") } else { "-" }
            $dt = if ($_.CadastroPSAI) { ([datetime]$_.CadastroPSAI).ToString("dd/MM/yyyy") } else { "-" }
            $grav = if ($_.gravidade_ne) { $_.gravidade_ne } else { "-" }
            $md += "| $($_.i_sai) | $($_.i_psai) | $($_.tipoSAI) | $grav | $dt | $desc |`n"
        }
    } else {
        $md += "Nenhuma SAI pendente neste dominio.`n"
    }

    $md += "`n## Liberadas Recentes (30 mais recentes)`n`n"
    if ($modLib.Count -gt 0) {
        $libTop = $modLib | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | Select-Object -First 30
        $md += "| SAI | PSAI | Tipo | Cadastro | Resumo |`n|-----|------|------|----------|--------|`n"
        $libTop | ForEach-Object {
            $desc = if ($_.sai_descricao) { $_.sai_descricao.Substring(0, [Math]::Min(80, $_.sai_descricao.Length)).Replace("|","").Replace("`n"," ").Replace("`r"," ") } else { "-" }
            $dt = if ($_.CadastroPSAI) { ([datetime]$_.CadastroPSAI).ToString("dd/MM/yyyy") } else { "-" }
            $md += "| $($_.i_sai) | $($_.i_psai) | $($_.tipoSAI) | $dt | $desc |`n"
        }
    } else {
        $md += "Nenhuma SAI liberada neste dominio.`n"
    }

    $md += "`n## Temas Frequentes`n`n"
    if ($modSlug -ne "nao-classificado" -and $modLib.Count -gt 0) {
        $temaCount = @{}
        foreach ($libItem in $modLib) {
            if ($libItem.sai_descricao) {
                $dLower = $libItem.sai_descricao.ToLower()
                foreach ($kw in $moduloKeywords[$modSlug]) {
                    if ($dLower.Contains($kw.ToLower())) {
                        if (-not $temaCount.ContainsKey($kw)) { $temaCount[$kw] = 0 }
                        $temaCount[$kw]++
                    }
                }
            }
        }
        $topTemas = $temaCount.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5
        if ($topTemas) {
            $md += "| Tema | Ocorrencias |`n|------|-------------|`n"
            $topTemas | ForEach-Object { $md += "| $($_.Key) | $($_.Value) |`n" }
        } else { $md += "Sem dados suficientes.`n" }
    } else {
        $md += "Sem dados suficientes para analise tematica.`n"
    }

    $md += "`n## Descartadas Recentes (10 mais recentes)`n`n"
    if ($modDesc.Count -gt 0) {
        $descTop = $modDesc | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | Select-Object -First 10
        $md += "| SAI | PSAI | Tipo | Cadastro | Resumo |`n|-----|------|------|----------|--------|`n"
        $descTop | ForEach-Object {
            $desc = if ($_.sai_descricao) { $_.sai_descricao.Substring(0, [Math]::Min(80, $_.sai_descricao.Length)).Replace("|","").Replace("`n"," ").Replace("`r"," ") } else { "-" }
            $dt = if ($_.CadastroPSAI) { ([datetime]$_.CadastroPSAI).ToString("dd/MM/yyyy") } else { "-" }
            $md += "| $($_.i_sai) | $($_.i_psai) | $($_.tipoSAI) | $dt | $desc |`n"
        }
    } else {
        $md += "Nenhuma SAI descartada neste dominio.`n"
    }

    $md += "`n## Busca Completa`n`nPara lista completa: ``powershell -File scripts\buscar-sai.ps1 -Termo `"$nomeExib`"```n"

    $null = Smart-Write (Join-Path $modulosDir "$modSlug.md") $md
}

# Arquivar MDs de slugs antigos (ex.: taxonomia Folha) para obsoleto/ **antes** de contar arquivos finais
$permitidosModMd = @($moduloKeywords.Keys) + @("nao-classificado")
$obModLegado = Join-Path $projetoDir "banco-dados\obsoleto\indices-sais-modulos-legado-$(Get-Date -Format 'yyyy-MM-dd')"
$staleMods = @(Get-ChildItem $modulosDir -Filter "*.md" -ErrorAction SilentlyContinue | Where-Object { $permitidosModMd -notcontains $_.BaseName })
if ($staleMods.Count -gt 0) {
    New-Item -ItemType Directory -Path $obModLegado -Force | Out-Null
    foreach ($f in $staleMods) {
        Move-Item -LiteralPath $f.FullName -Destination (Join-Path $obModLegado $f.Name) -Force
    }
    Write-Host "  Arquivados $($staleMods.Count) indices modulos legados -> $obModLegado" -ForegroundColor DarkYellow
}
$moduloFileCount = (Get-ChildItem $modulosDir -Filter "*.md" | Measure-Object).Count
Write-Host "  $moduloFileCount arquivos em indices/modulos/ ($($moduloKeywords.Count) dominios + nao-classificado)"

# --- B5c: Resumo de pendentes ---
Write-Host "[B5c] Gerando resumo de pendentes..." -ForegroundColor Yellow
$allPendentes = @($dados | Where-Object { -not $_.Liberacao -and -not $_.Descarte })
$saiPendUnicas = Get-SaiUnicas $allPendentes
$totalPend = $saiPendUnicas.Count

$mdResumo = "# Resumo de Pendentes - Escrita Fiscal`n`n"
$mdResumo += "> Atualizado em: $dataAtualizacao`n"
$mdResumo += "> Total pendentes (SAIs unicas): $totalPend`n`n"
$mdResumo += "## Totais por dominio`n`n"
$mdResumo += "| Dominio | Pendentes | % do Total |`n|---------|-----------|------------|`n"
$moduloStats.GetEnumerator() | Sort-Object { $_.Value.pendentes } -Descending | ForEach-Object {
    $pct = if ($totalPend -gt 0) { [math]::Round(($_.Value.pendentes / $totalPend) * 100, 1) } else { 0 }
    $mdResumo += "| $($_.Value.nome) | $($_.Value.pendentes) | $pct% |`n"
}

$mdResumo += "`n## Top 20 Novidades (pendentes mais recentes)`n`n"
$mdResumo += "| SAI | PSAI | Tipo | Dominio(s) | Cadastro | Resumo |`n|-----|------|------|------------|----------|--------|`n"
$top20 = $saiPendUnicas | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | Select-Object -First 20
$top20 | ForEach-Object {
    $desc = if ($_.sai_descricao) { $_.sai_descricao.Substring(0, [Math]::Min(80, $_.sai_descricao.Length)).Replace("|","").Replace("`n"," ").Replace("`r"," ") } else { "-" }
    $dt = if ($_.CadastroPSAI) { ([datetime]$_.CadastroPSAI).ToString("dd/MM/yyyy") } else { "-" }
    $modNome = if ($saiModulos.ContainsKey($_.i_psai)) { ($saiModulos[$_.i_psai] | ForEach-Object { if ($moduloNomes[$_]) { $moduloNomes[$_] } else { $_ } }) -join ", " } else { "N/C" }
    $mdResumo += "| $($_.i_sai) | $($_.i_psai) | $($_.tipoSAI) | $modNome | $dt | $desc |`n"
}
$null = Smart-Write (Join-Path $indicesDir "resumo-pendentes.md") $mdResumo
Write-Host "  resumo-pendentes.md gerado ($totalPend pendentes)"

# --- Por rubrica (detalhado) ---
Write-Host "[B6] Gerando indice por rubrica..." -ForegroundColor Yellow
$rubricaMap = @{}
$dados | ForEach-Object {
    if ($_.sai_descricao -match '\b(\d{4})\b') {
        $matches_found = [regex]::Matches($_.sai_descricao, '\b(\d{4})\b')
        foreach ($m in $matches_found) {
            $rub = $m.Value
            $numRub = [int]$rub
            if ($numRub -ge 1000 -and $numRub -le 9999) {
                if (-not $rubricaMap.ContainsKey($rub)) { $rubricaMap[$rub] = @() }
                $rubricaMap[$rub] += $_
            }
        }
    }
}
$mdRubrica = "# SAIs por Rubrica - Escrita Fiscal`n`n> Atualizado em: $dataAtualizacao`n> Rubricas identificadas: $($rubricaMap.Count)`n> Classificacao por numeros de 4 digitos (1000-9999) encontrados nas descricoes`n"
$rubricaMap.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | Select-Object -First 100 | ForEach-Object {
    $rub = $_.Key
    $itens = $_.Value
    $pendentes = @($itens | Where-Object { -not $_.Liberacao -and -not $_.Descarte })
    $mdRubrica += "`n## Rubrica $rub ($($itens.Count) SAIs, $($pendentes.Count) pendentes)`n`n"
    $mdRubrica += "| SAI | PSAI | Tipo | Status | Resumo |`n|-----|------|------|--------|--------|`n"
    $itens | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | Select-Object -First 30 | ForEach-Object {
        $status = if ($_.Liberacao) { "Lib" } elseif ($_.Descarte) { "Desc" } else { "Pend" }
        $desc = if ($_.sai_descricao) { $_.sai_descricao.Substring(0, [Math]::Min(70, $_.sai_descricao.Length)).Replace("|","").Replace("`n"," ").Replace("`r"," ") } else { "-" }
        $mdRubrica += "| $($_.i_sai) | $($_.i_psai) | $($_.tipoSAI) | $status | $desc |`n"
    }
}
$null = Smart-Write (Join-Path $indicesDir "por-rubrica-detalhado.md") $mdRubrica
Write-Host "  $($rubricaMap.Count) rubricas identificadas"

# --- B8a: indice-geral.md (orfao corrigido) ---
Write-Host "[B8a] Gerando indice-geral.md..." -ForegroundColor Yellow
$totalNE = @($dados | Where-Object { $_.tipoSAI -eq 'NE' }).Count
$totalSAM = @($dados | Where-Object { $_.tipoSAI -eq 'SAM' }).Count
$totalSAL = @($dados | Where-Object { $_.tipoSAI -eq 'SAL' }).Count
$totalSAIL = @($dados | Where-Object { $_.tipoSAI -eq 'SAIL' }).Count
$totalLib = @($dados | Where-Object { $_.Liberacao }).Count
$totalDescG = @($dados | Where-Object { $_.Descarte }).Count
$totalPendG = @($dados | Where-Object { -not $_.Liberacao -and -not $_.Descarte }).Count

$mdGeral = "# Indice de SAIs/PSAIs - Escrita Fiscal`n`n"
$mdGeral += "> Atualizado em: $dataAtualizacao`n"
$mdGeral += "> Total: $total registros`n`n"
$mdGeral += "## Por tipo`n`n| Tipo | Quantidade |`n|------|-----------|`n"
$mdGeral += "| NE | $totalNE |`n| SAM | $totalSAM |`n| SAL | $totalSAL |`n| SAIL | $totalSAIL |`n`n"
$mdGeral += "## Por status`n`n| Status | Quantidade |`n|--------|-----------|`n"
$mdGeral += "| Liberada | $totalLib |`n| Descartada | $totalDescG |`n| Pendente | $totalPendG |`n`n"
$mdGeral += "## Versoes recentes (ultimas 10)`n`n| Versao | Total | NE | SAM | SAL | SAIL |`n|--------|-------|----|-----|-----|------|`n"
$dados | Group-Object -Property nomeVersao | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
    $vne = ($_.Group | Where-Object { $_.tipoSAI -eq 'NE' } | Measure-Object).Count
    $vsam = ($_.Group | Where-Object { $_.tipoSAI -eq 'SAM' } | Measure-Object).Count
    $vsal = ($_.Group | Where-Object { $_.tipoSAI -eq 'SAL' } | Measure-Object).Count
    $vsail = ($_.Group | Where-Object { $_.tipoSAI -eq 'SAIL' } | Measure-Object).Count
    $mdGeral += "| $($_.Name) | $($_.Count) | $vne | $vsam | $vsal | $vsail |`n"
}
$null = Smart-Write (Join-Path $indicesDir "indice-geral.md") $mdGeral

# --- B8b: por-rubrica.md (orfao corrigido, versao resumida) ---
Write-Host "[B8b] Gerando por-rubrica.md (resumido)..." -ForegroundColor Yellow
$mdRubSimp = "# Indice de SAIs por Rubrica Referenciada`n`n"
$mdRubSimp += "> Atualizado em: $dataAtualizacao`n"
$mdRubSimp += "> Rubricas citadas nas descricoes de NEs pendentes`n`n"
$mdRubSimp += "## Rubricas mais citadas em NEs`n`n"
$mdRubSimp += "| Rubrica | Total SAIs | Pendentes | Exemplo SAI |`n|---------|-----------|-----------|-------------|`n"
$rubricaMap.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | Select-Object -First 20 | ForEach-Object {
    $pendRub = @($_.Value | Where-Object { -not $_.Liberacao -and -not $_.Descarte }).Count
    $exemploSai = ($_.Value | Select-Object -First 1).i_sai
    $mdRubSimp += "| $($_.Key) | $($_.Value.Count) | $pendRub | $exemploSai |`n"
}
$mdRubSimp += "`n## Busca por rubrica`n`nPara buscar SAIs de uma rubrica especifica:`n``powershell -File scripts\buscar-sai.ps1 -Termo `"8214`"```n"
$null = Smart-Write (Join-Path $indicesDir "por-rubrica.md") $mdRubSimp

# --- B8c: por-cenario-complexo.md (orfao corrigido) ---
Write-Host "[B8c] Gerando por-cenario-complexo.md..." -ForegroundColor Yellow
$mdCenario = "# Indice de SAIs por Cenario Complexo`n`n"
$mdCenario += "> Atualizado em: $dataAtualizacao`n"
$mdCenario += "> Cenarios que cruzam multiplos dominios (SAIs classificadas em 2+ dominios)`n`n"
$multiModSais = @{}
foreach ($item in $dados) {
    if ($saiModulos.ContainsKey($item.i_psai) -and $saiModulos[$item.i_psai].Count -ge 2) {
        $key = ($saiModulos[$item.i_psai] | Sort-Object) -join " + "
        if (-not $multiModSais.ContainsKey($key)) { $multiModSais[$key] = @() }
        $multiModSais[$key] += $item
    }
}
$mdCenario += "## Resumo por combinacao de dominios`n`n"
$mdCenario += "| Combinacao | SAIs | Pendentes |`n|-----------|------|-----------|`n"
$multiModSais.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | Select-Object -First 15 | ForEach-Object {
    $nomes = ($_.Key -split ' \+ ') | ForEach-Object { if ($moduloNomes[$_]) { $moduloNomes[$_] } else { $_ } }
    $nomesStr = $nomes -join " + "
    $saiU = Get-SaiUnicas $_.Value
    $pendC = @($saiU | Where-Object { -not $_.Liberacao -and -not $_.Descarte }).Count
    $mdCenario += "| $nomesStr | $($saiU.Count) | $pendC |`n"
}
$mdCenario += "`n## Detalhamento dos maiores cenarios`n`n"
$topCenarios = $multiModSais.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | Select-Object -First 5
foreach ($cenario in $topCenarios) {
    $nomes = ($cenario.Key -split ' \+ ') | ForEach-Object { if ($moduloNomes[$_]) { $moduloNomes[$_] } else { $_ } }
    $nomesStr = $nomes -join " + "
    $saiU = Get-SaiUnicas $cenario.Value
    $pendC = @($saiU | Where-Object { -not $_.Liberacao -and -not $_.Descarte })
    $mdCenario += "### $nomesStr ($($saiU.Count) SAIs, $($pendC.Count) pendentes)`n`n"
    if ($pendC.Count -gt 0) {
        $mdCenario += "| SAI | PSAI | Tipo | Resumo |`n|-----|------|------|--------|`n"
        $pendC | Sort-Object { if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue } } -Descending | Select-Object -First 10 | ForEach-Object {
            $desc = if ($_.sai_descricao) { $_.sai_descricao.Substring(0, [Math]::Min(70, $_.sai_descricao.Length)).Replace("|","").Replace("`n"," ").Replace("`r"," ") } else { "-" }
            $mdCenario += "| $($_.i_sai) | $($_.i_psai) | $($_.tipoSAI) | $desc |`n"
        }
    }
    $mdCenario += "`n"
}
$null = Smart-Write (Join-Path $indicesDir "por-cenario-complexo.md") $mdCenario
Write-Host "  Indices orfaos gerados (indice-geral, por-rubrica, por-cenario-complexo)"

# --- Pagina de navegacao (dominios Escrita / modulos-keywords.json) ---
Write-Host "[B7] Gerando pagina de navegacao..." -ForegroundColor Yellow
$kDominios = $moduloKeywords.Count
$mdNav = @"
# SAIs e PSAIs - Escrita Fiscal

> Base de conhecimento de solicitacoes de alteracao da area Escrita Fiscal (PBCVS nomeArea = Escrita, Importacao, Onvio Escrita nos caches).
> Atualizado em: $dataAtualizacao | Total: $total registros

## Indices por dominio (modulos-keywords.json)

Cada arquivo em [modulos/](modulos/) agrupa SAIs por **slug de dominio** (palavras-chave). Conteudo: pendentes, liberadas recentes, temas frequentes, descartadas.

- [Resumo de Pendentes](resumo-pendentes.md) - Totais por dominio + top 20 novidades
- [modulos/](modulos/) - Um ``.md`` por slug ($kDominios dominios em ``banco-dados/config/modulos-keywords.json`` + ``nao-classificado.md`` para o restante)

## Indices Gerais

- [Indice Geral](indice-geral.md) - Resumo com totais por tipo, status e versao
- [Estatisticas](estatisticas.md) - Numeros por ano, gravidade
- [Por Modulo](por-modulo.md) - Lista agregada por dominio (classificacao multi-dominio; ver ``modulos-keywords.json``)
- [Por Rubrica](por-rubrica.md) - Top rubricas citadas (resumido)
- [Por Rubrica Detalhado](por-rubrica-detalhado.md) - SAIs por numero de rubrica (top 100)
- [Por Cenario Complexo](por-cenario-complexo.md) - SAIs classificadas em 2+ dominios

## Pendentes

- [NEs Pendentes Recentes](pendentes-ne-recentes.md) - NEs de 2025+
- [NEs Pendentes Antigas](pendentes-ne-antigas.md) - NEs anteriores a 2025
- [SAM Pendentes](pendentes-sam.md) - Melhorias pendentes
- [SAL Pendentes](pendentes-sal.md) - Legislacao pendente
- [SAIL Pendentes](pendentes-sail.md) - Legislacao interna pendente

## Liberadas

- [NEs Liberadas Recentes](liberadas-ne-recentes.md) - NEs liberadas 2022+ (nivel SAI)
- [NEs Liberadas Antigas](liberadas-ne-antigas.md) - NEs liberadas anteriores a 2022 (nivel SAI)
- [SAM Liberadas](liberadas-sam.md) - Melhorias liberadas (nivel SAI)
- [SAL Liberadas](liberadas-sal.md) - Legislacao liberada (nivel SAI)
- [SAIL Liberadas](liberadas-sail.md) - Legislacao interna liberada (nivel SAI)

## Descartadas

- [NEs Descartadas](descartadas-ne.md) - NEs descartadas (nivel SAI)
- [SAM Descartadas](descartadas-sam.md) - Melhorias descartadas (nivel SAI)
- [SAL Descartadas](descartadas-sal.md) - Legislacao descartada (nivel SAI)
- [SAIL Descartadas](descartadas-sail.md) - Legislacao interna descartada (nivel SAI)

## Por versao (ultimas 5)

$($versoes | ForEach-Object { $nome = $_.Name -replace '[^\w\-\.]', '_'; "- [$($_.Name)](por-versao/$nome.md) - $($_.Count) registros" } | Out-String)

## Regenerar indices

Fluxo completo: ``banco-dados/config/README.md`` (``importar-sais.ps1`` + ``gerar-indices-sais.ps1``, **fora do Cursor**).

## Como usar

1. Abrir resumo-pendentes.md para visao geral
2. Identificar o dominio (slug) e abrir ``modulos/{slug}.md``
3. Quando o tema cruzar areas, consultar dominios adjacentes (ex.: ``sped-documentos-eletronicos`` e ``obrigacoes-relatorios-estaduais``)
4. Usar busca textual (Ctrl+Shift+F) nos indices
5. Pedir ao agente IA para cruzar informacoes

## JSONs fracionados (em dados-brutos/)

- ``dados-brutos/psai/`` - Todos os PSAIs individuais (NE, SAM, SAL, SAIL x pendentes, liberadas, descartadas)
- ``dados-brutos/sai/`` - SAIs unicas agrupadas (1 registro por SAI, com contagem de PSAIs)

## Buscar SAIs

Para buscar por termo: ``scripts\buscar-sai.ps1 -Termo "palavra"`` (terminal separado)
Para atualizar: ``scripts\atualizar-tudo.bat`` (terminal separado)
"@
$null = Smart-Write (Join-Path $indicesDir "README.md") $mdNav

Write-Host ""
Write-Host "=== Concluido! ===" -ForegroundColor Green
Write-Host "Indices MD em: $indicesDir"
Write-Host "Smart-Write: $($script:smartEscritos) escritos, $($script:smartPulados) pulados (identicos)"

$statsFile = Join-Path $projetoDir "atualizacao\.stats-temp.json"
@{
    smartEscritos = $script:smartEscritos
    smartPulados = $script:smartPulados
    totalRegistros = $total
    indicesMD = $script:smartEscritos + $script:smartPulados
    psaiMaisRecente = $psaiMaisRecente
    dataMaisRecente = if ($dataMaisRecente) { $dataMaisRecente.ToString("yyyy-MM-dd") } else { $null }
    defasagemHoras = $defasagemHoras
} | ConvertTo-Json | Set-Content $statsFile -Encoding UTF8

