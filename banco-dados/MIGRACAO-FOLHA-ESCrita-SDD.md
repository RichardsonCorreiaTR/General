# Migracao Folha SDD para Escrita SDD

## O que mudou (2026-04)

- **Produto**: gestao de definicoes passou do modulo Folha de Pagamento para **Escrita Fiscal** (PBCVS `nomeArea = Escrita`).
- **Cache SAIs**: arquivo monolitico `sai-psai-escrita.json` (antes `sai-psai-folha.json`).
- **Fonte alternativa**: clone **BuscaSAI** em `C:\1 - A\B\Programas\BuscaSAI`. O extrator gera **tres** caches: `sai-psai-escrita.json`, `sai-psai-importacao.json`, `sai-psai-onvio-escrita.json`. O `importar-sais.ps1` **mescla** todos os `sai-psai-*.json` em um monolitico e regenera fracionados.
- **ODBC**: `config/conexao-odbc.json` usa `extracao.areas` com os tres `nomeArea` do PBCVS: `Escrita`, `Importação`, `Onvio Escrita`.
- **Codigo PB**: copia da pasta `escrita\` do repo `tr/brtap-dominio_contabil`; destino padrao `C:\CursorEscrita\codigo-sistema\versao-atual`.
- **OneDrive/SharePoint**: documentacao aponta para `CursorEscrita - General`; confirme com a TI se o site ja existe ou ajuste a URL.
- **Regras de negocio**: taxonomia Folha (`calculo/`, `ferias/`, etc.) arquivada em `banco-dados/obsoleto/regras-negocio-taxonomia-folha-2026-04-09/`. Dominios Escrita atuais: `regras-negocio/README.md`.
- **Fluxos / glossario**: fluxos `fl-*` e termos Folha (02-04) em `obsoleto/fluxos-processos-folha-*` e `obsoleto/glossario-termos-folha-*`.
- **Mapa do sistema**: `banco-dados/mapa-sistema/mapa-escrita.md` (codigo real `escrita/pbcvsexp`); `mapa-importacao.md`, `mapa-onvio-escrita.md` e `indice-mapas-areas.md` para as demais areas PBCVS. `mapa-folha.md` permanece como legado Folha.
- **Indices SAIs / modulos-keywords**: v2 com dominios Escrita; backup Folha `config/modulos-keywords.v1-folha.backup.json`; regerar indices: `config/README.md`.

## Acoes recomendadas apos atualizar este repositorio

1. Rodar `scripts\importar-sais.ps1` (ODBC ou fallback BuscaSAI) para regenerar fracionados e indices.
2. Rodar `scripts\atualizar-codigo.ps1` para copiar o modulo Escrita.
3. Revisar `config\conexao-odbc.json` se a coluna `nomeArea` no banco nao for exatamente `Escrita` (ajustar conforme PBCVS).
