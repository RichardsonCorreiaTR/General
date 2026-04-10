# Fluxo de Processo: FL-008 - Provisoes de Ferias e 13o

## Metadados

| Campo | Valor |
|---|---|
| **ID** | FL-008 |
| **Titulo** | Calculo e Contabilizacao de Provisoes |
| **Modulo** | Provisoes |
| **Autor** | Agente IA (base: codigo-fonte + SAIs) |
| **Data** | 2026-03-04 |
| **Versao** | 0.2 (revisado - pendente aprovacao) |

## Objetivo do Fluxo

Descreve o processo de calculo mensal das provisoes de ferias e 13o salario
para contabilizacao, incluindo ajustes por baixa (gozo/pagamento).

## Atores Envolvidos

| Ator | Papel no Fluxo |
|---|---|
| Departamento Pessoal | Configura parametros, confere valores |
| Sistema Folha | Calcula provisoes, gera lancamentos contabeis |
| Contabilidade | Confere saldos, integra ao contabil |

## Fluxo Principal

```
INICIO
  |
  v
[1] Configurar parametros de provisao (encargos, contas contabeis)
  |
  v
[2] Executar calculo de provisao de ferias (Processos > Provisao)
  |   (uo_provisao_ferias.sru)
  |
  v
[3] Executar calculo de provisao de 13o (uo_provisao_13.sru)
  |
  v
[4] Conferir saldo provisionado vs saldo anterior
  |
  v
[Divergencia?] --SIM--> [4A] Analisar: gozo de ferias, rescisao, reajuste
  |
  NAO
  |
  v
[5] Gerar lancamentos contabeis de provisao
  |
  v
[6] Integrar com modulo contabil
  |
  v
FIM
```

## Descricao dos Passos

### Passo 1 - Parametros
- **Ator**: Departamento Pessoal
- **Acao**: Configurar percentuais de encargos sobre provisao (INSS patronal, FGTS), contas contabeis de debito/credito.

### Passo 2 - Provisao de ferias
- **Ator**: Sistema Folha (uo_provisao_ferias.sru, w_provisao.srw)
- **Acao**: Para cada empregado, calcular: (salario/12) x meses desde ultima ferias + 1/3 + encargos. Considerar medias de variaveis.

### Passo 3 - Provisao de 13o
- **Ator**: Sistema Folha (uo_provisao_13.sru)
- **Acao**: Para cada empregado, calcular: (salario/12) x meses no ano + encargos. Considerar medias.

### Passo 4 - Conferencia
- **Ator**: Departamento Pessoal
- **Acao**: Comparar saldo atual com anterior. Identificar movimentacoes: baixas por gozo de ferias, pagamento de 13o, rescisoes.

### Passo 5 - Lancamentos contabeis
- **Ator**: Sistema Folha
- **Acao**: Gerar lancamentos de debito (despesa) e credito (provisao) conforme contas configuradas.

### Passo 6 - Integracao contabil
- **Ator**: Contabilidade
- **Acao**: Importar lancamentos no modulo contabil. Conferir saldos.

## Regras de Negocio Relacionadas

| Regra | Onde se aplica |
|---|---|
| RN-FER-001 | Passo 2 (medias para provisao de ferias) |
| RN-13S-001 | Passo 3 (proporcionalidade 13o na provisao) |

## Observacoes

- Provisao e mensal, executada apos o calculo da folha.
- Alteracao de provisao disponivel em w_provisao_ferias.srw e w_provisao_13.srw.

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (rascunho) |
| 0.2 | 2026-03-04 | Agente IA | Revisao: cruzamento com regras e mapa |
