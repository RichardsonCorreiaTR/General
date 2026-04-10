# Regra de Negocio: RN-CAL-001 — Diferenca Salarial Retroativa (CCT)

## Metadados

| Campo | Valor |
|---|---|
| **ID** | RN-CAL-001 |
| **Titulo** | Calculo de diferenca salarial retroativa por CCT |
| **Modulo** | Calculo |
| **Autor** | Agente IA (semente - precisa validacao) |
| **Data** | 2026-03-04 |
| **Versao** | 0.1 |
| **Status** | Rascunho |
| **Prioridade** | Alta |

## Contexto

A diferenca salarial retroativa por Convencao Coletiva de Trabalho (CCT)
e um dos temas mais complexos e com mais NEs. Envolve recalcular meses
anteriores e todas as incidencias (INSS, IRRF, FGTS, ferias, 13o).

## Regra

1. O sistema DEVE recalcular retroativamente todos os meses desde a
   data-base ate a competencia atual quando houver reajuste por CCT.
2. Para cada competencia retroativa, o sistema DEVE calcular a diferenca
   entre o valor novo e o valor pago originalmente.
3. As incidencias (INSS, IRRF, FGTS) DEVEM ser recalculadas sobre a
   diferenca, respeitando as tabelas vigentes em cada competencia.
4. Diferenca de ferias e 13o retroativo DEVEM ser calculadas proporcionalmente.
5. O sistema DEVE considerar a forma de reajuste: percentual, valor fixo
   ou piso salarial.
6. Na folha de pagamento, as diferencas DEVEM ser demonstradas em rubricas
   separadas (diferenca salarial, diferenca HE, diferenca ferias, etc.).

## Condicoes de Aplicacao

- [x] Reajuste por CCT com data-base retroativa
- [x] Empregado ativo ou desligado apos a data-base

## Excecoes

| Excecao | Motivo |
|---|---|
| Empregado desligado antes da data-base | Sem direito ao reajuste |
| Intermitente (em alguns cenarios) | Regra especifica de calculo |

## Exemplos Praticos

### Cenario Normal
**Dado que**: CCT com reajuste de 5% retroativo a maio, processado em agosto
**Quando**: calculo de diferencas
**Entao**: diferencas de maio, junho e julho calculadas e pagas em agosto, com incidencias

### Cenario com Ferias no Periodo
**Dado que**: empregado teve ferias em junho, reajuste retroativo a maio
**Quando**: calculo de diferencas
**Entao**: diferenca de ferias de junho tambem calculada (salario novo x ferias)

## Areas de Impacto

- [x] Calculo mensal
- [x] Ferias
- [x] 13o salario
- [x] Rescisao
- [x] INSS / Previdencia
- [x] IRRF
- [x] FGTS
- [x] eSocial
- [x] Relatorios gerenciais

## Base Legal

- CLT Art. 611 — Convencao coletiva
- CLT Art. 611-A — Prevalencia do negociado (Reforma)

## Criterios de Aceite

1. [x] Diferencas calculadas mes a mes retroativamente
2. [x] INSS/IRRF/FGTS recalculados por competencia
3. [x] Rubricas de diferenca separadas no recibo
4. [x] Diferenca de ferias e 13o incluidas
5. [x] Base nos relatorios (extrato/resumo) consistente

## SAIs relacionadas

- NE 91496/PSAI 115747: Diferencas de salario com alteracao salarial
- NE 95069/PSAI 119453: FGTS CCT com alteracao salarial incorreto
- NE 95518/PSAI 120213: Diferenca salarial retroativa CCT incorreta
- NE 96420/PSAI 119535: Divergencia base INSS CCT nos relatorios
- NE 93690/PSAI 118456: Diferenca salarios e licenca remunerada

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (semente) |
