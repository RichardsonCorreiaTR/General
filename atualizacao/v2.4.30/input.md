# v2.4.30 — Regra SGD para comportamento vazio

## Arquivos alterados

- .cursor/rules/guardiao.mdc — nova secao: "Consulta ao SGD quando comportamento/definicao estiver vazio"
- config/VERSION.json — versao 2.4.30

## O que muda para o analista

O agente Cursor passa a verificar se comportamento e definicao estao vazios ao exibir uma PSAI:

- Se i_sai = 0 (PSAI sem SAI gerada) → campos nulos sao **esperados**, agente nao avisa
- Se i_sai > 0 e comportamento vazio → agente **avisa** o analista e aguarda pedido de consulta SGD
- Quando solicitado: executa `.\scripts\Consultar-PSAI-SGD.ps1 <numero> --json` automaticamente

## Como atualizar

Execute no terminal do projeto-filho:

```powershell
.\scripts\atualizar-projeto.ps1
```
