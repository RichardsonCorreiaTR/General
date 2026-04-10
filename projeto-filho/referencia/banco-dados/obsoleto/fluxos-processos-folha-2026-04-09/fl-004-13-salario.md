# Fluxo de Processo: FL-004 - 13o Salario

## Metadados

| Campo | Valor |
|---|---|
| **ID** | FL-004 |
| **Titulo** | Calculo do 13o Salario (1a e 2a parcelas) |
| **Modulo** | 13o Salario |
| **Autor** | Agente IA (base: codigo-fonte + SAIs) |
| **Data** | 2026-03-04 |
| **Versao** | 0.2 (revisado - pendente aprovacao) |

## Objetivo do Fluxo

Descreve o processo de calculo do 13o salario, incluindo adiantamento
(1a parcela) e calculo integral (2a parcela), provisoes e eSocial.

## Atores Envolvidos

| Ator | Papel no Fluxo |
|---|---|
| Departamento Pessoal | Parametriza calculo, confere valores |
| Sistema Folha | Calcula parcelas, aplica medias, gera eSocial |

## Fluxo Principal

```
INICIO
  |
  v
[1] Configurar parametros do 13o (Controle > Parametros)
  |
  v
[2] Calcular 1a parcela - adiantamento (ate novembro)
  |   (Processos > Calculo da Folha, opcao 13o adiantamento)
  |
  v
[3] Conferir valores do adiantamento (50% da remuneracao)
  |
  v
[4] Pagar 1a parcela (ate 30/nov ou junto com ferias)
  |
  v
[5] Calcular 2a parcela - integral (ate 20/dez)
  |   (Processos > Calculo da Folha, opcao 13o integral)
  |
  v
[6] Verificar medias variaveis (HE, adicionais, comissoes)
  |
  v
[7] Conferir diferenca (integral - adiantamento) e descontos (INSS, IRRF)
  |
  v
[Correto?] --NAO--> [7A] Corrigir e recalcular
  |
  SIM
  |
  v
[8] Pagar 2a parcela (ate 20/dez)
  |
  v
[9] Gerar provisao de 13o (uo_provisao_13)
  |
  v
[10] Gerar eSocial S-1200 com rubrica de 13o
  |
  v
FIM
```

## Descricao dos Passos

### Passo 1 - Configurar parametros
- **Ator**: Departamento Pessoal
- **Acao**: Verificar meses de referencia, percentuais, regras de media.

### Passo 2 - Calcular adiantamento
- **Ator**: Sistema Folha (w_calculo.srw, opcao 13o)
- **Acao**: Calcular 50% da remuneracao de novembro (ou mes configurado). Sem descontos de INSS/IRRF no adiantamento.

### Passo 3 - Conferir adiantamento
- **Ator**: Departamento Pessoal
- **Acao**: Verificar base de calculo, proporcionalidade (meses trabalhados / 12).

### Passo 4 - Pagar 1a parcela
- **Ator**: Departamento Pessoal
- **Acao**: Efetuar pagamento. Pode ser pago junto com ferias se solicitado pelo empregado (ate janeiro).

### Passo 5 - Calcular integral
- **Ator**: Sistema Folha
- **Acao**: Calcular 13o integral com base na remuneracao de dezembro. Aplicar medias de variaveis dos 12 meses.

### Passo 6 - Verificar medias
- **Ator**: Departamento Pessoal
- **Acao**: Conferir calculo de medias (HE, comissoes, adicionais) dos ultimos 12 meses.

### Passo 7 - Conferir diferenca
- **Ator**: Departamento Pessoal
- **Acao**: Verificar: 13o integral - adiantamento = valor a pagar. Descontos de INSS e IRRF incidem sobre o valor integral.

### Passo 8 - Pagar 2a parcela
- **Ator**: Departamento Pessoal
- **Acao**: Efetuar pagamento ate 20 de dezembro.

### Passo 9 - Gerar provisao
- **Ator**: Sistema Folha (uo_provisao_13.sru)
- **Acao**: Calcular provisao mensal de 13o para contabilizacao.

### Passo 10 - Gerar eSocial
- **Ator**: Sistema Folha (forel20)
- **Acao**: Gerar S-1200 com rubricas de 13o salario.

## Regras de Negocio Relacionadas

| Regra | Onde se aplica |
|---|---|
| RN-INSS-002 | Passo 7 (INSS sobre 13o) |
| RN-13S-001 | Passos 2, 3, 5 e 7 (proporcionalidade 13o) |

## Observacoes

- Diferenca de 13o (ajuste em janeiro) segue fluxo separado.
- Rascunho - precisa validacao do gerente de produto.

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (rascunho) |
| 0.2 | 2026-03-04 | Agente IA | Revisao: cruzamento com regras e mapa |
