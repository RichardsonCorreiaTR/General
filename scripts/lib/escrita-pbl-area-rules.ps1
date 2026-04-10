# escrita-pbl-area-rules.ps1
# Regras de classificacao PBL -> Area (Espelho de mapa-sistema/mapa-escrita.md)
# Usado por: gerar-mapa-pbl-escrita.ps1 (gera pbl-area-escrita.json)

function Get-EscritaAreaPbl {
    param([string]$PblName)
    if (-not $PblName) { return "" }
    $n = $PblName.ToLowerInvariant()

    if ($n -eq "esrotinasautomaticasimportacao") { return "Rotinas automaticas - Importacao" }
    if ($n -eq "esrotinasautomaticasescrita") { return "Rotinas automaticas - Escrita" }
    if ($n -eq "esrotinasautomaticas") { return "Rotinas automaticas" }

    if ($n.StartsWith("esionbalance")) { return "Integracao Onvio / saldo" }

    if ($n.StartsWith("esapuracao")) { return "Apuracao de impostos" }

    if ($n -match "^esc(0[1-9]|1[0-9]|2[0-7])$") { return "Nucleo escrituracao (esc)" }
    foreach ($x in @("escrita", "escpr01", "esmodulo", "esobjetosglobais", "esselecao")) {
        if ($n -eq $x) { return "Nucleo escrituracao (esc)" }
    }
    if ($n -like "esobj*") { return "Nucleo escrituracao (esc)" }

    if ($n -match "^esf\d") { return "Movimento fiscal (esf)" }

    if ($n -like "esm_*") { return "Layouts / ajustes (prefixo esm_)" }
    if ($n -match "^esm\d") { return "Movimento e parametros (esm)" }

    if ($n.StartsWith("esifdipj")) { return "SPED / layouts DIPJ" }
    if ($n.StartsWith("esifix")) { return "SPED / layouts fixos e documentos eletronicos" }

    if ($n -in @("esileiauteconjuntodados", "esxml")) { return "SPED / leiaute e XML" }
    if ($n -eq "esimodeloutilitario") { return "SPED / modelo utilitario" }

    if ($n -eq "esexternos") { return "Integracoes externas" }
    if ($n.StartsWith("esiwebservice") -or $n -in @("esidigitalbank", "esichromium")) { return "Integracoes / canais digitais" }
    if ($n -in @("esianalytics", "esipainelapi")) { return "Integracoes / painel e analytics" }
    if ($n.StartsWith("esiapibaixas")) { return "API baixas" }
    if ($n -eq "esibuscaprodutos") { return "Busca produtos" }

    if ($n.StartsWith("esisitesefaz")) { return "Sefaz e sites estaduais" }

    if ($n -eq "esidominioatendimento") { return "Atendimento dominio (import NF-e)" }
    if ($n -in @("esierninformativofiscal", "esifdacon01")) { return "Informativos / Dacon" }

    if ($n.StartsWith("esisite") -or $n -eq "esiveiculosusados") { return "Cadastros site / portal / CTe" }

    if ($n.StartsWith("esparcelamento")) { return "Parcelamento" }
    if ($n -eq "esplanejamentotributario") { return "Planejamento tributario" }
    if ($n -eq "esconsultarpagamentoimpostoecac") { return "Consulta e-CAC" }
    if ($n -eq "escontabilizacao01") { return "Contabilizacao" }

    if ($n.StartsWith("esutil")) { return "Utilitarios e alteracoes" }

    if ($n.StartsWith("esr_api") -or $n.StartsWith("esr_defis") -or $n -eq "esr_pgdas" -or $n.StartsWith("esr_memoria")) {
        return "API contador / DEFIS / PGDAS / memorias"
    }

    if ($n.StartsWith("esr")) { return "Relatorios e obrigacoes (matriz estadual)" }

    if ($n -eq "esnfeatendimento") { return "Atendimento NF-e" }

    return ""
}
