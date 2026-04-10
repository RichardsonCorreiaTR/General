<#
.SYNOPSIS
    Consolida logs ricos dos analistas em resumo semanal/mensal.
.DESCRIPTION
    Le logs em logs/analistas/{nome}/ e gera resumo com metricas de
    desempenho, insights coletados e gaps identificados.
.PARAMETER Periodo
    Periodo a consolidar: "semana" (ultimos 7 dias) ou "mes" (ultimos 30 dias).
.PARAMETER Analista
    Nome do analista para filtrar (opcional, padrao: todos).
.EXAMPLE
    .\consolidar-logs.ps1 -Periodo semana
    .\consolidar-logs.ps1 -Periodo mes -Analista joao-silva
#>
param(
    [ValidateSet("semana","mes")]
    [string]$Periodo = "semana",
    [string]$Analista = ""
)

$ErrorActionPreference = "Stop"
$projetoDir = Split-Path -Parent $PSScriptRoot
$logsDir = Join-Path $projetoDir "logs\analistas"
$consolidadoDir = Join-Path $projetoDir "logs\consolidado"

if (-not (Test-Path $logsDir)) {
    Write-Host "ERRO: Pasta de logs nao encontrada: $logsDir" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Path $consolidadoDir -Force | Out-Null

$dias = if ($Periodo -eq "semana") { 7 } else { 30 }
$dataLimite = (Get-Date).AddDays(-$dias)
$hoje = Get-Date -Format "yyyy-MM-dd"

Write-Host "=== Consolidacao de Logs ===" -ForegroundColor Cyan
Write-Host "Periodo: $Periodo (ultimos $dias dias)"
Write-Host ""

$analistas = Get-ChildItem $logsDir -Directory -ErrorAction SilentlyContinue
if ($Analista) {
    $analistas = $analistas | Where-Object { $_.Name -eq $Analista }
    if (-not $analistas) {
        Write-Host "ERRO: Analista '$Analista' nao encontrado em $logsDir" -ForegroundColor Red
        exit 1
    }
}

$metricas = @{}
$totalLogs = 0
$modulosAtivos = @{}
$acoesPorTipo = @{
    "Analise" = 0; "Consulta" = 0; "Definicao" = 0; "Revisao" = 0
    "Conclusao" = 0; "Exploracao" = 0; "Atualizacao" = 0; "Outro" = 0
}
$complexidades = @{ "Alta" = 0; "Media" = 0; "Baixa" = 0 }
$todosInsights = @()
$todosGaps = @()
$artefatosGerados = @()
$todasLeituras = @()
$todasContribuicoes = @()

function Parse-LogBlock {
    param([string]$Bloco, [string]$AnalistaNome)

    $resultado = @{
        tipo = "Outro"; titulo = ""; complexidade = ""
        modulos = @(); insights = @(); gaps = @()
        artefato = ""; falas = @(); contribuicoes = @()
        leitura = ""; trouxe_conhecimento = $false
        nivel = "rapido"
    }

    if ($Bloco -match '## \d{2}:\d{2} - \[(\w+)\]\s*(.*)') {
        $resultado.tipo = $Matches[1]
        $resultado.titulo = $Matches[2]
    }

    $temSecoes = $Bloco -match '### '
    if ($temSecoes) { $resultado.nivel = "completo" }

    if ($Bloco -match '\*\*Complexidade\*\*:\s*(Alta|Media|Baixa)') {
        $resultado.complexidade = $Matches[1]
    }
    if ($Bloco -match '\*\*Artefato\*\*:\s*((?:PSAI|SAI)-[^\s\(]+)') {
        $resultado.artefato = $Matches[1]
    }
    if ($Bloco -match '\*\*Modulos envolvidos\*\*:\s*(.+)') {
        $resultado.modulos = ($Matches[1] -split '[,;]') | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ -and $_ -ne "nao consultado" }
    }

    if (-not $temSecoes) {
        $linhas = $Bloco -split "`n"
        foreach ($l in $linhas) {
            if ($l -match '>\s*"(.+)"') { $resultado.falas += $Matches[1] }
            elseif ($l -match '>\s*(.+)') { $resultado.falas += $Matches[1] }
            if ($l -match '\*\*Gap\*\*:\s*(.+)') { $resultado.gaps += "$AnalistaNome : $($Matches[1].Trim())" }
        }
        return $resultado
    }

    $secaoAtual = ""
    foreach ($linha in ($Bloco -split "`n")) {
        if ($linha -match '^### (.+)') { $secaoAtual = $Matches[1].Trim(); continue }

        switch -Regex ($secaoAtual) {
            'O que o analista disse' {
                if ($linha -match '>\s*-?\s*"(.+)"') {
                    $resultado.falas += $Matches[1]
                } elseif ($linha -match '^>\s*"?(.+)"?\s*$' -and $linha.Trim().Length -gt 2) {
                    $resultado.falas += $Matches[1]
                }
            }
            'O que o analista trouxe' {
                if ($linha -match '^- (.+)' -and $linha -notmatch 'Seguiu a conducao') {
                    $resultado.contribuicoes += $Matches[1].Trim()
                    $resultado.trouxe_conhecimento = $true
                }
            }
            'Gaps e descobertas' {
                if ($linha -match '^- (.+)' -and $linha -notmatch 'Nenhum gap') {
                    $item = $Matches[1].Trim()
                    if ($item -match '(?i)gap|faltante|ausente|incompleta|nao existe|nao encontr|falta|sem cobertura') {
                        $resultado.gaps += "$AnalistaNome : $item"
                    } else {
                        $resultado.insights += "$AnalistaNome : $item"
                    }
                }
            }
            'Leitura do analista' {
                if ($linha.Trim()) {
                    $resultado.leitura += $linha.Trim() + " "
                }
            }
        }
    }

    $resultado.leitura = $resultado.leitura.Trim()
    return $resultado
}

foreach ($dir in $analistas) {
    $nome = $dir.Name
    $metricas[$nome] = @{
        logs = 0; acoes = 0; acoes_rapidas = 0; acoes_completas = 0
        modulos = @{}; dias_ativos = 0
        complexidades = @{ "Alta" = 0; "Media" = 0; "Baixa" = 0 }
        artefatos = @(); insights_count = 0; gaps_count = 0
        contribuicoes_count = 0; leituras = @()
    }

    $logFiles = Get-ChildItem $dir.FullName -File -Filter "*.md" -ErrorAction SilentlyContinue |
        Where-Object {
            if ($_.BaseName -match '^(\d{4}-\d{2}-\d{2})(-\d+)?$') {
                [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd', $null) -ge $dataLimite
            } else { $false }
        }

    $diasUnicos = @($logFiles | ForEach-Object {
        if ($_.BaseName -match '^(\d{4}-\d{2}-\d{2})') { $Matches[1] }
    } | Select-Object -Unique)
    $metricas[$nome].dias_ativos = $diasUnicos.Count

    foreach ($logFile in $logFiles) {
        $totalLogs++
        $metricas[$nome].logs++
        $conteudo = Get-Content $logFile.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if (-not $conteudo) { continue }

        $blocos = $conteudo -split '(?=## \d{2}:\d{2} - )'
        foreach ($bloco in $blocos) {
            if ($bloco -notmatch '## \d{2}:\d{2} - ') { continue }

            $metricas[$nome].acoes++
            $parsed = Parse-LogBlock -Bloco $bloco -AnalistaNome $nome
            if ($parsed.nivel -eq "completo") { $metricas[$nome].acoes_completas++ }
            else { $metricas[$nome].acoes_rapidas++ }

            $tipoNorm = $parsed.tipo
            if ($tipoNorm -match 'Analise|Pipeline') { $tipoNorm = "Analise" }
            elseif ($tipoNorm -match 'Definicao|Criou') { $tipoNorm = "Definicao" }
            elseif ($tipoNorm -match 'Conclusao|Moveu') { $tipoNorm = "Conclusao" }
            if ($acoesPorTipo.ContainsKey($tipoNorm)) { $acoesPorTipo[$tipoNorm]++ }
            else { $acoesPorTipo["Outro"]++ }

            if ($parsed.complexidade -and $complexidades.ContainsKey($parsed.complexidade)) {
                $complexidades[$parsed.complexidade]++
                $metricas[$nome].complexidades[$parsed.complexidade]++
            }

            if ($parsed.artefato) {
                $artefatosGerados += "$nome : $($parsed.artefato)"
                $metricas[$nome].artefatos += $parsed.artefato
            }

            foreach ($mod in $parsed.modulos) {
                if (-not $metricas[$nome].modulos.ContainsKey($mod)) { $metricas[$nome].modulos[$mod] = 0 }
                $metricas[$nome].modulos[$mod]++
                if (-not $modulosAtivos.ContainsKey($mod)) { $modulosAtivos[$mod] = 0 }
                $modulosAtivos[$mod]++
            }

            $todosInsights += $parsed.insights
            $todosGaps += $parsed.gaps
            $metricas[$nome].insights_count += $parsed.insights.Count
            $metricas[$nome].gaps_count += $parsed.gaps.Count

            if ($parsed.trouxe_conhecimento) { $metricas[$nome].contribuicoes_count++ }
            $todasContribuicoes += $parsed.contribuicoes | ForEach-Object { "$nome : $_" }

            if ($parsed.leitura) {
                $metricas[$nome].leituras += $parsed.leitura
                $todasLeituras += @{ analista = $nome; texto = $parsed.leitura }
            }
        }
    }

    $a = $metricas[$nome]
    Write-Host "  $nome : $($a.dias_ativos) dias, $($a.acoes) interacoes, $($a.contribuicoes_count) contribuicoes" -ForegroundColor $(if ($a.dias_ativos -gt 0) { "Green" } else { "DarkGray" })
}

$totalAcoes = ($metricas.Values | ForEach-Object { $_.acoes } | Measure-Object -Sum).Sum
$totalDiasAtivos = ($metricas.Values | ForEach-Object { $_.dias_ativos } | Measure-Object -Sum).Sum
$nomeArquivo = if ($Periodo -eq "semana") { "semana-$hoje.md" } else { "mes-$hoje.md" }

$totalContribuicoes = ($metricas.Values | ForEach-Object { $_.contribuicoes_count } | Measure-Object -Sum).Sum

$md = @"
# Consolidado -- $($Periodo.Substring(0,1).ToUpper() + $Periodo.Substring(1)) ate $hoje

> Gerado em: $(Get-Date -Format 'dd/MM/yyyy HH:mm')
> Periodo: ultimos $dias dias

## Visao geral

| Metrica | Valor |
|---------|-------|
| **Analistas ativos** | $(($metricas.Values | Where-Object { $_.dias_ativos -gt 0 }).Count) de $($metricas.Count) |
| **Dias com atividade** | $totalDiasAtivos |
| **Total de interacoes** | $totalAcoes |
| **Artefatos gerados** | $($artefatosGerados.Count) |
| **Contribuicoes dos analistas** | $totalContribuicoes (interacoes onde trouxeram conhecimento proprio) |
| **Gaps identificados** | $($todosGaps.Count) |

## Interacoes por tipo

| Tipo | Qtd |
|------|-----|
| Analise/Pipeline | $($acoesPorTipo["Analise"]) |
| Consulta | $($acoesPorTipo["Consulta"]) |
| Definicao | $($acoesPorTipo["Definicao"]) |
| Revisao | $($acoesPorTipo["Revisao"]) |
| Conclusao | $($acoesPorTipo["Conclusao"]) |
| Exploracao | $($acoesPorTipo["Exploracao"]) |
| Outro | $($acoesPorTipo["Outro"]) |

## Complexidade do trabalho

| Nivel | Qtd |
|-------|-----|
| Alta | $($complexidades["Alta"]) |
| Media | $($complexidades["Media"]) |
| Baixa | $($complexidades["Baixa"]) |

## Numeros por analista

| Analista | Dias | Rapidas | Completas | Artefatos | Contribuicoes | Gaps | Modulos |
|----------|------|---------|-----------|-----------|---------------|------|---------|

"@

foreach ($nome in ($metricas.Keys | Sort-Object)) {
    $a = $metricas[$nome]
    $mods = if ($a.modulos.Count -gt 0) { ($a.modulos.Keys | Sort-Object | Select-Object -First 3) -join ", " } else { "-" }
    $md += "| $nome | $($a.dias_ativos) | $($a.acoes_rapidas) | $($a.acoes_completas) | $($a.artefatos.Count) | $($a.contribuicoes_count) | $($a.gaps_count) | $mods |`n"
}

$md += "`n## Quem e quem -- Leitura da IA sobre cada analista`n`n"
$md += "Estas sao as observacoes narrativas registradas pela IA durante as interacoes.`n"
$md += "Leia como se fossem anotacoes de um colega que acompanhou o analista trabalhando.`n`n"
foreach ($nome in ($metricas.Keys | Sort-Object)) {
    $a = $metricas[$nome]
    if ($a.leituras.Count -eq 0) { continue }
    $md += "### $nome`n`n"
    $i = 0
    foreach ($leitura in $a.leituras) {
        $i++
        if ($leitura.Length -gt 20) {
            $md += "> $leitura`n`n"
        }
    }
    if ($a.contribuicoes_count -gt 0) {
        $proporcao = [math]::Round(($a.contribuicoes_count / [math]::Max($a.acoes, 1)) * 100)
        $md += "**Engajamento**: Trouxe conhecimento proprio em $($a.contribuicoes_count) de $($a.acoes) interacoes ($proporcao%).`n`n"
    } else {
        $md += "**Engajamento**: Nao trouxe contribuicoes proprias no periodo. Avaliar se esta apenas seguindo a IA.`n`n"
    }
}

if ($todasContribuicoes.Count -gt 0) {
    $md += "`n## Contribuicoes dos analistas (conhecimento trazido)`n`n"
    $md += "Momentos em que o analista trouxe contexto, correcoes ou experiencia propria:`n`n"
    foreach ($c in ($todasContribuicoes | Select-Object -Unique | Select-Object -First 25)) { $md += "- $c`n" }
}

if ($modulosAtivos.Count -gt 0) {
    $md += "`n## Modulos mais ativos`n`n"
    $md += "| Modulo | Mencoes |`n|--------|---------|`n"
    foreach ($mod in ($modulosAtivos.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10)) {
        $md += "| $($mod.Key) | $($mod.Value) |`n"
    }
}

if ($artefatosGerados.Count -gt 0) {
    $md += "`n## Artefatos gerados no periodo`n`n"
    foreach ($art in $artefatosGerados) { $md += "- $art`n" }
}

if ($todosGaps.Count -gt 0) {
    $md += "`n## Gaps identificados (melhorias futuras)`n`n"
    $md += "Oportunidades de melhoria na base de conhecimento detectadas durante o uso:`n`n"
    foreach ($gap in ($todosGaps | Select-Object -Unique | Select-Object -First 25)) { $md += "- $gap`n" }
}

if ($todosInsights.Count -gt 0) {
    $md += "`n## Insights coletados`n`n"
    foreach ($ins in ($todosInsights | Select-Object -Unique | Select-Object -First 25)) { $md += "- $ins`n" }
}

$alertas = @()
$inativos = @($metricas.GetEnumerator() | Where-Object { $_.Value.dias_ativos -eq 0 })
if ($inativos.Count -gt 0) {
    $alertas += "- **$($inativos.Count) analista(s) sem atividade** no periodo: $(($inativos | ForEach-Object { $_.Key }) -join ', ')"
}
$passivos = @($metricas.GetEnumerator() | Where-Object { $_.Value.contribuicoes_count -eq 0 -and $_.Value.acoes -gt 3 })
if ($passivos.Count -gt 0) {
    $alertas += "- **Analistas passivos** (nenhuma contribuicao propria em 3+ interacoes): $(($passivos | ForEach-Object { $_.Key }) -join ', ') -- avaliar se estao apenas aceitando a IA sem criticar"
}
$soConsultas = @($metricas.GetEnumerator() | Where-Object { $_.Value.artefatos.Count -eq 0 -and $_.Value.acoes -gt 5 })
if ($soConsultas.Count -gt 0) {
    $alertas += "- **Sem producao** (5+ interacoes, 0 artefatos): $(($soConsultas | ForEach-Object { $_.Key }) -join ', ') -- verificar se estao com dificuldade ou usando so para consulta"
}

$md += @"

## Alertas

$(if ($alertas.Count -eq 0) { "- Sem alertas no periodo." } else { $alertas -join "`n" })

## Recomendacoes

$(if ($todosGaps.Count -gt 3) { "- **Priorizar fechamento de gaps**: $($todosGaps.Count) gaps identificados. Revisar e criar definicoes faltantes." } else { "" })
$(if ($totalAcoes -eq 0) { "- Verificar se os analistas estao utilizando o sistema e se os logs estao sendo gerados." } else { "- Continuar acompanhamento regular." })
$(if ($passivos.Count -gt 0) { "- Sessao de capacitacao: incentivar pensamento critico e contribuicao ativa durante as analises." } else { "" })
$(if ($todasContribuicoes.Count -gt 5) { "- **Valorizar contribuicoes**: $($todasContribuicoes.Count) contribuicoes de conhecimento dos analistas. Considerar incorporar na base oficial." } else { "" })
"@

$destino = Join-Path $consolidadoDir $nomeArquivo
Set-Content -Path $destino -Value $md -Encoding UTF8

Write-Host ""
Write-Host "=== Concluido! ===" -ForegroundColor Green
Write-Host "Resumo salvo em: $destino"
Write-Host "Analistas: $($metricas.Count) | Interacoes: $totalAcoes | Contribuicoes: $totalContribuicoes | Gaps: $($todosGaps.Count)"
