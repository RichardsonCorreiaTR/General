# Fluxo de Processo: FL-007 - Guias Fiscais e Recolhimentos

## Metadados

| Campo | Valor |
|---|---|
| **ID** | FL-007 |
| **Titulo** | Geracao de Guias de Recolhimento (GPS, DARF, FGTS, PIS) |
| **Modulo** | Guias Fiscais |
| **Autor** | Agente IA (base: codigo-fonte + SAIs) |
| **Data** | 2026-03-04 |
| **Versao** | 0.2 (revisado - pendente aprovacao) |

## Objetivo do Fluxo

Descreve o processo de geracao das guias de recolhimento fiscal e
previdenciario apos o calculo da folha mensal.

## Atores Envolvidos

| Ator | Papel no Fluxo |
|---|---|
| Departamento Pessoal / Contabilidade | Confere valores, efetua pagamentos |
| Sistema Folha | Calcula e gera guias |

## Fluxo Principal

```
INICIO (Calculo da folha finalizado - FL-001)
  |
  v
[1] Gerar GPS - INSS (Processos > Guias > GPS)
  |
  v
[2] Gerar DARF - IRRF (Processos > Guias > IRRF)
  |
  v
[3] Gerar guia FGTS Digital (Processos > Guias > FGTS)
  |
  v
[4] Gerar guia PIS (se aplicavel)
  |
  v
[5] Gerar DAE (domesticos, se aplicavel)
  |
  v
[6] Conferir valores com resumo da folha
  |
  v
[Divergencia?] --SIM--> [6A] Investigar e corrigir
  |
  NAO
  |
  v
[7] Efetuar pagamentos nos prazos legais
  |
  v
FIM
```

## Prazos legais

| Guia | Prazo |
|---|---|
| GPS (INSS) | Dia 20 do mes seguinte |
| DARF (IRRF) | Dia 20 do mes seguinte |
| FGTS | Dia 20 do mes seguinte (via FGTS Digital) |
| PIS | Dia 25 do mes seguinte |
| DAE | Dia 7 do mes seguinte |

## Descricao dos Passos

### Passo 1 - GPS
- **Ator**: Sistema Folha (forel05, uo_calc_guiainss.sru)
- **Acao**: Calcular contribuicao patronal + empregados. Gerar GPS com codigo de pagamento, competencia, valores.

### Passo 2 - DARF IRRF
- **Ator**: Sistema Folha (forel14)
- **Acao**: Totalizar IRRF retido na folha. Gerar DARF com codigo de receita.

### Passo 3 - FGTS Digital
- **Ator**: Sistema Folha (w_guia_fgts_digital.srw)
- **Acao**: Gerar arquivo para FGTS Digital com base nos dados da folha.

### Passo 4 - PIS
- **Ator**: Sistema Folha (uo_calc_guia_pis.sru)
- **Acao**: Calcular PIS sobre folha de pagamento (se empresa nao optante pelo Simples).

### Passo 5 - DAE
- **Ator**: Sistema Folha
- **Acao**: Gerar DAE para empregadores domesticos (unifica INSS, FGTS, IRRF).

### Passo 6 - Conferencia
- **Ator**: Departamento Pessoal / Contabilidade
- **Acao**: Cruzar valores das guias com resumo da folha e provisoes.

### Passo 7 - Pagamento
- **Ator**: Contabilidade
- **Acao**: Efetuar pagamentos dentro dos prazos legais.

## Regras de Negocio Relacionadas

| Regra | Onde se aplica |
|---|---|
| RN-INSS-001 | Passo 1 (GPS - calculo progressivo INSS) |
| RN-INSS-002 | Passo 1 (GPS - INSS sobre 13o quando aplicavel) |
| RN-IRRF-001 | Passo 2 (DARF - IRRF retido) |
| RN-FGTS-001 | Passo 3 (FGTS Digital - deposito mensal) |

## Observacoes

- GRRF (rescisao) segue fluxo de rescisao (FL-003).
- Rascunho - precisa validacao do gerente de produto.

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (rascunho) |
| 0.2 | 2026-03-04 | Agente IA | Revisao: cruzamento com regras e mapa |
