# Regra de Negocio: RN-FER-001 — Calculo de Medias para Ferias

## Metadados

| Campo | Valor |
|---|---|
| **ID** | RN-FER-001 |
| **Titulo** | Calculo de medias de variaveis para ferias |
| **Modulo** | Ferias |
| **Autor** | Agente IA (semente - precisa validacao) |
| **Data** | 2026-03-04 |
| **Versao** | 0.1 |
| **Status** | Rascunho |
| **Prioridade** | Alta |

## Contexto

O calculo de medias para ferias e um dos maiores geradores de NEs. Envolve
horas extras, adicionais, comissoes e DSR sobre variaveis nos ultimos 12 meses.
Cenarios com transferencia entre empresas e CCT ampliam a complexidade.

## Regra

1. O sistema DEVE calcular a media dos ultimos 12 meses de variaveis habituais
   para compor a remuneracao de ferias.
2. Variaveis incluidas na media: horas extras, adicionais (noturno, periculosidade,
   insalubridade se variavel), comissoes, DSR sobre variaveis.
3. O sistema DEVE considerar apenas meses efetivamente trabalhados como divisor.
4. Quando houver transferencia entre empresas, o sistema DEVE considerar os
   valores da empresa de origem no periodo anterior a transferencia.
5. O sistema DEVE incluir o DSR sobre medias no calculo de ferias.
6. O 1/3 constitucional DEVE incidir sobre o total (salario + medias).

## Condicoes de Aplicacao

- [x] Ferias individuais, coletivas ou em grupo
- [x] Empregado com rubricas variaveis nos ultimos 12 meses
- [x] Ferias gozadas ou indenizadas

## Excecoes

| Excecao | Motivo |
|---|---|
| Adicionais fixos (insalubridade fixa) | Nao entram na media, entram diretamente |
| Comissionado puro sem salario fixo | Calculo especifico sobre comissoes |

## Exemplos Praticos

### Cenario Normal
**Dado que**: empregado com HE media de R$ 500/mes nos ultimos 12 meses
**Quando**: calculo de ferias de 30 dias
**Entao**: media de HE (R$ 500) + DSR proporcional somados ao salario base para calculo

### Cenario Transferencia
**Dado que**: empregado transferido da empresa A para B ha 4 meses
**Quando**: calculo de ferias na empresa B
**Entao**: media considera 8 meses na empresa A + 4 meses na empresa B

## Areas de Impacto

- [x] Ferias
- [x] Rescisao (ferias proporcionais/vencidas)
- [x] 13o salario (medias similares)
- [x] INSS / Previdencia
- [x] IRRF
- [x] FGTS
- [x] eSocial
- [x] Provisoes contabeis

## Dependencias

| Regra | Relacao |
|---|---|
| RN-FER-002 | Complementa (fracionamento) |
| RN-INSS-001 | Depende de (incidencia sobre ferias) |

## Base Legal

- CLT Art. 142, par. 3o e 5o — Media de variaveis para ferias
- Sumula 253 TST — DSR integra remuneracao de ferias

## Criterios de Aceite

1. [x] Media calculada corretamente com divisor de meses trabalhados
2. [x] DSR sobre medias incluido
3. [x] 1/3 sobre total (salario + medias)
4. [x] Transferencia: valores da empresa origem considerados

## SAIs relacionadas

- NE 93425/PSAI 116837: Ferias e INSS sobre diferenca de ferias na rescisao
- NE 93282/PSAI 117791: Medias de ferias vencidas incorretas
- NE 93306/PSAI 117960: Medias incorretas quando colaborador transferido
- NE 93620/PSAI 117034: Competencia de ferias na consulta de medias

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (semente) |
