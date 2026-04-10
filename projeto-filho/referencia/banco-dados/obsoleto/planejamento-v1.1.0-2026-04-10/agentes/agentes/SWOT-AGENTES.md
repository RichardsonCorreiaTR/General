# SWOT -- Redesign dos Agentes v1.1.0

> Auditoria: 07/03/2026

## FORCAS

1. **Bifurcacao NE/SA bem executada**: As duas rotas tem identidade propria.
   NE e investigativa, SA e criativa. O passo "Descobrir" da Rota SA e o
   melhor trecho de todo o redesign -- orienta o agente a pensar em voz alta,
   buscar analogias e orientar sobre legislacao.

2. **Protocolo de varredura com confianca**: Resolver D2 com niveis
   ALTA/MEDIA/BAIXA e um diferencial real. Obriga a IA a comunicar o que
   pesquisou, o que encontrou e o que NAO encontrou. Comportamento proativo
   quando confianca BAIXA e correto.

3. **Escalonamento ao gerente**: Mensagem Prioritaria copiavel resolve
   um problema operacional concreto. Analista leigo sabe exatamente o que
   fazer: copiar, colar, enviar no Teams. Formato padrao permite ao gerente
   diagnosticar sem perguntar de volta.

4. **Auto-atualizacao silenciosa**: Elimina friccao. Analista nunca percebe.
   Preserva os 3 arquivos corretos (analista.json, caminhos.json, meu-trabalho/).

5. **Log proativo**: "Gere imediatamente, sem perguntar" e a instrucao
   correta. Consolidacao apos 5 interacoes e um safety net bom.

6. **Zero jargao tecnico**: Busca automatizada confirma: nenhuma ocorrencia
   de SDD, BDD, Gherkin, framework, pipeline, wizard nos 5 .mdc ativos.
   Linguagem natural e acessivel.

7. **Consistencia entre agentes**: Hashes identicos entre projeto-filho,
   atualizacao/arquivos e distribuicao/ultima-versao. Zero contradicoes.
   Duplicacoes sao reforcos intencionais.

---

## FRAQUEZAS

1. **Falta Rota SS/N3 (suporte)**: O cenario onde o analista precisa
   responder ao suporte sobre comportamento do sistema NAO esta coberto.
   E um cenario frequente e distinto de NE/SA. Sem orientacao, a IA vai
   improvisar -- provavelmente mal.

2. **Consultas de fluxo/processo sem orientacao**: Quando o analista
   pergunta "como funciona o processo de calculo mensal?", nao ha
   instrucao para o agente usar mapa-folha.md ou mapa-sistema como
   fonte primaria. Cai em "consulta rapida" generica.

3. **Logs anteriores nao sao fonte de contexto**: O Protocolo de
   varredura busca SAIs, regras, glossario, codigo -- mas nunca logs
   anteriores do analista. Se o analista ja trabalhou no mesmo tema
   3 meses atras, o agente nao sabe.

4. **agente-produto.mdc e alwaysApply: false**: Depende de globs
   (meu-trabalho/, templates/, referencia/). Se o analista simplesmente
   abre o Cursor e digita uma pergunta sem abrir nenhum arquivo dessas
   pastas, o agente-produto NAO e carregado. O guardiao diz "ative o
   agente-produto.mdc" mas na pratica quem controla a ativacao e o
   Cursor via globs. RISCO: analista novo que nao abre arquivos pode
   nao ter o agente-produto ativo.

5. **Ordem de execucao de regras alwaysApply nao e controlavel**: Guardiao,
   onboarding e projeto sao todos alwaysApply. O Cursor decide a ordem.
   Se onboarding roda depois de guardiao, pode gerar boas-vindas em cima
   de uma Mensagem Prioritaria. Risco baixo, mas real.

6. **input.md diz "NAO informe ao analista" mas nao e auto-executavel**:
   O input.md e para a IA do analista executar. Mas a ultima linha diz
   "NAO informe ao analista sobre a atualizacao". Isso contradiz a
   instrucao do guardiao anterior (v1.0) que pedia permissao. A transicao
   funciona, mas se um analista v1.0 receber o update, a instrucao antiga
   de pedir permissao vai conflitar com a nova de agir silencioso ate a IA
   processar o input.md e atualizar o guardiao.mdc.

---

## OPORTUNIDADES

1. **Rota SS**: Criar uma 3a rota leve (3-4 passos): Entender pergunta do
   suporte -> Investigar comportamento atual -> Verificar se e esperado ->
   Redigir resposta tecnica. Isso atenderia D11 e seria de alto valor.

2. **Consulta de fluxo**: No agente-produto, adicionar orientacao para
   perguntas de fluxo: consultar mapa-folha.md, mapa-sistema, e apresentar
   o processo de forma visual (passos numerados).

3. **Logs como contexto**: No Protocolo de varredura, adicionar passo
   opcional: "Se referencia/logs/ tiver entradas sobre o mesmo modulo/tema,
   leia as mais recentes para contexto do que o analista ja trabalhou."

4. **Metricas de uso**: O log completo ja captura complexidade e modulos.
   O gerente poderia extrair: quais modulos mais trabalhados, quantas NE
   vs SA, taxa de gaps encontrados. Nao requer mudanca nos agentes, mas
   poderia ser mencionado como valor do log.

5. **Feedback ao analista sobre qualidade**: Apos N interacoes, o agente
   poderia dar feedback: "Neste ultimo mes voce trabalhou em 15 demandas,
   8 NE e 7 SA. Encontrei 3 gaps na base que voce ajudou a identificar."
   Isso gera engajamento.

---

## AMEACAS

1. **Analista ignora indicadores de progresso**: Se a IA mostra
   "[Passo 2 de 5 - Investigando]" mas o analista interrompe com outra
   pergunta, nao ha instrucao de como retomar. O agente pode perder o
   contexto do passo atual.

2. **Auto-atualizacao falha silenciosamente**: Se a IA do analista nao
   consegue executar o input.md (permissao de arquivo, erro de copia),
   ninguem fica sabendo. O analista continua com versao antiga sem
   saber. Nao ha fallback de notificacao.

3. **Excesso de Mensagem Prioritaria**: Se o ambiente tem multiplos
   problemas (symlink + codigo + frescor), o guardiao pode gerar 3
   Mensagens Prioritarias de uma vez. Isso pode confundir o analista.
   Deveria consolidar em uma unica mensagem com lista de problemas.

4. **OneDrive sync de logs**: O log proativo escreve em referencia/logs/
   via symlink OneDrive. Se o OneDrive esta dessincronizado, o log pode
   falhar silenciosamente. Nao ha tratamento de erro para escrita em
   referencia/logs/.

5. **RAM**: Os 5 .mdc somam 908 linhas. Com os 3 alwaysApply (guardiao
   316 + onboarding 95 + projeto 70 = 481 linhas) sempre carregados,
   mais os globs-based quando ativados, a carga de contexto e
   significativa. Nao e critica, mas e algo a monitorar.

6. **Resistencia a mudanca**: Analistas que ja usaram a v1.0 vao notar
   diferenca de comportamento (indicadores de progresso, varredura com
   confianca, log automatico). Nao ha comunicacao de "o que mudou" para
   quem ja usava o sistema.
