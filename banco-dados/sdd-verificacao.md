# SDD Verificacao — Matriz de Conformidade do Projeto

## Metadados

| Campo | Valor |
|---|---|
| **ID** | SDD-VERIF-001 |
| **Titulo** | Matriz de verificacao da construcao do projeto |
| **Data** | 2026-04-10 |
| **Versao** | 1.2 |

---

## 1. Componentes do Projeto

Cada componente abaixo foi especificado, construido e verificado.

### 1.1 Estrutura de Pastas

| Componente | Especificado em | Construido? | Verificacao |
|---|---|---|---|
| banco-dados/ | PROJETO.md secao 3 | Sim | 8 subpastas populadas |
| banco-dados/regras-negocio/ (dominios Escrita) | PROJETO.md secao 6 | Sim | 8 dominios + README; Folha em obsoleto/ |
| banco-dados/fluxos/ | PROJETO.md secao 3 | Sim | README; fluxos Folha em obsoleto/ |
| banco-dados/glossario/ | PROJETO.md secao 3 | Sim | 5 categorias ativas; 3 termos Folha em obsoleto/ |
| banco-dados/legislacao/ | PROJETO.md secao 3 | Sim | 8 arquivos |
| banco-dados/mapa-sistema/ | PROJETO.md secao 3 | Sim | mapa-escrita, importacao, onvio-escrita, indice-mapas-areas |
| banco-dados/sais/indices/ | PROJETO.md secao 3 | Sim | 10 indices |
| banco-dados/dados-brutos/ | sdd-construcao.md secao 3 | Sim | 26 JSONs (24 fracionados + 2 cache) |
| banco-dados/codigo-sistema/ | sdd-construcao.md secao 3.3 | Sim | REFERENCIA.md + META.json |
| revisao/ (3 subpastas) | PROJETO.md secao 3 | Sim | pendente/aprovado/devolvido |
| templates/ | PROJETO.md secao 3 | Sim | 4 templates |
| scripts/ | PROJETO.md secao 3 | Sim | 8 scripts |
| .cursor/rules/ | PROJETO.md secao 3 | Sim | 11 regras .mdc |
| projeto-filho/ | PROJETO.md secao 3 | Sim | Estrutura completa |
| logs/ | PROJETO.md secao 3 | Sim | revisao.log ativo |

### 1.2 Scripts de Automacao

| Script | Funcao | Especificado em | Testado? |
|---|---|---|---|
| importar-sais.ps1 | Importa SAIs (ODBC ou BuscaSAI, mescla sai-psai-*.json multi-area) | sdd-construcao.md 3.4 | Sim (04/03) |
| gerar-indices-sais.ps1 | Fraciona JSONs + gera indices MD | sdd-construcao.md 3.4 | Sim (04/03) |
| buscar-sai.ps1 | Busca em JSONs fracionados | sdd-construcao.md 4.2 | Sim (04/03) |
| atualizar-codigo.ps1 | Copia PB para local do gerente | sdd-construcao.md 3.3 | Sim (04/03) |
| atualizar-tudo.bat | Orquestra importar + atualizar | sdd-construcao.md 3.4 | Sim (04/03) |
| revisar-definicao.ps1 | Fluxo de revisao SDD | Guardiao + sdd-revisao | Sim (04/03) |
| lib-lock.ps1 | Prevencao de conflito | sdd-construcao.md 2.2 | Sim |
| setup-odbc.ps1 | Configura ODBC pbcvs9 | DELEGACAO-ATUALIZACAO | Nao testado coletivo |

### 1.3 Regras Cursor (.mdc)

| Regra | Escopo | AlwaysApply? | Verificacao |
|---|---|---|---|
| guardiao.mdc | Checklist antes/depois de alteracao | Sim | Ativo |
| projeto.mdc | Contexto geral do projeto | Sim | Ativo |
| protecao-oom.mdc | Prevencao de crash por memoria | Sim | Ativo |
| onedrive-escrita.mdc | Forca uso de PowerShell | Sim | Ativo |
| architecture.mdc | Estrutura tecnica | Nao | Ativo |
| naming-conventions.mdc | Padrao de nomes | Nao | Ativo |
| duvidas.mdc | Gestao de duvidas | Nao | Ativo |
| sdd-definicao.mdc | Agente: criar regras | Nao (globs) | Ativo |
| sdd-impacto.mdc | Agente: analise impacto | Nao (globs) | Ativo |
| sdd-revisao.mdc | Agente: revisao | Nao (globs) | Ativo |
| sdd-projeto.mdc | Agente: meta-melhoria | Nao (globs) | Ativo |

### 1.4 Protecoes

| Protecao | Mecanismo | Verificacao |
|---|---|---|
| OOM (memoria) | .cursorignore exclui dados-brutos/ | Verificado: arquivo existe |
| OneDrive escrita | onedrive-escrita.mdc forca PowerShell | Verificado: regra ativa |
| Arquivo >300 linhas | guardiao.mdc verifica | Verificado: 0 violacoes |
| Regra >100 linhas | guardiao.mdc verifica | Verificado: 0 violacoes (max 52) |
| Conflito de execucao | lib-lock.ps1 | Verificado: mecanismo existe |
| Dados pesados no Cursor | protecao-oom.mdc | Verificado: regra ativa |

---

## 2. O que NAO seguiu SDD (transparencia)

| Item | O que aconteceu | Risco | Mitigacao |
|---|---|---|---|
| Estrutura de pastas | Definida iterativamente, nao spec-first | Baixo: resultado esta conforme PROJETO.md | Documentado em PROJETO.md retroativamente |
| Arquitetura de dados (local vs OneDrive) | Mudou 2x por OOM e requisitos do usuario | Medio: inconsistencias | sdd-construcao.md documenta versao final |
| 16 regras de negocio semente | Criadas pela IA sem revisao formal | Baixo: marcadas como rascunho v0.1 | Submetidas ao fluxo de revisao |
| 12 fluxos de processo | Criados pela IA como rascunho | Baixo: marcados como v0.2 pendente aprovacao | Precisam aprovacao do gerente |

---

## 3. Checklist de Verificacao (rodar periodicamente)

### 3.1 Base tecnica e conteudo

- [x] PROJETO.md < 500 linhas e atualizado
- [x] Todas .mdc < 100 linhas
- [x] Todos os MD < 300 linhas
- [x] .cursorignore exclui dados-brutos/
- [x] Templates (`templates/` raiz e `projeto-filho/templates/`) com os mesmos arquivos (paridade verificada; copiar da raiz para o filho ao alterar)
- [x] Glossario com 8+ categorias
- [x] Mapa do sistema existe
- [x] Scripts testados (atualizar-tudo.bat rodou com sucesso)
- [x] Log de revisao funcional (logs/revisao.log)

### 3.2 Itens operacionais (gerente / infra)

Marcar **somente** com evidencia (teste, registro em log ou ata). Nao marcar por inferencia.

| Item | Criterio de conclusao | Referencia |
|---|---|---|
| Permissoes SharePoint | Site **CursorEscrita**, grupos (gerentes / analistas) e biblioteca **General** conforme guia; checklists do **Passo 5** em `PERMISSOES-SHAREPOINT.md` validados (ou alternativa simplificada documentada). | `PERMISSOES-SHAREPOINT.md` (raiz do repo) |
| Piloto com analista | Pelo menos uma sessao piloto concluida: pre-requisitos ok, fluxo `projeto-filho` testado, item **Apos o piloto** em `PILOTO.md` atendido ou registro equivalente. | `projeto-filho/PILOTO.md` |
| Tarefa agendada | No ambiente do gerente (ou host designado), atualizacao automatica ativa: `scripts/agendar-atualizacao.ps1` executado com sucesso **ou** tarefa manual equivalente no Agendador do Windows documentada (nome da tarefa + periodicidade). | `scripts/README.md` (secao `agendar-atualizacao.ps1`) |

Checklist rapido:

- [ ] Permissoes SharePoint configuradas e testadas (conforme tabela acima)
- [ ] Piloto com analista realizado (conforme tabela acima)
- [ ] Tarefa agendada configurada ou alternativa documentada (conforme tabela acima)

### 3.3 Dados SAIs, indices e keywords (Escrita)

- [x] `modulos-keywords.json` regenerado com `scripts/build-modulos-keywords-escrita.ps1` preservando tags/keywords v2 (apos correcao 2026-04-10)
- [ ] Apos **reimportar** SAIs das areas PBCVS (Escrita, Importacao, Onvio Escrita), revisar manualmente palavras-chave e `tags_origem` conforme `banco-dados/config/README.md`

### 3.4 Frescor da importacao (status.json)

Antes de respostas em lote sobre SAIs/PSAIs, a IA deve consultar `atualizacao/status.json` (admin) ou `referencia/atualizacao/status.json` (filho, via symlink). Ver `atualizacao/README.md` e `guardiao.mdc`.

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 1.0 | 2026-03-04 | Agente IA + Gerente | Criacao inicial |
| 1.1 | 2026-04-10 | Agente IA + Gerente | Secao 3.2: criterios e referencias para itens operacionais |
| 1.2 | 2026-04-10 | Agente IA + Gerente | Secoes 3.3 e 3.4: keywords/status; templates com paridade raiz/filho |
