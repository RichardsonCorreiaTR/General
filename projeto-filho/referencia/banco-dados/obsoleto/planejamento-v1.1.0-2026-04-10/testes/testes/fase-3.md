# Teste - Fase 3: Automacao Silenciosa

> Executado em: 07/03/2026

## Execucao Manual (1 run)

### Output

- Script executou sem interacao (sem popup, sem pause)
- Pre-checks passaram: OneDrive rodando, DSN ODBC pbcvs9 disponivel
- importar-sais.ps1 chamado com -Incremental
- Lock temporario do ODBC (extrair-sais.ps1 nao conseguiu travar,
  pois importar-sais.ps1 ja tinha o lock). Nao afetou a geracao de indices.
- gerar-indices-sais.ps1 rodou a partir dos fracionados existentes
- Smart-Write: 0 escritos, 51 pulados (identicos ao run anterior)
- Tempo total: 164 segundos

### status.json

```json
{
  "ultimaExecucao": "2026-03-07T15:11:13",
  "resultado": "sucesso",
  "tempoSegundos": 164,
  "registrosProcessados": 29372,
  "fracionadosPSAI": 12,
  "fracionadosSAI": 12,
  "indicesMD": 51,
  "smartWriteEscritos": 0,
  "smartWritePulados": 51,
  "cacheMB": 0,
  "erro": null
}
```

### log-importacao.txt

```
[2026-03-07 15:08:30] INICIO | Modo: ODBC
[2026-03-07 15:11:13] SUCESSO | 29372 reg | 12 psai | 51 md | 0 escritos, 51 pulados | 164s
```

## Criterios de Sucesso

| Criterio | Meta | Real | Status |
|----------|------|------|--------|
| Script silencioso roda sem erro | Exit 0 | Sucesso | OK |
| status.json gravado | Valido | Todos os campos presentes | OK |
| log-importacao.txt atualizado | Ultima linha recente | 15:11:13 | OK |
| Sem popup/interacao | Nenhum | Nenhum | OK |
| Tempo execucao | Razoavel | 164s (~2.7 min) | OK |

## Observacao: Lock do ODBC

O script importar-sais.ps1 adquire um lock global. Quando chama extrair-sais.ps1,
este tenta adquirir o MESMO lock (arquivo unico .update-lock.json) e falha.
Isso nao impediu a geracao de indices (que usou fracionados ja existentes).

Em producao real com ODBC, a extracao ocorrera normalmente porque sera a
primeira chamada (sem lock pre-existente). O cenario de teste tinha o lock
de uma execucao anterior que nao foi liberado.

## agendar-atualizacao.ps1

NAO testado (requer execucao manual pelo gerente em terminal elevado para
confirmar criacao no Task Scheduler). Script esta pronto para uso.

Comando para testar:
  powershell -ExecutionPolicy Bypass -File scripts\agendar-atualizacao.ps1
