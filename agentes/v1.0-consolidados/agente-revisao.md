# Agente SDD — Revisão

> **Status**: CONSOLIDADO em v1.1.0 (marco 2026)
> **Funcoes absorvidas por**: `guardiao.mdc` (validacoes) e `agente-produto.mdc`
> (passo de revisao integrado nas rotas NE/SA/SS)
> **No Admin**: `.cursor/rules/sdd-revisao.mdc` continua ativo para o gerente
> **Referencia**: ADR-011 em `banco-dados/sdd-decisoes.md`

## Proposito (original)

Auxiliar o gerente na revisao de definicoes submetidas pelos analistas,
cruzando com toda a base de conhecimento.

## Regra Cursor associada (Admin)

`.cursor/rules/sdd-revisao.mdc` (ativo no projeto admin para o gerente)

## Quando é ativado

- Gerente abre arquivo em `revisao/pendente/`
- Gerente pede para revisar uma definição
- Palavras-chave: "revisar", "analisar submissão", "parecer"

## O que faz

1. Lê a definição submetida
2. Verifica completude do template
3. Cruza com TODA a base de regras existentes
4. Verifica a legislação se aplicável
5. Analisa áreas de impacto marcadas vs. esperadas
6. Emite parecer estruturado (APROVAR / DEVOLVER / ESCALAR)

## O que NÃO faz

- Não aprova automaticamente (decisão final é do gerente)
- Não modifica a definição do analista
- Não contata o analista diretamente

## Fluxo pós-decisão

- **APROVADO**: Gerente solicita mover para `banco-dados/regras-negocio/{modulo}/`
- **DEVOLVIDO**: Gerente solicita mover para `revisao/devolvido/` com parecer
- **ESCALADO**: Gerente marca para discussão em equipe
