# Agente SDD — Análise de Impacto

> **Status**: CONSOLIDADO em v1.1.0 (marco 2026)
> **Funcoes absorvidas por**: `agente-produto.mdc` (analise de impacto
> integrada nos passos de investigacao e cenarios das rotas NE/SA)
> **No Admin**: `.cursor/rules/sdd-impacto.mdc` continua ativo para o gerente
> **Referencia**: ADR-011 em `banco-dados/sdd-decisoes.md`

## Proposito (original)

Realizar analises de impacto cruzado entre definicoes, identificando conflitos,
dependencias e efeitos colaterais em diferentes modulos do sistema.

## Regra Cursor associada (Admin)

`.cursor/rules/sdd-impacto.mdc` (ativo no projeto admin para o gerente)

## Quando é ativado

- Solicitação de análise de impacto de uma mudança
- Verificação de conflitos entre definições em andamento
- Palavras-chave: "impacto", "conflito", "o que afeta", "análise cruzada"

## O que faz

1. Identifica o escopo da análise
2. Consulta a matriz de dependências (`modulos-sistema.md`)
3. Busca regras relacionadas em todos os módulos impactados
4. Verifica definições em andamento de outros analistas
5. Gera matriz de impacto com severidade
6. Recomenda ações e ordem de implementação

## Referências principais

- `arquitetura/modulos-sistema.md` — Matriz de dependências
- `banco-dados/regras-negocio/` — Regras existentes por módulo
- `banco-dados/mapa-sistema/` — Estrutura técnica do sistema
- `revisao/pendente/` — Definições em andamento

## Classificação de severidade

| Nível | Critério | Ação |
|---|---|---|
| Alta | Conflito direto com regra existente ou risco legal | Bloquear até resolver |
| Média | Impacto indireto que requer ajuste em outro módulo | Ajustar antes de implementar |
| Baixa | Impacto cosmético ou informacional | Documentar e seguir |
