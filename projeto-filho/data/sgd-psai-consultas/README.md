# Consultas SGD / PSAI (projeto-filho)

Esta pasta guarda **só na cópia local do projeto-filho** os dados do analista que corre `scripts/Consultar-PSAI-SGD.ps1`:

| Conteúdo | Onde |
|----------|------|
| JSON, HTML, screenshots, manifest | `consultas/arquivo/psai_<n>/…` |
| Resumo `psai_<n>.json` | `consultas/psai_<n>.json` |
| Log agregado (melhorias de extração) | `consultas/logs/psai-extracao.jsonl` |
| Sessão Playwright (cookies) | `session_state_<hash>.json` |
| Credenciais opcionais (não versionar) | `.sgd-credentials.local` |

Copie `projeto-filho/scripts/sgd_consulta/.sgd-credentials.local.example` para **`.sgd-credentials.local`** nesta pasta (mesmo formato) para não digitar senha em cada execução — o `env.py` tenta **primeiro** este ficheiro, depois o de `scripts/sgd_consulta/`.

**Primeira vez (Python):** na pasta `projeto-filho/scripts/sgd_consulta`, rode `python -m venv .venv`, depois `.venv\Scripts\pip install -r requirements.txt` e `playwright install` (ou use Python global com os mesmos comandos). O script `Consultar-PSAI-SGD.ps1` usa `.venv` desta pasta se existir.

O repositório deve ignorar credenciais e saídas pesadas (ver `.gitignore` na raiz do General).
