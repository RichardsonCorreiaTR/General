# Changelog - Projeto Filho

## v2.4.16 - 30/04/2026

v2.4.16: Consultar-PSAI-SGD e Enriquecer-PSAI-DadosBrutos pedem utilizador/senha SGD apenas na primeira vez (sem data/sgd-psai-consultas/.sgd-credentials.local); opcao gravar credenciais locais. lib-sgd-caminhos: Test-SgdCredentialsLocalFile, Save-SgdCredentialsLocalFile.

---

## v2.4.15 - 30/04/2026

v2.4.15: env.py le credenciais SGD em projeto-filho/data/sgd-psai-consultas quando o modulo Python esta em projeto-filho/scripts/sgd_consulta. Instalador: passo opcional apos verificacao para gravar utilizador e senha SGD (.sgd-credentials.local). atualizar-projeto.ps1: se nao existir credencial local, pergunta ao final. instalar-projeto-filho.ps1 incluido no sync SharePoint; parametro -PularSgdCredenciais.

---

## v2.4.13 - 29/04/2026

Indices SAIs: gerador tolera alias importao/importacao no modulo; nao-classificado.md sempre gerado (vazio quando nao houver). Keywords em modulos-keywords.json ampliadas para classificacao por dominio. Admin: agendar-atualizacao.ps1 (seg-sex), sincronizar-sharepoint.ps1 inclui scripts de agendamento e atualizacao silenciosa. Scripts buscar-sai e setup-odbc alinhados ao pacote do analista.

---

## v2.4.12 - 27/04/2026

feat(buscar-sai): adicionar URLs clicaveis para SAI/PSAI no resultado das buscas. Cada resultado agora exibe duas linhas em azul (SAI: https://sgsai.dominiosistemas.com.br/sgsai/faces/sai.html?sai={n} e PSAI: https://sgd.dominiosistemas.com.br/sgsa/faces/psai.html?psai={n}), funcionando em todos os modos (padrao, -Resumido, -VisualizarSai). Terminais modernos (Windows Terminal, VSCode/Cursor, pwsh) tornam as URLs clicaveis via Ctrl+Click. URLs configuraveis via constantes no topo do script.

---

## v2.4.11 - 27/04/2026

fix(distribuicao): incluir CORRECAO-SYMLINKS.md nos pacotes (Canal 1 e Canal 2). Antes ficava so no projeto-filho do admin; agora a IA do analista tem o guia para diagnosticar problemas de symlinks/acesso a referencia/. atualizar-projeto.ps1 tambem foi atualizado para copiar o arquivo.

---

## v2.4.10 - 24/04/2026

fix(privacidade): excluir status-ambiente.json dos pacotes de atualizacao (continha nome/email/host/usuario_windows do empacotador). gerar-atualizacao.ps1 agora limpa esse arquivo automaticamente, e .gitignore cobre tambem atualizacao/v*/arquivos/config/status-ambiente.json.

---

## v2.4.9 - 24/04/2026

verificar-ambiente.ps1 agora publica status-ambiente.json no OneDrive (logs/analistas/{pasta_log}/) com campos analista, email, host e usuario_windows; novo script scripts/relatorio-versoes-analistas.ps1 (admin) consolida os status publicados e gera relatorio centralizado em logs/relatorios/versoes-analistas.{md,json} comparando versao instalada de cada analista com a versao alvo de distribuicao/ultima-versao.

---

## v2.4.8 - 24/04/2026

Area Contabil adicionada: 6 novos modulos (Contabilidade, Patrimônio, Atualização Monetária, LALUR, Registros Contábeis, Conteúdo Contábil Tributário); importar-sais.ps1 com -SomenteAreas para extração incremental por área; extrair-sais.ps1 com -AreasOverride; modulos-keywords.json com campo keywords nos módulos Contábil; gerar-indices-sais.ps1 robusto a keywords null. Templates PSAI e regra-negocio atualizados com areas Escrita/Importacao/Contabilidade; novos guias GUIA-padroes-psai.md e GUIA-validacao-ne.md; nova regra revisar-psai.mdc.

---

## v2.4.7 - 23/04/2026

Filtro de areas por analista: campo areas[] em time-analistas.json e analista.json; buscar-sai.ps1 aceita -Areas (array); agente-produto.mdc aplica areas automaticamente nas buscas; instalar-projeto-filho.ps1 copia areas do cadastro central no setup.

---

## v2.4.6 - 23/04/2026

Atualizacao base SAIs modulos Escrita e Importacao (PSAI mais recente 130257 de 20-04-2026); registro centralizado do time de analistas (27 membros) em config/time-analistas.json; pastas de log criadas para todos os analistas.

---

## v2.4.5 - 22/04/2026

Removida referencia a rubrica nos filtros de busca (agente-produto.mdc e guardiao.mdc); fix buscar-sai.ps1: inicializacao nula de variavel e remocao de BOM.

---

## v2.4.4 - 15/04/2026

Atualizacao base SAIs todos os modulos (ODBC multi-area): +15053 registros vs ciclo anterior, PSAI mais recente 130119 de 15-04-2026; indices regenerados.

---

## v2.4.3 - 14/04/2026

Fix buscar-sai.ps1: remocao de BOM e correcao de variavel nao inicializada; normalizacao de line endings em templates.

---

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




















