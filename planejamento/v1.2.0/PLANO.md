# Planejamento v1.2.0 -- Sistema de Tasks

## Objetivo

Implementar sistema de tasks para rastreamento de demandas no projeto-filho.
Cada analise em rota (NE/SA/SS) gera uma task persistente em JSON que permite
retomada entre chats, visibilidade de progresso e vinculo com artefatos.

## Decisao

ADR-013 em `banco-dados/sdd-decisoes.md`.

## O que foi feito

### Novos arquivos

- `templates/TEMPLATE-task.json` -- template padrao (admin + filho)
- `projeto-filho/meu-trabalho/tasks/README.md` -- explicacao da pasta

### Arquivos alterados no projeto-filho

- `.cursor/rules/agente-produto.mdc` -- secao "Gestao de tasks" com logica
  de criacao, atualizacao, vinculo, conclusao e retomada
- `.cursor/rules/guardiao.mdc` -- verificacao 5: detecta tasks em andamento
  e oferece retomada ao analista
- `.cursor/rules/projeto.mdc` -- lista `meu-trabalho/tasks/` como pasta
- `GUIA-RAPIDO.md` -- tabela de pastas e FAQ sobre tasks
- `config/VERSION.json` -- versao 1.2.0

### Arquivos alterados no admin

- `PROJETO.md` secao 4 -- rastreamento via tasks documentado
- `agentes/agente-produto.md` -- versao 1.2.0, secao de tasks, ADR-013
- `.cursor/rules/guardiao.mdc` -- referencia a tasks no filho
- `.cursor/rules/sdd-projeto.mdc` -- checklist de saude inclui tasks
- `banco-dados/sdd-decisoes.md` -- ADR-013 registrada
- `distribuicao/CHANGELOG.md` -- entrada v1.2.0

## Principios de design

1. **Silencioso**: analista nao gerencia tasks, tudo automatico
2. **Leve**: JSON de ~2 KB, nao infla contexto
3. **Nao bloqueia**: se escrita falhar, analise continua
4. **Aditivo**: nao altera rotas existentes, apenas adiciona rastreamento

## Compatibilidade

- Retrocompativel com v1.1.x (pasta tasks/ simplesmente nao existe antes)
- Auto-atualizacao via guardiao cria a pasta e atualiza regras
- Nenhum dado do analista e perdido na atualizacao
