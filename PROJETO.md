# PROJETO — Escrita SDD: Gestão de Definições de Produto

> **ATENÇÃO AGENTE**: Este arquivo é o blueprint mestre do projeto. Nunca leia inteiro.
> Use busca (Grep) para encontrar a seção relevante. Cada seção é autossuficiente.

---

## 1. O que é este projeto

Este é o **Projeto Admin** do Escrita SDD — um sistema de gestão de definições de
regras de negócio para o módulo **Escrita Fiscal** (Domínio Contábil), usando a metodologia
Spec-Driven Development (SDD).

**Não é um projeto de código.** É um projeto de gestão de conhecimento de produto.

O objetivo é que um time de ~17 analistas de produto consiga:
- Definir regras de negócio de forma padronizada
- Consultar regras existentes antes de criar novas
- Identificar impactos cruzados entre definições
- Manter histórico rastreável de todas as decisões
- Reduzir erros, retrabalho e críticas graves

---

## 2. Papéis

| Papel | Quem | Projeto | Permissão |
|---|---|---|---|
| Orquestrador | Gerente de Produto | Projeto Admin (este) | Leitura + Escrita total |
| Executor | Analista de Produto (~17) | Projeto Filho | Escrita na sua pasta, leitura no resto |
| Validador | Agentes IA (Cursor) | Ambos | Conforme regras .mdc |

---

## 3. Estrutura de pastas

```
CursorEscrita - General/            ← PROJETO ADMIN (este)
├── .cursor/rules/                  ← Regras de comportamento da IA
├── PROJETO.md                      ← Este arquivo (blueprint mestre)
├── arquitetura/                    ← Documentação de arquitetura
├── banco-dados/                    ← Base de conhecimento oficial
│   ├── regras-negocio/{dominio}/   ← Dominios Escrita (ver regras-negocio/README.md)
│   ├── glossario/                  ← Termos padronizados
│   ├── fluxos/                     ← Fluxos de processos
│   ├── legislacao/                 ← Base legal
│   ├── dados-brutos/                ← Cache pesado (ignorado pelo Cursor via .cursorignore)
│   │   ├── sai-psai-escrita.json   ← Cache completo de SAIs (~165MB)
│   │   └── situacoes.json          ← Mapa de situações
│   ├── sais/                       ← SAIs/PSAIs (area PBCVS Escrita)
│   │   └── indices/                ← Índices MD navegáveis (gerados por script)
│   ├── codigo-sistema/             ← Referência ao código-fonte
│   │   ├── REFERENCIA.md           ← Aponta para código PB local (do gerente)
│   │   ├── META.json               ← Metadados da versão atual
│   │   └── changelog/              ← Registro de atualizações de versão
│   ├── sdd-construcao.md           ← SDD de construção do projeto
│   ├── obsoleto/                   ← Taxonomia Folha e artefatos arquivados (somente leitura)
│   └── mapa-sistema/              ← Mapas, pbl-area-escrita.json (618 PBLs), indice-arquivos
├── scripts/                        ← Scripts de automação
│   ├── atualizar-tudo.bat          ← Atalho: importa SAIs + atualiza código
│   ├── importar-sais.ps1           ← Importa SAIs (ODBC ou BuscaSAI em Programas)
│   ├── gerar-indices-sais.ps1      ← Fraciona JSON e gera índices Markdown
│   ├── atualizar-codigo.ps1        ← Atualiza código-fonte (local ou GitHub)
│   ├── gerar-indice-codigo.ps1     ← Gera índice navegável de arquivos PB por PBL
│   ├── buscar-sai.ps1              ← Busca SAIs no cache por termo/módulo
│   ├── revisar-definicao.ps1       ← Fluxo de revisão: listar/aprovar/devolver
│   ├── gerar-atualizacao.ps1       ← Gera pacote de atualização do projeto filho
│   ├── instalar-projeto-filho.ps1  ← Instalador do projeto filho na máquina do analista
│   ├── consolidar-logs.ps1          ← Gera resumo semanal/mensal dos logs dos analistas
│   ├── arquivar-logs.ps1           ← Arquiva logs antigos (>30 dias) para logs/arquivo/
│   ├── setup-odbc.ps1              ← Configura DSN ODBC pbcvs9
│   └── lib-lock.ps1                ← Biblioteca de lock para evitar concorrência
├── templates/                      ← Templates obrigatórios
├── agentes/                        ← Documentacao dos agentes (SDD + produto)
├── revisao/                        ← Fluxo de aprovação
│   ├── pendente/                   ← Aguardando revisão do gerente
│   ├── aprovado/                   ← Aprovado (pronto para banco-dados)
│   └── devolvido/                  ← Devolvido com feedback
├── logs/                           ← Atividades do time (ver `logs/README.md`: ponte com `referencia/logs/` do filho)
│   ├── analistas/{nome}/           ← Log por analista por dia (entrada do consolidar-logs.ps1)
│   └── consolidado/               ← Resumos semanais
├── analises-ia/                    ← Análises sob demanda
└── projeto-filho/                  ← Pacote para distribuir aos analistas
```

---

## 4. Metodologia SDD aplicada

### Fluxo de definicao (Projeto Admin -- RNs)

```
1. CONSULTAR   → Gerente lê banco-dados/ e definições dos analistas
2. DEFINIR     → Preenche template RN na pasta de trabalho
3. VALIDAR     → IA cruza com regras existentes e identifica impactos
4. PUBLICAR    → Move para banco-dados/regras-negocio/{dominio-escrita}/
```

### Fluxo de analise de produto (Projeto Filho -- PSAIs/SAIs)

Visao simplificada do processo de analise:

```
1. RECEPCAO    → Analista traz demanda (NE/SAM/SAL) com codigo
2. CONTEXTO    → IA busca SAIs relacionadas e definicoes existentes
3. CODIGO      → IA analisa codigo-fonte e traduz para linguagem de produto
4. CENARIOS    → IA gera cenarios BDD internamente para cobertura completa
5. DIALOGO     → Analista e IA refinam cenarios juntos
6. DEFINICAO   → IA gera PSAI ou SAI no formato tradicional
7. QUALIDADE   → IA revisa completude e clareza
```

Na pratica, o agente-produto adapta o processo por tipo de demanda:
- **Rota NE** (correcao de erro): 5 passos
- **Rota SA** (funcionalidade nova): 6 passos
- **Rota SS** (suporte N3): 4 passos
- **Consulta rapida**: atendimento direto

### Rastreamento de demandas via tasks (v1.2.0)

Cada analise em rota gera uma task persistente em `meu-trabalho/tasks/`.
A task registra rota, passo atual, achados, artefatos e pendencias.
Se o analista fecha e reabre o Cursor, o guardiao detecta tasks em andamento
e oferece retomar de onde parou. Consultas rapidas nao criam task.
Ver ADR-013 em `banco-dados/sdd-decisoes.md`.

Apos o fluxo de analise, o analista:
- Finaliza em `meu-trabalho/concluido/` (task marcada como concluida)
- Preenche e submete no SGD (via especialista)
- Gerente revisa e consolida na base

> **Nota**: BDD/Gherkin e usado como motor interno de pensamento da IA
> (Given/When/Then) para garantir cobertura completa de cenarios.
> O analista ve analise inteligente e recebe PSAI/SAI no formato tradicional.

### Fluxo de melhoria contínua do projeto (Meta-SDD)

```
1. ANALISAR    → Agente SDD-Projeto revisa a arquitetura atual
2. IDENTIFICAR → Encontra gargalos, inconsistências, melhorias
3. PROPOR      → Sugere mudanças com justificativa
4. VALIDAR     → Gerente aprova a melhoria
5. APLICAR     → Agente implementa a melhoria no projeto
```

---

## 5. Conexão com OneDrive/SharePoint

**SharePoint**: https://trten.sharepoint.com/sites/CursorEscrita/Shared%20Documents/General

**Sincronização local**: O OneDrive sincroniza automaticamente para a máquina de cada
pessoa. A pasta local é mapeada em:
`C:\Users\{usuario}\Thomson Reuters Incorporated\CursorEscrita - General`

> **Nota**: Se o site SharePoint ainda não existir, crie a biblioteca ou ajuste a URL com a TI; até lá pode manter um atalho local espelhado do repositório em `C:\1 - A\B\Programas\General`.

### Dados no OneDrive (acessíveis a todos)

| Dado | Local | Sync |
|---|---|---|
| Índices, glossário, mapa, templates | `banco-dados/` | Automático |
| Cache JSON de SAIs (~165MB) | `banco-dados/dados-brutos/` | Automático |
| Scripts de atualização | `scripts/` | Automático |

O `.cursorignore` na raiz impede o Cursor de indexar `dados-brutos/`, prevenindo OOM.

### Dados locais (só do gerente)

| Dado | Local | Motivo |
|---|---|---|
| Código PB (módulo Escrita) | `EscritaSDD-dados-pesados\versao-atual\` ou `C:\CursorEscrita\codigo-sistema\` | Volume inviável para sync em massa |

Analistas consultam o `mapa-sistema/` e pedem ao gerente se precisarem de arquivo específico.

### Atualização

O gerente (ou backup designado) roda `scripts\atualizar-tudo.bat` em terminal separado.
Resultado sincroniza via OneDrive para todos. Ver `banco-dados/sdd-construcao.md`.

### Fluxo de dados

```
ADMIN (Gerente)                  OneDrive                    ANALISTA
                                                              
banco-dados/ ──────sync──────→  pasta compartilhada  ←──sync── (leitura)
                                                              
revisao/pendente/ ←──sync────  pasta compartilhada  ──sync──→ (escrita)
                                                              
logs/analistas/ ←──sync──────  pasta compartilhada  ──sync──→ (escrita)
```

---

## 6. Módulos e áreas (Escrita Fiscal)

No **PBCVS**, SAIs/PSAIs do módulo usam `nomeArea = 'Escrita'`. A extração ODBC e o
cache local (`sai-psai-escrita.json`) referem-se a essa área.

**Repositório de dados e Git:** clone em `C:\1 - A\B\Programas\BuscaSAI`
(RichardsonCorreiaTR/BuscaSAI no GitHub corporativo). O mesmo projeto gera também
JSONs para **Importação** e **Onvio Escrita**; este SDD admin usa por padrão a
área **Escrita** (alinhado a `tools/extrair-escrita` no BuscaSAI).

A taxonomia Folha (`calculo/`, `ferias/`, etc.) foi **arquivada** em
`banco-dados/obsoleto/regras-negocio-taxonomia-folha-2026-04-09/`. Novas regras vao para
os **dominios Escrita** em `regras-negocio/` (veja `regras-negocio/README.md`), alinhados ao
**mapa do sistema** (`mapa-escrita.md`, `indice-mapas-areas.md`).

Os **índices de SAIs** usam dominios Escrita em `banco-dados/config/modulos-keywords.json`
(v2). Regeneracao: `banco-dados/config/README.md`. Backup da taxonomia Folha:
`modulos-keywords.v1-folha.backup.json`. Palavras-chave e modulos podem ainda refletir Folha;
revisar o JSON **depois** de reimportar SAIs de Escrita, Importacao e Onvio Escrita.

---

## 7. Regras de otimização (tokens/memória/OOM)

1. **Este arquivo (PROJETO.md)**: Nunca ler inteiro. Buscar a seção necessária.
2. **banco-dados/**: Ler apenas o módulo relevante para a tarefa.
3. **Templates**: Ler apenas o template que será usado.
4. **Logs**: Nunca ler todos. Ler apenas o analista/período solicitado.
5. **Regras .mdc**: Máximo 100 linhas cada. Se passar, dividir.
6. **Definições**: Máximo 300 linhas cada. Se passar, dividir em partes.
7. **.cursorignore**: Exclui `banco-dados/dados-brutos/`, logs, análises-ia.
8. **Sempre confirmar antes de tarefas complexas**: Listar o que será feito.
9. **NUNCA** carregar o JSON de `dados-brutos/` no terminal do Cursor (causa OOM).
10. **Scripts pesados** devem ser rodados em terminal separado, fora do Cursor.

---

## 8. Como rodar

### Pre-requisitos de ambiente

| Requisito | Projeto Admin | Projeto Filho |
|-----------|:---:|:---:|
| Cursor IDE | Obrigatorio | Obrigatorio |
| Git | Obrigatorio | Obrigatorio |
| OneDrive / SharePoint | Obrigatorio | Obrigatorio |
| PowerShell 5.1+ | Obrigatorio | Obrigatorio |
| ODBC SQL Anywhere | Opcional | Opcional |
| Caminho `C:\CursorEscrita\` | - | Padrao (configuravel no instalador) |

O projeto filho e instalado por padrao em `C:\CursorEscrita\projeto-filho` e o
codigo-fonte em `C:\CursorEscrita\codigo-sistema\versao-atual`. Esses caminhos
podem ser alterados via parametros do instalador (`-ProjetoDir`, `-CodigoDir`)
e ficam registrados em `config/caminhos.json`.

### Para o Gerente (Projeto Admin)
1. Abrir o Cursor na pasta `CursorEscrita - General` (via OneDrive) ou no clone local em `C:\1 - A\B\Programas\General`
2. As regras .mdc carregam automaticamente
3. Na primeira vez, rodar `scripts\atualizar-tudo.bat` em **terminal separado** (fora do Cursor)
4. Usar o chat para interagir com os agentes SDD (definicao, revisao, impacto, projeto)
5. Periodicamente rodar `atualizar-tudo.bat` para atualizar SAIs e codigo
6. Revisar definicoes: `.\scripts\revisar-definicao.ps1 -Acao listar`
7. Gerar pacote de atualizacao: `.\scripts\gerar-atualizacao.ps1 -Versao "X.Y.Z" -Changelog "desc"`
8. Consolidar logs: `.\scripts\consolidar-logs.ps1 -Periodo semana` (requer `.md` em `logs/analistas/`; formato em `logs/README.md`)
9. Arquivar logs antigos: `.\scripts\arquivar-logs.ps1` (ou `-SimularApenas` para testar)

### Para o Analista (Projeto Filho)
1. Analista recebe o instalador e roda: `powershell -File scripts\instalar-projeto-filho.ps1`
2. Abre o Cursor na pasta `C:\CursorEscrita\projeto-filho`
3. O onboarding automatico guia o analista nas primeiras etapas
4. Uso diario: explorar base de conhecimento, analisar demandas, confrontar codigo
5. A IA conduz a analise completa e gera PSAI/SAI no formato tradicional
6. O analista finaliza no SGD (submissao real via especialista)
7. (Opcional) Publicar o diario `referencia/logs/` para metricas do gerente: `.\scripts\Publicar-LogParaConsolidacao.ps1 -AnalistaSlug <slug-da-pasta-em-logs-analistas>` — ver `logs/README.md` no General; em monorepo o General e detetado automaticamente; fora dele, `-GeneralRoot` ou `GENERAL_REPO_ROOT`.

---

## 9. Versionamento

| Versão | Data | Autor | Alteração |
|---|---|---|---|
| 1.0 | 2026-03-04 | Gerente de Produto | Criação inicial do projeto |
| 1.1 | 2026-03-04 | Agente IA | Arquitetura de dados locais (prevenção OOM) |
| 2.0 | 2026-03-04 | Agente IA | JSON volta ao OneDrive (dados-brutos/ + .cursorignore) |
| 2.1 | 2026-03-04 | Agente IA | Framework de analise de produto com BDD interno no projeto-filho |
| 2.2 | 2026-03-10 | Agente IA + Gerente | Auditoria de consistencia: fluxo com rotas, modulos 12+24, PB 5.579 |
| 2.3 | 2026-03-10 | Agente IA + Gerente | Sistema de tasks (v1.2.0 filho): rastreamento de demandas, retomada entre chats |
| 2.4 | 2026-04-10 | Agente IA + Gerente | Republicacao pacote projeto-filho; distribuicao/ultima-versao alinhada Escrita; gerar-atualizacao.ps1: compativel_com_admin parametrizado + hash_validacao (MD5 guardiao) |
| 2.5 | 2026-04-10 | Agente IA + Gerente | sdd-construcao.md v4.0 (Escrita SDD, BuscaSAI multi-area); sdd-verificacao + templates apresentacao/fluxo alinhados Escrita; pacote filho republicado |
| 2.6 | 2026-04-10 | Agente IA + Gerente | Higiene documental: agente-projeto-sdd Escrita; CHANGELOG nota BuscaSAI; planejamento v1.1.0 -> obsoleto/planejamento-v1.1.0-2026-04-10; referencias ADR atualizadas |
| 2.7 | 2026-04-30 | Agente IA + Gerente | Pacote projeto-filho **v2.4.14**: revisao PSAI com consulta SGD obrigatoria antes de colagem; consolidacao de logs (HH:MM:SS); scripts `Publicar-LogAnalista` / `Publicar-LogParaConsolidacao`; `logs/README.md`; sincronizar SharePoint inclui novos scripts e regras |
