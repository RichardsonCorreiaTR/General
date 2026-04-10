# SDD Decisoes — Registro de Decisoes Arquiteturais (ADR)

## Metadados

| Campo | Valor |
|---|---|
| **ID** | SDD-ADR-001 |
| **Titulo** | Registro de decisoes arquiteturais do projeto |
| **Data** | 2026-03-04 |
| **Versao** | 1.0 |

---

## ADR-001: Projeto vive no OneDrive/SharePoint

**Data**: 2026-03-04
**Status**: Aceita
**Contexto**: 17 analistas precisam acessar a base de conhecimento.
**Decisao**: Todo o projeto vive na pasta OneDrive `CursorEscrita - General` (migrado de Folha; validar URL SharePoint com a TI).
**Alternativas consideradas**:
- Git/GitHub: descartado — analistas nao tem conhecimento tecnico de Git
- Pasta de rede: descartado — sem acesso remoto
- SharePoint puro (web): descartado — nao integra com Cursor
**Consequencia**: OneDrive sincroniza automaticamente, mas tem limitacoes de
escrita (resolvido com regra onedrive-escrita.mdc) e de volume de arquivos.

---

## ADR-002: Dados pesados no OneDrive mas ignorados pelo Cursor

**Data**: 2026-03-04
**Status**: Aceita (3a iteracao)
**Contexto**: JSON de SAIs (~165MB) e codigo PB (~165MB, 5.584 arquivos) causam OOM.
**Historico de decisoes**:
1. v1: Tudo no OneDrive → OOM (3 crashes)
2. v2: Tudo em pasta local fora do OneDrive → analistas sem acesso
3. v3 (atual): JSON no OneDrive em `dados-brutos/`, excluido via `.cursorignore`
**Decisao final**: JSON fica no OneDrive (analistas acessam), Cursor nao indexa.
Codigo PB fica local (volume inviavel para sync de 17 pessoas).
**Consequencia**: `.cursorignore` e critico. Se removido, OOM volta.

---

## ADR-003: JSONs fracionados por tipo e status

**Data**: 2026-03-04
**Status**: Aceita
**Contexto**: JSON unico de 165MB e pesado para busca e sync.
**Decisao**: Fracionar em 24 JSONs (12 psai/ + 12 sai/) por tipo x status.
**Alternativas consideradas**:
- Manter JSON unico: descartado — sync lento, busca consome muita RAM
- Banco SQLite: descartado — analistas nao tem ferramentas
- CSV: descartado — perde estrutura
**Consequencia**: `buscar-sai.ps1` carrega apenas o JSON relevante (~5-46MB).

---

## ADR-004: PowerShell como linguagem de automacao

**Data**: 2026-03-04
**Status**: Aceita
**Contexto**: Precisa de scripts para importar dados, gerar indices, automatizar.
**Decisao**: PowerShell para todos os scripts.
**Alternativas consideradas**:
- Python: descartado — nao instalado em todas as maquinas
- Node.js: descartado — mesma razao
- BAT puro: descartado — limitado demais
**Consequencia**: Funciona em qualquer Windows sem instalar nada.

---

## ADR-005: Projeto Filho como pacote independente

**Data**: 2026-03-04
**Status**: Aceita
**Contexto**: Analistas nao podem alterar o projeto principal.
**Decisao**: Criar `projeto-filho/` com copia dos templates, regras proprias
da IA, e symlink para `banco-dados/` do OneDrive.
**Alternativas consideradas**:
- Analistas abrem o projeto principal: descartado — risco de alteracao
- Branch Git por analista: descartado — analistas nao usam Git
- Workspace separado no Cursor: viavel mas menos controlavel
**Consequencia**: Analista le do OneDrive (via symlink) e escreve localmente.
Submissoes vao para `para-revisao/`.

---

## ADR-006: Regras .mdc como governanca da IA

**Data**: 2026-03-04
**Status**: Aceita
**Contexto**: A IA precisa seguir regras do projeto sem que o usuario repita.
**Decisao**: 11 regras .mdc em `.cursor/rules/`, sendo 4 alwaysApply e 7
condicionais (por glob). 4 agentes SDD especificos.
**Alternativas consideradas**:
- Prompt fixo no chat: descartado — perde contexto entre sessoes
- Arquivo AGENTS.md: possivel mas menos granular
**Consequencia**: IA segue automaticamente guardiao, protecao OOM, padroes.

---

## ADR-007: Fluxo de revisao formalizado

**Data**: 2026-03-04
**Status**: Aceita
**Contexto**: Definicoes dos analistas precisam ser revisadas antes de entrar na base.
**Decisao**: Fluxo: submeter → pendente → aprovar/devolver. Script
`revisar-definicao.ps1` com log em `logs/revisao.log`.
**Alternativas consideradas**:
- Revisao informal por chat: descartado — sem rastreabilidade
- GitHub PR: descartado — analistas nao usam Git
**Consequencia**: Toda acao de revisao e rastreavel no log.

---

## ADR-008: Templates obrigatorios

**Data**: 2026-03-04
**Status**: Aceita
**Contexto**: Padronizar formato das definicoes de todos os analistas.
**Decisao**: 4 templates em `templates/`. IA instruida (sdd-definicao.mdc)
a recusar definicoes fora do template.
**Templates admin**: regra-negocio, fluxo-processo, analise-impacto, glossario.
**Templates projeto-filho**: TEMPLATE-psai.md, TEMPLATE-sai.md (ver ADR-010).
**Consequencia**: Consistencia. Analistas nao criam formatos ad-hoc.

---

## ADR-009: Framework de Analise de Produto com BDD interno

**Data**: 2026-03-04
**Status**: Aceita
**Contexto**: O projeto-filho precisa de um processo mais sofisticado para ajudar
analistas a criar definicoes de alta qualidade. O modelo anterior (template simples
+ preenchimento guiado) nao garantia cobertura completa de cenarios.
**Decisao**: Adotar um framework de analise de produto onde:
- BDD/Gherkin e usado como motor INTERNO de pensamento da IA (Given/When/Then)
- A saida para o analista e sempre no formato tradicional (PSAI ou SAI)
- Um agente orquestrador (`agente-produto.mdc`) conduz 7 fases: recepcao, contexto,
  codigo, cenarios, dialogo, definicao, qualidade
- Um agente de codigo (`agente-codigo.mdc`) traduz analise tecnica para linguagem de produto
- Templates novos: `TEMPLATE-psai.md` e `TEMPLATE-sai.md`
- Naming baseado em codigos PSAI/SAI: `PSAI-119453-descricao.md`, `SAI-95069-tipo-descricao.md`
**Alternativas consideradas**:
- BDD como formato de saida: descartado -- analistas usam formato PSAI/SAI tradicional
- Manter SDD simples: descartado -- nao garante cobertura de cenarios e edge cases
- Ferramentas externas de BDD: descartado -- complexidade desnecessaria
**Consequencia**: Analistas criam definicoes com cobertura muito superior de cenarios.
O formato de saida nao muda (PSAI/SAI tradicional). O `TEMPLATE-regra-negocio.md`
e o `sdd-definicao.mdc` do projeto-filho foram deprecados.

---

## ADR-010: Templates PSAI e SAI substituem Template de Regra no projeto-filho

**Data**: 2026-03-04
**Status**: Aceita
**Contexto**: O template unico de regra de negocio (RN) nao distinguia entre
pre-analise (PSAI) e definicao detalhada (SAI), que sao etapas diferentes do processo.
**Decisao**: Criar dois templates no projeto-filho:
- `TEMPLATE-psai.md`: pre-analise com cenarios e areas de impacto
- `TEMPLATE-sai.md`: definicao detalhada com secoes GERAL/PROCESSOS/ARQUIVO/CONTROLE/RELATORIOS
O `TEMPLATE-regra-negocio.md` no projeto-filho foi marcado como obsoleto.
No projeto admin, os 4 templates originais (RN, FL, AI, glossario) continuam validos.
**Consequencia**: Projeto-filho usa PSAI/SAI. Projeto admin mantém RN para legado.
Ambos convivem na mesma base de revisao (`revisao/pendente/`).

---

## ADR-011: Consolidacao de 7 agentes em 5 no projeto-filho (v1.1.0)

**Data**: 2026-03-10
**Status**: Aceita
**Contexto**: O design original (v1.0) previa 7 agentes especializados para o
projeto-filho: Produto, Codigo, Definicao, Revisao, Impacto, Consolidacao e
Projeto-SDD. Na pratica, agentes com escopo muito estreito (Revisao, Impacto,
Consolidacao) raramente eram acionados isoladamente e fragmentavam o fluxo de
trabalho do analista. O redesign v1.1.0 identificou que funcoes de revisao,
impacto e consolidacao sao etapas naturais dentro do processo de analise, nao
agentes autonomos.
**Decisao**: Consolidar para 5 agentes no projeto-filho:

| Agente v1.1.0 | Tipo | Absorveu de |
|---|---|---|
| guardiao.mdc | alwaysApply | Funcoes de validacao do agente-revisao + metricas do agente-consolidacao |
| onboarding.mdc | alwaysApply | Novo (primeiro uso e dicas contextuais) |
| projeto.mdc | alwaysApply | Versao simplificada do agente-projeto-sdd |
| agente-produto.mdc | sob demanda | Absorveu agente-definicao + analise de impacto do agente-impacto |
| agente-codigo.mdc | sob demanda | Mantido (investigacao de codigo-fonte) |

Adicionalmente, o pipeline rigido de 7 fases foi substituido por 3 rotas
adaptativas: Rota NE (5 passos), Rota SA (6 passos) e Rota SS (4 passos).
As 7 etapas genericas (RECEPCAO a QUALIDADE) continuam como visao didatica
simplificada no GUIA-RAPIDO.md.

**Alternativas consideradas**:
- Manter 7 agentes: descartado — fragmentacao, agentes pouco acionados,
  dificuldade de manutencao
- Reduzir para 3 (guardiao, produto, codigo): descartado — onboarding e
  contexto do projeto sao necessarios como agentes separados
**Consequencia**: Projeto-filho tem 5 .mdc + 1 obsoleto (sdd-definicao.mdc).
A documentacao em `agentes/` mantém os 7 docs originais com cabecalho
indicando status (ativo ou consolidado). O projeto admin mantém seus
proprios agentes SDD (sdd-revisao, sdd-impacto, sdd-definicao, sdd-projeto)
que servem ao gerente, nao ao analista.

**Referencia** (arquivado em obsoleto): `banco-dados/obsoleto/planejamento-v1.1.0-2026-04-10/agentes/agentes/MAPA-AGENTES.md`,
`banco-dados/obsoleto/planejamento-v1.1.0-2026-04-10/agentes/agentes/VALIDACAO-DORES.md` (D9)

---

## ADR-012: Modulos do sistema — 12 principais com 24 categorias indexadas

**Data**: 2026-03-10
**Status**: Aceita
**Contexto**: O PROJETO.md listava 12 modulos do sistema de Folha; o projeto migrou
para **Escrita Fiscal**. Os indices de SAIs (`banco-dados/sais/indices/modulos/`)
podem ainda usar categorias herdadas da classificacao Folha ate revisao do time.
**Decisao**: Atualizar taxonomia de modulos Escrita no `PROJETO.md` e em
`modulos-keywords.json` quando o mapa oficial estiver fechado. Ate la, tratar
categorias dos indices como **aproximacao** para busca.
**Consequencia**: Documentos de alto nivel referem Escrita; indices podem precisar
regeneracao/ajuste de palavras-chave apos importar SAIs da area Escrita.

---


## ADR-013: Sistema de Tasks para rastreamento de demandas (v1.2.0)

**Contexto**: O agente-produto conduz analises em rotas (NE/SA/SS) com passos
definidos, mas o estado da analise vive apenas na memoria do chat. Se o analista
fecha o Cursor, perde o contexto e precisa recontar tudo.
**Decisao**: Implementar sistema de tasks que persiste o estado de cada demanda
em JSON (`meu-trabalho/tasks/{codigo}-{descricao}.json`). O agente cria, atualiza
e conclui tasks silenciosamente. O guardiao detecta tasks em andamento e oferece
retomada. Consultas rapidas nao criam task.
**Alternativas descartadas**: (1) Salvar estado no log -- logs sao write-only,
nao servem para retomada. (2) Usar meu-trabalho/em-andamento/ -- pasta ja usada
para artefatos PSAI/SAI, misturar com metadados de estado poluiria o fluxo.
**Consequencia**: Retomada de analises entre chats, visibilidade de demandas
em andamento, base para metricas futuras. Nao altera o fluxo das rotas.

---


| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 1.0 | 2026-03-04 | Agente IA + Gerente | Criacao com 8 ADRs |
| 1.1 | 2026-03-04 | Agente IA | ADR-009 e ADR-010: framework BDD e templates PSAI/SAI |
| 1.2 | 2026-03-10 | Agente IA + Gerente | ADR-011: consolidacao agentes 7→5; ADR-012: modulos 12+24 |

| 1.3 | 2026-03-10 | Agente IA + Gerente | ADR-013: sistema de tasks para rastreamento de demandas |
