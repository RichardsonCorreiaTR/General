# gerar-indices-enriquecidos.ps1
# Gera indices enriquecidos a partir de JSONs de dados brutos.
# Cada entrada contem: descricao (~300 chars), comportamento-chave,
# modulos impactados e gravidade.
#
# USO:
#   .\gerar-indices-enriquecidos.ps1
#   .\gerar-indices-enriquecidos.ps1 -FonteDados "C:\caminho\dados-brutos" -Destino "C:\caminho\indices\enriquecidos"
#
# IMPORTANTE: Rodar em terminal SEPARADO (fora do Cursor)

param(
    [string]$FonteDados = "",
    [string]$Destino = ""
)

# ============================================
# CONFIGURACAO
# ============================================

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent (Split-Path -Parent $scriptDir)

# Definir caminhos padrao se nao fornecidos
if (-not $FonteDados) {
    $FonteDados = Join-Path $projetoDir "banco-dados\dados-brutos"
}
if (-not $Destino) {
    $Destino = Join-Path $projetoDir "indices\enriquecidos"
}

# Tamanho maximo da descricao enriquecida
$MAX_DESCRICAO_CHARS = 300

# ============================================
# FUNCOES AUXILIARES
# ============================================

function Write-Info($msg)    { Write-Host "  [INFO] $msg" -ForegroundColor Cyan }
function Write-OK($msg)      { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Aviso($msg)   { Write-Host "  [!] $msg" -ForegroundColor DarkYellow }
function Write-Erro($msg)    { Write-Host "  [ERRO] $msg" -ForegroundColor Red }

function Write-Etapa($num, $total, $msg) {
    Write-Host ""
    Write-Host "[$num/$total] $msg" -ForegroundColor Yellow
    Write-Host ("-" * 60) -ForegroundColor DarkGray
}

# Smart-Write: so reescreve se conteudo mudou (evita churn desnecessario no OneDrive)
$script:smartEscritos = 0
$script:smartPulados = 0

function Smart-Write {
    param([string]$Path, [string]$Content)

    if (Test-Path $Path) {
        $existente = (Get-Content $Path -Raw -Encoding UTF8 -ErrorAction SilentlyContinue)
        if ($existente) {
            $existente = $existente.TrimEnd()
            $novo = $Content.TrimEnd()
            if ($existente -eq $novo) {
                $script:smartPulados++
                return $false
            }
        }
    }
    Set-Content -Path $Path -Value $Content -Encoding UTF8
    $script:smartEscritos++
    return $true
}

function Truncar-Texto {
    param(
        [string]$Texto,
        [int]$MaxChars
    )

    if (-not $Texto) { return "" }

    # Limpar quebras de linha e espacos extras
    $limpo = $Texto -replace '[\r\n]+', ' ' -replace '\s+', ' '
    $limpo = $limpo.Trim()

    if ($limpo.Length -le $MaxChars) { return $limpo }

    # Truncar no ultimo espaco antes do limite
    $cortado = $limpo.Substring(0, $MaxChars)
    $ultimoEspaco = $cortado.LastIndexOf(' ')
    if ($ultimoEspaco -gt ($MaxChars * 0.7)) {
        $cortado = $cortado.Substring(0, $ultimoEspaco)
    }

    return "$cortado..."
}

function Extrair-ComportamentoChave {
    param([string]$Descricao)

    if (-not $Descricao) { return "Nao identificado" }

    $dLower = $Descricao.ToLower()

    # Padroes de comportamento comuns em SAIs
    $padroes = @(
        @{ Padrao = "calculo.*incorret|valor.*errad|calcul.*err"; Comportamento = "Calculo incorreto" },
        @{ Padrao = "nao gera|nao emite|nao imprime|deixa de gerar"; Comportamento = "Falha na geracao/emissao" },
        @{ Padrao = "trava|congela|loop|nao responde|lentidao"; Comportamento = "Travamento/lentidao" },
        @{ Padrao = "erro ao|mensagem de erro|exception|falha ao"; Comportamento = "Erro em operacao" },
        @{ Padrao = "layout|formato|impressao|relatorio"; Comportamento = "Problema de layout/relatorio" },
        @{ Padrao = "gravar|salvar|persistir|banco.*dados"; Comportamento = "Problema de persistencia" },
        @{ Padrao = "integra|esocial|sefip|dirf|rais|dctfweb"; Comportamento = "Integracao/obrigacao acessoria" },
        @{ Padrao = "legisla|lei |mp |portaria|decreto|convencao"; Comportamento = "Adequacao legislativa" },
        @{ Padrao = "ferias|abono"; Comportamento = "Processo de ferias" },
        @{ Padrao = "rescis|demiss|aviso previo"; Comportamento = "Processo rescisorio" },
        @{ Padrao = "melhoria|nova funcionalidade|implementar|incluir opcao"; Comportamento = "Solicitacao de melhoria" }
    )

    foreach ($p in $padroes) {
        if ($dLower -match $p.Padrao) {
            return $p.Comportamento
        }
    }

    return "Comportamento geral"
}

function Extrair-ModulosImpactados {
    param([string]$Descricao)

    if (-not $Descricao) { return @("Nao identificado") }

    $dLower = $Descricao.ToLower()
    $modulos = @()

    $mapeamento = @(
        @{ Keywords = @("calculo mensal","folha mensal","holerite","contracheque","calculo da folha"); Modulo = "Calculo Mensal" },
        @{ Keywords = @("ferias","abono pecuniario","gozo de ferias","programacao de ferias"); Modulo = "Ferias" },
        @{ Keywords = @("rescisao","aviso previo","demissao","desligamento","trct","grrf"); Modulo = "Rescisao" },
        @{ Keywords = @("inss","previdencia","gps","contribuicao previdenciaria","rat","fap"); Modulo = "INSS/Previdencia" },
        @{ Keywords = @("fgts","sefip","fundo de garantia","grf","grrf"); Modulo = "FGTS" },
        @{ Keywords = @("esocial","s-1200","s-2200","s-2299","s-1210","s-1299","s-2230","s-2206"); Modulo = "eSocial" },
        @{ Keywords = @("irrf","imposto de renda","dirf","informe de rendimento"); Modulo = "IRRF" },
        @{ Keywords = @("decimo terceiro","13o","adiantamento 13","gratificacao natalina"); Modulo = "13o Salario" },
        @{ Keywords = @("beneficio","vale transporte","vale alimentacao","assistencia medica","plano de saude"); Modulo = "Beneficios" },
        @{ Keywords = @("ponto","frequencia","hora extra","banco de horas","jornada"); Modulo = "Ponto/Frequencia" },
        @{ Keywords = @("provisao","contabiliz","lancamento contabil","centro de custo"); Modulo = "Contabilizacao" },
        @{ Keywords = @("admissao","cadastro","funcionario","empregado","colaborador"); Modulo = "Cadastro/Admissao" },
        @{ Keywords = @("dctfweb","reinf","efd-reinf","r-4010","r-2010"); Modulo = "DCTFWeb/REINF" },
        @{ Keywords = @("rais","caged","novo caged"); Modulo = "RAIS/CAGED" }
    )

    foreach ($m in $mapeamento) {
        foreach ($kw in $m.Keywords) {
            if ($dLower.Contains($kw)) {
                if ($modulos -notcontains $m.Modulo) {
                    $modulos += $m.Modulo
                }
                break
            }
        }
    }

    if ($modulos.Count -eq 0) { return @("Geral") }
    return $modulos
}

function Classificar-Gravidade {
    param(
        [string]$GravidadeOriginal,
        [string]$TipoSAI,
        [string]$Descricao
    )

    # Se ja tem gravidade original (NEs), usar como base
    if ($GravidadeOriginal -and $GravidadeOriginal -ne "-") {
        return $GravidadeOriginal
    }

    # Para SAs sem gravidade, inferir do tipo e descricao
    $dLower = if ($Descricao) { $Descricao.ToLower() } else { "" }

    if ($TipoSAI -eq "SAL") {
        # Legislacao geralmente e alta prioridade
        if ($dLower -match "prazo|obrigatorio|multa|penalidade") { return "Alta" }
        return "Media"
    }

    if ($TipoSAI -eq "SAIL") {
        return "Media"
    }

    if ($TipoSAI -eq "SAM") {
        if ($dLower -match "urgent|critic|bloqueant") { return "Alta" }
        return "Baixa"
    }

    return "Nao classificada"
}

# ============================================
# EXECUCAO PRINCIPAL
# ============================================

Write-Host ""
Write-Host "  =============================================" -ForegroundColor Cyan
Write-Host "  |  Gerador de Indices Enriquecidos v2.4.0   |" -ForegroundColor Cyan
Write-Host "  |  Admin - Folha                             |" -ForegroundColor Cyan
Write-Host "  =============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Fonte: $FonteDados"
Write-Host "  Destino: $Destino"
Write-Host ""

# ---- ETAPA 1: Validar entrada ----
Write-Etapa 1 5 "Validando fonte de dados"

if (-not (Test-Path $FonteDados)) {
    Write-Erro "Pasta de dados brutos nao encontrada: $FonteDados"
    Write-Host "  Verifique se o caminho esta correto ou forneça -FonteDados." -ForegroundColor Yellow
    exit 1
}

# Buscar todos os JSONs na fonte de dados (incluindo subpastas)
$arquivosJson = Get-ChildItem -Path $FonteDados -Filter "*.json" -Recurse -ErrorAction SilentlyContinue
if (-not $arquivosJson -or $arquivosJson.Count -eq 0) {
    Write-Erro "Nenhum arquivo JSON encontrado em: $FonteDados"
    exit 1
}

Write-OK "$($arquivosJson.Count) arquivo(s) JSON encontrado(s)"

# Criar pasta de destino
New-Item -ItemType Directory -Path $Destino -Force | Out-Null

# ---- ETAPA 2: Carregar dados brutos ----
Write-Etapa 2 5 "Carregando dados brutos"

$todosRegistros = [System.Collections.ArrayList]::new()
$arquivosProcessados = 0
$errosLeitura = 0

foreach ($arquivo in $arquivosJson) {
    try {
        $conteudo = Get-Content $arquivo.FullName -Raw -Encoding UTF8 -ErrorAction Stop
        if (-not $conteudo -or $conteudo.Trim().Length -eq 0) {
            Write-Aviso "Arquivo vazio ignorado: $($arquivo.Name)"
            continue
        }

        $json = $conteudo | ConvertFrom-Json

        # Suportar formato com campo "dados" (array) ou array direto
        $registros = $null
        if ($json.dados -and $json.dados -is [array]) {
            $registros = $json.dados
        } elseif ($json -is [array]) {
            $registros = $json
        } else {
            # Objeto unico: empacotar em array
            $registros = @($json)
        }

        foreach ($reg in $registros) {
            [void]$todosRegistros.Add($reg)
        }

        $arquivosProcessados++
        Write-Host "  Carregado: $($arquivo.Name) ($($registros.Count) registros)" -ForegroundColor DarkGray

    } catch {
        Write-Aviso "Erro ao ler $($arquivo.Name): $($_.Exception.Message)"
        $errosLeitura++
    }
}

# Liberar memoria dos JSONs brutos
[GC]::Collect()

Write-OK "$($todosRegistros.Count) registros carregados de $arquivosProcessados arquivo(s)"
if ($errosLeitura -gt 0) {
    Write-Aviso "$errosLeitura arquivo(s) com erro de leitura (ignorados)"
}

if ($todosRegistros.Count -eq 0) {
    Write-Erro "Nenhum registro valido encontrado. Saindo."
    exit 1
}

# ---- ETAPA 3: Enriquecer dados ----
Write-Etapa 3 5 "Enriquecendo registros"

$enriquecidos = [System.Collections.ArrayList]::new()
$contador = 0

foreach ($reg in $todosRegistros) {
    $contador++

    # Extrair campos (tolerante a formatos variados)
    $id = if ($reg.i_sai) { $reg.i_sai } elseif ($reg.id) { $reg.id } elseif ($reg.codigo) { $reg.codigo } else { "ID-$contador" }
    $idPsai = if ($reg.i_psai) { $reg.i_psai } else { "" }
    $tipo = if ($reg.tipoSAI) { $reg.tipoSAI } elseif ($reg.tipo) { $reg.tipo } else { "N/D" }
    $descOriginal = if ($reg.sai_descricao) { $reg.sai_descricao } elseif ($reg.descricao) { $reg.descricao } elseif ($reg.titulo) { $reg.titulo } else { "" }
    $gravOriginal = if ($reg.gravidade_ne) { $reg.gravidade_ne } elseif ($reg.gravidade) { $reg.gravidade } else { "" }
    $versao = if ($reg.nomeVersao) { $reg.nomeVersao } elseif ($reg.versao) { $reg.versao } else { "" }
    $cadastro = if ($reg.CadastroPSAI) { $reg.CadastroPSAI } elseif ($reg.data_cadastro) { $reg.data_cadastro } else { "" }
    $situacao = if ($reg.situacaoSai) { $reg.situacaoSai } elseif ($reg.situacao) { $reg.situacao } elseif ($reg.status) { $reg.status } else { "" }

    # Enriquecimento
    $descEnriquecida = Truncar-Texto -Texto $descOriginal -MaxChars $MAX_DESCRICAO_CHARS
    $comportamento = Extrair-ComportamentoChave -Descricao $descOriginal
    $modulos = Extrair-ModulosImpactados -Descricao $descOriginal
    $gravidade = Classificar-Gravidade -GravidadeOriginal $gravOriginal -TipoSAI $tipo -Descricao $descOriginal

    $enriquecido = [PSCustomObject]@{
        id                   = $id
        psai                 = $idPsai
        tipo                 = $tipo
        descricao_enriquecida = $descEnriquecida
        comportamento_chave  = $comportamento
        modulos_impactados   = ($modulos -join "; ")
        gravidade            = $gravidade
        versao               = $versao
        data_cadastro        = $cadastro
        situacao             = $situacao
    }

    [void]$enriquecidos.Add($enriquecido)

    # Progresso a cada 1000 registros
    if ($contador % 1000 -eq 0) {
        Write-Host "  Processados: $contador / $($todosRegistros.Count)..." -ForegroundColor DarkGray
    }
}

Write-OK "$($enriquecidos.Count) registros enriquecidos"

# ---- ETAPA 4: Gerar arquivos de saida ----
Write-Etapa 4 5 "Gerando arquivos de saida"

# 4a: Indice JSON completo
Write-Info "Gerando indice JSON completo..."
$indiceCompletoPath = Join-Path $Destino "indice-enriquecido-completo.json"
$saida = @{
    gerado_em       = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    total_registros = $enriquecidos.Count
    fonte           = $FonteDados
    versao_script   = "2.4.0"
    dados           = @($enriquecidos)
}
$null = Smart-Write $indiceCompletoPath ($saida | ConvertTo-Json -Depth 4)
Write-OK "Indice completo: $indiceCompletoPath"

# 4b: Indices por tipo de SAI
Write-Info "Gerando indices por tipo..."
$tipos = $enriquecidos | Group-Object -Property tipo

foreach ($grupo in $tipos) {
    $tipoSlug = $grupo.Name.ToLower() -replace '[^a-z0-9]', '-'
    $tipoPath = Join-Path $Destino "por-tipo-$tipoSlug.json"

    $saidaTipo = @{
        gerado_em       = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        tipo            = $grupo.Name
        total_registros = $grupo.Count
        dados           = @($grupo.Group)
    }
    $null = Smart-Write $tipoPath ($saidaTipo | ConvertTo-Json -Depth 4)
    Write-Host "  Tipo $($grupo.Name): $($grupo.Count) registros -> $tipoSlug.json" -ForegroundColor DarkGray
}
Write-OK "$($tipos.Count) indices por tipo gerados"

# 4c: Indices por modulo impactado
Write-Info "Gerando indices por modulo..."
$modulosDir = Join-Path $Destino "por-modulo"
New-Item -ItemType Directory -Path $modulosDir -Force | Out-Null

$todosModulos = @{}
foreach ($reg in $enriquecidos) {
    $mods = $reg.modulos_impactados -split '; '
    foreach ($mod in $mods) {
        $mod = $mod.Trim()
        if (-not $mod) { continue }
        if (-not $todosModulos.ContainsKey($mod)) {
            $todosModulos[$mod] = [System.Collections.ArrayList]::new()
        }
        [void]$todosModulos[$mod].Add($reg)
    }
}

foreach ($modEntry in $todosModulos.GetEnumerator()) {
    $modSlug = ($modEntry.Key -replace '[^a-zA-Z0-9]', '-').ToLower() -replace '-+', '-' -replace '^-|-$', ''
    $modPath = Join-Path $modulosDir "$modSlug.json"

    $saidaMod = @{
        gerado_em       = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        modulo          = $modEntry.Key
        total_registros = $modEntry.Value.Count
        dados           = @($modEntry.Value)
    }
    $null = Smart-Write $modPath ($saidaMod | ConvertTo-Json -Depth 4)
    Write-Host "  Modulo '$($modEntry.Key)': $($modEntry.Value.Count) registros" -ForegroundColor DarkGray
}
Write-OK "$($todosModulos.Count) indices por modulo gerados"

# 4d: Indice por gravidade
Write-Info "Gerando indice por gravidade..."
$gravidades = $enriquecidos | Group-Object -Property gravidade

foreach ($g in $gravidades) {
    $gravSlug = ($g.Name -replace '[^a-zA-Z0-9]', '-').ToLower() -replace '-+', '-' -replace '^-|-$', ''
    if (-not $gravSlug) { $gravSlug = "sem-classificacao" }
    $gravPath = Join-Path $Destino "por-gravidade-$gravSlug.json"

    $saidaGrav = @{
        gerado_em       = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        gravidade       = $g.Name
        total_registros = $g.Count
        dados           = @($g.Group)
    }
    $null = Smart-Write $gravPath ($saidaGrav | ConvertTo-Json -Depth 4)
    Write-Host "  Gravidade '$($g.Name)': $($g.Count) registros" -ForegroundColor DarkGray
}
Write-OK "$($gravidades.Count) indices por gravidade gerados"

# 4e: Indice por comportamento-chave
Write-Info "Gerando indice por comportamento-chave..."
$comportamentos = $enriquecidos | Group-Object -Property comportamento_chave

foreach ($c in $comportamentos) {
    $compSlug = ($c.Name -replace '[^a-zA-Z0-9]', '-').ToLower() -replace '-+', '-' -replace '^-|-$', ''
    if (-not $compSlug) { $compSlug = "outro" }
    $compPath = Join-Path $Destino "por-comportamento-$compSlug.json"

    $saidaComp = @{
        gerado_em          = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        comportamento_chave = $c.Name
        total_registros    = $c.Count
        dados              = @($c.Group)
    }
    $null = Smart-Write $compPath ($saidaComp | ConvertTo-Json -Depth 4)
    Write-Host "  Comportamento '$($c.Name)': $($c.Count) registros" -ForegroundColor DarkGray
}
Write-OK "$($comportamentos.Count) indices por comportamento gerados"

# 4f: Resumo geral (navegacao)
Write-Info "Gerando resumo geral..."
$resumoPath = Join-Path $Destino "resumo.json"
$resumo = @{
    gerado_em       = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    total_registros = $enriquecidos.Count
    fonte           = $FonteDados
    destino         = $Destino
    versao_script   = "2.4.0"
    por_tipo        = @{}
    por_modulo      = @{}
    por_gravidade   = @{}
    por_comportamento = @{}
}

foreach ($t in $tipos) { $resumo.por_tipo[$t.Name] = $t.Count }
foreach ($m in $todosModulos.GetEnumerator()) { $resumo.por_modulo[$m.Key] = $m.Value.Count }
foreach ($g in $gravidades) { $resumo.por_gravidade[$g.Name] = $g.Count }
foreach ($c in $comportamentos) { $resumo.por_comportamento[$c.Name] = $c.Count }

$null = Smart-Write $resumoPath ($resumo | ConvertTo-Json -Depth 4)
Write-OK "Resumo geral gerado: $resumoPath"

# ---- ETAPA 5: Relatorio final ----
Write-Etapa 5 5 "Relatorio final"

$totalArquivosSaida = (Get-ChildItem -Path $Destino -Filter "*.json" -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count

Write-Host ""
Write-Host "  =============================================" -ForegroundColor Green
Write-Host "  |  INDICES ENRIQUECIDOS GERADOS!             |" -ForegroundColor Green
Write-Host "  =============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Registros processados: $($enriquecidos.Count)" -ForegroundColor White
Write-Host "  Arquivos de saida: $totalArquivosSaida" -ForegroundColor White
Write-Host "  Destino: $Destino" -ForegroundColor White
Write-Host ""
Write-Host "  Detalhes:" -ForegroundColor White
Write-Host "    - Por tipo: $($tipos.Count) grupos" -ForegroundColor DarkGray
Write-Host "    - Por modulo: $($todosModulos.Count) modulos" -ForegroundColor DarkGray
Write-Host "    - Por gravidade: $($gravidades.Count) niveis" -ForegroundColor DarkGray
Write-Host "    - Por comportamento: $($comportamentos.Count) padroes" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Smart-Write: $($script:smartEscritos) escritos, $($script:smartPulados) pulados (identicos)" -ForegroundColor DarkGray
Write-Host ""
