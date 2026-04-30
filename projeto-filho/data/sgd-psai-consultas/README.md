# Consultas SGD / PSAI (projeto-filho)

Esta pasta guarda **só na cópia local do projeto-filho** os dados do analista que corre `scripts/Consultar-PSAI-SGD.ps1`:

| Conteúdo | Onde |
|----------|------|
| JSON, HTML, screenshots, manifest | `consultas/arquivo/psai_<n>/…` |
| Resumo `psai_<n>.json` | `consultas/psai_<n>.json` |
| Log agregado (melhorias de extração) | `consultas/logs/psai-extracao.jsonl` |
| Sessão Playwright (cookies) | `session_state_<hash>.json` |
| Credenciais opcionais (não versionar) | `.sgd-credentials.local` |

Copie `scripts/sgd_consulta/.sgd-credentials.local.example` da raiz do General para **`.sgd-credentials.local`** aqui (mesmo formato) para não ter de digitar senha em cada execução — o `env.py` tenta **primeiro** este ficheiro, depois o de `scripts/sgd_consulta/`.

O repositório deve ignorar credenciais e saídas pesadas (ver `.gitignore` na raiz do General).
