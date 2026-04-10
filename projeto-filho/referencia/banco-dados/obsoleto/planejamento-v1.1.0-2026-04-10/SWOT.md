# SWOT - Plano de Atualizacao v2

> Gerado em: 07/03/2026
> Objetivo: Identificar furos, riscos nao mapeados e oportunidades perdidas

---

## S - FORCAS (o que funciona bem no plano)

### S1. Fases independentes
Cada fase funciona sozinha. Se Fase 2 falhar, Fases 1/3/4 continuam.
Nenhuma fase quebra o que ja existe. Isso e raro em projetos de refatoracao.

### S2. Backward compatible
Indices antigos mantidos. por-modulo.md continua existindo.
Analista que nao atualizar continua funcionando (so nao tem as melhorias).

### S3. Resolve o problema REAL
A FASE 2 do agente-produto esta QUEBRADA (por-modulo.md = 408% do contexto).
O plano ataca diretamente isso com modulos de 5-20 KB (max 15%).

### S4. Mecanismo de atualizacao elegante
Analista cola 1 frase no Cursor. IA executa. Sem scripts, sem terminal.
Combina com o perfil leigo dos analistas.

### S5. Smart rewrite e eliminacao do monolitico
Reducao real: 335 MB -> 92 MB sync, 2 GB -> 550 MB RAM.
Numeros baseados em dados concretos (volumes medidos).

### S6. Automacao desacoplada
Task Scheduler roda silencioso, nao interfere no trabalho do gerente.
Pre-checks evitam execucao quando ODBC ou OneDrive indisponivel.

### S7. Multi-modulo maximiza valor
SAI sobre FGTS retroativo aparece em FGTS e em Retroativo/CCT.
Elimina o problema de SAI "escondida" no modulo errado.

---

## W - FRAQUEZAS (problemas internos do plano)

### W1. RESOLVIDO: classificacao via SGD e inviavel, keywords sao o caminho
Investigacao completa (07/03/2026):
  - i_modulos = 19 (Folha) em 100% dos 35.307 registros (consulta ODBC direta)
  - bethadba.modulos existe mas so mapeia para "Folha" (sem sub-areas)
  - SGD NAO tem sub-classificacao dentro de Folha. Nenhuma tabela resolve.
  - BuscaSaiFolha ja usava keyword matching (87 tags) pela mesma razao.

SOLUCAO: Absorver DICIONARIO_TAGS do BuscaSaiFolha (87 tags) como base.
Agrupar em ~22 modulos. Nenhuma mudanca SQL. Nenhum risco na extracao.
Meta: Nao Classificado de ~5335 para ~800-1500.
W1 deixa de ser fraqueza e vira FORCA (simplicidade: so keywords, sem JOIN).

### W2. Cursor/IA como executor e nao-deterministico
A IA do analista pode interpretar o input.md de formas diferentes.
Modelos diferentes (Claude, GPT-4, etc.) podem ter comportamentos distintos.
Nao e um script com resultado previsivel.

MITIGACAO: input.md extremamente estruturado (tabela origem->destino).
MITIGACAO EXTRA: Adicionar secao de verificacao pos-atualizacao no input.md
para que a IA confirme que cada arquivo foi copiado corretamente.

### W3. Sem feedback loop para o gerente
O admin nao sabe se os 17 analistas atualizaram com sucesso.
Se 5 nao atualizarem, ficam com regras antigas (FASE 2 quebrada).

ACAO NECESSARIA: Na atualizacao via IA, gravar confirmacao no log
do analista (referencia/logs/) com versao atualizada e data.
Gerente consulta logs para ver quem atualizou.

### W4. Backup vai para %TEMP%
Se a atualizacao falhar no meio, backup esta em %TEMP%.
Windows pode limpar TEMP em qualquer momento.

ACAO NECESSARIA: Backup deve ir para meu-trabalho/.backup/ (local, seguro).

### W5. Sem ambiente de teste/staging
Mudancas no gerar-indices-sais.ps1 vao direto para o OneDrive de producao.
Se a Fase 1 gerar modulos errados, todos os analistas veem dados errados.

MITIGACAO: Rodar gerar-indices-sais.ps1 com output em pasta temporaria
primeiro. Conferir resultado antes de copiar para banco-dados/sais/indices/.

### W6. Estimativas de tamanho sao estimativas
"Nao Classificado de ~5335 para ~500-800" e projecao, nao medida.
"Modulos de 5-20 KB" e calculo, nao verificado com dados reais.
A realidade pode ser diferente.

MITIGACAO: Rodar Fase 1 e MEDIR antes de prosseguir.
Se Nao Classificado ficar em 2000+ ou modulos ficarem > 30 KB,
reavaliar keywords e formato antes de publicar.

### W7. Guardiao fica mais pesado na primeira interacao
Hoje: verificacao de versao + verificacao de codigo.
Novo: + verificacao de dados novos + verificacao de atualizacao.
Sao 4+ leituras de arquivos antes do analista comecar a trabalhar.

MITIGACAO: Aceitavel (sao arquivos leves, < 1 segundo total).
Mas documentar para nao adicionar mais checks sem necessidade.

---

## O - OPORTUNIDADES (o que poderiamos ganhar alem)

### O1. Resolucao de i_modulos para nome
Se adicionarmos JOIN com tabela de modulos no SGD (extrair-sais.ps1),
ganhamos classificacao precisa direto da fonte, sem depender de keywords.
Isso resolve W1 e pode levar Nao Classificado para < 200.

### O2. Dashboard de saude do projeto
status.json + logs de importacao + logs de analistas = dados para um
dashboard simples (HTML estatico gerado pelo script) que mostre:
- Ultima importacao (data, registros, erros)
- Analistas que atualizaram
- Modulos mais consultados
Nao e prioridade, mas e oportunidade futura.

### O3. Classificacao assistida por IA
SAIs que caem em Nao Classificado poderiam ter sugestao de modulo
pela IA com base no texto completo (descricao + comportamento + definicao).
Gerente revisaria e aprovaria. Alimentaria as keywords automaticamente.

### O4. Reuso do padrao para regras-negocio
A estrutura de modulos inteligentes (resumo + detalhado + temas) pode
ser replicada para banco-dados/regras-negocio/ e glossario/.
Mesmo padrao, mesma logica de contexto para a IA.

### O5. Versionamento de keywords como arquivo externo
Hoje keywords estao hardcoded no gerar-indices-sais.ps1.
Extrair para banco-dados/config/modulos-keywords.json permitiria:
- Gerente editar keywords sem mexer no script
- Analistas sugerirem novas keywords
- Versionamento independente

### O6. Confirmacao de atualizacao automatica
Quando IA do analista executa a atualizacao com sucesso, ela
grava automaticamente no log do OneDrive. Gerente monitora
quem atualizou sem perguntar.

---

## T - AMEACAS (riscos externos ao plano)

### T1. OneDrive sync conflict
Task Scheduler rodando enquanto OneDrive ainda sincroniza rodada anterior.
Pode causar conflitos de arquivo (versao do OneDrive vs versao local).

MITIGACAO: Pre-check no script verifica se OneDrive nao esta em sync
pesado. Ou: gerar em pasta temp e mover atomaticamente (move e atomico).

### T2. Cursor pode mudar comportamento
Atualizacoes do Cursor podem mudar como .mdc e interpretado,
como tools funcionam, ou limites de contexto.
O que funciona hoje pode nao funcionar em 6 meses.

MITIGACAO: Baixo risco real (Cursor mantem backward compatibility).
Manter input.md generico, sem depender de features especificas do Cursor.

### T3. SGD pode mudar schema
Se campos como i_modulos, sai_descricao ou tipoSAI mudarem de nome
no banco, a extracao quebra silenciosamente ou com erro.

MITIGACAO: extrair-sais.ps1 ja tem tratamento de erros.
Adicionar validacao pos-extracao: conferir se campos esperados existem.

### T4. Permissoes corporativas
TI pode bloquear: Task Scheduler, criacao de symlinks, ODBC.
Qualquer um desses bloqueia uma fase inteira.

MITIGACAO EXISTENTE: Task Scheduler = so admin. Symlinks = junction (/J)
nao precisa admin. ODBC = ja validado e funcionando.
RISCO REAL: Politica de TI mudar no futuro. Baixo risco atual.

### T5. Volume crescente
29.296 registros hoje. Se dobrar para 60K em 2 anos:
- Modulos maiores poderiam exceder limite de contexto novamente
- Fracionados ficam mais pesados
- Tempo de processamento aumenta

MITIGACAO: Smart rewrite + incremental reduzem impacto proporcional.
Formato dos modulos (so pendentes detalhados) escala bem porque
liberadas antigas sao resumidas (30 mais recentes, nao todas).

### T6. Analista ignora atualizacoes repetidamente
Guardiao sugere, analista diz "nao" toda vez. Fica com regras antigas.
Nao ha enforcement, so sugestao.

MITIGACAO: Log registra que analista recusou. Gerente identifica
e intervem pessoalmente se necessario.

### T7. Falha silenciosa da automacao
Task Scheduler falha e ninguem percebe por dias.
Dados ficam desatualizados sem alerta.

MITIGACAO: status.json registra ultima execucao.
Guardiao do admin poderia verificar se faz > 24h sem importacao.
Ou: script envia notificacao simples (email ou Teams webhook) se falhar.

---

## ACHADOS CRITICOS - Acoes Necessarias

### AC1. RESOLVIDO: i_modulos inutil, keywords sao o caminho
Investigacao completa (07/03/2026):
  - i_modulos = 19 (Folha) em 100% dos 35.307 registros (consulta ODBC).
  - bethadba.modulos existe mas so resolve para "Folha" (sem sub-areas).
  - SGD NAO tem sub-classificacao dentro de Folha.
  - BuscaSaiFolha (Node.js) ja tinha chegado a mesma conclusao e usava
    DICIONARIO_TAGS com 87 tags por keyword matching.
DECISAO FINAL: Nivel 1 eliminado. Absorver dicionario BuscaSaiFolha (87 tags)
  como base para keywords expandidas. Nenhuma mudanca no SQL necessaria.

### AC2. Mover backup para local seguro
Trocar %TEMP% por meu-trabalho/.backup/ no input.md e no atualizar-projeto.ps1.

### AC3. Adicionar feedback de atualizacao no log
Quando IA atualiza projeto, gravar no log do analista:
"## HH:MM - [Atualizacao] Projeto atualizado para v1.1.0"

### AC4. Extrair keywords para arquivo externo
banco-dados/config/modulos-keywords.json em vez de hardcoded no script.
Facilita manutencao e permite versionar independentemente.

---

## VEREDICTO

Plano e SOLIDO. Os 4 requisitos (IA assertiva, sync minimo, atualizacao constante,
RAM controlada) estao bem cobertos com numeros reais.

O RISCO AC1 (modulo_caminho) foi INVESTIGADO E RESOLVIDO.
i_modulos = 19 (Folha) para 100% dos registros. SGD nao tem sub-areas.
Nivel 1 eliminado. Fase 1 usa keywords do BuscaSaiFolha (87 tags) + multi-modulo.
Nenhuma mudanca SQL necessaria. Nenhum ponto bloqueante restante.

Os demais achados (AC2-AC4) sao melhorias que podemos incorporar sem mudar
a arquitetura. Nenhum e bloqueante.

RECOMENDACAO: Validar AC1 AGORA. Se confirmar que modulo_caminho esta vazio,
adicionar ao plano como "Fase 0: Enriquecer extracao com nome de modulo".
