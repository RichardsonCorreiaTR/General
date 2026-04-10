# Agente de Produto (agente-produto.mdc)

> **Status**: ATIVO (v1.2.0)
> **Referencia**: ADR-009, ADR-011, ADR-013 em `banco-dados/sdd-decisoes.md`

## Localizacao

- Projeto filho: `projeto-filho/.cursor/rules/agente-produto.mdc`

## Funcao

Parceiro de analise para criacao de PSAIs e SAIs. Conduz o processo
investigativo com postura de investigador, nao de preenchedor de formulario.

## Rotas de trabalho (v1.1.0)

O pipeline rigido de 7 fases foi substituido por 3 rotas adaptativas:

### Rota NE — Correcao de erro (5 passos)
1. Entender o erro
2. Investigar (protocolo de varredura + agente-codigo)
3. Cenarios de impacto
4. Gerar definicao
5. Revisar

### Rota SA — Funcionalidade nova (6 passos)
1. Entender a necessidade
2. Descobrir (brainstorming, pesquisa, analogias)
3. Desenhar a solucao
4. Cenarios
5. Gerar definicao
6. Revisar

### Rota SS — Suporte N3 (4 passos)
1. Entender a pergunta do suporte
2. Investigar o comportamento atual
3. Verificar se e esperado
4. Redigir resposta tecnica

### Consulta rapida
Atendimento direto, sem rota formal.

## Visao didatica simplificada

Para fins de comunicacao, as 7 etapas genericas continuam validas como visao
de alto nivel: RECEPCAO, CONTEXTO, CODIGO, CENARIOS, DIALOGO, DEFINICAO,
QUALIDADE. Na pratica, o agente adapta por tipo de demanda.

## Motor BDD interno

O agente usa BDD/Gherkin como forma de PENSAR, nao como formato de saida.
O analista ve analise inteligente e definicao no formato tradicional.

## Absorveu funcoes de

- `agente-definicao` — criacao de definicoes integrada nas rotas
- `agente-impacto` — analise de impacto integrada nos passos de investigacao
- `agente-revisao` (parcial) — passo de revisao integrado em cada rota

## Sistema de tasks (v1.2.0)

O agente gerencia tasks automaticamente para cada analise em rota (NE/SA/SS).
Consultas rapidas nao criam task.

- **Criacao**: ao identificar a rota, cria JSON em `meu-trabalho/tasks/`
- **Atualizacao**: a cada mudanca de passo (historico, achados, pendencias)
- **Vinculo**: artefatos (PSAI/SAI) registrados na task
- **Conclusao**: status muda para `concluido` ao finalizar
- **Retomada**: guardiao detecta tasks em andamento e oferece retomar

Template: `templates/TEMPLATE-task.json`
ADR: ADR-013 em `banco-dados/sdd-decisoes.md`

Principio: silencioso, leve (~2 KB), nao bloqueia o fluxo.

## Dependencias

- `agente-codigo.mdc`: Para investigacao de codigo-fonte
- `templates/TEMPLATE-psai.md` e `templates/TEMPLATE-sai.md`: Para gerar definicao
- `templates/TEMPLATE-task.json`: Para criar tasks de rastreamento
- `referencia/banco-dados/`: Para contexto e varredura

## Naming de artefatos

- PSAIs: `PSAI-{codigo}-{descricao}.md`
- SAIs: `SAI-{codigo}-{tipo}-{descricao}.md`
- Tasks: `{codigo}-{descricao}.json`
