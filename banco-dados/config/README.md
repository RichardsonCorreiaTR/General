# Configuracao — indices SAIs e dominios

## `modulos-keywords.json`

Define os **slugs de dominio** (alinhados a `regras-negocio/README.md` e ao produto Escrita Fiscal) e as **palavras-chave** usadas por `scripts/gerar-indices-sais.ps1` para classificar SAIs nos arquivos:

- `banco-dados/sais/indices/modulos/{slug}.md`
- `banco-dados/sais/indices/por-modulo.md`

**Versao:** campo `versao` no JSON (2.0 = dominios Escrita). Backup da taxonomia Folha: `modulos-keywords.v1-folha.backup.json`.

**Apos reimportar SAIs** das areas PBCVS **Escrita**, **Importacao** e **Onvio Escrita** (`importar-sais.ps1` com caches correspondentes), vale **revisar** `modulos-keywords.json`: palavras-chave, `tags_origem` e agrupamentos ainda podem carregar linguagem ou temas de **Folha** ate a base refletir o volume atual das tres areas.

**Regenerar o JSON** (mescla legado Folha — se slugs antigos ainda existirem no arquivo — + conteudo **v2 atual** por slug + extras Escrita):

```powershell
cd "C:\1 - A\B\Programas\General"
.\scripts\build-modulos-keywords-escrita.ps1
```

O script grava backup em `modulos-keywords.v1-folha.backup.json` antes de sobrescrever. A partir de 2026-04-10, a regeracao **preserva** `tags_origem` e `keywords` ja consolidados nos slugs v2 (a taxonomia Folha pura por chave `ferias`, etc., nao existe mais no JSON; o merge usa o modulo Escrita atual).

## Regenerar indices SAIs (Markdown)

Rodar **fora do Cursor** (pico de RAM ~550 MB; ver `protecao-oom.mdc`):

```powershell
cd "C:\1 - A\B\Programas\General"
.\scripts\importar-sais.ps1
.\scripts\gerar-indices-sais.ps1
```

1. `importar-sais.ps1` — atualiza fracionados em `dados-brutos/psai/` e `dados-brutos/sai/` (fonte ODBC ou BuscaSAI).
2. `gerar-indices-sais.ps1` — le `modulos-keywords.json` e reescreve `sais/indices/`. Slugs antigos sao movidos para `banco-dados/obsoleto/indices-sais-modulos-legado-AAAA-MM-DD/`.

**Opcional:** indices enriquecidos JSON (v2.5.0+; mesmos dominios/slugs que `gerar-indices-sais.ps1` via `modulos-keywords.json`; saida tipica `indices/enriquecidos/` ou caminho em `-Destino`):

```powershell
.\scripts\gerar-indices-enriquecidos.ps1
```

## Busca por dominio

`buscar-sai.ps1 -Modulo` filtra por texto em `nomeArea` e descricao (nao le o JSON acima). Para listar por slug gerado, abra o `.md` em `sais/indices/modulos/{slug}.md` apos regenerar.
