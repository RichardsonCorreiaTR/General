# General — Escrita SDD (Projeto Admin + projeto-filho)

Repositorio unico com o **projeto admin** (gestao de definicoes Escrita Fiscal) e a pasta **`projeto-filho/`** (pacote distribuido aos analistas). Nao e repositorio de aplicacao; e base de conhecimento, templates e automacao (metodologia SDD).

## Documentacao principal

- **[PROJETO.md](PROJETO.md)** — blueprint mestre (estrutura, papeis, fluxos, OneDrive).
- **[banco-dados/sdd-construcao.md](banco-dados/sdd-construcao.md)** — arquitetura e restricoes do ambiente.
- **[scripts/README.md](scripts/README.md)** — scripts PowerShell (importacao SAIs, atualizacao, revisao).

## GitHub

Remoto sugerido: `https://github.com/RichardsonCorreiaTR/General.git`

## Apos clonar (sem dados brutos no Git)

O `.gitignore` **nao versiona** caches pesados nem `banco-dados/dados-brutos/`. Quem clona recebe regras, indices leves onde aplicavel, templates e scripts, mas **nao** o JSON monolitico de SAIs (~165 MB) nem fracionados completos.

Para ter a base alinhada ao ambiente corporativo:

1. **OneDrive / SharePoint** — sincronizar a biblioteca **CursorEscrita - General** (ver `PROJETO.md` secao 5), **ou**
2. **Gerente / maquina com ODBC / BuscaSAI** — rodar `scripts\atualizar-tudo.bat` ou `importar-sais.ps1` em **terminal fora do Cursor** (ver `protecao-oom.mdc` e `banco-dados/config/README.md`).

## Credenciais ODBC

O arquivo `config/conexao-odbc.json` **nao** vai para o Git. Copie `config/conexao-odbc.example.json` para `config/conexao-odbc.json` e preencha localmente.

## Projeto filho (analistas)

Codigo-fonte e pacote de atualizacao: pasta **`projeto-filho/`** e `distribuicao/ultima-versao/`. Instalacao: `scripts\instalar-projeto-filho.ps1` (padrao `C:\CursorEscrita\projeto-filho`).
