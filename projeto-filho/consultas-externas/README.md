# Consultas externas (projeto-filho)

Canal para **outro projeto Cursor** pedir busca de SAI e pesquisa no codigo-fonte, e receber o resultado em arquivo.

## Pastas

| Pasta | Quem usa |
|-------|----------|
| `entrada/` | O outro projeto grava `*.json` (pedido) |
| `processando/` | Uso interno do processador |
| `saida/` | JSON de resposta (`{id}.json`) |
| `erros/` | Copia do pedido se falhar |
| `cliente/` | Pacote para copiar no outro projeto |

## Processar a fila (neste projeto-filho)

```
cd C:\CursorEscrita\projeto-filho
powershell -File .\scripts\processar-consultas-externas.ps1
```

Tipos de pedido: `sai`, `codigo`, `ler-arquivo`, `sai-sgd`, `psai-sgd`.

No chat do Cursor aberto neste projeto-filho, voce pode pedir: **processe as consultas externas**.

Guia para o outro projeto: `cliente/README.md`.
