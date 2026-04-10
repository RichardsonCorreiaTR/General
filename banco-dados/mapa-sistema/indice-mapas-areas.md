# Indice — Mapas do sistema (Escrita SDD)

> Atualizado em: 2026-04-02

Este diretorio concentra o **mapa de produto e de codigo** usado pelos agentes e analistas.

| Arquivo | Uso |
|---------|-----|
| [mapa-escrita.md](mapa-escrita.md) | **Fonte primaria** — modulo Escrita Fiscal (`brtap-dominio/escrita`), PBLs e areas funcionais. |
| [mapa-importacao.md](mapa-importacao.md) | Area PBCVS **Importação** + pontos de codigo/SAIs relacionados. |
| [mapa-onvio-escrita.md](mapa-onvio-escrita.md) | Area PBCVS **Onvio Escrita** + jornada Onvio no codigo. |
| [pbl-area-escrita.json](pbl-area-escrita.json) | **Hashtable PBL → area** (618 chaves reais do `pbcvsexp`); gerar com `gerar-mapa-pbl-escrita.ps1`. |
| [mapa-escrita-lista-pbls.md](mapa-escrita-lista-pbls.md) | Lista tabular dos PBLs + contagem por area (mesmo gerador). |
| [indice-arquivos.md](indice-arquivos.md) | Inventario por arquivo (regenerar com `gerar-indice-codigo.ps1`; coluna Area usa o JSON). |
| [mapa-folha.md](mapa-folha.md) | Legado **modulo Folha** — referencia historica; nao usar como fonte do Escrita SDD. |
| [../config/README.md](../config/README.md) | `modulos-keywords.json` (slugs dominio Escrita) e comando para regerar `sais/indices/modulos/*.md`. |

## PBCVS e caches

`config/conexao-odbc.json` define `extracao.areas` com os nomes **exatos** do PBCVS: **Escrita**, **Importação**, **Onvio Escrita**. Os caches BuscaSAI correspondentes: `sai-psai-escrita.json`, `sai-psai-importacao.json`, `sai-psai-onvio-escrita.json`; o `importar-sais.ps1` mescla todos no fluxo do projeto.
