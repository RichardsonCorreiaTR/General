# Regra de Negocio: RN-INSS-003 — INSS sobre Diferenca Salarial CCT

## Metadados

| Campo | Valor |
|---|---|
| **ID** | RN-INSS-003 |
| **Titulo** | Calculo do INSS sobre diferenca salarial retroativa (CCT) |
| **Modulo** | INSS |
| **Autor** | Agente IA (extraida de NEs recorrentes) |
| **Data** | 2026-03-04 |
| **Versao** | 0.1 |
| **Status** | Rascunho |
| **Prioridade** | Alta |

## Contexto

Quando uma CCT gera diferenca salarial retroativa, o INSS deve ser
recalculado por competencia. E um dos cenarios com mais NEs.

## Regra

1. O sistema DEVE recalcular o INSS de cada competencia retroativa usando
   a tabela vigente naquela competencia.
2. O complemento DEVE ser: INSS novo - INSS ja descontado.
3. Se o empregado ja atingiu o teto na competencia original, a diferenca
   salarial NAO DEVE gerar INSS adicional.
4. A base INSS CCT nos relatorios DEVE refletir o total original + diferenca.
5. Para eSocial, o sistema DEVE gerar S-1200 retificador se a diferenca
   for de competencia ja transmitida.

## Condicoes de Aplicacao

- [x] Reajuste CCT com retroatividade
- [x] Empregado ativo ou desligado apos data-base

## Base Legal

- Lei 8.212/91 Art. 28 — Salario de contribuicao
- IN RFB 971 — Competencia de incidencia

## SAIs relacionadas

- NE 95069/PSAI 119453: FGTS CCT com alteracao salarial
- NE 96420/PSAI 119535: Divergencia base INSS CCT nos relatorios
- NE 95068/PSAI 119474: Base INSS CCT com antecipacao salarial
- NE 93073/PSAI 116937: Base INSS e FGTS CCT nos relatorios

## Dependencias

| Regra | Relacao |
|---|---|
| RN-CAL-001 | Depende de (diferenca salarial) |
| RN-INSS-001 | Depende de (aliquotas progressivas) |

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao (extraida de NEs) |
