# Mapa do Sistema - Modulo Folha (Dominio Contabil)

> **LEGADO** — Projeto **Escrita SDD** usa [mapa-escrita.md](mapa-escrita.md), [mapa-importacao.md](mapa-importacao.md) e [mapa-onvio-escrita.md](mapa-onvio-escrita.md); veja [indice-mapas-areas.md](indice-mapas-areas.md).  
> Mantido como referencia historica do modulo **Folha**.

> Fonte: codigo-fonte PowerBuilder branch VC106A02  
> Atualizado em: 04/03/2026

---

## Visao Geral

O modulo Folha e composto por ~5.583 arquivos PowerBuilder organizados em
PBLs (bibliotecas). Cada PBL corresponde a uma pasta em `codigo-sistema/versao-atual/pbcvsexp/`.

## Areas de Negocio

### 1. Calculo Mensal
Processamento da folha de pagamento mensal.

| Pasta PBL | Descricao | Arquivos-chave |
|-----------|-----------|----------------|
| focalc00 | Calculo principal | w_calculo.srw, w_calculo_periodo.srw, w_log_calculo.srw |
| focalc09 | Configuracoes | w_cad_utilizacao_maximo_recurso_maquina.srw |
| situacao | Situacoes (DSR, afastamentos) | uo_calc_situacao.sru, uo_situacoes.sru |
| situacao_dados | DataWindows de situacoes | dw_calc_situacao_sit.srd, dw_calc_faltas_13.srd |
| util | Parametros de calculo | dw_cad_paramto_calculo.srd, dw_cad_bases.srd |

**Menu:** Processos > Calculo da Folha

---

### 2. Ferias
Calculo, programacao e pagamento de ferias individuais, coletivas e em grupo.

| Pasta PBL | Descricao | Arquivos-chave |
|-----------|-----------|----------------|
| foproc03 | Ferias individuais | w_ferias_inicio.srw, w_ferias_nova.srw |
| foproc04 | Ferias coletivas/grupo | w_calculo_ferias.srw, w_calculo_ferias_grupo.srw |
| simulacao | Simulacao de ferias | uo_calculo_simulacao_ferias.sru |

**Menu:** Processos > Ferias > Individual / Coletivas / Em Grupo / Programacao

---

### 3. Rescisao
Calculo rescisorio individual, em grupo e complementar.

| Pasta PBL | Descricao | Arquivos-chave |
|-----------|-----------|----------------|
| foproc04 | Rescisao individual/grupo | w_rescisao.srw, w_rescisao_grupo.srw |
| util | Logica de rescisao | uo_rescisao.sru, uo_aviso_previo_rescisao.sru |
| simulacao | Simulacao | uo_calculo_simulacao_rescisao.sru |

**Menu:** Processos > Rescisao > Individual / Em Grupo / Complementar

---

### 4. 13o Salario
Adiantamento e calculo integral do 13o salario.

| Pasta PBL | Descricao | Arquivos-chave |
|-----------|-----------|----------------|
| focalc00 | Integrado ao calculo | Opcoes em w_calculo.srw |
| provisao | Provisao de 13o | uo_provisao_13.sru |
| provisao_dados | Dados de provisao | dw_provisao_13.srd, dw_provisao_13sal.srd |

**Menu:** Dentro do Calculo da Folha (opcoes de 13o)

---

### 5. Admissao e Cadastros
Cadastro de empregados, estagiarios, contribuintes e parametros.

| Pasta PBL | Descricao | Arquivos-chave |
|-----------|-----------|----------------|
| focad01 | Sindicatos, tabelas | w_cad_sindicatos.srw, w_cad_tab_calc_irrf.srw |
| focad03 | Empregados | w_cad_empregados.srw |
| focad05 | Historico e PPP | w_hist_ppp.srw |
| focad06 | Estagiarios | w_cad_estagiarios.srw |
| focad07 | Ambientes de trabalho | w_cad_ambientes_trabalho.srw, w_fatores_riscos.srw |

**Menu:** Cadastros > Empregados / Estagiarios / Contribuintes / Sindicatos

---

### 6. Impostos e Encargos (INSS, IRRF, FGTS)
Tabelas de calculo e configuracao de tributos.

| Pasta PBL | Descricao | Arquivos-chave |
|-----------|-----------|----------------|
| tabela_calculo | Logica das tabelas | uo_tab_calc_inss.sru, uo_tab_calc_irrf.sru, uo_tab_calc_fap.sru |
| tabela_calculo_dados | DataWindows | dw_tab_calc_inss.srd, dw_tab_calc_irrf.srd |

**Menu:** Cadastros > Tabela > IRRF / INSS / FAP / Salario Minimo

---

### 7. eSocial
Geracao de eventos, validacao, comunicacao e exportacao.

| Pasta PBL | Descricao | Arquivos-chave |
|-----------|-----------|----------------|
| forel20 | eSocial principal (~471 arqs) | w_esocial.srw, uo_esocial.sru, w_painel_esocial.srw |
| foutil05 | Manutencao | w_manutencao_codigo_e_social.srw, w_qualificacao_cadastral.srw |

**Menu:** Processos > Informacoes Obrigatorias eSocial

---

### 8. Provisoes
Provisao de ferias e 13o salario.

| Pasta PBL | Descricao | Arquivos-chave |
|-----------|-----------|----------------|
| foproc01 | Tela principal | w_provisao.srw |
| provisao | Logica | uo_provisao_ferias.sru, uo_provisao_13.sru |
| altera_provisao | Alteracoes | w_provisao_ferias.srw, w_provisao_13.srw |

**Menu:** Processos > Provisao Ferias e 13o

---

### 9. Sindicato
Regras sindicais, contribuicoes, PLR e convencoes coletivas.

| Pasta PBL | Descricao | Arquivos-chave |
|-----------|-----------|----------------|
| sindicato | Regras | uo_regra_sindicato.sru, uo_contribuicao_sindical.sru |
| focad01 | Cadastro | w_cad_sindicatos.srw, w_cad_sindicatos_cct.srw |

**Menu:** Cadastros > Sindicatos

---

### 10. Relatorios
Impressao e visualizacao de relatorios da folha.

| Pasta PBL | Descricao | Arquivos-chave |
|-----------|-----------|----------------|
| forel01-forel22 | ~22 PBLs de relatorios | Recibo, holerite, DIRF, RAIS, CAGED, etc. |

Principais: forel20 (eSocial), forel14 (Guias), forel19 (Historico/DIRF)

---

### 11. Guias Fiscais
GPS, IRRF, PIS, FGTS, DAE, ISS.

| Pasta PBL | Descricao | Arquivos-chave |
|-----------|-----------|----------------|
| forel05 | GPS (INSS) | w_guias_gps.srw |
| forel14 | PIS, IRRF, FGTS, DAE | w_guias_pis.srw, w_guias_irrf.srw, w_guia_fgts_digital.srw |
| guia | Calculo de guias | uo_calc_guiainss.sru, uo_calc_guia_pis.sru |

---

### 12. Integracao
Integracao contabil, fiscal e exportacao de dados.

| Pasta PBL | Descricao | Arquivos-chave |
|-----------|-----------|----------------|
| fointeg1-fointeg4 | Configuracao e execucao | w_integ_configura.srw, w_integracao.srw |
| foexternos | Integracao contabil/fiscal | w_integracao_contabil.srw |

---

## Hierarquia do Menu Principal

```
Folha (m_geral_folha_app)
+-- Controle
|   +-- Empresas, Parametros, Saldo Inicial
|   +-- Avisos do Calculo, Data do Fechamento
|   +-- Permissoes, Log eSocial, Log do Calculo
+-- Cadastros
|   +-- Empregados, Estagiarios, Contribuintes
|   +-- Bases de Calculo, Tabelas (IRRF, INSS, FAP)
|   +-- Sindicatos, Cargos, Funcoes
|   +-- Horarios, Jornadas, Ambientes de Trabalho
|   +-- Contabilidade (Configuracao)
+-- Processos
    +-- Calculo da Folha
    +-- Rescisao (Individual, Em Grupo, Complementar)
    +-- Ferias (Programacao, Individual, Coletivas, Em Grupo)
    +-- Provisao Ferias e 13o
    +-- Situacoes, Licenca Premio, Estabilidade
    +-- Informacoes Obrigatorias eSocial
```

---

## Resumo de PBLs por Area

| Area | PBLs | Total arqs (aprox) |
|------|------|--------------------|
| Calculo mensal | focalc00, focalc09, situacao, situacao_dados | ~200 |
| Ferias | foproc03, foproc04, simulacao | ~300 |
| Rescisao | foproc04, util, simulacao | ~250 |
| 13o Salario | focalc00, provisao, provisao_dados | ~40 |
| Cadastros | focad01-focad07 | ~850 |
| Impostos | tabela_calculo, tabela_calculo_dados | ~22 |
| eSocial | forel20, foutil05 | ~550 |
| Provisoes | provisao, provisao_dados, altera_provisao | ~30 |
| Sindicato | sindicato, sindicato_dados | ~20 |
| Relatorios | forel01-forel22 | ~800 |
| Guias | forel05, forel14, guia, guia_dados | ~120 |
| Integracao | fointeg1-fointeg4, foexternos | ~600 |
| Utilitarios | foutil01-foutil07 | ~440 |
