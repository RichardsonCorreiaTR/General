# Visão Geral — Projeto Folha SDD

## Objetivo

Estruturar o processo de definição de regras de negócio do Sistema de Folha
de Pagamento usando Spec-Driven Development (SDD), garantindo padronização,
rastreabilidade e qualidade nas entregas do time de produto.

## Arquitetura de dois projetos

```
┌─────────────────────┐     OneDrive      ┌─────────────────────────┐
│   PROJETO ADMIN     │◄──── sync ────►   │  PROJETO FILHO (x17)    │
│   (Gerente)         │                    │  (Analistas)            │
│                     │   Compartilhado:   │                         │
│   • Revisa          │   • banco-dados/   │   • Consulta base       │
│   • Aprova          │   • submissoes/    │   • Cria definições     │
│   • Consolida       │   • comunicados/   │   • Valida com IA       │
│   • Publica         │                    │   • Submete             │
└─────────────────────┘                    └─────────────────────────┘
```

## Princípios de arquitetura

| # | Princípio | Descrição |
|---|---|---|
| 1 | Single Source of Truth | banco-dados/ no Admin é a única fonte oficial |
| 2 | Imutabilidade | Regras aprovadas nunca se editam, se versionam |
| 3 | Separação de responsabilidades | Admin e Filho têm escopos diferentes |
| 4 | Rastreabilidade | Todo artefato tem autor, data, versão |
| 5 | Validação em camadas | IA → Analista → Gerente |
| 6 | Padronização | Templates obrigatórios |
| 7 | Baixo acoplamento | Cada analista trabalha offline |
| 8 | Otimização de contexto | Nunca carregar dados desnecessários |

## Regras de otimização

- Arquivos .mdc: máximo 100 linhas
- Definições .md: máximo 300 linhas
- PROJETO.md: máximo 500 linhas, lido por seção
- Sempre usar busca em vez de leitura completa
- .cursorignore exclui logs e dados pesados
