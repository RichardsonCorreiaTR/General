# Regra de Negocio: RN-INSS-002 — INSS sobre 13o Salario

## Metadados

| Campo | Valor |
|---|---|
| **ID** | RN-INSS-002 |
| **Titulo** | Calculo do INSS sobre 13o salario |
| **Modulo** | INSS |
| **Autor** | Agente IA (semente - precisa validacao) |
| **Data** | 2026-03-04 |
| **Versao** | 0.1 |
| **Status** | Rascunho |
| **Prioridade** | Alta |

## Contexto

O INSS sobre 13o tem tributacao separada da folha mensal. NEs frequentes
mostram erros no 13o com multiplos vinculos e no calculo da diferenca de 13o.

## Regra

1. O sistema DEVE calcular o INSS do 13o separadamente da folha mensal.
2. A incidencia DEVE ser sobre o valor integral do 13o (nao sobre cada parcela).
3. O desconto DEVE ocorrer integralmente na 2a parcela (dezembro).
4. Na 1a parcela (adiantamento), o sistema NAO DEVE descontar INSS.
5. Quando houver diferenca de 13o (janeiro), o sistema DEVE recalcular o INSS
   sobre o valor total e descontar/restituir a diferenca.
6. Com multiplos vinculos, o sistema DEVE somar os 13os de todos os vinculos
   para apurar a faixa correta.

## Condicoes de Aplicacao

- [x] 13o salario (1a parcela, 2a parcela ou diferenca)
- [x] Empregado ativo ou desligado no exercicio

## Excecoes

| Excecao | Motivo |
|---|---|
| 13o proporcional na rescisao | INSS calculado junto com verbas rescisorias |
| Estagiario | Sem 13o e sem INSS |

## Exemplos Praticos

### Cenario Normal
**Dado que**: empregado com 13o integral de R$ 5.000
**Quando**: calculo da 2a parcela em dezembro
**Entao**: INSS calculado sobre R$ 5.000 (progressivo), descontado integralmente

### Cenario Diferenca
**Dado que**: reajuste salarial retroativo apos dezembro
**Quando**: calculo da diferenca de 13o em janeiro
**Entao**: INSS recalculado sobre o novo valor integral, descontando o ja pago

## Areas de Impacto

- [x] 13o salario
- [x] Calculo mensal
- [x] INSS / Previdencia
- [x] Rescisao
- [x] eSocial

## Dependencias

| Regra | Relacao |
|---|---|
| RN-INSS-001 | Depende de (aliquotas progressivas) |

## Base Legal

- Lei 8.212/91 Art. 28, par. 7o
- IN RFB 971 — Secao sobre 13o

## Criterios de Aceite

1. [x] INSS do 13o separado da folha mensal
2. [x] Sem desconto na 1a parcela
3. [x] Diferenca de 13o recalcula corretamente
4. [x] Multiplos vinculos: teto respeitado na soma

## SAIs relacionadas

- NE 91967/PSAI 115777: INSS e IRRF de diferenca de 13o incorretos
- NE 93223/PSAI 115725: Rubrica 8214 INSS diferenca 13o indevida

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (semente) |
