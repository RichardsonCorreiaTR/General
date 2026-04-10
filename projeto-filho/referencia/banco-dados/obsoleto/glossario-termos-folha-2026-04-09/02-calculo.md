# Glossario: Calculo de Folha

> Termos do nucleo de calculo da folha de pagamento

---

## Competencia

**Definicao:** Mes/ano de referencia do calculo. Ex: competencia 01/2026 = janeiro de 2026. Diferente da data de pagamento.

**Atencao:** O fato gerador de IRRF e a data de pagamento, nao a competencia.

---

## Rubrica (Evento de Provento/Desconto)

**Definicao:** Codigo que representa um provento ou desconto na folha. Ex: 8883 - DIARIAS NAO TRIBUTAVEIS, 8215 - IRRF DIFERENCA 13o SALARIO.

**Configuracoes:** Base de calculo, incidencias tributarias, integracao eSocial, formula personalizada.

---

## Base de Calculo

**Definicao:** Valor sobre o qual se aplica uma aliquota para calcular um tributo ou beneficio. Ex: "Base 45 - IRRF Juros sobre o Capital Proprio". Configurada na guia "Soma na Base de Calculo" da rubrica.

---

## DSR - Descanso Semanal Remunerado

| Campo | Valor |
|---|---|
| **Sigla** | DSR |
| **Sinonimos** | RSR (Repouso Semanal Remunerado) |
| **Base Legal** | CLT |

**Definicao:** Calculo do descanso semanal sobre horas extras, adicional noturno e outras verbas variaveis. Proporcional aos dias uteis e domingos/feriados.

---

## Folha Mensal

**Definicao:** Processamento principal do calculo da folha de pagamento de uma competencia. Inclui proventos, descontos, encargos e geracoes para eSocial.

---

## Folha Complementar

**Definicao:** Calculo adicional apos a folha mensal para ajustes, diferencas salariais ou correcoes. Pode haver mais de uma complementar por competencia. Usada em cenarios de dissidio, alteracao salarial retroativa.

---

## Antecipacao Salarial

**Definicao:** Adiantamento de parte do salario antes do fechamento da folha. O desconto pode ser proporcional ao periodo trabalhado quando ha eventos como ferias ou afastamento no mes.

---

## Garantia Minima

**Definicao:** Valor minimo garantido ao empregado quando o liquido fica negativo apos descontos. O sistema ajusta automaticamente os descontos para preservar o valor minimo configurado.

---

## Media e Vantagem

**Definicao:** Calculo de media de verbas variaveis (HE, comissoes, adicionais) para integracao em ferias, 13o, rescisao e afastamentos. Configurada no sindicato como regra parametrica.
