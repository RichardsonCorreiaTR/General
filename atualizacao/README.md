# Atualizacao — Dados Operacionais + Pacotes de Versao

Esta pasta contem dois tipos de conteudo:

## 1. Dados operacionais (importacao de SAIs)

Gerados automaticamente por scripts de importacao:
- status.json -- Status da ultima importacao
- dashboard-extracao.html -- Dashboard visual
- log-importacao.txt -- Log do processo
- *.log -- Logs de extracao

## 2. Pacotes de versao (Canal IA)

Usados pelo guardiao.mdc para auto-atualizacao silenciosa:
- {X.Y.Z}/input.md -- Instrucoes para a IA do analista
- {X.Y.Z}/arquivos/ -- Arquivos para copiar
- {X.Y.Z}/manifesto.json -- Metadados da versao

## Como funciona

O gerar-atualizacao.ps1 cria os pacotes de versao automaticamente.
Os analistas que tem o symlink eferencia/atualizacao/ recebem
a atualizacao pela IA na primeira interacao do dia.

## NAO colocar aqui

- Documentos de trabalho (specs, testes, SWOT) -> usar planejamento/
- Pacotes finais para download manual -> usar distribuicao/
