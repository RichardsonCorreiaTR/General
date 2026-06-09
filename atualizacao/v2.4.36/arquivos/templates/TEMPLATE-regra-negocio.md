# Regra de Negócio: [RN-XXX] — [Título da Regra]

## Metadados

| Campo | Valor |
|---|---|
| **ID** | RN-XXX |
| **Título** | [Título descritivo] |
| **Modulo** | Escrita / Importação / Contabilidade |
| **Autor** | [Nome do analista] |
| **Data** | AAAA-MM-DD |
| **Versão** | 1.0 |
| **Status** | Rascunho / Em revisão / Aprovada / Obsoleta |
| **Prioridade** | Alta / Média / Baixa |

> **Referência de domínios** (subpasta em `banco-dados/regras-negocio/`): **Escrita** → `apuracao-impostos`, `escrituracao-movimento-fiscal`, `sped-documentos-eletronicos`, `obrigacoes-relatorios-estaduais`, `parcelamento-planejamento`, `utilitarios-rotinas` | **Importação** → `onvio-importacao-dados` | **Contabilidade** → `integracoes-canais-digitais`.

## Contexto

> Por que essa regra existe? Qual problema ou necessidade de negócio ela atende?

[Escreva aqui]

## Regra

> Descreva de forma clara e sem ambiguidade. Use frases como:
> "O sistema DEVE...", "Quando X, o sistema DEVE...", "O sistema NÃO DEVE..."

[Escreva aqui]

## Condições de Aplicação

> Quando essa regra se aplica? Liste as pré-condições.

- [ ] [Condição 1]
- [ ] [Condição 2]

## Exceções

> Quando essa regra NÃO se aplica?

| Exceção | Motivo |
|---|---|
| [Descreva a situação] | [Por que não se aplica] |

## Exemplos Práticos

### Cenário Normal

**Dado que**: [condições iniciais]
**Quando**: [ação ou evento]
**Então**: [resultado esperado]

### Cenário de Exceção

**Dado que**: [condições iniciais]
**Quando**: [ação ou evento]
**Então**: [resultado esperado]

## Áreas de Impacto

> Marque **área** e **domínios** que podem ser afetados. Na dúvida, marque.

### Escrita

- [ ] Apuração / DRCST / Simples (`apuracao-impostos`)
- [ ] Escrituração e movimento fiscal (`escrituracao-movimento-fiscal`)
- [ ] SPED e documentos eletrônicos (`sped-documentos-eletronicos`)
- [ ] Obrigações e relatórios estaduais (`obrigacoes-relatorios-estaduais`)
- [ ] Parcelamento e planejamento tributário (`parcelamento-planejamento`)
- [ ] Utilitários e rotinas (`utilitarios-rotinas`)

### Importação

- [ ] Onvio e rotinas de importação (`onvio-importacao-dados`)

### Contabilidade

- [ ] Integrações e canais digitais / amarração contábil (`integracoes-canais-digitais`)

### Outros

- [ ] Outro: [especifique]

## Dependências

| Regra | Relação |
|---|---|
| RN-XXX | Depende de / Complementa / Conflita com |

## Base Legal

> Legislação, normativo ou documento oficial que fundamenta esta regra (quando aplicável).

- [Referência]

## Critérios de Aceite

> Como validar que foi implementado corretamente?

1. [ ] [Critério verificável 1]
2. [ ] [Critério verificável 2]

## Observações

[Informações adicionais ou "Nenhuma"]

---

| Versão | Data | Autor | Alteração |
|---|---|---|---|
| 1.0 | AAAA-MM-DD | [Nome] | Criação inicial |
