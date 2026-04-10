# Agente SDD — Consolidação e Logs

> **Status**: CONSOLIDADO em v1.1.0 (marco 2026)
> **Funcoes absorvidas por**: `guardiao.mdc` (log proativo e metricas) e
> script `consolidar-logs.ps1`
> **No Admin**: Sem regra .mdc propria; funcoes distribuidas
> **Referencia**: ADR-011 em `banco-dados/sdd-decisoes.md`

## Proposito (original)

Analisar logs dos analistas, gerar resumos consolidados e identificar padroes
de trabalho, gargalos e oportunidades de melhoria.

## Quando era ativado (original)

- Gerente solicita análise dos logs da semana/mês
- Gerente quer visão geral da produtividade do time
- Palavras-chave: "consolidar", "resumo do time", "logs", "produtividade"

## O que faz

1. Lê logs dos analistas em `logs/analistas/`
2. Gera resumo consolidado com métricas:
   - Quantas definições cada analista criou
   - Quantas foram aprovadas vs. devolvidas
   - Quais módulos tiveram mais atividade
   - Quais analistas podem precisar de apoio
3. Identifica padrões:
   - Erros recorrentes nos templates
   - Módulos negligenciados
   - Analistas trabalhando em temas sobrepostos
4. Salva resumo em `logs/consolidado/`

## Formato do resumo semanal

```markdown
# Consolidado — Semana XX/2026

## Métricas
- Definições criadas: X
- Submetidas para revisão: X
- Aprovadas: X
- Devolvidas: X

## Por analista
| Analista | Criadas | Submetidas | Aprovadas | Devolvidas |
|---|---|---|---|---|

## Módulos mais ativos
| Módulo | Definições |
|---|---|

## Alertas
- [problemas identificados]

## Recomendações
- [sugestões de melhoria]
```

## Otimização

- Ler apenas os logs do período solicitado
- Nunca ler todos os logs de uma vez
- Usar busca para filtrar por analista ou período
