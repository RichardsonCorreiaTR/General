# Fluxo de Processo: FL-002 - Ferias Individual

## Metadados

| Campo | Valor |
|---|---|
| **ID** | FL-002 |
| **Titulo** | Concessao de Ferias Individual |
| **Modulo** | Ferias |
| **Autor** | Agente IA (base: codigo-fonte + SAIs) |
| **Data** | 2026-03-04 |
| **Versao** | 0.2 (revisado - pendente aprovacao) |

## Objetivo do Fluxo

Descreve o processo de concessao de ferias individuais, desde a programacao
ate o pagamento e reflexos no eSocial.

## Atores Envolvidos

| Ator | Papel no Fluxo |
|---|---|
| Departamento Pessoal | Programa ferias, confere periodos, autoriza pagamento |
| Sistema Folha | Calcula valores, aplica medias, gera recibo e eSocial |
| Empregado | Solicita abono pecuniario (opcional) |

## Fluxo Principal (Caminho Feliz)

```
INICIO
  |
  v
[1] Verificar periodo aquisitivo (Processos > Ferias > Programacao)
  |
  v
[2] Programar ferias (data inicio, dias, abono pecuniario?)
  |
  v
[Abono?] --SIM--> [2A] Registrar conversao de 1/3 em abono
  |
  NAO
  |
  v
[3] Calcular ferias (Processos > Ferias > Individual)
  |
  v
[4] Verificar medias (horas extras, adicionais, comissoes)
  |
  v
[5] Conferir recibo de ferias
  |
  v
[Correto?] --NAO--> [5A] Corrigir dados e recalcular (volta ao passo 3)
  |
  SIM
  |
  v
[6] Gerar pagamento (ate 2 dias antes do inicio)
  |
  v
[7] Gerar evento eSocial S-2230 (afastamento)
  |
  v
[8] Registrar retorno apos ferias
  |
  v
FIM
```

## Descricao dos Passos

### Passo 1 - Verificar periodo aquisitivo
- **Ator**: Departamento Pessoal
- **Acao**: Consultar periodos aquisitivos em aberto. Verificar se ha faltas que reduzem dias de direito (CLT art. 130).
- **Saida**: Periodo aquisitivo selecionado, dias de direito confirmados

### Passo 2 - Programar ferias
- **Ator**: Departamento Pessoal
- **Acao**: Definir data de inicio, quantidade de dias, fracionamento (ate 3 periodos, min 14 dias no maior). Registrar se ha abono pecuniario.
- **Regra**: CLT art. 134 - ferias em ate 3 periodos; art. 143 - abono pecuniario

### Passo 3 - Calcular ferias
- **Ator**: Sistema Folha (w_ferias_inicio.srw, w_ferias_nova.srw)
- **Acao**: Calcular remuneracao de ferias + 1/3 constitucional. Aplicar medias variaveis, adicionais habituais, comissoes.
- **Saida**: Valores calculados, descontos (INSS, IRRF)

### Passo 4 - Verificar medias
- **Ator**: Departamento Pessoal
- **Acao**: Conferir base de calculo das medias (ultimos 12 meses). Verificar HE, adicionais, DSR sobre variaveis.

### Passo 5 - Conferir recibo
- **Ator**: Departamento Pessoal
- **Acao**: Emitir recibo de ferias e conferir valores bruto, descontos, liquido.

### Passo 6 - Gerar pagamento
- **Ator**: Sistema Folha
- **Acao**: Registrar pagamento. CLT art. 145: pagar ate 2 dias antes do inicio.

### Passo 7 - Gerar eSocial
- **Ator**: Sistema Folha (forel20)
- **Acao**: Gerar evento S-2230 (afastamento temporario) com codigo de ferias.

### Passo 8 - Registrar retorno
- **Ator**: Departamento Pessoal
- **Acao**: Registrar data de retorno. Sistema atualiza situacao do empregado.

## Regras de Negocio Relacionadas

| Regra | Onde se aplica |
|---|---|
| RN-FER-001 | Passos 3 e 4 (medias para ferias) |
| RN-FER-002 | Passo 2 (fracionamento ferias) |
| RN-IRRF-001 | Passo 3 (IRRF sobre ferias) |

## Observacoes

- Ferias coletivas e em grupo seguem fluxo similar porem com selecao em massa.
- Simulacao de ferias disponivel em menu separado (uo_calculo_simulacao_ferias).
- Rascunho - precisa validacao do gerente de produto.

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (rascunho) |
| 0.2 | 2026-03-04 | Agente IA | Revisao: cruzamento com regras e mapa |
