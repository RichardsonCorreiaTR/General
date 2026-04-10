# Mapa de Assertividade da Busca em SAIs/PSAIs

Data: 2026-03-08
Autor: Pipeline de Revisao Critica (IA-CURSOR)

---

## 1. Resumo executivo

| Metrica | ANTES | DEPOIS |
|---------|-------|--------|
| Campos de busca | 6 (so metadados) | **14 (metadados + BLOBs + textoCompleto)** |
| Campos BLOB buscados | 0 | **7** (comportamento, definicao, psai_descricao, sai_destaque, psai_destaque, textoCompleto, nomeArea) |
| Campo modulo | modulo_caminho (inexistente) | **
omeArea** (real) |
| Cobertura de campos texto | ~50% | **100%** |
| Dedup por SAI | Nao (74% duplicatas) | **Sim (1 resultado por SAI)** |
| Snippets BLOB | Nao | **Sim (mostra onde o match ocorreu)** |
| Protecao OOM cache | Parcial | **Completa (scripts/cache/ no .cursorignore)** |
| Propagacao v1.1.0 | Sem buscar-sai.ps1 | **Incluido no pacote** |
| Agentes com busca profunda | 1 (agente-produto) | **2 (agente-produto + guardiao)** |

---

## 2. Cobertura completa de campos

### Campos BUSCADOS pelo buscar-sai.ps1 (14 de 14 texto)

| # | Campo | Tipo | Tamanho medio | Tamanho maximo | Relevancia |
|---|-------|------|---------------|----------------|------------|
| 1 | sai_descricao | texto | 137 chars | 550 chars | Alta -- titulo da SAI |
| 2 | comportamento | BLOB | 2.400 chars | 38.357 chars | Alta -- como o sistema funciona |
| 3 | definicao | BLOB | 6.620 chars | 310.891 chars | Alta -- o que deve ser feito |
| 4 | psai_descricao | texto | 142 chars | 503 chars | Media -- titulo da PSAI |
| 5 | sai_destaque | texto | variavel | variavel | Media -- resumo destacado |
| 6 | psai_destaque | texto | variavel | variavel | Media -- resumo destacado |
| 7 | textoCompleto | BLOB | variavel | variavel | Alta -- concatenacao de textos |
| 8 | nomeArea | texto | curto | curto | Alta -- modulo/area (ex: Folha) |
| 9 | nomeVersao | texto | curto | curto | Media -- versao do produto |
| 10 | tipoSAI | texto | 2-4 chars | 4 chars | Media -- NE/SAM/SAL/SAIL |
| 11 | gravidade_ne | texto | curto | curto | Media -- criticidade |
| 12 | situacaoSai | texto | curto | curto | Baixa -- status da SAI |
| 13 | situacaoPsai | texto | curto | curto | Baixa -- status da PSAI |
| 14 | nivel_alteracao | texto | curto | curto | Baixa -- nivel de mudanca |

### Campos NÃO buscados (metadados numericos/datas -- irrelevantes para busca texto)

| Campo | Tipo | Motivo |
|-------|------|--------|
| i_sai | numerico | Filtrado por -SAI (busca exata) |
| i_psai | numerico | Filtrado por -PSAI (busca exata) |
| CadastroPSAI | data | Nao relevante para busca por texto |
| CadastroSAI | data | Nao relevante para busca por texto |
| Liberacao | data | Usado internamente para status |
| Descarte | data | Usado internamente para status |
| i_modulos, i_sistemas, etc | numerico | IDs internos |
| pontuacao, qtde_sane, etc | numerico | Metricas internas |

**Cobertura: 14 de 14 campos de texto = 100%**

---

## 3. Deduplicacao inteligente

### Problema resolvido

Antes: Uma busca por `lotacao` retornava a mesma SAI multiplas vezes
(uma vez por cada PSAI vinculada). Em ne-liberadas, 100% das PSAIs
tinham SAI correspondente, gerando 100% de duplicacao.

### Solucao implementada

O uscar-sai.ps1 agora agrupa por i_sai e mantem apenas a PSAI
mais recente (ou a liberada, se houver). Prioridade:

1. PSAI liberada (SAI definitiva)
2. PSAI com maior i_psai (mais recente)
3. PSAIs sem SAI (i_psai=0) aparecem como `SAI sem PSAI`

### Resultado

| Metrica | Valor |
|---------|-------|
| PSAIs com SAI correspondente | 26.331 (74,6%) |
| Reducao de duplicatas | ~75% menos resultados redundantes |
| SAIs puras (sem PSAI) | 6.008 (~17%) |
| Flag para ver todas | `-VerPSAIs` |

---

## 4. Garantia de propagacao

| Item | Status | Local |
|------|--------|-------|
| buscar-sai.ps1 (original) | Atualizado | `scripts/buscar-sai.ps1` |
| buscar-sai.ps1 (wrapper) | Atualizado com fallback | `projeto-filho/scripts/buscar-sai.ps1` |
| Wrapper no pacote v1.1.0 | Incluido | `atualizacao/v1.1.0/arquivos/scripts/` |
| Wrapper na distribuicao | Incluido | `distribuicao/ultima-versao/scripts/` |
| agente-produto.mdc | Atualizado (busca profunda 14 campos) | projeto-filho + v1.1.0 + distribuicao |
| guardiao.mdc | Atualizado (sugere busca profunda) | projeto-filho + v1.1.0 + distribuicao |
| manifesto.json | Atualizado | `atualizacao/v1.1.0/manifesto.json` |
| input.md | Atualizado (buscar-sai.ps1 na tabela) | `atualizacao/v1.1.0/input.md` |

### Fluxo de acesso do analista

1. Analista roda atualizacao -> recebe wrapper + agentes atualizados
2. IA do analista faz Grep nos indices MD (rapido)
3. Se resultado truncado -> IA roda `buscar-sai.ps1` via Shell (busca profunda)
4. Wrapper resolve: caminhos.json -> referencia/scripts/ -> erro com instrucoes
5. Script busca em 14 campos, agrupa por SAI, mostra snippets BLOB

---

## 5. Protecao contra crash

| Risco | Mitigacao |
|-------|-----------|
| Cache monolitico (166 MB) | `.cursorignore` inclui `scripts/cache/` |
| Fracionados PSAI (179 MB) | `.cursorignore` inclui `banco-dados/dados-brutos/` |
| Indices MD (19 MB total) | `protecao-oom.mdc` orienta busca por modulo |
| buscar-sai.ps1 sem filtro | Roda em processo separado via Shell tool |
| Grep em todos indices | `protecao-oom.mdc` proibe; orienta busca especifica |

---

## 6. HTML nos BLOBs -- Decisao

Analise completa verificou que o conteudo detectado como HTML e:
- Placeholders de especificacao: `<Total rubrica periodo>`
- Tags eSocial: `<dtTerm>`, `<eSocial xmlns=...>`
- Caminhos de screenshots: `...\Db2.png`

**Decisao: NAO remover.** Economia seria <5 MB em 185 MB, com perda de
termos buscaveis. O conteudo e parte da especificacao tecnica.

---

## 7. Respostas as 7 dores

| # | Dor | Status | Resposta |
|---|-----|--------|----------|
| 1 | Cobertura de busca | RESOLVIDA | 14 campos, 100% texto coberto |
| 2 | HTML/imagens nos BLOBs | INVESTIGADA | Nao e lixo, e especificacao. Nao remover. |
| 3 | Mapa de assertividade | ENTREGUE | Este documento |
| 4 | Acesso apos atualizacao | RESOLVIDA | Wrapper com fallback + v1.1.0 atualizada |
| 5 | Tudo na v1.1.0 | RESOLVIDA | buscar-sai.ps1 + agentes incluidos no pacote |
| 6 | Agentes para pesquisa | RESOLVIDA | agente-produto + guardiao usam busca profunda |
| 7 | Protecao contra crash | RESOLVIDA | scripts/cache/ no .cursorignore + protecao-oom detalhada |
