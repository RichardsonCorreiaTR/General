# Revisao - Fase 2: Smart Rewrite + Eliminar Monolitico

> Revisada em: 07/03/2026

## Checklist de Implementacao

| # | Item | Status |
|---|------|--------|
| 1 | extrair-sais.ps1: param inclui [switch]$GerarMonolitico | OK |
| 2 | extrair-sais.ps1: $destinoJson aponta para scripts/cache/ | OK |
| 3 | extrair-sais.ps1: funcao Smart-Write definida | OK |
| 4 | extrair-sais.ps1: funcao Gravar-Fracionados grava PSAI e SAI | OK |
| 5 | extrair-sais.ps1: Salvar-CacheFinal salva em cache + chama Gravar-Fracionados | OK |
| 6 | extrair-sais.ps1: GerarMonolitico grava no OneDrive quando habilitado | OK |
| 7 | gerar-indices-sais.ps1: header ~550 MB peak RAM, sem ref. monolitico | OK |
| 8 | gerar-indices-sais.ps1: sem referencia a sai-psai-folha.json | OK |
| 9 | gerar-indices-sais.ps1: Smart-Write com contadores (CORRIGIDO: recursao infinita detectada e corrigida) | OK |
| 10 | gerar-indices-sais.ps1: carrega PSAI fracionados sequencialmente | OK |
| 11 | gerar-indices-sais.ps1: Phase A (fracionamento) removida | OK |
| 12 | gerar-indices-sais.ps1: ZERO Set-Content externos (todos via Smart-Write) | OK |
| 13 | gerar-indices-sais.ps1: saida final mostra contadores smart-write | OK |
| 14 | importar-sais.ps1: $destinoJson aponta para scripts/cache/ | OK |
| 15 | importar-sais.ps1: $cacheDir criado e referenciado | OK |
| 16 | importar-sais.ps1: metadados incluem contagem de fracionados | OK |

## Bug Encontrado e Corrigido

A substituicao regex de Set-Content -> Smart-Write afetou TAMBEM o Set-Content
DENTRO da propria funcao Smart-Write, criando recursao infinita.

Correcao: restaurado Set-Content na linha 31 do gerar-indices-sais.ps1.
Verificado: unico Set-Content restante esta dentro da funcao Smart-Write.

## Resultado: 16/16 OK (1 bug corrigido durante revisao)
