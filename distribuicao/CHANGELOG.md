# Changelog - Projeto Filho

## v2.4.2 - 10/04/2026

Documentacao Escrita SDD: templates apresentacao e TEMPLATE-fluxo-processo; alinhamento CursorEscrita. Blueprint admin 2.5.

---

## v2.4.1 - 10/04/2026

Templates raiz/filho em paridade (9 arquivos, incl. TEMPLATE-prompt-blueprint e apresentacao-slides). Pacote pos-sincronizacao documentacao SDD e regras. Admin blueprint 2.4.

---

## v2.4.0 - 10/04/2026

Republicacao distribuicao (ultima-versao, ZIP, canal IA); SETUP CursorEscrita; compativel_com_admin 2.4; hash_validacao MD5 do guardiao.mdc.

---

## v2.4.0 - 21/03/2026

Busca profunda obrigatoria em regras alwaysApply. Indices enriquecidos. Deteccao de similaridade. Checklist estrategico. Rota SS (suporte). Cache de busca. Indicador de completude. Limites de resultados.

---

## v1.2.0 - 10/03/2026

Sistema de tasks para rastreamento de demandas. Retomada entre chats. Deteccao automatica pelo guardiao. Consultas rapidas nao criam task.

---

## v1.1.1 - 10/03/2026

- Auditoria de consistencia: alinhamento entre documentacao, implementacao e apresentacao
- GUIA-RAPIDO.md: nota sobre rotas adaptativas (NE/SA/SS) adicionada

---

## v1.1.0 - 07/03/2026

- Indices inteligentes por modulo (23 modulos + resumo-pendentes)
- Classificacao multi-modulo com 331 keywords (pipeline de importacao via BuscaSAI; nome legado do repo "BuscaSaiFolha" na epoca)
- Smart-Write: nao reescreve arquivos identicos (economia de sync OneDrive)
- Monolitico movido para cache local (fora do OneDrive, -165 MB sync)
- gerar-indices processa fracionados sequencialmente (RAM: 2 GB -> 750 MB)
- Automacao silenciosa: importacao a cada 3h via Task Scheduler
- status.json com metricas de cada execucao
- Mecanismo de atualizacao via Cursor/IA (input.md + manifesto.json)
- Novo symlink referencia/atualizacao/ para acesso a pacotes de versao
- agente-produto.mdc: duas rotas (NE 5 passos / SA 6 passos discovery)
- agente-produto.mdc: protocolo de varredura com nivel de confianca (Alta/Media/Baixa)
- agente-produto.mdc: indicador de progresso em cada passo
- agente-codigo.mdc: modo discovery para funcionalidades que nao existem no sistema
- guardiao.mdc: auto-atualizacao silenciosa (sem perguntar ao analista)
- guardiao.mdc: log proativo automatico (sem esperar o analista pedir)
- guardiao.mdc: mensagem prioritaria copiavel para escalonar ao gerente
- guardiao.mdc: verificacao de frescor dos dados via status.json
- onboarding.mdc: deteccao inteligente (pula wizard se analista ja usa o projeto)
- projeto.mdc: linguagem acessivel focada em dores do dia-a-dia
- Removidas todas as referencias a SDD, BDD, Gherkin dos agentes
- agente-produto.mdc: Rota SS (4 passos) para resposta ao suporte N3
- agente-produto.mdc: orientacao para perguntas de fluxo/processo (usa mapa-folha.md)
- agente-produto.mdc: logs anteriores como fonte de contexto na varredura
- agente-produto.mdc: tratamento de interrupcao (oferece retomar passo)
- guardiao.mdc: tipos "Suporte" e "Fluxo" no log de atividades
- guardiao.mdc: consolidacao de multiplas mensagens prioritarias em uma unica
- guardiao.mdc: fallback se auto-atualizacao falhar (gera mensagem prioritaria)
- guardiao.mdc: Rota SS referenciada no fluxo de trabalho e formato de log
- projeto.mdc: exemplos de chamados SS no dia-a-dia

---

## v1.0.0 - 05/03/2026

Versao inicial do projeto filho. Pipeline exploratorio de 7 fases, logs com essencia do analista, integracao OneDrive.

---







