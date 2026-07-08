# Consulta PSAI no SGD (General)

Cópia autocontida do fluxo `consultar_psai.py` + sessão Playwright do projeto **SGD/sgd-extractor**, para usar **só neste repositório General** (sem `cd` para outra pasta de código).

## Dependências de runtime

- Python 3.11+ (recomendado)
- Pacotes: `pip install -r requirements.txt`
- Navegador: `playwright install chromium`

Não há dependência do repositório `SGD` no disco; apenas o site SGD e credenciais (ambiente, ficheiro local ou pedido no terminal).

## Credenciais (política)

- **`SGD_USERNAME` e `SGD_PASSWORD` não são lidos dos `.env` gerais** do projeto (evita misturar contas).
- **Opcional na sua máquina:** copie `.sgd-credentials.local.example` para **`.sgd-credentials.local`** e preencha — ficheiro **gitignored**. O `env.py` tenta, por ordem: `projeto-filho/data/sgd-psai-consultas/`, `data/sgd-psai-consultas/` (raiz do General) e `scripts/sgd_consulta/` — só aplica se as variáveis **ainda não** estiverem definidas no ambiente.
- **`Consultar-PSAI-SGD.ps1` na raiz do General** (`.\scripts\Consultar-PSAI-SGD.ps1`): usa variáveis de ambiente, depois qualquer um desses `.sgd-credentials.local`; só pede `Read-Host` se faltar tudo. Define `SGD_SGD_DATA_ROOT` para `data/sgd-psai-consultas` na raiz do clone (saídas fora de `scripts/sgd_consulta/data/`).
- **`projeto-filho/scripts/Consultar-PSAI-SGD.ps1`:** define `SGD_SGD_DATA_ROOT` em `projeto-filho/data/sgd-psai-consultas/` (fluxo do analista).
- **Terminal / CI sem ficheiro:** o Python pode pedir credenciais; em CI use `SGD_USERNAME` e `SGD_PASSWORD` no ambiente.

O `.env` serve para `SGD_URL`, `SCRAPER_HEADLESS`, `SCRAPER_TIMEOUT_MS`, `SCRAPER_SESSION_FILE`, `LOG_LEVEL`, etc. — ver `.env.example`.

A sessão Playwright fica em `data/session_state_<hash>.json` **por utilizador** (não versionar; contém cookies).

## Uso

Na raiz do General (preferido — pede credenciais):

```powershell
.\scripts\Consultar-PSAI-SGD.ps1 130298
.\scripts\Consultar-PSAI-SGD.ps1 130298 --json
.\scripts\Consultar-PSAI-SGD.ps1 130298 --json --quiet
```

Diretamente com Python (pede credenciais no terminal se ainda não estiverem no ambiente):

```powershell
python scripts/sgd_consulta/consultar_psai.py 130298
python scripts/sgd_consulta/consultar_psai.py 130298 --json
```

Ou, com venv local nesta pasta:

```powershell
cd scripts\sgd_consulta
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
playwright install chromium
python consultar_psai.py 130298 --json
```

Saídas:

- **`--json`**: `data/consultas/psai_<numero>.json` (resumo estruturado).
- **Por defeito (arquivo completo)**: `data/consultas/arquivo/psai_<numero>/<run_id>/`
  - `page.html` — página inteira para inspeção offline / anexos em `href`
  - `body_inner_text_bruto.txt` / `body_inner_text_principal.txt` — texto plano antes e depois do corte de rodapé
  - `screenshot_pagina_completa.png`, `screenshot_viewport.png`, `grid_tabela_*.png` (até 40 tabelas)
  - `manifest.json` — contagens, lista de campos extraídos, **avisos** (ex.: campo esperado vazio, trâmites vazios)
  - `consulta.json` — mesmo payload do resumo + manifest
  - `ultima_execucao.json` na pasta `psai_<n>/` — apontador para a última pasta `run_id`
- **Log agregado** (para o General sugerir melhorias): `data/consultas/logs/psai-extracao.jsonl` (uma linha JSON por execução: códigos de aviso, tamanhos, contagem de trâmites, hash do utilizador).

`--no-arquivo` — só gera o screenshot simples em `data/consultas/` (comportamento antigo, mais leve).

**Projeto-filho:** o mesmo fluxo de credenciais — `.\scripts\Consultar-PSAI-SGD.ps1` dentro de `projeto-filho`.

## Enriquecer fracionados (`dados-brutos/psai`) a partir do SGD

Quando `comportamento` e/ou `definicao` (ou `psai_descricao`) estiverem **vazios** no JSON fracionado mas existirem no SGD (extracao ODBC/importacao incompleta ou mapeamento errado), grave os textos no repositorio:

```powershell
.\scripts\Enriquecer-PSAI-DadosBrutos.ps1 130475
.\scripts\Enriquecer-PSAI-DadosBrutos.ps1 130475 130476 -DryRun   # so simular
```

Equivalente Python (mesmas credenciais que `consultar_psai.py`):

```powershell
cd scripts\sgd_consulta
python enriquecer_psai_dados_brutos.py 130475
```

Usa lock `scripts\.update-lock.json` (igual a outros atualizadores). Opcao `--arquivo-sgd` gera tambem pasta `arquivo/psai_<n>/` na consulta.

## Documentação do fluxo

Ver `banco-dados/sais/cache/REFERENCIA.md` (secção SGD).
