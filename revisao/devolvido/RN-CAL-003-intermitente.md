# Regra de Negocio: RN-CAL-003 — Calculo do Trabalhador Intermitente

## Metadados

| Campo | Valor |
|---|---|
| **ID** | RN-CAL-003 |
| **Titulo** | Regras de calculo para contrato intermitente |
| **Modulo** | Calculo |
| **Autor** | Agente IA (extraida de NEs recorrentes) |
| **Data** | 2026-03-04 |
| **Versao** | 0.1 |
| **Status** | Rascunho |
| **Prioridade** | Media |

## Contexto

O contrato intermitente (CLT art. 443 e 452-A, Reforma Trabalhista) tem
regras especificas de calculo. Gera NEs frequentes por ser cenario atipico.

## Regra

1. O sistema DEVE calcular a remuneracao proporcionalmente ao periodo convocado.
2. Ao final de cada periodo de trabalho, o sistema DEVE pagar junto:
   remuneracao + ferias proporcionais + 1/3 + 13o proporcional + INSS + FGTS.
3. O sistema DEVE emitir recibo com todas as parcelas discriminadas.
4. Ferias: ao completar 12 meses de contrato, o empregado tem direito a 1 mes
   de inatividade (ja recebeu ferias proporcionais mensalmente).
5. INSS: se a remuneracao for inferior ao minimo, o empregado DEVE complementar.
6. Diferenca salarial retroativa no intermitente DEVE recalcular apenas os
   periodos efetivamente trabalhados.

## Condicoes de Aplicacao

- [x] Contrato de trabalho intermitente (art. 443 CLT)

## Excecoes

| Excecao | Motivo |
|---|---|
| Periodo de inatividade | Nao e tempo a disposicao, nao gera remuneracao |

## Exemplos Praticos

### Cenario Normal
**Dado que**: intermitente convocado por 10 dias, diaria R$ 200
**Quando**: final do periodo
**Entao**: R$ 2.000 + ferias prop + 1/3 + 13o prop + INSS + FGTS pagos junto

## Areas de Impacto

- [x] Calculo mensal
- [x] Ferias
- [x] 13o salario
- [x] INSS / Previdencia
- [x] FGTS
- [x] eSocial (categoria especifica)

## Base Legal

- CLT Art. 443 par. 3o e Art. 452-A (Reforma Trabalhista)

## SAIs relacionadas

- NE 96562/PSAI 120037: Diferencas de salario no intermitente incorretas

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao (extraida de NEs) |
