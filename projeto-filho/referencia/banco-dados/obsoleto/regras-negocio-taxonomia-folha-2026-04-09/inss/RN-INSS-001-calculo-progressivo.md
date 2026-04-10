# Regra de Negocio: RN-INSS-001 — Calculo Progressivo do INSS Segurado

## Metadados

| Campo | Valor |
|---|---|
| **ID** | RN-INSS-001 |
| **Titulo** | Calculo progressivo do INSS segurado (EC 103/2019) |
| **Modulo** | INSS |
| **Autor** | Agente IA (semente - precisa validacao) |
| **Data** | 2026-03-04 |
| **Versao** | 0.1 |
| **Status** | Rascunho |
| **Prioridade** | Alta |

## Contexto

A EC 103/2019 alterou o calculo do INSS segurado de aliquota unica para
aliquotas progressivas por faixa. NEs recorrentes mostram erros quando ha
multiplos vinculos, transferencia entre empresas ou antecipacao salarial.

## Regra

1. O sistema DEVE aplicar aliquotas progressivas por faixa de remuneracao.
2. Quando o empregado possui multiplos vinculos, o sistema DEVE considerar
   a soma das remuneracoes de todos os vinculos para determinar a faixa,
   respeitando o teto previdenciario.
3. O sistema DEVE calcular o INSS faixa a faixa (nao aliquota efetiva unica).
4. Quando houver transferencia entre empresas no mesmo mes, o sistema DEVE
   somar as remuneracoes para apurar o desconto correto e evitar duplicidade.

## Condicoes de Aplicacao

- [x] Empregado com vinculo CLT ativo
- [x] Competencia a partir de 03/2020 (vigencia EC 103)
- [x] Remuneracao sujeita a contribuicao previdenciaria

## Excecoes

| Excecao | Motivo |
|---|---|
| Estagiario sem vinculo | Nao contribui ao INSS via folha |
| Domestico (DAE) | Recolhimento unificado pelo DAE |

## Exemplos Praticos

### Cenario Normal
**Dado que**: empregado com salario de R$ 4.000,00, vinculo unico
**Quando**: calculo da folha mensal
**Entao**: INSS calculado faixa a faixa (7,5% + 9% + 12% nas faixas aplicaveis)

### Cenario Multiplos Vinculos
**Dado que**: empregado com 2 vinculos (R$ 3.000 + R$ 2.000)
**Quando**: calculo da folha em cada empresa
**Entao**: cada empresa desconta proporcionalmente, respeitando teto na soma (R$ 5.000)

## Areas de Impacto

- [x] Calculo mensal
- [x] Ferias
- [x] 13o salario
- [x] Rescisao
- [x] INSS / Previdencia
- [x] eSocial
- [x] Relatorios gerenciais

## Dependencias

| Regra | Relacao |
|---|---|
| RN-INSS-002 | Complementa (INSS 13o) |

## Base Legal

- EC 103/2019 (Reforma da Previdencia) — Arts. 28 e 29
- Portaria Interministerial (anual) — Faixas e teto vigentes

## Criterios de Aceite

1. [x] Valor INSS calculado faixa a faixa confere com calculo manual
2. [x] Multiplos vinculos: soma nao ultrapassa teto
3. [x] Transferencia no mes: sem duplicidade de desconto
4. [x] Base INSS nos relatorios confere com extrato

## SAIs relacionadas

- NE 91727/PSAI 115973: INSS 13o incorreto com multiplos vinculos
- NE 92251/PSAI 115976: Base INSS incorreta com rubrica especifica
- NE 92120/PSAI 115825: Base interna INSS incorreta com antecipacao

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (semente) |
