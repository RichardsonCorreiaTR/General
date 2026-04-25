# build-modulos-keywords-escrita.ps1
# Reconstroi banco-dados/config/modulos-keywords.json a partir da taxonomia Folha legada
# + palavras-chave Escrita Fiscal. Uso interno / regeracao pontual.
# Dominius alinhados a regras-negocio/README.md

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir
$outFile = Join-Path $projetoDir "banco-dados\config\modulos-keywords.json"
$backup = Join-Path $projetoDir "banco-dados\config\modulos-keywords.v1-folha.backup.json"

$oldPath = $outFile
if (-not (Test-Path $oldPath)) {
    Write-Host "ERRO: $oldPath nao encontrado" -ForegroundColor Red
    exit 1
}
Copy-Item -LiteralPath $oldPath -Destination $backup -Force
$old = Get-Content $oldPath -Raw -Encoding UTF8 | ConvertFrom-Json

function Merge-OldModules {
    param([string[]]$OldNames)
    $tags = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $kws = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($n in $OldNames) {
        $m = $old.modulos.$n
        if (-not $m) { continue }
        foreach ($t in @($m.tags_origem)) { [void]$tags.Add($t) }
        foreach ($k in @($m.keywords)) { [void]$kws.Add($k) }
    }
    return @{ tags = @($tags); keywords = @($kws) }
}

$exibir = @{
    "apuracao-impostos"                = "Apuracao de impostos"
    "escrituracao-movimento-fiscal"    = "Escrituracao e movimento fiscal"
    "sped-documentos-eletronicos"      = "SPED e documentos eletronicos"
    "integracoes-canais-digitais"      = "Integracoes e canais digitais"
    "obrigacoes-relatorios-estaduais"  = "Obrigacoes, relatorios e declaracoes"
    "parcelamento-planejamento"        = "Parcelamento e planejamento tributario"
    "onvio-importacao-dados"           = "Onvio, importacao e dados"
    "utilitarios-rotinas"              = "Utilitarios e rotinas"
}

$agrupamento = @{
    "apuracao-impostos"               = @("inss", "irrf", "fgts")
    "escrituracao-movimento-fiscal"   = @("ferias", "rescisao", "calculo-mensal", "admissao", "beneficios", "afastamentos", "13o-salario", "retroativo-cct", "transferencia", "pensao-judicial")
    "sped-documentos-eletronicos"     = @("esocial")
    "integracoes-canais-digitais"     = @("integracao")
    "obrigacoes-relatorios-estaduais" = @("relatorios", "rais-dirf", "dctfweb-guias")
    "parcelamento-planejamento"       = @("provisoes")
    "onvio-importacao-dados"          = @("rpa-contribuintes")
    "utilitarios-rotinas"             = @("seguranca-trabalho", "outros-sistema")
}

$extrasKeywords = @{
    "apuracao-impostos"               = @(
        "apuracao", "icms", "ipi", "pis cofins", "cofins", "drcst", "substituicao tributaria", "st",
        "simples nacional", "regime tributario", "credito tributario", "debito tributario", "efd",
        "escrituracao fiscal", "livro fiscal", "obrigacao principal"
    )
    "escrituracao-movimento-fiscal"   = @(
        "escrituracao", "movimento fiscal", "entrada", "saida", "cfop", "nota fiscal", "nfe", "nf-e",
        "meu escritorio", "cadastro de empresa", "parametro fiscal"
    )
    "sped-documentos-eletronicos"   = @(
        "sped", "efd-fiscal", "efd fiscal", "ecd", "ecf", "xml", "layout", "validador", "chave de acesso",
        "documento eletronico", "mdfe", "cte", "nfce", "evento esocial"
    )
    "integracoes-canais-digitais"     = @(
        "webservice", "api", "portal federal", "integrador", "exportacao", "comunicacao", "rest", "soap",
        "chromium", "digital bank", "painel"
    )
    "obrigacoes-relatorios-estaduais" = @(
        "sefaz", "estadual", "obrigacao acessoria", "declaracao", "gnre", "dief", "dapi", "gia",
        "obrigacao estadual", "relatorio fiscal", "demonstrativo"
    )
    "parcelamento-planejamento"       = @(
        "parcelamento", "planejamento tributario", "e-cac", "ecac", "contabilizacao", "provisao fiscal",
        "tributo a pagar"
    )
    "onvio-importacao-dados"          = @(
        "onvio", "importacao de nota", "importacao nfe", "carga de xml", "rotina automatica", "dominio atendimento",
        "rpa", "contribuinte", "lote de importacao"
    )
    "utilitarios-rotinas"             = @(
        "utilitario", "alteracao em lote", "grafico", "certificado", "rotina", "manutencao", "ajuste em massa"
    )
}

# Mescla: (1) slugs legados Folha em $agrupamento, se ainda existirem em $old.modulos;
# (2) conteudo ja consolidado no slug v2 (obrigatorio — a taxonomia v2 nao usa mais chaves "ferias", etc.);
# (3) palavras extras Escrita por dominio.
$nova = [ordered]@{}
foreach ($slug in $exibir.Keys) {
    $legacy = Merge-OldModules -OldNames $agrupamento[$slug]
    $kwSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $tagSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($k in @($legacy.keywords)) { [void]$kwSet.Add($k) }
    foreach ($t in @($legacy.tags)) { [void]$tagSet.Add($t) }
    $cur = $old.modulos.$slug
    if ($cur) {
        foreach ($k in @($cur.keywords)) { [void]$kwSet.Add($k) }
        foreach ($t in @($cur.tags_origem)) { [void]$tagSet.Add($t) }
    }
    foreach ($k in $extrasKeywords[$slug]) { [void]$kwSet.Add($k) }
    $nova[$slug] = @{
        nome_exibicao = $exibir[$slug]
        tags_origem   = @($tagSet | Sort-Object)
        keywords      = @($kwSet | Sort-Object)
    }
}

$obj = [ordered]@{
    versao        = "2.0"
    atualizado_em = (Get-Date -Format "yyyy-MM-dd")
    nota          = "Dominios alinhados a regras-negocio/ e mapa-escrita.md; keywords legadas Folha agrupadas em escrituracao-movimento-fiscal e demais dominios. Regeneracao preserva tags/keywords do JSON v2 atual e soma extras Escrita."
    modulos       = [ordered]@{}
}
foreach ($k in $nova.Keys) { $obj.modulos[$k] = $nova[$k] }

$json = $obj | ConvertTo-Json -Depth 8
Set-Content -Path $outFile -Value $json -Encoding UTF8
Write-Host "Gerado: $outFile"
Write-Host "Backup v1 Folha: $backup"
