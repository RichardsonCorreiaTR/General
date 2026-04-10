# Regra de Negocio: RN-FGTS-001 — Deposito Mensal do FGTS

## Metadados

| Campo | Valor |
|---|---|
| **ID** | RN-FGTS-001 |
| **Titulo** | Calculo e deposito mensal do FGTS |
| **Modulo** | FGTS |
| **Autor** | Agente IA (semente - precisa validacao) |
| **Data** | 2026-03-04 |
| **Versao** | 0.1 |
| **Status** | Rascunho |
| **Prioridade** | Alta |

## Contexto

O FGTS incide sobre a remuneracao mensal a 8% (2% para aprendiz).
NEs frequentes envolvem a base de FGTS CCT, FGTS na rescisao e
divergencias entre a base FGTS e os relatorios.

## Regra

1. O sistema DEVE calcular 8% de FGTS sobre a remuneracao bruta mensal.
2. Para aprendiz, a aliquota DEVE ser 2%.
3. A base de FGTS DEVE incluir: salario, HE, adicionais, comissoes, DSR,
   ferias gozadas + 1/3, 13o salario (cada parcela).
4. A base NAO DEVE incluir: ferias indenizadas, aviso previo indenizado,
   PLR (parcela ate limite legal).
5. Na diferenca salarial retroativa (CCT), o sistema DEVE calcular FGTS
   complementar sobre cada diferenca.
6. O valor DEVE constar no FGTS Digital e nos relatorios do sistema.

## Condicoes de Aplicacao

- [x] Todo empregado CLT (incluindo domestico)
- [x] Folha mensal, ferias, 13o, rescisao

## Excecoes

| Excecao | Motivo |
|---|---|
| Estagiario | Sem FGTS |
| Diretor sem vinculo CLT | Opcional |

## Exemplos Praticos

### Cenario Normal
**Dado que**: empregado com remuneracao bruta R$ 5.000
**Quando**: calculo da folha mensal
**Entao**: FGTS = R$ 5.000 x 8% = R$ 400

### Cenario CCT
**Dado que**: diferenca salarial retroativa de 3 meses, R$ 200/mes
**Quando**: calculo das diferencas
**Entao**: FGTS complementar = R$ 200 x 3 x 8% = R$ 48

## Areas de Impacto

- [x] Calculo mensal
- [x] Ferias
- [x] 13o salario
- [x] Rescisao (GRRF)
- [x] FGTS
- [x] eSocial
- [x] Relatorios gerenciais

## Base Legal

- Lei 8.036/90 Arts. 15 e 18
- LC 150/2015 Art. 34 (domesticos)

## Criterios de Aceite

1. [x] 8% sobre base correta (2% aprendiz)
2. [x] Base FGTS nos relatorios = base no FGTS Digital
3. [x] FGTS CCT complementar correto
4. [x] FGTS 13o calculado sobre cada parcela

## SAIs relacionadas

- NE 92584/PSAI 116419: FGTS CCT complementar incorreto
- NE 92545/PSAI 116684: FGTS 13o CCT no calculo complementar
- NE 93758/PSAI 118352: FGTS CCT nos relatorios extrato/resumo
- NE 93443/PSAI 118231: Colunas FGTS e FGTS GRRF/Rescisao incorretas

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (semente) |
