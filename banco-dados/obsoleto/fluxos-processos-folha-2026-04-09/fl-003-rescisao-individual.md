# Fluxo de Processo: FL-003 - Rescisao Individual

## Metadados

| Campo | Valor |
|---|---|
| **ID** | FL-003 |
| **Titulo** | Calculo Rescisorio Individual |
| **Modulo** | Rescisao |
| **Autor** | Agente IA (base: codigo-fonte + SAIs) |
| **Data** | 2026-03-04 |
| **Versao** | 0.2 (revisado - pendente aprovacao) |

## Objetivo do Fluxo

Descreve o processo de rescisao de contrato de trabalho individual,
desde o motivo ate a geracao do TRCT e eventos eSocial.

## Atores Envolvidos

| Ator | Papel no Fluxo |
|---|---|
| Departamento Pessoal | Registra desligamento, confere valores |
| Sistema Folha | Calcula verbas rescisorias, gera TRCT, eSocial |

## Fluxo Principal (Caminho Feliz)

```
INICIO
  |
  v
[1] Informar motivo da rescisao e data do desligamento
  |
  v
[2] Informar aviso previo (trabalhado, indenizado, dispensado)
  |
  v
[3] Executar calculo rescisorio (Processos > Rescisao > Individual)
  |
  v
[4] Verificar verbas: saldo salario, ferias proporcionais + 1/3,
    13o proporcional, aviso previo indenizado, multa FGTS
  |
  v
[5] Conferir TRCT e demonstrativo
  |
  v
[Correto?] --NAO--> [5A] Corrigir e recalcular (volta ao passo 1 ou 3)
  |
  SIM
  |
  v
[6] Gerar guia GRRF (multa FGTS 40%)
  |
  v
[7] Gerar eventos eSocial S-2299 (desligamento)
  |
  v
[8] Efetuar pagamento (prazo: 10 dias corridos)
  |
  v
FIM
```

## Descricao dos Passos

### Passo 1 - Informar motivo
- **Ator**: Departamento Pessoal
- **Acao**: Selecionar tipo de rescisao: sem justa causa, pedido de demissao, justa causa, acordo (art. 484-A CLT), termino de contrato, falecimento, aposentadoria.
- **Impacto**: O motivo define quais verbas sao devidas e se ha multa FGTS.

### Passo 2 - Aviso previo
- **Ator**: Departamento Pessoal
- **Acao**: Definir tipo de aviso previo e calcular projecao. Aviso previo proporcional (art. 1o Lei 12.506/2011): 30 dias + 3 dias por ano de servico.
- **Saida**: Data projetada para calculo de ferias e 13o proporcionais.

### Passo 3 - Executar calculo
- **Ator**: Sistema Folha (w_rescisao.srw, uo_rescisao.sru)
- **Acao**: Calcular todas as verbas rescisorias. Aplicar medias, adicionais habituais, DSR.

### Passo 4 - Verificar verbas
- **Ator**: Departamento Pessoal
- **Acao**: Conferir cada verba: saldo de salario, ferias vencidas e proporcionais + 1/3, 13o proporcional, aviso previo, multa FGTS (se aplicavel), descontos (INSS, IRRF, adiantamentos).

### Passo 5 - Conferir TRCT
- **Ator**: Departamento Pessoal
- **Acao**: Emitir e conferir Termo de Rescisao do Contrato de Trabalho.

### Passo 6 - Gerar GRRF
- **Ator**: Sistema Folha
- **Acao**: Gerar guia de recolhimento rescisorio do FGTS (multa 40% ou 20% em acordo).

### Passo 7 - Gerar eSocial
- **Ator**: Sistema Folha (forel20)
- **Acao**: Gerar evento S-2299 (desligamento) com verbas e motivo.

### Passo 8 - Pagamento
- **Ator**: Departamento Pessoal
- **Acao**: Efetuar pagamento das verbas rescisorias. Prazo: 10 dias corridos apos termino do contrato (CLT art. 477).

## Fluxos Alternativos

### Alternativa A - Rescisao complementar
Quando identificado erro ou diferenca apos a rescisao principal, recalcular apenas a diferenca via Processos > Rescisao > Complementar.

### Alternativa B - Rescisao em grupo
Para desligamento de multiplos empregados, usar Processos > Rescisao > Em Grupo.

## Regras de Negocio Relacionadas

| Regra | Onde se aplica |
|---|---|
| RN-RES-001 | Passos 1 e 4 (verbas por motivo) |

## Observacoes

- Simulacao disponivel antes do calculo definitivo (uo_calculo_simulacao_rescisao).
- Rascunho - precisa validacao do gerente de produto.

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (rascunho) |
| 0.2 | 2026-03-04 | Agente IA | Revisao: cruzamento com regras e mapa |
