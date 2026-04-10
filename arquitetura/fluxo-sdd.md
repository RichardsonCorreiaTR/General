# Fluxo SDD — Passo a Passo

## Visão Geral

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│ CONSULTAR│──►│ DEFINIR  │──►│ VALIDAR  │──►│ SUBMETER │──►│ REVISAR  │
│          │   │          │   │          │   │          │   │          │
│ Analista │   │ Analista │   │ Analista │   │ Analista │   │ Gerente  │
│ + IA     │   │ + IA     │   │ IA       │   │ OneDrive │   │ + IA     │
└──────────┘   └──────────┘   └──────────┘   └──────────┘   └─────┬────┘
                                                                   │
                                                          ┌────────┴────────┐
                                                          │                 │
                                                     ┌────▼─────┐   ┌──────▼──────┐
                                                     │ APROVAR  │   │  DEVOLVER   │
                                                     │          │   │             │
                                                     │ → banco- │   │ → feedback  │
                                                     │   dados/ │   │ → corrigir  │
                                                     └──────────┘   └─────────────┘
```

## Passo 1 — CONSULTAR

**Quem**: Analista + IA
**Onde**: Projeto Filho

O analista, antes de criar qualquer definição:
1. Consulta `banco-dados/regras-negocio/{modulo}/` para ver regras existentes
2. Consulta `banco-dados/glossario/` para usar termos corretos
3. Verifica se outro analista já está trabalhando em algo relacionado
4. Pede à IA: "Existe alguma regra sobre [tema]?"

## Passo 2 — DEFINIR

**Quem**: Analista + IA
**Onde**: Projeto Filho → `meu-trabalho/em-andamento/`

1. Analista pede à IA para iniciar uma nova definição
2. IA carrega o template correto (`TEMPLATE-regra-negocio.md`)
3. IA faz perguntas para preencher cada seção
4. Analista responde e complementa com conhecimento de negócio
5. IA identifica o próximo ID disponível e gera o arquivo

## Passo 3 — VALIDAR

**Quem**: IA (agente SDD-Definição)
**Onde**: Projeto Filho

A IA automaticamente:
1. Verifica se o template foi preenchido corretamente
2. Busca conflitos com regras existentes no `banco-dados/`
3. Consulta a matriz de dependências em `modulos-sistema.md`
4. Lista áreas de impacto sugeridas
5. Emite um relatório de validação para o analista

## Passo 4 — SUBMETER

**Quem**: Analista
**Onde**: Projeto Filho → `meu-trabalho/para-revisao/`

1. Analista move o arquivo de `em-andamento/` para `para-revisao/`
2. OneDrive sincroniza → aparece em `revisao/pendente/` no Admin
3. Log registra a submissão

## Passo 5 — REVISAR

**Quem**: Gerente + IA (agente SDD-Revisão)
**Onde**: Projeto Admin → `revisao/pendente/`

1. Gerente pede à IA para revisar a definição
2. IA faz análise completa (template, conflitos, impactos, legislação)
3. IA emite parecer
4. Gerente toma a decisão final:
   - **APROVAR** → Move para `banco-dados/regras-negocio/{modulo}/`
   - **DEVOLVER** → Move para `revisao/devolvido/` com feedback

## Fluxo Meta-SDD (Melhoria do Projeto)

Periodicamente o gerente aciona o agente SDD-Projeto para:
1. Revisar a arquitetura e regras .mdc
2. Analisar logs para identificar padrões de dificuldade
3. Propor melhorias nos templates e processos
4. Atualizar o projeto-filho com as mudanças
