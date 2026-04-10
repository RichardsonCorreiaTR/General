# Regra de Negocio: RN-FER-002 — Fracionamento de Ferias

## Metadados

| Campo | Valor |
|---|---|
| **ID** | RN-FER-002 |
| **Titulo** | Fracionamento de ferias em ate 3 periodos |
| **Modulo** | Ferias |
| **Autor** | Agente IA (semente - precisa validacao) |
| **Data** | 2026-03-04 |
| **Versao** | 0.1 |
| **Status** | Rascunho |
| **Prioridade** | Media |

## Contexto

A Reforma Trabalhista (Lei 13.467/2017) permitiu o fracionamento de ferias
em ate 3 periodos, mediante concordancia do empregado.

## Regra

1. O sistema DEVE permitir fracionamento de ferias em ate 3 periodos.
2. Um dos periodos DEVE ter no minimo 14 dias corridos.
3. Os demais periodos NAO DEVEM ser inferiores a 5 dias corridos cada.
4. O sistema DEVE impedir fracionamento que viole os limites acima.
5. O pagamento de cada fracao DEVE ocorrer ate 2 dias antes do inicio do
   respectivo periodo.
6. O 1/3 constitucional DEVE ser pago proporcionalmente a cada fracao.

## Condicoes de Aplicacao

- [x] Ferias individuais
- [x] Concordancia do empregado registrada

## Excecoes

| Excecao | Motivo |
|---|---|
| Menor de 18 anos | Ferias devem ser concedidas de uma so vez |
| Maior de 50 anos (revogado) | Reforma Trabalhista revogou a restricao |
| Ferias coletivas | Regra propria (max 2 periodos, min 10 dias) |

## Exemplos Praticos

### Cenario Normal
**Dado que**: empregado com 30 dias de ferias
**Quando**: solicita fracionamento em 3 periodos
**Entao**: sistema permite 14 + 8 + 8, ou 15 + 10 + 5, etc.

### Cenario de Bloqueio
**Dado que**: empregado tenta fracionar em 14 + 12 + 4
**Quando**: registro da programacao
**Entao**: sistema BLOQUEIA (terceiro periodo < 5 dias)

## Areas de Impacto

- [x] Ferias
- [x] Calculo mensal (reflexo do afastamento)
- [x] eSocial (S-2230 por periodo)

## Base Legal

- CLT Art. 134, par. 1o (Reforma Trabalhista)
- CLT Art. 136 — Menores de 18 e estudantes

## Criterios de Aceite

1. [x] Sistema permite ate 3 periodos
2. [x] Validacao de 14 dias minimo no maior periodo
3. [x] Validacao de 5 dias minimo nos demais
4. [x] Bloqueio em caso de violacao
5. [x] Pagamento correto por fracao

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (semente) |
