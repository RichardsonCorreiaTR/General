# Mapa — Area PBCVS **Onvio Escrita**

> **PBCVS `nomeArea`**: **Onvio Escrita**  
> **Cache BuscaSAI**: `sai-psai-onvio-escrita.json` (mesclado por `importar-sais.ps1`)  
> Atualizado em: 2026-04-02

---

## Papel no produto

**Onvio** e a linha de solucao em nuvem da Thomson Reuters. No Escrita Fiscal, o codigo trata **modo Onvio** em telas e textos (ex.: `of_is_atendimento_onvio`, `of_set_textos_onvio`, `of_set_titulo_onvio`) para adaptar rotulos e fluxos quando o cliente esta no atendimento Onvio.

As SAIs dessa area documentam comportamentos e regras **especificos** a clientes/jornada Onvio Escrita.

---

## Pontos de codigo (Escrita)

| Tema | PBL / referencia |
|------|------------------|
| Parametros e textos Onvio | `esc05/w_parametros_es.srw` — funcoes `of_set_textos_onvio` |
| Atendimento / importacao NF | `esidominioatendimento` — `of_set_titulo_onvio` em janelas de importacao |
| Cadastro empresa modulos | `esifixoempresa/w_imp_fixo_empresas_modulos.srw` — `of_set_texto_onvio` |
| Integracao saldo / Onvio | `esionbalance`, `esionbalance01`, `esionbalance03`, `esionbalance04` |

---

## Relacao com outras areas

- Mapa tecnico geral: [mapa-escrita.md](mapa-escrita.md).
- Importacao de documentos (pode coexistir com Onvio): [mapa-importacao.md](mapa-importacao.md).

---

## Base SDD

- Extracao: `config/conexao-odbc.json` inclui **Onvio Escrita** em `extracao.areas` (string exata do banco).
- Ao cruzar SAIs, priorize registros com `nomeArea` coerente com esta area quando a demanda for exclusiva Onvio.
