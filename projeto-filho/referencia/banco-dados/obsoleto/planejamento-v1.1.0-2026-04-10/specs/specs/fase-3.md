# Spec Tecnica - Fase 3: Automacao Silenciosa

> Gerado em: 07/03/2026
> Base: PLANO.md secao Fase 3, PENDENTES.md D4/D5

---

## 1. RESUMO

Pipeline automatizado que roda importacao + geracao de indices a cada 3h,
silenciosamente, sem interacao do usuario. Loga resultados e grava status.

---

## 2. ARQUIVOS A CRIAR

### 2.1 scripts/atualizar-silencioso.ps1

Script principal da automacao. Fluxo:

```
1. PRE-CHECK
   - OneDrive rodando? (Get-Process OneDrive)
   - ODBC DSN disponivel? (Get-OdbcDsn)
   - Outro processo de importacao rodando? (lock)
   Se falhar: loga erro, exit 1

2. EXECUTAR
   - Chamar importar-sais.ps1 -Incremental
   - Capturar output + erros

3. POS-CHECK
   - Fracionados PSAI existem? Quantos?
   - Indices MD existem? Quantos?
   - Cache local existe? Tamanho?
   - Algum erro na execucao?

4. GRAVAR STATUS
   - atualizacao/status.json com resultado
   - atualizacao/log-importacao.txt (append)

5. EXIT
   - Exit 0 se sucesso
   - Exit 1 se falha (sera retentado na proxima janela)
```

Parametros: nenhum (totalmente autonomo)
Encoding: UTF8
Sem popup, sem Read-Host, sem pause

### 2.2 scripts/agendar-atualizacao.ps1

Script auxiliar para criar a tarefa no Task Scheduler.
Executar UMA VEZ (setup). Parametros:

- [switch]$Remover : Remove a tarefa em vez de criar
- [string]$HoraInicial = "08:00" : Hora da primeira execucao

Cria tarefa "FolhaSDD-Atualizacao" com:
- Gatilho 1: AtLogOn (ao fazer logon do usuario atual)
- Gatilho 2: Daily com repeticao a cada 3h (08:00, 11:00, 14:00, 17:00)
- Dias: Segunda a sexta (DaysOfWeek Mon,Tue,Wed,Thu,Fri)
- Acao: powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "path/atualizar-silencioso.ps1"
- Settings: AllowStartIfOnBatteries, DontStopIfGoingOnBatteries, StartWhenAvailable
- RunLevel: Limited (nao precisa de admin)

### 2.3 atualizacao/status.json

Gravado a cada execucao de atualizar-silencioso.ps1:

```json
{
  "ultimaExecucao": "2026-03-07T14:30:00",
  "resultado": "sucesso",
  "tempoSegundos": 158,
  "registrosProcessados": 29372,
  "fracionadosPSAI": 12,
  "fracionadosSAI": 12,
  "indicesMD": 51,
  "smartWriteEscritos": 0,
  "smartWritePulados": 51,
  "cacheMB": 165.4,
  "erro": null
}
```

### 2.4 atualizacao/log-importacao.txt

Append-only. Formato por linha:
```
[2026-03-07 14:30:00] SUCESSO | 29372 reg | 158s | 0 escritos, 51 pulados
[2026-03-07 11:00:00] SUCESSO | 29372 reg | 160s | 2 escritos, 49 pulados
[2026-03-07 08:00:00] FALHA | ODBC indisponivel | DSN pbcvs9 nao encontrado
```

---

## 3. ARQUIVOS A ALTERAR

### 3.1 scripts/gerar-indices-sais.ps1

Mudanca MINIMA: ao final da execucao, gravar contadores em arquivo
temporario para que atualizar-silencioso.ps1 possa ler.

Adicionar apos a mensagem "=== Concluido! ===":
```
$statsFile = Join-Path $projetoDir "atualizacao\.stats-temp.json"
@{
    smartEscritos = $script:smartEscritos
    smartPulados = $script:smartPulados
    totalRegistros = $total
    indicesMD = $script:smartEscritos + $script:smartPulados
} | ConvertTo-Json | Set-Content $statsFile -Encoding UTF8
```

---

## 4. DEPENDENCIAS E ORDEM

1. Alterar gerar-indices-sais.ps1 (gravar stats temp)
2. Criar atualizar-silencioso.ps1
3. Criar agendar-atualizacao.ps1
4. Testar: executar manualmente atualizar-silencioso.ps1
5. Verificar status.json e log-importacao.txt

---

## 5. CRITERIOS DE SUCESSO MENSURAVEIS

| Criterio | Meta | Como medir |
|----------|------|------------|
| atualizar-silencioso.ps1 roda sem erro | Exit 0 | $LASTEXITCODE |
| status.json gravado | Existe e valido | Test-Path + ConvertFrom-Json |
| log-importacao.txt atualizado | Ultima linha recente | Get-Content -Tail 1 |
| Pre-check detecta ODBC ausente | Loga FALHA se DSN nao existe | Testar sem DSN |
| Sem popup/interacao | Nenhum Read-Host/pause | Grep no codigo |
| agendar-atualizacao.ps1 cria tarefa | Get-ScheduledTask funciona | Verificar |

---

## 6. RISCOS

| Risco | Probabilidade | Mitigacao |
|-------|---------------|----------|
| Task Scheduler requer admin | Baixa | RunLevel Limited, sem admin |
| ODBC indisponivel em VPN | Media | Pre-check loga e pula |
| OneDrive parado | Baixa | Pre-check verifica processo |
| Lock de outro processo | Baixa | lib-lock.ps1 ja gerencia |

---

## Validacao

(sera preenchido na Etapa 2)

---

## Validacao (Etapa 2 - 07/03/2026)

### Checklist PLANO.md Fase 3

- [x] Task Scheduler: gatilho ao logon
- [x] Task Scheduler: gatilho a cada 3h (8h, 11h, 14h, 17h)
- [x] Dias: segunda a sexta
- [x] Acao: PowerShell silencioso (sem popup)
- [x] Pre-check: ODBC disponivel? OneDrive rodando?
- [x] Falha: loga erro, tenta na proxima janela
- [x] Verificacao pos-execucao: confere arquivos e grava status.json
- [x] Arquivos criados: atualizar-silencioso.ps1, agendar-atualizacao.ps1, status.json, log-importacao.txt

### Checklist PENDENTES.md

- [x] D4: Ao logar + cada 3h, seg-sex
- [x] D5: Guardiao verifica status.json

### Checklist SWOT.md

- [x] W5: Teste manual (1 execucao)

### Verificacao de paths reais

- [x] scripts/importar-sais.ps1: EXISTE (sera chamado)
- [x] scripts/lib-lock.ps1: EXISTE (sera usado)
- [x] atualizacao/: EXISTE (destino status.json e log)
- [x] scripts/gerar-indices-sais.ps1: EXISTE (sera alterado)

### RESULTADO

Validada em 07/03/2026. Nenhuma inconsistencia encontrada.
