# Dados de SAIs - Referencia

Os dados de SAIs/PSAIs ficam em `banco-dados/dados-brutos/` (OneDrive).
O Cursor NAO indexa essa pasta (excluida via `.cursorignore`).

## Estrutura

| Pasta | Conteudo | Uso |
|---|---|---|
| `dados-brutos/psai/` | 12 JSONs fracionados (todos os PSAIs por tipo+status) | buscar-sai.ps1 |
| `dados-brutos/sai/` | 12 JSONs fracionados (SAIs unicas agrupadas) | buscar-sai.ps1 -VisualizarSai |
| `dados-brutos/sai-psai-escrita.json` | Cache completo (~165MB) | Backup e verificacao incremental |

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

## Conteudo completo da PSAI (SGD) quando o JSON ODBC vier vazio

A extracao **ODBC** (`importar-sais.ps1` → JSON em `dados-brutos/`) as vezes traz `definicao` / `comportamento` **vazios** no ficheiro, mesmo com a PSAI **preenchida** no SGD (HTML ou modelo diferente no PBCVS).

Para **auditoria**, validacao com `@templates/PROMPT-auditoria-psai.md` ou consulta pontual, use o fluxo **neste repositório** (nao e necessario abrir o projeto SGD separado):

1. Pasta **`scripts/sgd_consulta/`** — `consultar_psai.py`, sessao Playwright e `requirements.txt`.
2. **Credenciais SGD:** o utilizador e a senha **não vêm do `.env`**; são pedidos **sempre** pelos scripts `Consultar-PSAI-SGD.ps1` (General ou projeto-filho), ou pelo Python em terminal interativo, ou por variáveis de ambiente em automação. Ver `scripts/sgd_consulta/README.md` e `.env.example`.
3. Instalacao (uma vez): `pip install -r scripts/sgd_consulta/requirements.txt` e `playwright install chromium`.
4. Consulta pontual: no **General** as saídas vão para `scripts/sgd_consulta/data/consultas/`; no **projeto-filho** o script define `SGD_SGD_DATA_ROOT` e grava em `projeto-filho/data/sgd-psai-consultas/consultas/` (mesmo layout: `arquivo/`, `logs/`, sessão). Ver `projeto-filho/data/sgd-psai-consultas/README.md`.

```powershell
# Preferido: atalhos pedem utilizador e senha (General ou projeto-filho)
.\scripts\Consultar-PSAI-SGD.ps1 <numero_psai> --json

cd projeto-filho
.\scripts\Consultar-PSAI-SGD.ps1 <numero_psai> --json

# Alternativa: Python pede credenciais no terminal se ainda não estiverem no ambiente
python scripts/sgd_consulta/consultar_psai.py <numero_psai> --json
```

Com **`--json`**, o resumo fica em `…/consultas/psai_<numero>.json` (caminho acima conforme General vs projeto-filho). Por defeito é também gravado um **pacote de arquivo** em `…/consultas/arquivo/psai_<numero>/<data>/` e linha em `…/consultas/logs/psai-extracao.jsonl`. Ver `scripts/sgd_consulta/README.md`.

**Opcional (outro repo):** o projeto legado `C:\1 - A\B\Programas\SGD\sgd-extractor` ainda existe para sincronizacao em massa (`python -m src.scraper.run`, Streamlit, SQLite); para **só** ler uma PSAI, prefira o fluxo acima no General.

O script extrai cabecalho, Descricao, **Definicao**, **Comportamento**, **Observacoes** (e sinonimos), **Anotacoes**, **Anexos**, Embasamento quando presente no texto, **lista completa de tramites** (numero, data, usuario, descricao — mesmo vazio) e gera `psai_<numero>.png`. A saida no terminal segue a **ordem de conferencia** usada na auditoria (Definicao → Comportamento → Observacoes → Anexos → Tramites).

## AVISO para IA

NUNCA carregue arquivos de dados-brutos/ no terminal do Cursor.
Use apenas os indices em `banco-dados/sais/indices/`.

Para **texto integral** de uma PSAI quando o JSON local nao basta, use o fluxo **SGD** acima (terminal fora do indexador do Cursor, ou pedir ao analista para colar o export).
