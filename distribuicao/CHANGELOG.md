# Changelog - Projeto Filho

## v2.4.39 - 10/06/2026

- breaking: GitHub-only no projeto-filho. Analista NAO clona mais o codigo do BR Contabil; toda consulta vai via gh CLI sob demanda.
- remove: scripts/atualizar-codigo.ps1 e scripts/atualizar-codigo-fonte.ps1 (nao mais necessarios no filho).
- remove: config/codigo-fonte.json (consumido pelos scripts removidos).
- breaking: campo "codigo_local" removido de config/caminhos.json. Instalador (General) nao escreve mais esse campo.
- feat: .cursor/rules/agente-codigo.mdc reescrito - "Onde buscar" agora documenta apenas gh api (sem clone local). Inclui comandos basicos (branches, contents, search/code) e protecao de rate limit.
- feat: .cursor/rules/acesso-github.mdc enfatiza que gh api e o UNICO modo de consulta (sem mais "Modo A/Modo B").
- feat: scripts/verificar-ambiente.ps1 sem checagem "Codigo-fonte local" (checagens 2b/2c/2d ja cobrem gh + auth + acesso ao repo).
- feat: scripts/instalar-projeto-filho.ps1 (General) - Install-GitCode/Install-FromZip substituidos por Test-GitHubAccess (verifica gh, auth, acesso a tr/brtap-dominio_contabil); Passo 6 do instalador renomeado "Verificando acesso ao GitHub".
- docs: SETUP.md (pre-requisitos sem Git opcional), SETUP-GITHUB.md (secao "Como a IA usa" reescrita), PROMPT-INSTALACAO.md (passo 4 sem codigo_local), PROJETO.md (estrutura sem atualizar-codigo.ps1; tabela de scripts atualizada), GUIA-RAPIDO.md (FAQ "Onde vejo o codigo-fonte" reescrita), CORRECAO-SYMLINKS.md (sem codigo_local).
- docs: corrigir-symlinks.ps1 - codigo_local removido da reconstrucao automatica.
- nota: General MANTEM Modo A (gestor tem clone local em C:\1 - A\B\Programas\brtap-dominio; scripts/atualizar-codigo.ps1 e atualizar-tudo.bat continuam validos para o admin).

---

## v2.4.38 - 10/06/2026

- feat: SETUP-GITHUB.md - guia do analista para acesso ao codigo-fonte do BR Contabil via gh CLI (autenticacao, troubleshooting, regras de seguranca)
- feat: .cursor/rules/acesso-github.mdc - regra dedicada para acesso seguro ao GitHub (alwaysApply): NUNCA pedir token no chat, NUNCA gravar token em arquivo do projeto, preferir gh auth login (keyring) ou GITHUB_TOKEN em env var
- feat: config/codigo-fonte-branches.json - branches declaradas pelo gestor (vigente, vigente_anterior, em_dev); scripts agora leem dela em vez de hardcoded VC106A02
- feat: scripts/atualizar-codigo.ps1 - parametro -BranchConceito (vigente/vigente_anterior/em_dev) que le config/codigo-fonte-branches.json; -Branch (explicito) mantem precedencia para override manual
- feat: scripts/verificar-ambiente.ps1 - checagens novas: gh CLI instalado, gh auth status, acesso ao tr/brtap-dominio_contabil, config/codigo-fonte-branches.json valido; mensagem orientativa em caso de 404 (Team / Fernando Pizetti) ou SSO
- feat: agente-codigo.mdc - Modo B (fallback via gh api) documentado para quando codigo local indisponivel ou para olhar outra branch
- feat: scripts/atualizar-projeto.ps1 - passa a copiar SETUP-GITHUB.md e PROMPT-INSTALACAO.md no upgrade
- docs: guardiao.mdc (General + filho) - bloco resumo "Acesso ao GitHub" apontando para regra dedicada acesso-github.mdc
- docs: PROMPT-INSTALACAO.md - novo passo 8b orienta IA a verificar gh CLI, autenticacao e acesso ao repo durante a instalacao
- docs: SETUP.md - pre-requisitos atualizados com gh CLI + referencia a SETUP-GITHUB.md
- config: cursor-rules-manifest.json - inclui acesso-github.mdc na lista de regras obrigatorias

---

## v2.4.38 - 10/06/2026

- feat: SETUP-GITHUB.md - guia do analista para acesso ao codigo-fonte do BR Contabil via gh CLI (autenticacao, troubleshooting, regras de seguranca)
- feat: .cursor/rules/acesso-github.mdc - regra dedicada para acesso seguro ao GitHub (alwaysApply): NUNCA pedir token no chat, NUNCA gravar token em arquivo do projeto, preferir gh auth login (keyring) ou GITHUB_TOKEN em env var
- feat: config/codigo-fonte-branches.json - branches declaradas pelo gestor (vigente, vigente_anterior, em_dev); scripts agora leem dela em vez de hardcoded VC106A02
- feat: scripts/atualizar-codigo.ps1 - parametro -BranchConceito (vigente/vigente_anterior/em_dev) que le config/codigo-fonte-branches.json; -Branch (explicito) mantem precedencia para override manual
- feat: scripts/verificar-ambiente.ps1 - checagens novas: gh CLI instalado, gh auth status, acesso ao tr/brtap-dominio_contabil, config/codigo-fonte-branches.json valido; mensagem orientativa em caso de 404 (Team / Fernando Pizetti) ou SSO
- feat: agente-codigo.mdc - Modo B (fallback via gh api) documentado para quando codigo local indisponivel ou para olhar outra branch
- docs: guardiao.mdc (General + filho) - bloco resumo "Acesso ao GitHub" apontando para regra dedicada acesso-github.mdc
- docs: PROMPT-INSTALACAO.md - novo passo 8b orienta IA a verificar gh CLI, autenticacao e acesso ao repo durante a instalacao
- docs: SETUP.md - pre-requisitos atualizados com gh CLI + referencia a SETUP-GITHUB.md
- config: cursor-rules-manifest.json - inclui acesso-github.mdc na lista de regras obrigatorias

---

## v2.4.37 - 09/06/2026

- feat: GUIA-validacao-sal.md - guia dedicado para validacao de SAL (Solicitacao de Alteracao Legal)
  * 9 etapas: identificacao da norma, datas (publicacao/vigencia/eficacia/retroatividade), comportamento anterior x novo, versao de liberacao, CCT (Checkpoint), calculos, reflexos, comunicacao externa, analise estrategica
  * Distincao clara SAL vs SAIL vs SAM vs NE
  * Checklist final com decisao APROVADO/DEVOLVER/ESCALAR
  * Margem de seguranca minima de 5 dias uteis antes da vigencia
  * Integracao com GUIA-validacao-calculos-negativos.md e GUIA-padroes-psai.md
- docs: revisar-psai.mdc aponta para GUIA-validacao-sal.md no Passo 5 (Conformidade)
  * SAL agora usa guia dedicado; SAIL mantem regras inline (guia dedicado em desenvolvimento)
- docs: agente-produto.mdc Rota SA Passo 5 cita o novo guia para SAL
- docs: GUIA-padroes-psai.md cabecalho atualizado com referencia ao novo guia
- (proximos): GUIA-validacao-sam.md e GUIA-validacao-sail.md (separados por tipo, facilita evolucao independente)

---

## v2.4.36 - 09/06/2026

- feat: GUIA-validacao-calculos-negativos.md - novo guia de validacao de calculos com possibilidade de valor negativo (SAM/SAL/SAIL apenas; NAO aplicavel a NE)
  * 3 etapas: analise preventiva (classificar formula), tratamento (definir regra explicita) e validacao em tempo de execucao
  * Modelo de secao "Tratamento de valor negativo" para preencher na PSAI/SAI
  * Checklist de qualidade + exemplos no dominio Escrita (ICMS, DARF, lucro real, estoque)
  * Mensagem de alerta padrao quando faltar regra: bloqueia conclusao da PSAI ate o analista definir
- docs: integracao do guia em revisar-psai.mdc (Passo 5 - Conformidade) e agente-produto.mdc (Rota SA Passos 4 e 5)
- docs: GUIA-padroes-psai.md com referencia cruzada ao novo guia (cabecalho e secao 9)

---

## v2.4.35 - 09/06/2026

- fix: areas do analista re-sincronizadas automaticamente em toda atualizacao (corrige problema do time contabil)
  * atualizar-projeto.ps1 agora chama sincronizar-areas.ps1 -Confirmar:$false ao final
  * Resolve o problema de analistas reclassificadas (ex.: contabil) que apareciam como Escrita
  * Causa raiz: instalador antigo gravou um default codificado e o ciclo de atualizacao nao re-lia o time-analistas.json
  * Falhas de sincronizacao (sem OneDrive) viram avisos -- a atualizacao continua
  * Backup automatico em config/analista.json.bak antes de sobrescrever
- docs: regra de validacao de areas no projeto-filho (guardiao.mdc)
  * IA alerta o analista na primeira interacao do dia se as areas locais estiverem diferentes do central
  * Sugere rodar sincronizar-areas.ps1 quando detecta divergencia

---

## v2.4.34 - 22/05/2026

- fix: validacao robusta de credenciais SGD ao consultar PSAI
  * Detecta senha incorreta mesmo quando SGD faz redirect breve antes de voltar ao login
  * Nova excecao LoginError (tipo especifico) em session.py
  * Novas funcoes em env.py: pedir_credenciais_sgd, atualizar_credenciais, _gravar_credenciais_local
  * Retry automatico ate 3x com prompt de novas credenciais em terminal interativo
  * Em terminal nao-interativo (Cursor/agente): mensagem clara pedindo para rodar manualmente

- feat: novo script sincronizar-areas.ps1
  * Re-le o cadastro central (config/time-analistas.json no OneDrive) e atualiza config/analista.json local
  * Compara areas locais x centrais e pede confirmacao antes de sobrescrever
  * Faz backup automatico em config/analista.json.bak
  * Util quando o gerente reclassifica areas fora do ciclo de release

- feat: buscar-sai.ps1 com paridade ao General
  * Novo parametro -Termos (array OR entre varios termos)
  * Novo parametro -PalavraIsolada (regex \b<termo>\b)
  * Novo parametro -SomenteDescricao (limita ao campo sai_descricao)
  * Normalizacao automatica de acentos (Contabil <-> Contábil)
  * Permite reproduzir exatamente o mesmo criterio dos relatorios PDF gerados no General

---
## v2.4.33 - 18/05/2026

- feat: analise de legislacao via Claude AI (claude-sonnet-4-6)
  * Novo script Python: scripts/sgd_consulta/consultar_legislacao.py
  * Novo wrapper PowerShell: scripts/Consultar-Legislacao.ps1
  * Nova regra Cursor: .cursor/rules/consultar-legislacao.mdc
  * Analista fornece URL ou arquivo (PDF/DOCX/TXT) de lei, decreto, portaria ou IN
  * Claude retorna resumo estruturado (identificacao, objetivo, obrigacoes, prazos, pontos de atencao)
  * Suporte a perguntas especificas sobre a legislacao
  * Resultados salvos em data/legislacao/ como JSON
  * Requer: ANTHROPIC_API_KEY em scripts/sgd_consulta/.env (instruções no .env.example)
  * Dependencias novas: anthropic, httpx, beautifulsoup4, pdfplumber (requirements.txt atualizado)

---

## v2.4.32 — 2026-05-16

- Fix: extracao por area/sistema — modo merge preserva fracionados das demais areas ao usar -SomenteAreas
- Fix: pausa automatica com Enter ao cair zScaler (retoma sem reiniciar)
- Fix: modo batch=1 com SKIP de PSAIs com erro para diagnostico
- Fix: agente-produto.mdc publica log automaticamente apos cada interacao
- Fix: encoding UTF-8 limpo nos scripts (elimina caracteres invisiveis)

## v2.4.31 — 2026-05-13

- Fix: gente-produto.mdc agora publica log automaticamente em 
eferencia/logs/YYYY-MM-DD.md e executa Publicar-LogParaConsolidacao.ps1 ao final de cada interacao substancial, sem exigir acao do analista.
# Changelog - Projeto Filho

## v2.4.27 - 06/05/2026

Fix: atualizar-codigo.ps1 lib-lock ausente e caminho META.json errado; contato de escalonamento atualizado

---

## v2.4.26 - 06/05/2026

Correcao: contato de escalonamento atualizado para Richardson Picinini Correia

---

## v2.4.25 - 06/05/2026

Correcao: ALERTA PROJETO FOLHA -> PROJETO ESCRITA no guardiao.mdc

---

## v2.4.24 - 05/05/2026

Consulta SAI no SGSAI: script consultar_sai.py, wrapper Consultar-SAI-SGD.ps1 e regra de auto-acesso ao SGSAI

---

## v2.4.23 - 04/05/2026

Atualizacao de rotina.

---

## v2.4.22 - 04/05/2026

Atualizacao de rotina.

---

## v2.4.21 - 04/05/2026

Atualizacao de rotina.

---

## v2.4.20 - 04/05/2026

Atualizacao de rotina.

---

## v2.4.19 - 04/05/2026

Atualizacao de rotina.

---

## v2.4.18 - 04/05/2026

v2.4.18: Cursor Agent — .cursor/sandbox.json (rede permitida no sandbox, enableSharedBuildCache), permissions.json.example, scripts/configurar-cursor-auto-run.ps1; onboarding e projeto.mdc com Auto-Run/WSL2; sincronizar-sharepoint inclui configurar-cursor-auto-run.

---

## v2.4.17 - 30/04/2026

v2.4.17: sync scripts/sgd_consulta (Python) Admin para projeto-filho antes do pacote (sync-sgd-consulta-para-projeto-filho.ps1). setup-sgd-python.ps1: venv + pip + Playwright chromium. verificar-ambiente: Python, modulo sgd_consulta, .venv. Consultar/Enriquecer: mensagem se Python ausente. sincronizar-sharepoint: novos scripts.

---

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









































