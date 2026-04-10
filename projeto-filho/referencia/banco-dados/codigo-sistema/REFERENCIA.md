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
| **Branch** | VC106A02 |
| **Fonte** | GitHub tr/brtap-dominio_contabil |

O script `atualizar-codigo.ps1` detecta automaticamente qual caminho usar
(EscritaSDD, FolhaSDD legado ou padrao novo). Copia a pasta `escrita\` do repositorio.

## Como acessar

1. Consultar o **mapa do sistema**: `banco-dados/mapa-sistema/mapa-escrita.md` (e `indice-mapas-areas.md` para Importação / Onvio Escrita)
2. Consultar o **indice de arquivos**: `banco-dados/mapa-sistema/indice-arquivos.md`
3. Para atualizar: `scripts\atualizar-codigo.ps1` (terminal separado)

## Para instalar/atualizar

Rode em terminal separado (fora do Cursor):
```
scripts\atualizar-codigo.ps1
```
O script faz clone/pull do Git e gera o indice de arquivos automaticamente.
