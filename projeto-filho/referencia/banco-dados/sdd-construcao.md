# SDD-CONSTRUCAO: Construcao do Projeto Escrita SDD

## Metadados

| Campo | Valor |
|---|---|
| **ID** | SDD-CONSTRUCAO-001 |
| **Titulo** | Especificacao de Construcao do Projeto |
| **Autor** | Agente IA + Gerente de Produto |
| **Data criacao** | 2026-03-04 |
| **Versao** | 4.0 |
| **Status** | Em vigor |

---

## 1. Objetivo

Documentar as decisoes de arquitetura, restricoes tecnicas e regras de
operacao para a **construcao** do **projeto Escrita SDD** (definicoes de
regras de negocio do modulo **Escrita Fiscal** e areas PBCVS relacionadas:
**Importacao**, **Onvio Escrita**). Este documento nao descreve o produto
contabil em si, mas como este repositorio de gestao de definicoes e
construido e mantido.

> **Legado Folha**: o projeto migrou do modulo Folha de Pagamento para Escrita
> Fiscal (ver `MIGRACAO-FOLHA-ESCrita-SDD.md`). Caminhos e artefatos antigos
> permanecem apenas onde o suporte a migracao ou o arquivo historico exigem.

---

## 2. Restricoes do Ambiente

### 2.1 Cursor IDE

| Restricao | Limite | Consequencia se violado |
|---|---|---|
| Memoria do Electron | ~2-4 GB | Crash OOM (codigo -536870904) |
| File watcher | ~5.000 arquivos | Lentidao extrema ou crash |
| Contexto IA (tokens) | ~128k tokens | Perda de contexto, erros |
| Arquivo individual | 300 linhas (regra guardiao) | Subdividir obrigatoriamente |
| Regra .mdc | 100 linhas | Subdividir obrigatoriamente |

### 2.2 OneDrive/SharePoint

| Restricao | Impacto |
|---|---|
| Sync de muitos arquivos (>1.000) | Fila de sync, conflitos |
| Escrita via Cursor Write tool | Falha com permissao negada |
| Acesso simultaneo | Risco de conflito de edicao |

---

## 3. Arquitetura de Dados

### 3.1 Principio: tudo no OneDrive, Cursor ignora o pesado

O projeto inteiro vive no OneDrive para que todos os analistas tenham
acesso automatico via sincronizacao. Dados pesados ficam em uma subpasta
`banco-dados/dados-brutos/` que o `.cursorignore` exclui da indexacao.

### 3.2 Estrutura do projeto (OneDrive)

Pasta sincronizada (exemplo): `...\Thomson Reuters Incorporated\CursorEscrita - General\`
(ver `PROJETO.md` secao 5).

```
CursorEscrita - General/
  .cursorignore               Exclui dados-brutos/ da indexacao
  banco-dados/
    dados-brutos/             PESADO - ignorado pelo Cursor
      psai/                   JSONs fracionados por tipo+status (NE/SAM/SAL etc.)
      sai/                    SAIs unicas agrupadas
      situacoes.json          Mapa de situacoes (quando usado)
    glossario/                Categorias ativas + legado em obsoleto/
    fluxos/                   Fluxos Escrita; Folha arquivado em obsoleto/
    legislacao/
    mapa-sistema/             mapa-escrita.md, importacao, onvio-escrita, indice-mapas-areas.md
    regras-negocio/           Dominios Escrita (ver README)
    sdd-construcao.md         Este documento
    sais/
      indices/                Indices MD (gerados por script)
      cache/
        importacao-meta.json  Metadados da ultima importacao
    codigo-sistema/
      REFERENCIA.md           Aponta para codigo PB local (modulo Escrita)
      META.json
      changelog/
  scripts/
    cache/                    sai-psai-escrita.json (trabalho; mescla multi-area no fluxo)
  templates/
  projeto-filho/
  .cursor/rules/
```

### 3.3 Codigo-fonte PB (local do gerente)

O codigo PowerBuilder do **modulo Escrita** NAO fica no OneDrive pelo volume
de arquivos e impacto no sync.

**Padrao atual** (ver `banco-dados/codigo-sistema/REFERENCIA.md`):
`C:\CursorEscrita\codigo-sistema\versao-atual\`  
**Alternativas**: `EscritaSDD-dados-pesados\versao-atual\` ou, em migracao,
`FolhaSDD-dados-pesados\versao-atual\` — o script `atualizar-codigo.ps1` detecta.

Analistas consultam o mapa (`banco-dados/mapa-sistema/`, `mapa-escrita.md`)
e pedem ao gerente se precisarem de arquivo especifico.

### 3.4 Fluxo de atualizacao

```
[Gerente/backup roda atualizar-tudo.bat em terminal separado]
  |
  +--[importar-sais.ps1]
  |    Fonte primaria: ODBC (extrair-sais.ps1) multi-area PBCVS
  |    Fallback: BuscaSAI — mescla data/cache/sai-psai-*.json (Escrita,
  |              Importacao, Onvio Escrita, etc.) -> fracionados em
  |              banco-dados/dados-brutos/ + indices em sais/indices/
  |
  +--[atualizar-codigo.ps1]
       Atualiza clone Git / copia arvore escrita\ para pasta local do gerente
       Metadados em banco-dados/codigo-sistema/
  |
  v
[OneDrive sincroniza o repositorio para analistas (leitura na base)]
```

### 3.5 Delegacao de atualizacao

Se o gerente estiver ausente, qualquer pessoa designada com ODBC
configurado pode rodar `scripts\atualizar-tudo.bat`.
O resultado sincroniza via OneDrive para todos.

---

## 4. Regras de Operacao da IA

### 4.1 PROIBIDO

| Acao | Motivo |
|---|---|
| Carregar JSON de dados-brutos/ no terminal do Cursor | Causa OOM |
| Ler >50 arquivos em sequencia | Consome tokens + memoria |
| Executar comandos paralelos pesados | Soma de memoria |
| Criar arquivos >300 linhas | Regra do guardiao |
| Usar Write tool (Cursor nativo) | Falha permissao OneDrive |
| Rodar scripts de importacao dentro do Cursor | Consome RAM demais |

### 4.2 OBRIGATORIO

| Acao | Como |
|---|---|
| Escrita de arquivos | PowerShell Set-Content |
| Processar JSON grande | Pedir ao usuario rodar script em terminal separado |
| Consultar SAIs | Via indices MD em banco-dados/sais/indices/ |
| Buscar SAI especifica | Pedir ao usuario rodar buscar-sai.ps1 (le JSONs fracionados) |
| Documentar decisoes | Atualizar este SDD |

---

## 5. Setup

### Para o gerente (Projeto Admin)

1. OneDrive sincroniza automaticamente a pasta **CursorEscrita - General**
2. Abrir Cursor nessa pasta (ou clone local espelhado; ver `PROJETO.md`)
3. Na primeira vez: rodar `scripts\atualizar-tudo.bat` em terminal separado
4. Dados brutos e indices em `banco-dados/` (OneDrive)
5. Codigo PB local: preferir `C:\CursorEscrita\codigo-sistema\versao-atual\`
   (outros caminhos: `REFERENCIA.md`)

### Para o analista (Projeto Filho)

1. Instalar via `scripts\instalar-projeto-filho.ps1` (ou copiar pacote)
2. Configurar `config/analista.json` com nome e email
3. OneDrive sincroniza **CursorEscrita - General** (base de conhecimento)
4. Abrir Cursor em `C:\CursorEscrita\projeto-filho` (nao na raiz OneDrive)
5. Indices e glossario via symlink `referencia/` para a base

### Atualizacoes de SAIs

O gerente (ou backup) roda `scripts\atualizar-tudo.bat` periodicamente.
Os novos indices sincronizam via OneDrive para todos os analistas.

---

## 6. Historico de Incidentes

| Data | Incidente | Causa | Correcao |
|---|---|---|---|
| 2026-03-04 | OOM crash 3x | Agente IA carregou JSON 165MB e listou 5.584 arquivos dentro do Cursor | Criado .cursorignore, regras de protecao, scripts redesenhados |

---

## 7. Documentos SDD complementares

| Documento | Conteudo |
|---|---|
| ``sdd-verificacao.md`` | Matriz de conformidade: cada componente, onde foi especificado, se foi construido e verificado |
| ``sdd-decisoes.md`` | 8 ADRs (Architecture Decision Records): cada decisao com contexto, alternativas e consequencias |

## 8. Processo de mudanca no projeto

Qualquer alteracao na **estrutura ou arquitetura** do projeto DEVE seguir:

1. Documentar a proposta (o que, por que, impacto)
2. Registrar como ADR em ``sdd-decisoes.md``
3. Obter aprovacao do gerente
4. Executar a mudanca
5. Atualizar ``sdd-verificacao.md`` com o novo componente
6. Atualizar PROJETO.md se afetou estrutura de pastas

Alteracoes de **conteudo** (novas regras, fluxos, legislacao) seguem o
fluxo SDD normal: template → submissao → revisao → aprovacao.

## 9. Checklist de Saude

Antes de qualquer operacao pesada:

- [ ] .cursorignore exclui banco-dados/dados-brutos/?
- [ ] Nenhum script pesado rodando no terminal do Cursor?
- [ ] Indices em banco-dados/sais/indices/ estao atualizados?
- [ ] sdd-verificacao.md reflete o estado atual?
- [ ] sdd-decisoes.md tem todas as ADRs?

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 1.0 | 2026-03-04 | Agente IA | Criacao apos 3 crashes OOM |
| 1.1 | 2026-03-04 | Agente IA | Code blocks corrigidos, setup analista |
| 2.0 | 2026-03-04 | Agente IA | JSON volta para OneDrive em dados-brutos/, .cursorignore, delegacao |
| 2.1 | 2026-03-04 | Agente IA | JSONs fracionados (psai/ e sai/ por tipo+status), buscar-sai.ps1 |
| 3.0 | 2026-03-04 | Agente IA + Gerente | SDD de construcao formalizado: sdd-verificacao + sdd-decisoes + processo de mudanca |
| 3.1 | 2026-03-04 | Agente IA + Gerente | Framework de analise de produto: BDD como motor interno, agentes produto/codigo, templates PSAI/SAI no projeto-filho, ADR-009/010 |
| 4.0 | 2026-04-10 | Agente IA + Gerente | Alinhamento Escrita SDD: OneDrive CursorEscrita, importacao BuscaSAI multi-area, codigo PB Escrita; legado Folha apenas onde migracao exige |
