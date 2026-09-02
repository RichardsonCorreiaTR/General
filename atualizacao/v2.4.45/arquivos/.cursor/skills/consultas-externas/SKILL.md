---
name: consultas-externas
description: Processar a fila consultas-externas (SAI e codigo-fonte) vinda de outro projeto Cursor
---

# Processar consultas externas

Quando o analista pedir para processar a fila ou houver JSON em `consultas-externas/entrada/`:

```
powershell -File scripts/processar-consultas-externas.ps1
```

Leia cada `consultas-externas/saida/{id}.json` e entregue o resumo. SAIs em tabela com links SGD/SGSAI. Codigo: path, branch, traducao de produto. Nao abrir dados-brutos no Cursor.
