# Fluxo de Processo: FL-001 - Calculo Mensal da Folha

## Metadados

| Campo | Valor |
|---|---|
| **ID** | FL-001 |
| **Titulo** | Calculo Mensal da Folha de Pagamento |
| **Modulo** | Calculo |
| **Autor** | Agente IA (base: codigo-fonte + SAIs) |
| **Data** | 2026-03-04 |
| **Versao** | 0.2 (revisado - pendente aprovacao) |

## Objetivo do Fluxo

Descreve o processo de calculo mensal da folha de pagamento, desde a
configuracao ate a geracao dos eventos para eSocial e guias de recolhimento.

## Atores Envolvidos

| Ator | Papel no Fluxo |
|---|---|
| Departamento Pessoal | Configura parametros, lanca eventos, executa calculo |
| Sistema Folha | Processa calculos, aplica tabelas, gera resultados |
| eSocial | Recebe eventos S-1200 e S-1210 |

## Fluxo Principal (Caminho Feliz)

```
INICIO
  |
  v
[1] Conferir Parametros (Controle > Parametros)
  |
  v
[2] Lancar Eventos (Processos > Lancamentos)
  |
  v
[3] Conferir Afastamentos e Situacoes
  |
  v
[4] Executar Calculo (Processos > Calculo da Folha)
  |
  v
[5] Verificar Log de Calculo e Avisos
  |
  v
[Erros?] --SIM--> [5A] Corrigir e recalcular (volta ao passo 2 ou 4)
  |
  NAO
  |
  v
[6] Conferir Recibo / Holerite / Resumo
  |
  v
[7] Gerar Provisoes (Processos > Provisao Ferias e 13o)
  |
  v
[8] Gerar eSocial (S-1200, S-1210)
  |
  v
[9] Gerar Guias (GPS, DARF IRRF, PIS, FGTS Digital)
  |
  v
[10] Fechar competencia (Controle > Data do Fechamento)
  |
  v
FIM
```

## Descricao dos Passos

### Passo 1 - Conferir Parametros
- **Ator**: Departamento Pessoal
- **Acao**: Verificar configuracoes em Controle > Parametros (regime, encargos, eSocial, personalizacoes)
- **Saida**: Parametros atualizados para a competencia

### Passo 2 - Lancar Eventos
- **Ator**: Departamento Pessoal
- **Acao**: Incluir lancamentos variaveis (horas extras, faltas, adicionais, descontos) via Processos > Lancamentos > Por empregado ou Por rubrica
- **Tipos**: Fixo (recorrente), Variavel (pontual), Primeira Folha

### Passo 3 - Conferir Afastamentos
- **Ator**: Departamento Pessoal
- **Acao**: Verificar afastamentos ativos (Processos > Afastamentos) e situacoes especiais
- **Impacto**: Afastamentos alteram o calculo de DSR, medias, bases

### Passo 4 - Executar Calculo
- **Ator**: Sistema Folha (w_calculo.srw)
- **Acao**: Processar calculo da competencia. O sistema:
  - Aplica tabelas de IRRF, INSS, FAP, salario minimo, salario familia
  - Calcula situacoes (DSR, afastamentos) via uo_calc_situacao
  - Aplica regras sindicais (medias, adicionais)
  - Gera log de calculo
- **Opcoes**: Incluir 13o adiantamento, diferenca de 13o, complementar

### Passo 5 - Verificar Avisos
- **Ator**: Departamento Pessoal
- **Acao**: Analisar avisos e erros do calculo (w_aviso_calculo, w_log_calculo)
- **Se erros**: Corrigir parametros/lancamentos e recalcular

### Passo 6 - Conferir Resultados
- **Ator**: Departamento Pessoal
- **Acao**: Emitir e conferir recibos (w_recibo_folha), resumo (w_folha_resumo), extrato (w_folha_extrato)

### Passo 7 - Gerar Provisoes
- **Ator**: Sistema Folha (uo_provisao_ferias, uo_provisao_13)
- **Acao**: Calcular provisoes de ferias e 13o para contabilizacao

### Passo 8 - Gerar eSocial
- **Ator**: Sistema Folha (forel20)
- **Acao**: Gerar eventos periodicos S-1200 (Remuneracao) e S-1210 (Pagamentos)
- **Saida**: XMLs validados e transmitidos

### Passo 9 - Gerar Guias
- **Ator**: Sistema Folha (guias)
- **Acao**: Gerar GPS (INSS), DARF (IRRF), PIS, FGTS Digital, DAE
- **Saida**: Guias para recolhimento

### Passo 10 - Fechar Competencia
- **Ator**: Departamento Pessoal
- **Acao**: Definir data de fechamento para impedir alteracoes na competencia

## Regras de Negocio Relacionadas

| Regra | Onde se aplica |
|---|---|
| RN-INSS-001 | Passo 4 (calculo progressivo INSS) |
| RN-INSS-002 | Passo 4 (INSS sobre 13o quando incluido) |
| RN-IRRF-001 | Passo 4 (IRRF sobre remuneracao) |
| RN-FGTS-001 | Passo 9 (deposito mensal FGTS) |
| RN-ESO-001 | Passo 8 (eventos periodicos eSocial) |

## Observacoes

- Este fluxo e um rascunho baseado na analise do codigo-fonte e SAIs.
- Precisa ser validado pelo gerente de produto.
- Nao cobre todos os cenarios especiais (dissidio, diferenca salarial, etc.).

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (rascunho) |
| 0.2 | 2026-03-04 | Agente IA | Revisao: cruzamento com regras e mapa |
