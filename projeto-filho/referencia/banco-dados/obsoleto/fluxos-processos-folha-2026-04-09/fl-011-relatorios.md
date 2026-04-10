# Fluxo de Processo: FL-011 - Relatorios da Folha

## Metadados

| Campo | Valor |
|---|---|
| **ID** | FL-011 |
| **Titulo** | Emissao de Relatorios Gerenciais e Legais |
| **Modulo** | Relatorios |
| **Autor** | Agente IA (base: codigo-fonte + SAIs) |
| **Data** | 2026-03-04 |
| **Versao** | 0.2 (revisado - pendente aprovacao) |

## Objetivo do Fluxo

Descreve os relatorios disponiveis no sistema, sua finalidade e momento
de emissao dentro do ciclo da folha.

## Categorias de Relatorios

### Relatorios do ciclo mensal (apos calculo)

| Relatorio | PBL | Finalidade |
|---|---|---|
| Recibo/Holerite | forel01 | Demonstrativo ao empregado |
| Resumo da Folha | forel02 | Totalizacao por rubrica |
| Extrato da Folha | forel03 | Detalhamento por empregado |
| Folha Analitica | forel04 | Visao completa por empregado |
| Relacao Bancaria | forel06 | Pagamento via banco |

### Relatorios de guias (apos calculo)

| Relatorio | PBL | Finalidade |
|---|---|---|
| GPS (INSS) | forel05 | Guia de recolhimento previdenciario |
| DARF (IRRF) | forel14 | Guia de IRRF |
| FGTS Digital | forel14 | Arquivo FGTS |
| PIS | forel14 | Guia PIS sobre folha |

### Relatorios anuais/periodicos

| Relatorio | PBL | Finalidade | Prazo |
|---|---|---|---|
| DIRF/Informe rendimentos | forel19 | Declaracao IR na fonte | Fev (ano seguinte) |
| RAIS (extinta, via eSocial) | forel19 | Relacao trabalhadores | Via eSocial |
| PPP | focad05 | Perfil profissiografico | Sob demanda |

### Relatorios de conferencia

| Relatorio | Finalidade |
|---|---|
| Log de calculo | Avisos e erros do processamento |
| Conferencia de bases | INSS, IRRF, FGTS comparados |
| Provisoes | Saldo provisionado vs realizado |

## Fluxo de Emissao

```
CALCULO FINALIZADO (FL-001)
  |
  v
[1] Emitir recibos/holerites
  |
  v
[2] Emitir resumo e extrato para conferencia
  |
  v
[3] Emitir guias (GPS, DARF, FGTS) - ver FL-007
  |
  v
[4] eSocial transmitido (FL-006)
  |
  v
[5] Fechar competencia
  |
  v
ANUALMENTE:
  |
  v
[6] DIRF/Informe de rendimentos (fevereiro)
```

## Regras de Negocio Relacionadas

Nenhuma regra especifica da base aplica-se diretamente a este fluxo.

## NEs recorrentes em relatorios

Padroes de erro mais comuns:
- Divergencia entre base INSS/FGTS no extrato vs resumo
- Valores de FGTS CCT incorretos nos relatorios
- Campo base IRRF incorreto no extrato
- Excedente demonstrado incorretamente

## Observacoes

- Sao ~22 PBLs de relatorios (~800 arquivos no codigo).
- RAIS e CAGED foram substituidos pelo eSocial.

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (rascunho) |
| 0.2 | 2026-03-04 | Agente IA | Revisao: cruzamento com regras e mapa |
