# Regra de Negocio: RN-CAL-004 — DSR sobre Variaveis

## Metadados

| Campo | Valor |
|---|---|
| **ID** | RN-CAL-004 |
| **Titulo** | Calculo do DSR sobre rubricas variaveis |
| **Modulo** | Calculo |
| **Autor** | Agente IA (extraida de NEs recorrentes) |
| **Data** | 2026-03-04 |
| **Versao** | 0.1 |
| **Status** | Rascunho |
| **Prioridade** | Media |

## Contexto

O Descanso Semanal Remunerado (DSR) incide sobre horas extras, comissoes
e outras rubricas variaveis. Erros no calculo afetam medias de ferias e 13o.

## Regra

1. O sistema DEVE calcular DSR sobre: horas extras, comissoes, adicional
   noturno variavel, gratificacoes variaveis.
2. Formula: DSR = (total da rubrica no mes / dias uteis) x domingos e feriados.
3. O DSR DEVE integrar a base para calculo de medias (ferias, 13o).
4. O DSR NAO DEVE incidir sobre rubricas fixas (salario base, insalubridade fixa).
5. Quando houver faltas injustificadas, o sistema DEVE reduzir o DSR
   proporcionalmente.
6. O DSR sobre comissoes DEVE usar a mesma formula, considerando dias
   uteis e nao-uteis do mes.

## Condicoes de Aplicacao

- [x] Empregado com rubricas variaveis no mes
- [x] Empregado horista ou mensalista com variaveis

## Excecoes

| Excecao | Motivo |
|---|---|
| Mensalista sem variaveis | DSR ja incluso no salario |
| Comissionado puro | DSR calculado sobre total de comissoes |

## Base Legal

- Lei 605/49 — Repouso semanal remunerado
- Sumula 172 TST — DSR sobre HE habituais integra ferias

## SAIs relacionadas

- NEs sobre situacoes de calculo (DSR em afastamentos, DSR sobre medias)
- Impacto transversal: ferias, 13o, INSS, FGTS sobre DSR

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao (extraida de NEs) |
