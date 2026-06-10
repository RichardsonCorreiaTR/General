# Codigo-Fonte - Referencia

O codigo-fonte PowerBuilder do **modulo Escrita** fica na maquina LOCAL de cada
usuario. NAO fica no OneDrive porque o volume de arquivos causa problemas de
sync para o time.

## Localizacao

| Item | Caminho |
|---|---|
| **Padrao (novo)** | `C:\CursorEscrita\codigo-sistema\versao-atual\` |
| **Legado (migracao Folha)** | `C:\Users\{usuario}\FolhaSDD-dados-pesados\versao-atual\` |
| **Legado Escrita** | `C:\Users\{usuario}\EscritaSDD-dados-pesados\versao-atual\` |
| **Repositorio completo (local)** | `C:\1 - A\B\Programas\brtap-dominio\` — arvore do Dominio Contabil (escrita, contabil, folha, etc.); Git: `tr/brtap-dominio_contabil`. Navegacao no Cursor: `General-brtap-dominio.code-workspace` na raiz do General |
| **Branches declaradas** | `config/codigo-fonte-branches.json` (campos `vigente`, `vigente_anterior`, `em_dev`) |
| **Fonte** | GitHub `tr/brtap-dominio_contabil` (acesso via Team `fiscont-gp-codigo-leitura`) |

O script `atualizar-codigo.ps1` detecta automaticamente qual caminho usar
(EscritaSDD, FolhaSDD legado ou padrao novo). Le a branch de
`config/codigo-fonte-branches.json` (conceito `vigente` por padrao) e
copia a pasta `escrita\` do repositorio.

## Acesso GitHub (pre-requisito)

A leitura do repo exige usuario no Team **`fiscont-gp-codigo-leitura`**
(org `tr`) com permissao Read concedida pelo Fernando Pizetti. Fluxo
completo em `arquitetura/acesso-github-codigo.md`.

## Como acessar

1. Consultar o **mapa do sistema**: `banco-dados/mapa-sistema/mapa-escrita.md` (e `indice-mapas-areas.md` para Importação / Onvio Escrita)
2. Consultar o **indice de arquivos**: `banco-dados/mapa-sistema/indice-arquivos.md`
3. Para atualizar (local): `scripts\atualizar-codigo.ps1` (terminal separado)
4. Para consulta leve sem clonar (`gh api`), ver `.cursor/rules/acesso-github.mdc`.

## Para instalar/atualizar

Rode em terminal separado (fora do Cursor):
```
scripts\atualizar-codigo.ps1                 # usa branch 'vigente' do config
scripts\atualizar-codigo.ps1 -BranchConceito em_dev   # outra branch declarada
scripts\atualizar-codigo.ps1 -Branch ALGUMA   # override manual
```
O script faz clone/pull do Git e gera o indice de arquivos automaticamente.
