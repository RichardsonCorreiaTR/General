# Plano de Atualizacao v2 - SAIs/PSAIs

> Status: APROVADO
> Aprovado em: 07/03/2026
> Contexto: Discussao completa entre gerente e IA

---

## Requisitos Aprovados

1. IA mais assertiva nas pesquisas, cruzamentos e deteccao de duplicatas
2. Sincronizacao minima no OneDrive (so o necessario)
3. Atualizacao constante com uso inteligente de dados imoveis
4. RAM controlada (gerente e analista)

---

## Diagnostico (Estado Atual)

### Volumes
- Total registros: 29.296
- Monolitico: 165.4 MB (intermediario, analista nunca usa)
- PSAIs fracionados: 159.6 MB (12 arquivos)
- SAIs fracionados: 5.8 MB (12 arquivos)
- Indices MD: 4.5 MB (26 arquivos)
- Total sync OneDrive por execucao: ~335 MB

### Problemas identificados
- por-modulo.md (2 MB, 20K linhas): IA nao consegue ler (408% do contexto)
- 13 dos 20 modulos excedem limite seguro como lista plana
- FASE 2 do agente-produto esta QUEBRADA na pratica
- RAM pico: ~2 GB (monolitico carregado inteiro)
- Sync: 335 MB reescritos mesmo quando 96% nao mudou
- 3 indices orfaos nao gerados pelo script
- Atualizacao manual (gerente precisa lembrar)

### Divisao ativo vs imovel
- Pendentes (muda diariamente): ~14.5 MB
- Liberadas + Descartadas (muda raramente): ~151 MB
- ~5 PSAIs novas/dia, ~10 mudancas de status/dia

---

## Solucao: 4 Fases Independentes

### FASE 1: Indices Inteligentes + Classificacao Melhorada
**Risco: BAIXO | Impacto: ALTO**

#### 1A. Melhoria da Classificacao por Modulo

Problema atual: ~5335 SAIs (est. 40%) caem em "Nao Classificado".
Causa: classificacao usa APENAS keywords na descricao, ignora dados do SGD.

INVESTIGACAO CONCLUIDA (07/03/2026 - consulta ODBC + analise BuscaSaiFolha):
  - i_modulos = 19 (Folha) em 100% dos 35.307 registros. Zero variacao.
  - SGD NAO tem sub-classificacao dentro de Folha.
  - BuscaSaiFolha ja tinha descoberto isso e usava DICIONARIO_TAGS (87 tags
    por keyword matching). Mesma abordagem que nosso moduloKeywords, mas 4.5x
    mais granular.
  - Nivel 1 (classificacao via SGD) ELIMINADO. Impossivel.
  - Campo modulo_caminho pode ser REMOVIDO dos fracionados (nunca sera populado).

Melhoria em 2 niveis:

Nivel A - Keywords expandidas com base no BuscaSaiFolha:
  Fonte: DICIONARIO_TAGS do BuscaSaiFolha (87 tags com keywords).
  Acao: Absorver as 87 tags e agrupar em ~22 modulos.
  Exemplo de agrupamento:
    Modulo "eSocial" = eSocial + 31 eventos S-xxxx (S-1200, S-2299, etc.)
    Modulo "FGTS" = FGTS + FGTS Digital + SEFIP + GRRF
    Modulo "INSS" = INSS + GPS + PIS + RAT + FAP
    Modulo "Ferias" = Ferias + Ferias Coletivas + Abono Pecuniario
    Modulo "Calculo Mensal" = Calculo + Horas Extras + Adicional Noturno +
      Insalubridade + Periculosidade + Adiantamento + Banco de Horas + PLR + PPR
    (etc. para todos os 22 modulos)
  Modulos novos (nao existiam): Sindicato/CCT, Guias Fiscais, Integracao,
    Seguranca do Trabalho.
  Keywords em arquivo externo: banco-dados/config/modulos-keywords.json
  Nenhuma mudanca no extrair-sais.ps1 (nao precisa alterar SQL).

Nivel B - Multi-modulo:
  SAI sobre "FGTS retroativo" aparece em FGTS E em Retroativo/CCT.
  Uma SAI pode ter multiplos modulos. Arquivo de modulo lista suas SAIs.
  Aumenta visibilidade sem duplicar dados.

Meta: Nao Classificado de ~5335 para ~800-1500.
  (com 87 tags agrupadas em 22 modulos a cobertura e muito maior que as 19
  keywords originais, embora sem dados do SGD nao chegamos a <500)

#### 1B. Modulos Inteligentes

O que fazer:
- Criar pasta indices/modulos/ com ~22 arquivos inteligentes (19+3 novos)
- Cada modulo tem formato estruturado:
  - Todos pendentes DETALHADOS (5-26 KB conforme modulo)
  - 30 liberadas mais recentes (referencia)
  - Temas frequentes nas liberadas (resumo estatistico)
  - 10 descartadas mais recentes
  - Orientacao para busca completa
- Criar resumo-pendentes.md (5 KB): totais + top 20 novidades
- Corrigir 3 indices orfaos no script

Tamanho dos modulos (todos cabem no contexto):
- Maior: Nao Classificado = ~15-20 KB (com classificacao melhorada, antes 35 KB)
- Tipico: FGTS, INSS, Calculo = 10-15 KB (8-12%)
- Menor: Pensao, Beneficios, Sindicato = 5 KB (4%)
- Total ~22 modulos: ~220 KB (vs 2.041 KB do por-modulo.md)

Arquivos alterados:
- scripts/gerar-indices-sais.ps1 (classificacao + geracao modulos)

Arquivos criados:
- banco-dados/sais/indices/modulos/*.md (~22 arquivos)
- banco-dados/sais/indices/resumo-pendentes.md

Arquivos mantidos:
- por-modulo.md (legado, nao quebra nada)
- TODOS os indices flat existentes continuam (pendentes-ne-recentes.md, etc.)

Impacto projeto-filho: Dados chegam via OneDrive automaticamente.
Modulos novos ficam visiveis sem acao do analista.

### FASE 2: Smart Rewrite + Eliminar Monolitico
**Risco: MEDIO | Impacto: ALTO**

O que fazer:
- Smart rewrite: comparar conteudo antes de gravar.
  Se identico ao existente, nao reescreve.
- Eliminar monolitico do OneDrive: mover para scripts/cache/
- Refatorar extracao para gravar direto nos fracionados
- Refatorar geracao de indices para processar 1 fracionado por vez

Numeros:
- Sync por execucao: 335 MB -> ~92 MB (-73%)
- Arquivos reescritos: 58 -> ~35 (45 pulados)
- RAM pico: 2.0 GB -> 550 MB (-73%)
- Tempo: ~10 min -> ~3 min (-70%)

Arquivos alterados:
- scripts/extrair-sais.ps1 (gravar direto nos fracionados)
- scripts/gerar-indices-sais.ps1 (smart rewrite + processar por arquivo)
- scripts/importar-sais.ps1 (ajustar orquestracao)

Arquivos movidos:
- sai-psai-folha.json -> scripts/cache/ (fora do OneDrive)

Mitigacao: Flag --gerar-monolitico mantido como backup.

Impacto projeto-filho: ZERO (analistas nao usam monolitico).

### FASE 3: Automacao
**Risco: BAIXO | Impacto: ALTO**

O que fazer:
- Task Scheduler Windows:
  - Gatilho 1: Ao fazer logon
  - Gatilho 2: A cada 3h (8h, 11h, 14h, 17h)
  - Dias: Segunda a sexta
  - Acao: PowerShell silencioso (sem popup)
- Pre-check: ODBC disponivel? OneDrive rodando?
- Falha: loga erro, tenta na proxima janela
- Verificacao pos-execucao: confere arquivos e grava status.json

Arquivos criados:
- scripts/atualizar-silencioso.ps1
- scripts/agendar-atualizacao.ps1
- atualizacao/status.json
- atualizacao/log-importacao.txt

Impacto projeto-filho: Dados frescos a cada 3h, sem acao.

### FASE 4: Atualizar Projeto-Filho (Mecanismo via Cursor/IA)
**Risco: BAIXO | Impacto: ALTO**

Premissa central: o analista e LEIGO. Nao roda scripts. O Cursor/IA e o executor.
O analista cola 1 frase no Cursor. A IA le as instrucoes e faz tudo.

#### 4A. Preparar a estrutura de atualizacao

Criar no OneDrive (raiz do projeto admin):
  atualizacao/
    v1.1.0/
      input.md          <- Instrucoes para a IA do analista
      manifesto.json    <- O que mudou (maquina-legivel)
      arquivos/         <- Conteudo exato dos arquivos novos/alterados
        .cursor/
          rules/
            agente-produto.mdc  <- Regra atualizada (FASE 2 com modulos)
            guardiao.mdc        <- Regra com verificacao de dados novos
        config/
          VERSION.json          <- v1.1.0

O input.md segue formato estruturado:
  1. O que mudou (humano-legivel)
  2. Backup obrigatorio (analista.json, caminhos.json)
  3. Tabela: origem -> destino (cada arquivo)
  4. Lista de arquivos NAO TOCAR
  5. Verificacao pos-atualizacao
  6. Nota sobre reabrir Cursor

#### 4B. Novo symlink no projeto-filho

Adicionar ao setup/instalador:
  referencia/atualizacao/ -> {onedrive_base}/atualizacao/

Isso permite a IA do analista ler:
  referencia/atualizacao/v1.1.0/input.md
  referencia/atualizacao/v1.1.0/arquivos/*

Arquivos alterados:
- scripts/instalar-projeto-filho.ps1 (criar symlink atualizacao)
- scripts/corrigir-symlinks.ps1 (incluir atualizacao)
- projeto-filho/CORRECAO-SYMLINKS.md (documentar symlink)
- projeto-filho/SETUP.md (mencionar symlink)

#### 4C. Atualizar regras da IA

agente-produto.mdc - FASE 2 (Contexto):
  ANTES: "Busque em referencia/banco-dados/sais/indices/"
  DEPOIS: Instrucao explicita em 3 passos:
    1. Abrir referencia/banco-dados/sais/indices/resumo-pendentes.md
    2. Identificar modulos relevantes ao assunto
    3. Abrir referencia/banco-dados/sais/indices/modulos/{modulo}.md
    4. Cruzar com modulos adjacentes (ex: FGTS -> olhar INSS e eSocial)

guardiao.mdc - Verificacao de atualizacao (adicionar):
  Na primeira interacao do dia:
  1. Ler config/VERSION.json (versao local)
  2. Ler referencia/atualizacao/ para encontrar a pasta de versao mais recente
  3. Se versao disponivel > local:
     "Ha uma atualizacao (vX.Y.Z). Posso atualizar para voce?"
  4. Se analista aceitar: ler input.md e executar passo a passo
  5. Backup -> copiar arquivos -> preservar dados pessoais -> confirmar

guardiao.mdc - Verificacao de dados novos (adicionar):
  Na primeira interacao do dia:
  1. Ler referencia/atualizacao/status.json (ultima importacao de SAIs)
  2. Se data > ultima verificacao: "Dados de SAIs atualizados em {data}."
  3. Isso e passivo (nao exige acao do analista), so informa.

#### 4D. Replicar em distribuicao/

Atualizar distribuicao/ultima-versao/ com:
- .cursor/rules/agente-produto.mdc (nova versao)
- .cursor/rules/guardiao.mdc (nova versao)
- config/VERSION.json (1.1.0)
- MANIFESTO-UPDATE.json (changelog)
- SETUP.md (atualizado com novo symlink)
- CORRECAO-SYMLINKS.md (atualizado)
- scripts/corrigir-symlinks.ps1 (atualizado)

Manter atualizar-projeto.ps1 como fallback (para quem preferir script).

#### 4E. Comunicacao (Teams)

Mensagem padrao:
  "Atualizacao v1.1.0 disponivel.
   O que mudou: indices de SAIs mais inteligentes, busca melhorada.
   Para atualizar, abra o Cursor e diga:
   'Atualize meu projeto conforme referencia/atualizacao/'
   A IA faz o resto."

Arquivos criados:
- atualizacao/v1.1.0/input.md
- atualizacao/v1.1.0/manifesto.json
- atualizacao/v1.1.0/arquivos/* (copia dos arquivos atualizados)

Arquivos alterados:
- projeto-filho/.cursor/rules/agente-produto.mdc
- projeto-filho/.cursor/rules/guardiao.mdc
- projeto-filho/config/VERSION.json -> 1.1.0
- projeto-filho/SETUP.md
- projeto-filho/CORRECAO-SYMLINKS.md
- scripts/instalar-projeto-filho.ps1
- scripts/corrigir-symlinks.ps1
- distribuicao/ultima-versao/* (replicado)

Impacto: Analista cola 1 frase no Cursor. IA executa. Zero scripts manuais.

---

## Garantias por Requisito

### REQ 1: IA Assertiva
- ~22 modulos de 5-20 KB cabem TODOS no contexto (max 15%)
- IA le 3 modulos + resumo = 20% do contexto. Sobra 80%.
- Cruzamento FGTS + INSS = 15% do contexto. Funciona.
- Classificacao melhorada (keywords BuscaSaiFolha + multi-modulo):
  - 87 tags agrupadas em 22 modulos (~80-90% classificadas)
  - Nao Classificado estimado: ~800-1500 (vs 5335 atual)
  - Melhoria significativa sobre os 60% atuais
- Multi-modulo: SAI aparece em todos os modulos relevantes (nao perde cruzamento)
- Keywords externalizadas em modulos-keywords.json (facil manutencao)
- Todos pendentes do modulo visiveis = deteccao de duplicatas
- 30 liberadas recentes = referencia de solucoes passadas
- Temas frequentes = inteligencia estatistica
- Cruza com regras-negocio/ = identifica gaps
- Cada SAI e informacao valiosa: classificacao maximiza aproveitamento

### REQ 2: Sync Minimo
- 335 MB -> ~92 MB por execucao (-73%)
- 45 arquivos pulados (conteudo identico)
- Monolitico eliminado do OneDrive (-165 MB fixos)
- Modulos: 200 KB total vs 2.041 KB antigo (-85% indices)
- Mensal: 7.2 GB -> 4.3 GB (-3 GB/mes)

### REQ 3: Atualizacao Constante
- Task Scheduler: logon + cada 3h (seg-sex)
- Incremental: ~15 registros, ~3 min, ~100 MB RAM
- Imoveis: so reescritos quando recebem registro novo
- status.json: registro de ultima execucao

### REQ 4: RAM Controlada
- Gerente: 2.0 GB -> 550 MB (-73%)
- Incremental: ~100-200 MB
- Analista Cursor: modulos de 5-35 KB vs 2 MB
- .cursorignore bloqueia dados-brutos/
- Contexto IA: nunca estoura (max 27% por modulo)

---

## Riscos e Mitigacao

| Fase | Risco | Mitigacao |
|------|-------|----------|
| 1 (indices) | BAIXO - adiciona, nao quebra | Indices antigos mantidos |
| 2 (smart+mono) | MEDIO - muda core | Flag --gerar-monolitico backup |
| 3 (automacao) | BAIXO - cria novo | Nao altera scripts existentes |
| 4 (projeto-filho) | BAIXO - melhora regras | Versao anterior funciona |

Pior cenario: Fase 2 falha -> volta ao monolitico.
Todas as outras fases continuam funcionando.
Fases sao independentes: executar e validar 1 por vez.

---

## Mapa de Impacto no Projeto-Filho

### O que muda AUTOMATICAMENTE (via OneDrive, sem acao do analista)
- banco-dados/sais/indices/modulos/*.md (novos, aparecem via symlink)
- banco-dados/sais/indices/resumo-pendentes.md (novo)
- banco-dados/sais/indices/* (indices existentes continuam atualizando)
- atualizacao/status.json (metadados da importacao)

### O que muda COM ATUALIZACAO (Fase 4, via Cursor/IA)
- .cursor/rules/agente-produto.mdc (regra da IA atualizada)
- .cursor/rules/guardiao.mdc (regra da IA atualizada)
- config/VERSION.json (1.0.0 -> 1.1.0)

### O que NAO muda (preservado em qualquer cenario)
- config/analista.json (dados pessoais)
- config/caminhos.json (paths locais)
- meu-trabalho/ (trabalho do analista)
- templates/ (nao muda nesta versao)

### Novo symlink necessario (uma vez, via corrigir-symlinks.ps1 ou IA)
- referencia/atualizacao/ -> {onedrive_base}/atualizacao/

---

## Execucao

Ordem: Fase 1 -> Fase 2 -> Fase 3 -> Fase 4
Validar cada fase antes de prosseguir.
Fase 4 so apos todas as anteriores validadas.

Analistas com projeto ja instalado:
- Fases 1-3: impacto automatico (dados novos via OneDrive)
- Fase 4: atualizar via Cursor/IA (1 frase) ou script (fallback)
