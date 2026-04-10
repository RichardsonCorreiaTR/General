# Mapa — Area PBCVS **Importacao**

> **PBCVS `nomeArea`**: **Importação**  
> **Cache BuscaSAI**: `sai-psai-importacao.json` (mesclado por `importar-sais.ps1`)  
> Atualizado em: 2026-04-02

---

## Papel no produto

A area **Importacao** agrupa SAIs/PSAIs sobre **importacao de dados e documentos** para o Escrita Fiscal: notas fiscais, movimentos, integracoes com outros sistemas e rotinas batch de carga. No monorepo, a maior parte do codigo executavel continua em `escrita/pbcvsexp`, em PBLs dedicadas a importacao e em fluxos que alimentam apuracao e escrituracao.

---

## Pontos de codigo (Escrita)

| Tema | PBL / pista |
|------|-------------|
| Rotinas automaticas de importacao | `esrotinasautomaticasimportacao` |
| Importacao NF no contexto atendimento | `esidominioatendimento` (ex.: janelas `w_importacao_nfe_dominio_atendimento`, `w_importacao_nfce_dominio_atendimento`) |
| Busca de produtos / bases | `esibuscaprodutos` |

Para detalhe de arquivos `.srw/.sru`, use `indice-arquivos.md` ou Grep no `codigo_local`.

---

## Relacao com o mapa principal

- Estrutura geral de PBLs: [mapa-escrita.md](mapa-escrita.md).
- **Onvio** (nuvem): [mapa-onvio-escrita.md](mapa-onvio-escrita.md) — importacoes podem compartilhar infraestrutura com atendimento Onvio.

---

## Base SDD

- Extracao: `config/conexao-odbc.json` inclui **Importacao** em `extracao.areas`.
- Busca: `scripts/buscar-sai.ps1` — filtrar por termos e, quando necessario, inspecionar campo `nomeArea` no JSON.
