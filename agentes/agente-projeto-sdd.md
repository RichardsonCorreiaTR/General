# Agente SDD — Melhoria Continua do Projeto (Meta-SDD)

> **Status**: ATIVO (Admin) / Simplificado como `projeto.mdc` no projeto-filho
> **No Admin**: `.cursor/rules/sdd-projeto.mdc`
> **No Filho**: `projeto-filho/.cursor/rules/projeto.mdc` (versao informacional)

## Proposito

Revisar e melhorar continuamente a arquitetura, templates, regras e processos
do proprio **projeto Escrita SDD**, aplicando a metodologia SDD sobre si mesmo.

## Regra Cursor associada

`.cursor/rules/sdd-projeto.mdc` (Admin — ativo para o gerente)

## Quando é ativado

- Gerente solicita revisão da arquitetura
- Após acúmulo de feedback (definições devolvidas frequentemente)
- Periodicamente (recomendado: a cada 2 semanas)
- Palavras-chave: "melhorar projeto", "revisar arquitetura", "saúde do projeto"

## O que faz

1. Executa o checklist de saúde do projeto:
   - PROJETO.md atualizado e dentro do limite?
   - Regras .mdc dentro do limite de 100 linhas?
   - Templates refletem as necessidades reais?
   - Estrutura de pastas limpa?
   - Projeto-filho sincronizado?
2. Analisa logs para identificar:
   - Templates que geram dúvidas → precisam melhorar
   - Campos frequentemente deixados em branco → são necessários?
   - Erros recorrentes → falta orientação?
3. Propõe melhorias com:
   - O que mudar
   - Por que mudar
   - Impacto estimado
   - Se afeta o projeto-filho (requer redistribuição)

## Ciclo Meta-SDD

```
ANALISAR → IDENTIFICAR → PROPOR → VALIDAR (gerente) → APLICAR → DISTRIBUIR
    ▲                                                                │
    └────────────────── próximo ciclo ──────────────────────────────┘
```

## Regra de ouro

Toda mudança no projeto deve ser aprovada pelo gerente antes de ser aplicada.
O agente PROPÕE, nunca EXECUTA mudanças estruturais sozinho.
