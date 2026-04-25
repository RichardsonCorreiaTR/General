# SAI [CODIGO] -- [Titulo]

## Identificacao

| Campo | Valor |
|---|---|
| **SAI** | [Codigo] |
| **PSAI** | [Codigo da PSAI vinculada] |
| **Tipo** | NE / SAM / SAL / SAIL |
| **Modulo** | [Modulo] |
| **Gravidade** | [Normal / Alta / Urgente] |
| **Versao** | [Ex: VC106A02] |
| **Analista** | [Nome] |
| **Data** | AAAA-MM-DD |
| **Status** | Em definicao / Em revisao / Aprovada |

## GERAL

> Contexto geral da alteracao. Objetivo, motivacao e relacao com outras SAIs.
> Descreva o problema que esta SAI resolve e como ela se encaixa no quadro geral.

[Descricao geral]

**SAIs relacionadas:**
- SAI XXXXX: [natureza da relacao]
- conforme SAI XXXXX: [referencia, se herda ou complementa]

## PROCESSOS

> Alteracoes em menus de processo: calculo mensal, rescisao, ferias,
> 13o salario, provisoes, integracao contabil, eSocial, etc.
> Descreva COMO o processo deve mudar, com regras e condicoes claras.

[Descricao das alteracoes em processos]

### Regras de calculo

> Formulas, condicoes, precedencias. Descreva com exemplos numericos.

[Regras, se aplicavel]

## ARQUIVO

> Alteracoes em cadastros, telas, campos, layouts de importacao/exportacao.
> Descreva campos novos, alterados ou removidos.

[Descricao das alteracoes em telas/cadastros]

### Campos novos ou alterados

| Tela | Campo | Tipo | Obrigatorio | Descricao |
|------|-------|------|-------------|-----------|
| [Tela] | [Campo] | [Tipo] | Sim/Nao | [Descricao] |

## CONTROLE

> Alteracoes em parametros, configuracoes, opcoes de sistema.
> Descreva novos parametros ou mudancas em parametros existentes.

[Descricao das alteracoes em parametros]

### Parametros novos ou alterados

| Parametro | Valor padrao | Descricao |
|-----------|-------------|-----------|
| [Parametro] | [Valor] | [O que controla] |

## RELATORIOS

> Alteracoes em impressos, listagens, demonstrativos, relatorios legais.
> Descreva mudancas no layout, conteudo e condicoes de impressao.

[Descricao das alteracoes em relatorios]

## Cenarios e Exemplos

> Todos os cenarios identificados na analise, com exemplos numericos concretos.
> Esta secao e fundamental para o desenvolvimento e para testes.

### Cenario 1: [Nome do cenario -- caso principal]
- **Dado que**: [condicoes iniciais / estado do cadastro]
- **Quando**: [acao do usuario ou processamento do sistema]
- **Entao**: [resultado esperado -- o que o sistema deve fazer]
- **Exemplo**: [dados concretos: valores, datas, quantidades]

### Cenario 2: [Nome do cenario -- variacao ou excecao]
- **Dado que**: [condicoes iniciais]
- **Quando**: [acao]
- **Entao**: [resultado esperado]
- **Exemplo**: [dados concretos]

### Cenario 3: [Nome do cenario -- caso de borda]
- **Dado que**: [condicoes limite]
- **Quando**: [acao]
- **Entao**: [resultado esperado]
- **Exemplo**: [dados concretos]

## Os demais comportamentos nao mencionados

Deverao permanecer conforme versao de mercado.

## Base Legal

> Legislacao, convencao coletiva ou normativo aplicavel.

- [Se aplicavel]

## Observacoes

[Informacoes adicionais ou "Nenhuma"]

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 1.0 | AAAA-MM-DD | [Nome] | Criacao inicial |
