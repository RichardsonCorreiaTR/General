# Mapa do Sistema — Modulo Escrita Fiscal (Dominio Contabil)

> **Fonte de codigo**: `brtap-dominio/escrita/pbcvsexp` (export PowerBuilder)  
> **Repositorio**: `tr/brtap-dominio_contabil`, branch **VC106A02**  
> **PBCVS `nomeArea`**: **Escrita**  
> **Escala**: ~618 PBLs (pastas em `pbcvsexp`)  
> Atualizado em: 2026-04-02

---

## Visao geral

O **Escrita Fiscal** e o modulo de escrituracao, apuracao e obrigacoes fiscais no **Dominio Contabil** (ecosistema Thomson Reuters Brasil). O codigo-fonte fica na pasta `escrita/` do monorepo; o SDD copia para `codigo-sistema/versao-atual/` via `scripts/atualizar-codigo.ps1`.

Este mapa descreve **agrupamentos reais de PBLs** (prefixos) no `pbcvsexp`. A lista completa **PBL → area** (chaves reais do repositorio) esta em `pbl-area-escrita.json` e na tabela `mapa-escrita-lista-pbls.md`, geradas por `scripts/gerar-mapa-pbl-escrita.ps1`. Para localizar arquivo especifico, use `indice-arquivos.md` (apos regenerar) ou Grep no `codigo_local` do analista.

---

## Areas funcionais (agrupamento por PBL)

### 1. Nucleo de escrituracao e cadastros base

Telas e objetos centrais do modulo (parametros, cadastros mestres, fluxo principal).

| Agrupamento | Exemplos de PBL | Notas |
|-------------|-----------------|-------|
| esc01–esc27 | `esc01` … `esc27` | Nucleo **esc** — processos centrais da escrituracao |
| escrita | `escrita` | Biblioteca identidade do modulo |
| esmodulo | `esmodulo` | Agregacao de funcionalidades do modulo |
| esobj, esobj02–esobj04 | `esobj`, `esobj02` … | Objetos compartilhados |
| esobjetosglobais | `esobjetosglobais` | Globais Escrita |
| escpr01 | `escpr01` | Cadastros/processo relacionado (ver indice) |
| esesselecao | `esselecao` | Selecoes de dados |

**Menu / processos**: conforme `m_*` e `w_*` nas PBLs `esc*` (detalhe em indice de arquivos).

---

### 2. Apuracao de impostos e regimes especiais

| Agrupamento | Exemplos de PBL |
|-------------|-----------------|
| esapuracao01–esapuracao15 | Apuracao por linhas de negocio / CFOP |
| esapuracao_drcst, esapuracao_drcst_pr | DRCST |
| esapuracaoconsulta, esapuracaoconsulta02 | Consultas de apuracao |
| esapuracaoempreendimento | Empreendimento |
| esapuracaoestoque | Estoque |
| esapuracaosimplesnacional01–03 | Simples Nacional |

---

### 3. Movimento fiscal e controles (prefixos esf / esm)

| Agrupamento | Exemplos de PBL |
|-------------|-----------------|
| esf01–esf25 | Bloco **esf** — movimento e controles fiscais |
| esm01–esm90 | Bloco **esm** — modulo amplo de movimentacao e parametros |

Use o **indice por PBL** para contagem exata de arquivos por biblioteca.

---

### 4. SPED, layouts fixos e documentos eletronicos

Integracao com layouts oficiais (EFD, DIPJ por ano, NF-e, NFC-e, CT-e, MDF-e, etc.).

| Agrupamento | Exemplos de PBL |
|-------------|-----------------|
| esifdipj1201–esifdipj1410 | Layouts DIPJ por exercicio |
| esifixocfe01–02, esifixocte01–02, esifixoonf* | Documentos eletronicos |
| esifixoconvenio115icms01–02 | Convenio ICMS 115 |
| esifixosintegra01–02 | Sintegra |
| esifixothreads*, esifixothreadasis | Processamento em thread de layouts |
| esileiauteconjuntodados | Leiaute conjunto de dados |
| esxml | XML |
| esm_ajustes_inss_rb, esm_cfe, esm_drcst, esm_obs_info_comp_01 | Ajustes e observacoes em layouts |

---

### 5. Integracoes externas, APIs e canais digitais

| Agrupamento | Exemplos de PBL |
|-------------|-----------------|
| esexternos | Integracoes externas |
| esiwebserviceportalfederal, esiwebserviceportalfederal02 | Web services Portal Federal |
| esidigitalbank, esichromium | Canais digitais / browser embutido |
| esipainelapi, esianalytics | Painel e analytics |
| esiapibaixas, esiapibaixas_impostos_encargos | API baixas |
| esibuscaprodutos | Busca produtos |
| esionbalance, esionbalance01, esionbalance03, esionbalance04 | Integracao **Onvio** (saldo/on balance) — ver tambem [mapa-onvio-escrita.md](mapa-onvio-escrita.md) |

---

### 6. Sefaz e sites estaduais (declaracoes e transmissao)

| Agrupamento | Exemplos de PBL |
|-------------|-----------------|
| esisitesefaz* | Por UF (ex.: RS, SC, GO, MT, MS, SP) — bases e declaracoes estaduais |

---

### 7. Relatorios e demonstrativos (matriz estadual / obrigacoes)

Grande bloco **esr** + sufixos por UF (ex.: `esrsp` SP, `esrrs` RS, `esrgo` GO).

| Agrupamento | Exemplos de PBL |
|-------------|-----------------|
| esr01–esr103 | Relatorios e rotinas numeradas |
| esrac*, esral*, esram*, esrap*, esrba*, esrce*, esrdf* | Por tipo/regiao |
| esrgo*, esrma*, esrmg*, esrms*, esrmt*, esrpa*, esrpb*, esrpe*, esrpi*, esrpr*, esrrj*, esrrn*, esrro*, esrrr*, esrsc*, esrse*, esrsp*, esrto* | **Relatorios e obrigacoes por estado** |
| esrgdemonstrativosimpostos01–03 | Demonstrativos de impostos |
| esrotinasautomaticas, esrotinasautomaticasescrita | Rotinas automaticas Escrita |
| esrotinasautomaticasimportacao | Rotinas automaticas **Importacao** — ver [mapa-importacao.md](mapa-importacao.md) |

---

### 8. Parcelamento, planejamento e consultas governo

| Agrupamento | Exemplos de PBL |
|-------------|-----------------|
| esparcelamentoimposto, esparcelamentoimpostosn | Parcelamento |
| esplanejamentotributario | Planejamento tributario |
| esconsultarpagamentoimpostoecac | Consulta pagamento imposto **e-CAC** |
| escontabilizacao01 | Contabilizacao |

---

### 9. Utilitarios, alteracoes e graficos

| Agrupamento | Exemplos de PBL |
|-------------|-----------------|
| esutil01–esutil02 | Utilitarios |
| esutilalteracao, esutilalteracao02–09 | Pacotes de alteracao |
| esutilgraficos01 | Graficos |

---

### 10. Cadastros site, CTe, portal e veiculos

| Agrupamento | Exemplos de PBL |
|-------------|-----------------|
| esisitecadastros | Cadastros via site |
| esisitecte01–02, esisitectedadoscarganfe | CTe / NF-e |
| esiteportal | Portal |
| esiveiculosusados | Veiculos usados |

---

### 11. APIs contador, DEFIS e PGDAS

| Agrupamento | Exemplos de PBL |
|-------------|-----------------|
| esr_api_contador, esr_defis, esr_defis_api_contador | DEFIS / API contador |
| esr_pgdas | PGDAS |

---

## Hierarquia de consulta (agentes)

1. **Fluxo de produto e dependencias entre areas**: este arquivo (`mapa-escrita.md`).
2. **Arquivo exato (PBL + nome)**: `indice-arquivos.md` ou Grep no `codigo_local`.
3. **SAIs e regras**: `banco-dados/sais/indices/modulos/{slug}.md` e `regras-negocio/` — a taxonomia de **slugs** pode ainda refletir classificacao herdada da migracao Folha; cruzar sempre com `nomeArea` no JSON quando a demanda for estritamente Escrita.

---

## Indice de SAIs por dominio (projeto)

Os slugs em `banco-dados/sais/indices/modulos/{slug}.md` vêm de **`banco-dados/config/modulos-keywords.json`** (dominios Escrita: `apuracao-impostos`, `escrituracao-movimento-fiscal`, `sped-documentos-eletronicos`, etc.). Keywords legadas da taxonomia Folha foram agrupadas nesses dominios.

**Regenerar indices:** ver `banco-dados/config/README.md` (`importar-sais.ps1` + `gerar-indices-sais.ps1`).

> **Nota**: Classificacao por palavra-chave na **descricao** da SAI; nao reproduz 1:1 as PBLs do codigo. Ajuste keywords em `modulos-keywords.json` ou rode `scripts/build-modulos-keywords-escrita.ps1` apos editar o mapeamento.

---

## Ver tambem

- [indice-mapas-areas.md](indice-mapas-areas.md) — outras areas PBCVS (Importacao, Onvio Escrita).
- [banco-dados/codigo-sistema/REFERENCIA.md](../codigo-sistema/REFERENCIA.md) — onde clonar/copiar o codigo.
