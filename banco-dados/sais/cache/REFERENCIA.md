# Dados de SAIs - Referencia

Os dados de SAIs/PSAIs ficam em `banco-dados/dados-brutos/` (OneDrive).
O Cursor NAO indexa essa pasta (excluida via `.cursorignore`).

## Estrutura

| Pasta | Conteudo | Uso |
|---|---|---|
| `dados-brutos/psai/` | 12 JSONs fracionados (todos os PSAIs por tipo+status) | buscar-sai.ps1 |
| `dados-brutos/sai/` | 12 JSONs fracionados (SAIs unicas agrupadas) | buscar-sai.ps1 -VisualizarSai |
| `dados-brutos/sai-psai-folha.json` | Cache completo (~165MB) | Backup e verificacao incremental |

## Arquivos fracionados

Cada tipo (NE, SAM, SAL, SAIL) x status (pendentes, liberadas, descartadas):
- `ne-pendentes.json`, `ne-liberadas.json`, `ne-descartadas.json`
- `sam-pendentes.json`, `sam-liberadas.json`, `sam-descartadas.json`
- `sal-pendentes.json`, `sal-liberadas.json`, `sal-descartadas.json`
- `sail-pendentes.json`, `sail-liberadas.json`, `sail-descartadas.json`

## Como acessar

1. **Indices navegaveis**: `banco-dados/sais/indices/` (leves, dentro do Cursor)
2. **Buscar por termo**: `scripts\buscar-sai.ps1 -Termo "INSS"` (terminal separado)
3. **Ver SAIs unicas**: `scripts\buscar-sai.ps1 -Termo "INSS" -VisualizarSai`
4. **Atualizar**: `scripts\importar-sais.ps1` (terminal separado)

## AVISO para IA

NUNCA carregue arquivos de dados-brutos/ no terminal do Cursor.
Use apenas os indices em `banco-dados/sais/indices/`.
