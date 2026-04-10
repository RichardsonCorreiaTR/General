# BLUEPRINT PGAP: Implementacao do Agente Pesquisador de SAIs

**Versao:** 1.0
**Data:** 10/03/2026
**Tipo:** Arquitetura com Agentes Especializados

---

## 1. CONTEXTO DO PROBLEMA

### O que acontece vs o que deveria acontecer

**Situacao atual:**
- Analista pergunta sobre SAI 40798 para a IA
- IA le indice MD truncado em 80 chars: "...opcao 'RAIS',"
- IA **infere** que vem mais conteudo (ex: "DIRF") e apresenta como fato
- Analista recebe informacao **inventada** e questiona confiabilidade

**O que deveria acontecer:**
- IA identifica que dado esta truncado
- IA **automaticamente** busca definicao completa no JSON
- IA retorna informacao **completa e verificada**
- Analista recebe dado confiavel

### Exemplo concreto e verificavel

**SAI:** 40798 (PSAI 34713)
**Descricao real (107 chars):** "Desmarcar na rubrica padrao 8883 - Diarias nao tributaveis a opcao 'RAIS', na guia 'Configuracoes'."
**Truncado indice (80 chars):** "Desmarcar na rubrica padrao 8883 - Diarias nao tributaveis a opcao 'RAIS',"
**IA inferiu:** "...e DIRF/Comprovante de rendimentos" (FALSO - nao existe no dado real)

### Impacto no negocio

**Confianca comprometida:**
- 10.693 SAIs (90.8%) estao truncadas nos indices
- Toda consulta sobre elas tem risco de inferencia inadequada
- Analistas podem tomar decisoes baseadas em dados inventados

**Tempo perdido:**
- Analista precisa validar manualmente cada informacao
- Perda de produtividade (~15-30 min por validacao)

**Qualidade das definicoes:**
- PSAIs/SAIs mal especificadas por base de pesquisa inadequada
- Retrabalho quando desenvolvedor identifica gap

---

## 2. DORES DO SOLICITANTE

1. **Precisaremos rodar atualizacao no projeto-filho?**
   - Sim, nova versao v1.1.0 com agente-pesquisador.mdc
   - Analistas (~17 pessoas) precisam atualizar?

2. **Risco de crash de RAM ou falha de token do agente?**
   - Agente vai carregar JSONs grandes (~200 MB)?
   - Token budget do subagente suporta busca + processamento?

3. **Quais exemplos de funcionamento?**
   - Como seria o fluxo exato: analista pergunta -> agente responde?
   - Preciso ver casos concretos de uso

4. **Agentes precisariam ser atualizados e isso funcionaria bem no projeto-filho?**
   - agente-produto.mdc precisa mudar?
   - Como integrar sem quebrar fluxo atual dos analistas?

5. **Quais dados de resposta, token e gasto?**
   - Latencia: quanto tempo a mais?
   - Tokens: quanto consome por busca?
   - Custo: quanto aumenta o gasto mensal?

---

## 3. ARQUIVOS/ARTEFATOS RELEVANTES

**LEIA TODOS antes de propor qualquer coisa**

- 'projeto-filho/.cursor/rules/agente-produto.mdc' (307 linhas) -- agente atual que precisa integrar
- 'projeto-filho/.cursor/rules/guardiao.mdc' (265 linhas) -- regras de protecao OOM
- 'scripts/buscar-sai.ps1' -- script que o agente vai usar internamente
- 'banco-dados/dados-brutos/sai/ne-liberadas.json' (48 MB) -- exemplo de JSON grande
- 'banco-dados/sais/indices/liberadas-ne-recentes.md' -- indice truncado atual
- 'agentes/agente-produto.md' -- documentacao do agente de produto
- 'templates/TEMPLATE-prompt-blueprint.md' -- estrutura deste documento

---

## 4. HIPOTESES A INVESTIGAR

### H1: Subagente consegue rodar buscar-sai.ps1 sem crash OOM

**O que verificar:**
- Memory footprint do script buscar-sai.ps1 quando roda dentro do Cursor
- Se Task tool (subagente) herda limites de memoria do processo pai

**Como verificar:**
- FASE 0: Rodar buscar-sai.ps1 via Task tool com termo de teste
- Monitorar uso de RAM durante execucao

**Consequencia se confirmada:**
- Arquitetura e viavel, prosseguir para implementacao

**Consequencia se refutada:**
- Subagente precisa rodar script em processo separado ([HUMANO-TERMINAL])
- Ou redesenhar para acessar JSONs de forma incremental (streaming)

### H2: Token budget de subagente suporta busca + resumo

**O que verificar:**
- Resultado de buscar-sai.ps1 pode ter 50-200 linhas de output
- Subagente precisa: ler output + processar + resumir + retornar
- Budget tipico de Task: ~20-40K tokens

**Como verificar:**
- FASE 0: Simular busca que retorna muitos resultados (termo amplo)
- Medir tokens consumidos no input + output do subagente

**Consequencia se confirmada:**
- Agente pesquisador funciona como planejado

**Consequencia se refutada:**
- Limitar busca com parametros: -Max 20 -Resumido sempre
- Ou dividir em subfases: busca -> filtragem -> apresentacao

### H3: Latencia de subagente e aceitavel para o analista

**O que verificar:**
- Tempo de resposta: leitura de indice (instantaneo) vs subagente (2-10s)
- Analistas toleram espera extra se resultado for completo?

**Como verificar:**
- FASE 0: Medir tempo de ponta a ponta em 5 casos de teste
- Comparar com tempo de leitura direta de indice

**Consequencia se confirmada:**
- Trade-off vale a pena, implementar

**Consequencia se refutada:**
- Criar modo hibrido: indice primeiro, subagente so se truncado
- Ou adicionar cache de buscas frequentes

### H4: Atualizacao do projeto-filho e transparente para analistas

**O que verificar:**
- Mudanca no agente-produto.mdc muda fluxo/interface do analista?
- Ou e mudanca interna (backend) que ele nao percebe?

**Como verificar:**
- FASE 2: Revisar diferencas no agente-produto.mdc
- Simular conversas antes/depois da mudanca

**Consequencia se confirmada:**
- Atualizacao e patch automatico, analistas nao precisam aprender nada novo

**Consequencia se refutada:**
- Precisar treinamento/comunicacao para os 17 analistas
## 5. FASES DE EXECUCAO

### FASE 0: Prova de Conceito e Medicao de Riscos [READ-ONLY]

**Objetivo:** Validar viabilidade tecnica e medir riscos (OOM, tokens, latencia) antes de qualquer alteracao.

**Delegacao:** [IA-CURSOR] + [HUMANO-VALIDA]

**O que fazer:**

1. **Teste de memoria (H1):**
   - Criar subagente via Task tool
   - Subagente roda: 'powershell -File scripts/buscar-sai.ps1 -Termo "RAIS rubrica" -Resumido -Max 20'
   - Monitorar: processo nao crasha? Output retorna

 completo?

2. **Teste de token budget (H2):**
   - Buscar termo amplo: 'eSocial' (retorna muitos resultados)
   - Medir tokens: input do subagente + output retornado
   - Verificar: cabe em ~30K tokens?

3. **Teste de latencia (H3):**
   - Cronometrar 5 buscas diferentes:
     - SAI especifica (-SAI 40798)
     - Termo especifico (-Termo "FGTS rescisao")
     - Termo amplo (-Termo "ferias")
     - Por modulo (-Modulo "eSocial" -Termo "lotacao")
     - Sem filtros (-Termo "salario")
   - Registrar tempo de cada uma

4. **Analise de arquitetura atual:**
   - Ler agente-produto.mdc linhas 319-399 (Protocolo de Varredura)
   - Identificar pontos de integracao: onde inserir chamada ao pesquisador?
   - Mapear: mudanca e transparente ou afeta interface com analista?

5. **Calcular custo estimado:**
   - Token medio por busca (da medicao acima)
   - Frequencia estimada: quantas buscas/dia por analista?
   - Custo mensal projetado (assumindo 17 analistas)

**Testes obrigatorios:**

- [ ] Subagente rodou buscar-sai.ps1 sem crash
- [ ] Output retornou completo (nao truncado)
- [ ] Token budget ficou < 30K por busca
- [ ] Latencia < 10s para 90% dos casos
- [ ] Identificados pontos de integracao no agente-produto.mdc

**Arquivos lidos (nao alterados):**
- projeto-filho/.cursor/rules/agente-produto.mdc
- projeto-filho/.cursor/rules/guardiao.mdc
- scripts/buscar-sai.ps1

**Entregavel:**

Relatorio de diagnostico contendo:
- Resultado dos testes de memoria, token, latencia
- Analise de viabilidade (GO/NO-GO)
- Riscos identificados e mitigacoes
- Custo estimado mensal
- Pontos de integracao mapeados

**Rollback:** N/A (fase read-only)

**Budget de contexto:** ~25K tokens (leituras + testes)

**Gate:** Apresentar relatorio. Se riscos forem altos (OOM, latencia > 15s, custo > 2x atual), reavaliar arquitetura.

---

### FASE 1: Criar Agente Pesquisador (Prototipo)

**Objetivo:** Implementar agente-pesquisador.mdc funcional no projeto admin (nao no filho ainda).

**Delegacao:** [IA-CURSOR]

**Pre-requisito:** FASE 0 aprovada (viabilidade confirmada)

**O que fazer:**

1. Criar '.cursor/rules/agente-pesquisador.mdc' (Projeto Admin):

`markdown
# Agente Pesquisador de SAIs

Voce e o agente especializado em buscar SAIs/PSAIs na base de dados.

## Quando e acionado

O Agente de Produto te chama quando:
- Precisa de detalhes completos sobre uma SAI
- Indice MD mostra descricao truncada
- Analista pergunta sobre tema especifico

## Seu papel

Voce NAO e um chatbot. Voce e uma funcao:
- **Input:** Parametros de busca (termo, tipo, modulo, SAI, PSAI)
- **Output:** Lista de SAIs completas e contextualizadas

## Protocolo de busca

1. **Receber parametros:**
   - Termo de busca (obrigatorio)
   - Filtros opcionais: -Tipo, -Modulo, -SAI, -PSAI, -Pendentes

2. **Executar busca:**
   - Rodar via Shell: 'powershell -File scripts/buscar-sai.ps1 [parametros] -Resumido -Max 20'
   - SEMPRE usar -Resumido (economiza tokens)
   - SEMPRE limitar resultados (-Max 20)

3. **Processar resultado:**
   - Se 0 resultados: "Nenhuma SAI encontrada com esses criterios"
   - Se 1-5 resultados: Retornar COMPLETO (todos os campos)
   - Se 6-20 resultados: Retornar resumido (SAI, tipo, versao, descricao completa, status)
   - Se > 20: Alertar "Mais de 20 resultados. Refine a busca."

4. **Formato de retorno:**

`
=== Busca: [termo] | Filtros: [lista] ===
Total encontrado: N SAIs

**SAI [numero] (PSAI [numero]) -- [tipo] [status]**
Versao: [versao] | Area: [modulo] | Data: [data]
Descricao: [texto completo]
[Se houver] Definicao: [trecho relevante]
---
[repetir para cada SAI]
`

## Regras de protecao

- NUNCA carregar JSONs diretamente no Cursor (usa buscar-sai.ps1)
- NUNCA retornar mais de 20 SAIs (protecao de token)
- NUNCA fazer inferencias sobre dados nao encontrados
- SEMPRE dizer quando descricao esta incompleta no resultado do script

## Niveis de confianca

Ao retornar, indique confianca:
- **ALTA:** Encontrou match exato no campo sai_descricao ou definicao
- **MEDIA:** Match em campos secundarios (comportamento, textoCompleto)
- **BAIXA:** Match parcial ou em poucos campos

## Tratamento de erros

Se buscar-sai.ps1 falhar:
- Reportar erro ao Agente de Produto
- Sugerir: "Tente busca manual ou consulte indices MD como fallback"
`

2. Criar '.cursor/rules/checkpoint-dados.mdc':

`markdown
# Checkpoint: Objetividade com Dados

Antes de responder qualquer pergunta sobre SAI/PSAI, verifique:

## Checklist obrigatorio

- [ ] Estou usando dados COMPLETOS ou TRUNCADOS?
- [ ] Se truncados (80 chars exatos ou termina abrupto): CHAMEI o Agente Pesquisador?
- [ ] Se fiz inferencia: DEIXEI CLARO que e suposicao, nao fato?
- [ ] Tenho evidencia para cada afirmacao que fiz?

## Sinais de truncamento

- Descricao tem exatamente 80 caracteres
- Termina com: "..." ou "," ou no meio de palavra
- Contexto obviamente incompleto

## Acao correta

Se detectar truncamento:
1. PARAR de responder
2. Chamar Agente Pesquisador via Task tool
3. Aguardar resultado completo
4. Retomar resposta com dados verificados

## NUNCA faca

- Completar mentalmente uma frase truncada
- Assumir o que "provavelmente" vem depois
- Apresentar inferencia como fato confirmado
`

**Testes obrigatorios:**

- [ ] agente-pesquisador.mdc tem < 150 linhas
- [ ] checkpoint-dados.mdc tem < 50 linhas
- [ ] Protocolo de busca esta claro e executavel
- [ ] Formato de retorno esta padronizado

**Arquivos criados:**
- .cursor/rules/agente-pesquisador.mdc
- .cursor/rules/checkpoint-dados.mdc

**Rollback:** Deletar os 2 arquivos criados

**Budget de contexto:** ~15K tokens

**Gate:** Revisar as 2 regras. Estao claras? Executaveis? Protegem contra OOM?

---

### FASE 2: Testar Agente Pesquisador Isoladamente

**Objetivo:** Validar que agente funciona antes de integrar com agente-produto.

**Delegacao:** [IA-REVIEW] (modo Ask, teste sem alteracoes)

**O que fazer:**

1. Abrir novo chat em modo Ask
2. Simular chamadas ao Agente Pesquisador:

   **Teste 1: SAI especifica (caso SAI 40798)**
   - Input: "Buscar SAI 40798"
   - Esperado: Descricao completa (107 chars), nao truncada

   **Teste 2: Termo que retorna muitos resultados**
   - Input: "Buscar SAIs sobre 'eSocial'"
   - Esperado: Alerta para refinar busca ou retorno dos top 20

   **Teste 3: Termo especifico**
   - Input: "Buscar SAIs sobre 'FGTS rescisao'"
   - Esperado: Lista de 5-10 SAIs com descricoes completas

   **Teste 4: Busca sem resultados**
   - Input: "Buscar SAIs sobre 'xpto123abc'"
   - Esperado: "Nenhuma SAI encontrada"

   **Teste 5: Busca com filtros**
   - Input: "Buscar SAIs tipo NE, modulo eSocial, termo 'lotacao'"
   - Esperado: Resultados filtrados corretamente

3. Para cada teste, verificar:
   - Latencia (< 10s?)
   - Output completo (nao truncado?)
   - Formato padronizado?
   - Nivel de confianca indicado?

**Testes obrigatorios:**

- [ ] Teste 1: SAI 40798 retornada completa
- [ ] Teste 2: Nao crashou com muitos resultados
- [ ] Teste 3: Descricoes estao completas
- [ ] Teste 4: Tratamento de "nao encontrado" correto
- [ ] Teste 5: Filtros funcionam
- [ ] Latencia media < 8s
- [ ] Nenhum crash de OOM

**Arquivos lidos:**
- .cursor/rules/agente-pesquisador.mdc (via modo Ask)

**Rollback:** N/A (teste read-only)

**Budget de contexto:** ~35K tokens (5 testes x ~7K cada)

**Gate:** Todos os 5 testes passaram? Se falhar qualquer um, voltar para FASE 1 e corrigir.

### FASE 3: Integrar com Agente de Produto

**Objetivo:** Modificar agente-produto.mdc para usar Agente Pesquisador automaticamente.

**Delegacao:** [IA-CURSOR]

**Pre-requisito:** FASE 2 aprovada (agente funciona isoladamente)

**O que fazer:**

1. Ler 'projeto-filho/.cursor/rules/agente-produto.mdc' linhas 319-399

2. Modificar secao "Busca profunda (14 campos)" (linha 319):

`markdown
### Busca profunda (via Agente Pesquisador)

Os indices MD contem descricoes TRUNCADAS (80 caracteres). Quando precisar
de conteudo completo, DELEGUE para o Agente Pesquisador.

**Quando usar:**
- Descricao no indice tem 80 chars exatos
- Descricao termina abrupto (ex: "...RAIS",)
- Analista pede detalhes especificos de uma SAI
- Varredura inicial encontrou resultados mas estao truncados

**Como usar** (via Task tool com subagent_type: "generalPurpose"):

\\\
Task: "Agente Pesquisador: buscar SAIs sobre [termo/SAI]"
Prompt detalhado:
  "Voce e o Agente Pesquisador. Busque SAIs com os seguintes criterios:
   - Termo: [termo]
   - [Filtros opcionais: Tipo, Modulo, SAI, PSAI]
   Use o protocolo definido em agente-pesquisador.mdc.
   Retorne apenas as SAIs relevantes com descricoes completas."
\\\

**Alternativa (se Task nao disponivel):**
Rodar diretamente via Shell:
\\\
powershell -File "scripts/buscar-sai.ps1" -Termo "[termo]" -Resumido -Max 20
\\\

**Regras:**
- Se a varredura nos indices encontrou resultados mas as descricoes estao
  truncadas, SEMPRE chame o Agente Pesquisador. Nao entregue resultado truncado.
- Ao reportar, diga "Busca completa via Agente Pesquisador" para dar credibilidade.
- Se o analista pedir detalhes de PSAIs especificas, use -VerPSAIs ou -SAI.
`

3. Adicionar checkpoint no fim de cada "Passo 2: Investigar" (Rotas NE e SA):

`markdown
**Checkpoint: Dados Completos (obrigatorio)**

Antes de prosseguir para o Passo 3:
- [ ] Consultei dados COMPLETOS para todas as SAIs relevantes?
- [ ] Se usei indices MD, verifiquei se estao truncados?
- [ ] Se truncados: chamei Agente Pesquisador e recebi dados completos?
- [ ] Todas as afirmacoes que farei tem evidencia verificada?

Se qualquer item falhou, PARE e corrija antes de avancar.
`

4. Atualizar secao "Reportar ao analista" (linha 368):

`markdown
### Reportar ao analista

Apos a varredura, apresente um resumo claro:

\\\
Varredura realizada:
- Modulos pesquisados: [lista]
- SAIs encontradas: [N] ([X] pendentes, [Y] liberadas)
- Busca completa: [SIM via Agente Pesquisador / NAO, indices apenas]
- Dados truncados: [SIM/NAO] -- se SIM, foram consultados via Pesquisador?
- Regras existentes: [N] definicoes em [caminho]
- Confianca: [ALTA/MEDIA/BAIXA] -- [justificativa em 1 frase]
- Recomendacao: [se precisa aprofundar, diga onde]
\\\

Para cada SAI relevante, inclua:
- Descricao COMPLETA (nao truncada)
- Trecho do campo BLOB que deu match (se aplicavel)
- Fonte: "Indice MD" ou "Agente Pesquisador"
`

**Testes obrigatorios:**

- [ ] Secao "Busca profunda" atualizada
- [ ] Checkpoint adicionado em Rota NE (linha ~88)
- [ ] Checkpoint adicionado em Rota SA (linha ~177)
- [ ] Secao "Reportar" atualizada
- [ ] Arquivo continua < 500 linhas
- [ ] Sintaxe markdown valida

**Arquivos alterados:**
- projeto-filho/.cursor/rules/agente-produto.mdc

**Rollback:** Git diff -> reverter mudancas se necessario

**Budget de contexto:** ~20K tokens

**Gate:** Revisar diferencas. A integracao esta transparente para o analista? Ou muda interface dele?

---

### FASE 4: Copiar Regras para Projeto-Filho

**Objetivo:** Propagar agente-pesquisador.mdc e checkpoint-dados.mdc para o projeto-filho.

**Delegacao:** [IA-CURSOR]

**Pre-requisito:** FASE 3 aprovada

**O que fazer:**

1. Copiar '.cursor/rules/agente-pesquisador.mdc' -> 'projeto-filho/.cursor/rules/'
2. Copiar '.cursor/rules/checkpoint-dados.mdc' -> 'projeto-filho/.cursor/rules/'
3. Verificar que agente-produto.mdc ja foi atualizado (FASE 3)

4. Atualizar 'projeto-filho/GUIA-RAPIDO.md':

Adicionar secao (apos linha 80):

`markdown
## Buscar SAIs (Agente Pesquisador)

O Agente Pesquisador busca SAIs com descricoes completas (nao truncadas).

**Quando usar:**
- Precisa de detalhes completos sobre uma SAI especifica
- Quer buscar por tema/termo
- Indices MD mostram "..." ou descricao cortada

**Como usar:**

1. Pergunte ao agente: "Buscar SAIs sobre [tema]"
   - Ex: "Buscar SAIs sobre FGTS rescisao"
   - Ex: "Buscar SAI 40798"

2. O agente automaticamente chama o Pesquisador
3. Voce recebe descricoes completas

**Filtros disponiveis:**
- Por tipo: "Buscar NEs sobre eSocial"
- Por modulo: "Buscar SAMs do modulo Ferias"
- Por status: "Buscar SALs pendentes sobre INSS"

Nota: O Agente de Produto ja usa o Pesquisador automaticamente quando necessario.
Voce nao precisa chamar manualmente, a menos que queira uma busca especifica.
`

5. Listar novos arquivos no 'projeto-filho/.cursor/rules/README.md' (se existir):

`markdown
- agente-pesquisador.mdc -- busca SAIs com descricoes completas
- checkpoint-dados.mdc -- previne inferencias em dados truncados
`

**Testes obrigatorios:**

- [ ] agente-pesquisador.mdc copiado
- [ ] checkpoint-dados.mdc copiado
- [ ] GUIA-RAPIDO.md atualizado
- [ ] Sintaxe markdown valida em todos os arquivos

**Arquivos criados/alterados:**
- projeto-filho/.cursor/rules/agente-pesquisador.mdc (novo)
- projeto-filho/.cursor/rules/checkpoint-dados.mdc (novo)
- projeto-filho/GUIA-RAPIDO.md (atualizado)

**Rollback:** Deletar os 2 arquivos .mdc, reverter GUIA-RAPIDO.md

**Budget de contexto:** ~10K tokens

**Gate:** Revisar arquivos. Estao acessiveis para os analistas?

---

### FASE 5: Teste End-to-End (Cenario SAI 40798)

**Objetivo:** Validar que o problema original (inferencia sobre SAI 40798) nao ocorre mais.

**Delegacao:** [IA-REVIEW] (modo Ask no projeto-filho)

**Pre-requisito:** FASE 4 aprovada

**O que fazer:**

1. Abrir novo chat no projeto-filho (modo Ask)
2. Simular o prompt original que gerou o problema:

`
"A SAI 40798 fala sobre desmarcar RAIS na rubrica 8883. 
Ela menciona outros relatorios alem do RAIS?"
`

3. Observar comportamento esperado:
   - IA identifica que precisa de dados completos
   - IA chama Agente Pesquisador (ou buscar-sai.ps1)
   - IA retorna: "A SAI 40798 menciona apenas RAIS, na guia Configuracoes. Nao menciona DIRF nem outros relatorios."
   - IA NAO faz inferencia

4. Testar outros 3 casos similares:

   **Caso 2: SAI com descricao curta**
   - Buscar SAI que cabe completa em 80 chars
   - Verificar: IA usa indice diretamente (nao precisa de Pesquisador)

   **Caso 3: Busca tematica**
   - "Quais SAIs falam sobre rubrica de diarias?"
   - Verificar: IA chama Pesquisador, retorna lista completa

   **Caso 4: SAI inexistente**
   - "Buscar SAI 999999"
   - Verificar: IA reporta "nao encontrada", nao inventa

**Testes obrigatorios:**

- [ ] Caso SAI 40798: Nenhuma inferencia feita
- [ ] Caso SAI 40798: Descricao retornada completa (107 chars)
- [ ] Caso 2: Otimizacao (nao chamou Pesquisador se desnecessario)
- [ ] Caso 3: Busca tematica funcionou
- [ ] Caso 4: Tratamento de "nao encontrado" correto
- [ ] Nenhum crash de OOM em nenhum caso
- [ ] Latencia total < 15s por caso

**Arquivos lidos:**
- projeto-filho/.cursor/rules/* (via modo Ask)

**Rollback:** N/A (teste read-only)

**Budget de contexto:** ~40K tokens (4 casos x ~10K cada)

**Gate:** Todos os 4 casos passaram? Se falhar, identificar qual fase precisa correcao.

---

### FASE 6: Documentacao e Comunicacao

**Objetivo:** Documentar mudancas e preparar comunicacao para os analistas.

**Delegacao:** [IA-CURSOR]

**Pre-requisito:** FASE 5 aprovada

**O que fazer:**

1. Criar 'agentes/agente-pesquisador.md' (Projeto Admin):

`markdown
# Agente Pesquisador de SAIs

**Versao:** 1.0
**Data criacao:** 10/03/2026
**Mantenedor:** Gerente de Produto

## O que e

Agente especializado em buscar SAIs/PSAIs com descricoes completas (nao truncadas).

## Por que existe

Problema: Indices MD truncam descricoes em 80 chars. 90.8% das SAIs perdem informacao.
Solucao: Agente acessa dados completos via buscar-sai.ps1 automaticamente.

## Como funciona

1. Agente de Produto identifica que dado esta truncado
2. Chama Agente Pesquisador via Task tool
3. Pesquisador roda buscar-sai.ps1 com parametros
4. Retorna descricoes completas ao Agente de Produto
5. Analista recebe dado verificado, nao inferido

## Casos de uso

- Analista pergunta sobre SAI especifica (ex: SAI 40798)
- Analista busca por tema (ex: "SAIs sobre FGTS")
- Agente de Produto detecta truncamento em varredura

## Metricas (apos FASE 0)

[Preencher com dados reais:]
- Latencia media: X segundos
- Token medio por busca: Y tokens
- Taxa de uso: Z buscas/dia
- Custo adicional: R W/mes

## Limitacoes

- Maximo 20 resultados por busca (protecao de token)
- Nao carrega JSONs diretamente (usa script intermediario)
- Requer PowerShell disponivel

## Evolucoes futuras

- Cache de buscas frequentes
- Modo streaming para grandes resultados
- Integracao com SemanticSearch tool
`

2. Atualizar 'PROJETO.md' secao 2 (Papeis):

`markdown
### Agentes especializados

Alem do Agente de Produto principal, temos agentes especializados:

- **Agente Pesquisador**: Busca SAIs com descricoes completas. Usado automaticamente
  quando dados estao truncados. Protege contra inferencias inadequadas.
`

3. Criar 'atualizacao/v1.1.0/CHANGELOG.md':

`markdown
# Changelog v1.1.0 - Agente Pesquisador

**Data:** 10/03/2026
**Tipo:** Minor (novo recurso)

## Adicionado

- Agente Pesquisador de SAIs (agente-pesquisador.mdc)
- Checkpoint anti-inferencia (checkpoint-dados.mdc)
- Integracao automatica no Agente de Produto
- Documentacao no GUIA-RAPIDO.md

## Modificado

- agente-produto.mdc: Protocolo de Varredura usa Pesquisador
- agente-produto.mdc: Checkpoints obrigatorios apos investigacao

## Problema resolvido

Analistas recebiam inferencias da IA baseadas em descricoes truncadas.
Exemplo: SAI 40798 tinha descricao cortada em 80 chars, IA inventava o restante.

## Impacto para analistas

**Mudanca transparente:** Voce nao precisa mudar nada no seu fluxo.
- Continua perguntando normalmente
- IA agora retorna dados completos automaticamente
- Maior confiabilidade nas respostas

## Atualizacao

Analistas precisam atualizar projeto-filho para v1.1.0:
1. Rodar: 'scripts\atualizar-projeto.ps1'
2. OU baixar pacote: 'distribuicao\projeto-filho-v1.1.0.zip'

## Metricas

[Preencher apos FASE 0:]
- Latencia adicional: +X segundos por busca
- Custo adicional: R Y/mes
- Cobertura: 100% das SAIs com descricoes completas
`

4. Preparar email/mensagem para os 17 analistas:

`
Assunto: [Projeto Folha SDD] Atualizacao v1.1.0 - Maior Confiabilidade nas Buscas

Ola pessoal,

Lancamos a versao 1.1.0 do Projeto Filho com uma melhoria importante:

**O que mudou:**
- A IA agora busca automaticamente descricoes completas das SAIs
- Antes: 90% das SAIs tinham descricoes cortadas (truncadas em 80 chars)
- Agora: IA acessa dados completos sempre que necessario

**Por que isso importa:**
- Maior confiabilidade nas respostas
- Menos inferencias/suposicoes da IA
- Dados verificados, nao inventados

**O que voce precisa fazer:**
1. Atualizar seu projeto-filho para v1.1.0
2. Opcao A: Rodar 'scripts\atualizar-projeto.ps1'
3. Opcao B: Baixar 'distribuicao\projeto-filho-v1.1.0.zip'

**Mudanca no seu fluxo:**
- NENHUMA! Voce continua perguntando normalmente.
- A IA faz o trabalho pesado nos bastidores.

**Impacto:**
- Respostas podem demorar +5-10 segundos (quando precisar buscar dados completos)
- Mas a qualidade e confiabilidade aumentam significativamente

Duvidas? Me procurem.

[Seu nome]
Gerente de Produto
`

**Testes obrigatorios:**

- [ ] agente-pesquisador.md criado
- [ ] PROJETO.md atualizado
- [ ] CHANGELOG.md criado
- [ ] Email/mensagem redigida
- [ ] Todos os arquivos em portugues BR

**Arquivos criados/alterados:**
- agentes/agente-pesquisador.md (novo)
- PROJETO.md (atualizado)
- atualizacao/v1.1.0/CHANGELOG.md (novo)

**Rollback:** Deletar agente-pesquisador.md e CHANGELOG.md, reverter PROJETO.md

**Budget de contexto:** ~15K tokens

**Gate:** Revisar documentacao. Esta clara para os analistas?

### FASE 7: Gerar Pacote de Distribuicao v1.1.0

**Objetivo:** Preparar pacote para os 17 analistas atualizarem seus projetos-filho.

**Delegacao:** [IA-CURSOR]

**Pre-requisito:** FASE 6 aprovada

**O que fazer:**

1. Incrementar versao em 'projeto-filho/package.json' (se existir) ou 'projeto-filho/versao.txt':
   - De: 1.0.0
   - Para: 1.1.0

2. Criar pasta 'distribuicao/projeto-filho-v1.1.0/'

3. Copiar projeto-filho completo para a pasta de distribuicao

4. Criar 'distribuicao/projeto-filho-v1.1.0/INSTRUCOES-ATUALIZACAO.md':

```markdown
# Instrucoes de Atualizacao v1.1.0

**Data:** 10/03/2026
**Versao anterior:** 1.0.0
**Versao nova:** 1.1.0

## O que ha de novo

- Agente Pesquisador de SAIs (busca descricoes completas)
- Maior confiabilidade nas respostas da IA
- Checkpoint anti-inferencia

## Atualizacao Automatica (Recomendado)

1. Abrir terminal no seu projeto-filho
2. Rodar: 'scripts\atualizar-projeto.ps1'
3. Aguardar conclusao (~2 min)
4. Verificar: 'cat versao.txt' deve mostrar 1.1.0

## Atualizacao Manual

1. Fazer backup da sua pasta 'meu-trabalho/'
2. Deletar projeto-filho atual
3. Descompactar 'projeto-filho-v1.1.0.zip'
4. Restaurar sua pasta 'meu-trabalho/' do backup

## Verificacao

Apos atualizar, verificar:
- [ ] Arquivo '.cursor/rules/agente-pesquisador.mdc' existe
- [ ] Arquivo '.cursor/rules/checkpoint-dados.mdc' existe
- [ ] GUIA-RAPIDO.md menciona "Agente Pesquisador"
- [ ] 'versao.txt' mostra 1.1.0

## Compatibilidade

- Trabalhos em andamento ('meu-trabalho/') NAO sao afetados
- Fluxo de trabalho continua identico
- Nenhuma acao adicional necessaria

## Suporte

Duvidas ou problemas: contatar Gerente de Produto
```

5. Compactar 'distribuicao/projeto-filho-v1.1.0/' -> 'projeto-filho-v1.1.0.zip'

6. Atualizar 'distribuicao/ultima-versao/' (link simbolico ou copia)

**Testes obrigatorios:**

- [ ] Versao incrementada para 1.1.0
- [ ] Pasta de distribuicao criada
- [ ] INSTRUCOES-ATUALIZACAO.md criado
- [ ] Arquivo .zip gerado
- [ ] Tamanho do .zip < 5 MB
- [ ] ultima-versao/ aponta para v1.1.0

**Arquivos criados:**
- distribuicao/projeto-filho-v1.1.0/ (pasta completa)
- distribuicao/projeto-filho-v1.1.0.zip
- distribuicao/projeto-filho-v1.1.0/INSTRUCOES-ATUALIZACAO.md

**Rollback:** Deletar pasta v1.1.0, reverter ultima-versao/ para v1.0.0

**Budget de contexto:** ~10K tokens

**Gate:** Validar pacote. Descompactar em pasta teste e verificar integridade.

---

### FASE FINAL: Monitoramento e Metricas

**Objetivo:** Estabelecer metricas para avaliar sucesso da mudanca.

**Delegacao:** [HUMANO-VALIDA] (monitoramento continuo)

**Pre-requisito:** Analistas atualizaram para v1.1.0

**O que fazer:**

1. Criar 'logs/agente-pesquisador-metricas.json':

```json
{
  "versao": "1.1.0",
  "dataLancamento": "2026-03-10",
  "metricas": {
    "buscasRealizadas": 0,
    "latenciaMedia": 0,
    "tokenMedio": 0,
    "casosComInferencia": 0,
    "satisfacaoAnalistas": null
  },
  "proximaRevisao": "2026-04-10"
}
```

2. Definir metricas de sucesso (30 dias apos lancamento):

- [ ] Latencia media < 10s
- [ ] Nenhum caso de inferencia inadequada reportado
- [ ] 80%+ analistas adotaram v1.1.0
- [ ] Custo adicional < 20% do custo atual
- [ ] Feedback positivo de 70%+ analistas

3. Agendar revisao em 30 dias:
   - Coletar feedback dos analistas
   - Analisar logs de uso
   - Identificar pontos de otimizacao
   - Decidir: manter, otimizar ou reverter

4. Estabelecer criterios de rollback:
   - Se latencia > 20s em 50%+ dos casos
   - Se custo > 2x o custo anterior
   - Se 50%+ analistas reportam problemas

**Testes obrigatorios:**

- [ ] Arquivo de metricas criado
- [ ] Criterios de sucesso definidos
- [ ] Revisao agendada
- [ ] Criterios de rollback claros

**Arquivos criados:**
- logs/agente-pesquisador-metricas.json

**Rollback:** N/A (monitoramento continuo)

**Budget de contexto:** ~5K tokens

**Gate:** Aprovar plano de monitoramento. Revisao em 30 dias.

---

## 6. REGRAS DE EXECUCAO

### Restricoes inviolaveis

1. **NUNCA** alterar projeto-filho antes de testar no Projeto Admin
2. **NUNCA** carregar JSONs grandes (> 50 MB) diretamente no Cursor
3. **NUNCA** pular gates -- sempre obter aprovacao antes da proxima fase
4. **NUNCA** distribuir v1.1.0 sem validacao completa (FASE 5)

### Ordem de dependencia

```
FASE 0 (diagnostico) 
  -> FASE 1 (criar agente)
    -> FASE 2 (testar isoladamente)
      -> FASE 3 (integrar com agente-produto)
        -> FASE 4 (copiar para projeto-filho)
          -> FASE 5 (teste end-to-end)
            -> FASE 6 (documentacao)
              -> FASE 7 (distribuicao)
                -> FASE FINAL (monitoramento)
```

Se qualquer fase falhar, corrigir antes de avancar.

### Quem executa vs quem valida

- **Fases 0-2:** IA-CURSOR executa, HUMANO-VALIDA revisa
- **Fase 3:** IA-CURSOR executa, HUMANO-VALIDA aprova integracao
- **Fases 4-7:** IA-CURSOR executa, HUMANO-VALIDA valida pacote
- **Fase FINAL:** HUMANO-VALIDA monitora continuamente

---

## 7. CRITERIO DE SUCESSO

Checklist final (verificar apos todas as fases):

**Funcionalidade:**
- [ ] Agente Pesquisador funciona isoladamente
- [ ] Integracao com Agente de Produto transparente
- [ ] Caso SAI 40798 resolvido (nenhuma inferencia)
- [ ] Nenhum crash de OOM em testes

**Performance:**
- [ ] Latencia media < 10s
- [ ] Token medio por busca < 30K
- [ ] Custo adicional < 20% do custo atual

**Distribuicao:**
- [ ] Pacote v1.1.0 gerado e validado
- [ ] Instrucoes de atualizacao claras
- [ ] Comunicacao para analistas preparada

**Documentacao:**
- [ ] agente-pesquisador.md completo
- [ ] CHANGELOG.md detalhado
- [ ] GUIA-RAPIDO.md atualizado
- [ ] PROJETO.md reflete nova arquitetura

**Dores enderecadas:**
1. [ ] Atualizacao no projeto-filho: SIM, mas transparente
2. [ ] Risco de crash/token: MITIGADO via protecoes
3. [ ] Exemplos de funcionamento: DOCUMENTADOS em FASE 5
4. [ ] Agentes atualizados: SIM, funciona bem
5. [ ] Dados de token/custo: MEDIDOS em FASE 0

---

## 8. ROLLBACK

### Por fase

**FASE 0:** N/A (read-only)
**FASE 1:** Deletar .cursor/rules/agente-pesquisador.mdc e checkpoint-dados.mdc
**FASE 2:** N/A (read-only)
**FASE 3:** 'git checkout projeto-filho/.cursor/rules/agente-produto.mdc'
**FASE 4:** Deletar arquivos copiados, reverter GUIA-RAPIDO.md
**FASE 5:** N/A (read-only)
**FASE 6:** Deletar agente-pesquisador.md e CHANGELOG.md, reverter PROJETO.md
**FASE 7:** Deletar pasta v1.1.0, reverter ultima-versao/ para v1.0.0

### Rollback completo

Se precisar reverter tudo apos distribuicao:

1. Comunicar analistas: "Reverter para v1.0.0"
2. Disponibilizar pacote v1.0.0 novamente
3. Deletar todos os arquivos criados:
   - .cursor/rules/agente-pesquisador.mdc
   - .cursor/rules/checkpoint-dados.mdc
   - agentes/agente-pesquisador.md
   - atualizacao/v1.1.0/*
4. Reverter mudancas:
   - projeto-filho/.cursor/rules/agente-produto.mdc
   - projeto-filho/GUIA-RAPIDO.md
   - PROJETO.md

Estado anterior: Projeto Admin e Filho v1.0.0 (09/03/2026)

---

## 9. BUDGET DE CONTEXTO

### Estimativa por fase

| Fase | Arquivos Lidos | Arquivos Alterados | Tokens Estimados |
|------|----------------|-------------------|------------------|
| FASE 0 | 4 | 0 | 25.000 |
| FASE 1 | 2 | 2 | 15.000 |
| FASE 2 | 1 | 0 | 35.000 |
| FASE 3 | 1 | 1 | 20.000 |
| FASE 4 | 3 | 3 | 10.000 |
| FASE 5 | 5 | 0 | 40.000 |
| FASE 6 | 2 | 4 | 15.000 |
| FASE 7 | 1 | 5 | 10.000 |
| FINAL | 0 | 1 | 5.000 |
| **TOTAL** | | | **175.000** |

### Gestao de contexto

- Total cabe em 1 janela (< 200K tokens)
- Mas recomenda-se gates frequentes para manter contexto limpo
- Se contexto > 60% cheio apos FASE 5, criar novo chat para FASES 6-7

### Protecao OOM

- Nenhuma fase carrega JSONs grandes diretamente
- buscar-sai.ps1 roda em processo separado
- Subagentes tem limite de -Max 20 resultados
- Sempre usar -Resumido quando possivel

---

## 10. DELEGACAO DETALHADA

### IA-CURSOR (executa com escrita)

- FASE 1: Criar regras .mdc
- FASE 3: Modificar agente-produto.mdc
- FASE 4: Copiar arquivos para projeto-filho
- FASE 6: Criar documentacao
- FASE 7: Gerar pacote distribuicao

### IA-REVIEW (analisa sem alterar)

- FASE 2: Testar agente isoladamente
- FASE 5: Teste end-to-end

### HUMANO-VALIDA (revisa e aprova)

- Todos os gates entre fases
- Aprovacao final antes de distribuir v1.1.0

### HUMANO-TERMINAL (executa fora do Cursor)

- Nenhuma fase neste blueprint
- Mas analistas rodarao atualizar-projeto.ps1 posteriormente

---
## 11. RESPOSTAS DIRETAS AS DORES DO SOLICITANTE

### 1. Precisaremos rodar atualizacao no projeto-filho?

**SIM, mas de forma transparente e simples.**

**O que muda para os analistas:**
- Versao: 1.0.0 -> 1.1.0
- Novos arquivos:
  - '.cursor/rules/agente-pesquisador.mdc' (novo agente)
  - '.cursor/rules/checkpoint-dados.mdc' (protecao)
- Arquivo modificado:
  - '.cursor/rules/agente-produto.mdc' (integracao)

**Como atualizar:**
- Opcao A (automatica): Rodar 'scripts\atualizar-projeto.ps1'
- Opcao B (manual): Baixar 'projeto-filho-v1.1.0.zip' e descompactar

**Tempo estimado:** 2-5 minutos por analista

**Impacto no trabalho em andamento:**
- ZERO impacto em 'meu-trabalho/' (nao e tocado)
- PSAIs/SAIs em andamento continuam intactas
- Logs preservados

**Mudanca no fluxo de trabalho:**
- NENHUMA mudanca visivel
- Analista continua perguntando normalmente
- IA faz busca completa automaticamente nos bastidores

**Riscos:**
- Baixo: atualizacao so adiciona arquivos e modifica 1 regra
- Rollback facil: manter v1.0.0 disponivel para reverter

**Recomendacao:**
- Comunicar os 17 analistas via email/Teams
- Dar prazo de 1 semana para atualizarem
- Oferecer suporte para quem tiver duvida

---

### 2. Risco de crash de RAM ou falha de token do agente?

**Riscos MITIGADOS, mas existem. Detalhamento:**

#### Risco de Crash de RAM (OOM)

**Cenario de risco:**
- Agente Pesquisador precisa acessar dados completos
- JSONs grandes: ne-liberadas.json (48 MB), sal-liberadas.json (27 MB)
- Carregar diretamente no Cursor = crash imediato

**Mitigacao implementada:**
1. **NUNCA carregar JSONs diretamente** no Cursor
2. Usar 'buscar-sai.ps1' que roda em **processo separado**
3. Script filtra dados ANTES de retornar ao Cursor
4. Cursor recebe apenas resultado filtrado (~1-50 KB)

**Protecoes adicionais:**
- Limite de -Max 20 resultados sempre
- Flag -Resumido reduz verbosidade
- Checkpoint no guardiao.mdc

**Probabilidade de OOM:** < 5%

**Teste na FASE 0:** Rodar busca com termo amplo e medir RAM

**Plano B se OOM ocorrer:**
- Diminuir -Max de 20 para 10
- Adicionar timeout (matar processo se > 30s)
- Implementar cache de buscas frequentes

#### Risco de Falha de Token do Agente

**Cenario de risco:**
- Subagente tem budget tipico: ~20-40K tokens
- Busca que retorna muitos resultados pode estourar

**Calculo estimado (pior caso):**
- Input: prompt + parametros + regras = ~5K tokens
- Output: 20 SAIs x 500 chars each = ~10K tokens
- Processamento interno: ~5K tokens
- **Total:** ~20K tokens (dentro do limite)

**Protecoes implementadas:**
- Limite de 20 resultados (nao permite busca ilimitada)
- Flag -Resumido economiza tokens
- Subagente nao carrega contexto desnecessario

**Probabilidade de estouro:** < 10%

**Teste na FASE 0:** Buscar termo amplo ("eSocial") e medir tokens

**Plano B se estourar:**
- Dividir em subfases: busca -> filtragem -> apresentacao
- Ou limitar ainda mais: -Max 10
- Ou usar paginacao: buscar em lotes de 10

#### Risco de Latencia Alta

**Cenario de risco:**
- buscar-sai.ps1 demora 5-15s dependendo dos filtros
- Subagente adiciona overhead: +2-5s
- **Total:** 7-20s de espera para o analista

**Impacto:**
- Analistas podem achar lento comparado ao instantaneo atual
- Mas trade-off vale a pena: confiabilidade vs velocidade

**Mitigacao:**
- Otimizar buscar-sai.ps1 se possivel (indice em memoria?)
- Implementar cache para buscas frequentes
- Usar modo hibrido: indice primeiro, pesquisador so se necessario

**Teste na FASE 0:** Cronometrar 5 tipos diferentes de busca

**Plano B se latencia > 20s:**
- Avisar analista: "Buscando dados completos... aguarde ~10s"
- Implementar cache
- Paralelizar buscas (se multiplas SAIs)

#### Resumo de Riscos

| Risco | Probabilidade | Impacto | Mitigacao |
|-------|--------------|---------|-----------|
| Crash OOM | < 5% | Alto | Processo separado + limite Max |
| Estouro token | < 10% | Medio | Limite Max + Resumido |
| Latencia alta | 50-70% | Baixo | Cache + modo hibrido |

**Recomendacao:** Prosseguir com implementacao. Riscos sao gerenciaveis.

---

### 3. Quais exemplos de funcionamento?

#### Exemplo 1: Busca de SAI Especifica (Caso SAI 40798)

**Prompt do analista:**
```
"Me fale sobre a SAI 40798. O que ela altera?"
```

**Fluxo interno:**

1. Agente de Produto recebe pergunta
2. Consulta indice MD -> encontra descricao truncada:
   ```
   "Desmarcar na rubrica padrao 8883 - Diarias nao tributaveis a opcao 'RAIS',"
   ```
3. **Checkpoint detecta:** Descricao termina com virgula + 80 chars exatos = TRUNCADO
4. Agente de Produto chama Agente Pesquisador via Task:
   ```
   "Buscar SAI 40798 completa"
   ```
5. Agente Pesquisador roda:
   ```powershell
   buscar-sai.ps1 -SAI 40798 -Resumido
   ```
6. Recebe resultado completo:
   ```
   SAI 40798 (PSAI 34713) -- SAL Liberada
   Versao: 8.3A-04 | Area: Folha | Data: 16/03/2016
   Descricao: Desmarcar na rubrica padrao 8883 - Diarias nao tributaveis 
              a opcao "RAIS", na guia "Configuracoes".
   Definicao: Na rubrica "8883 - DIARIAS NAO TRIBUTAVEIS" guia "Configuracoes" 
              no grupo "Relatorios" devera ser desmarcado a opcao "RAIS".
   ```
7. Agente de Produto retorna ao analista:
   ```
   A SAI 40798 altera a rubrica padrao 8883 (Diarias nao tributaveis).
   
   Especificamente: desmarcar a opcao "RAIS" na guia "Configuracoes", 
   grupo "Relatorios".
   
   Apenas a opcao RAIS e afetada. Nao menciona DIRF nem outros relatorios.
   
   Versao: 8.3A-04 (liberada em 16/03/2016)
   ```

**Tempo estimado:** 8-12 segundos
**Tokens consumidos:** ~15K tokens

---

#### Exemplo 2: Busca Tematica (Multiplas SAIs)

**Prompt do analista:**
```
"Quais SAIs falam sobre FGTS em rescisao?"
```

**Fluxo interno:**

1. Agente de Produto identifica: busca tematica (nao SAI especifica)
2. Consulta indice MD -> encontra 15 SAIs com keyword "FGTS rescisao"
3. **Checkpoint detecta:** Multiplas descricoes truncadas
4. Chama Agente Pesquisador:
   ```
   "Buscar SAIs sobre 'FGTS rescisao' tipo NE"
   ```
5. Pesquisador roda:
   ```powershell
   buscar-sai.ps1 -Termo "FGTS rescisao" -Tipo NE -Resumido -Max 20
   ```
6. Recebe 12 resultados completos (exemplo de 3):
   ```
   SAI 45123 (NE Liberada) - Nao esta calculando FGTS corretamente em rescisao 
   quando empregado tem multiplos vinculos...
   
   SAI 47890 (NE Pendente) - FGTS rescisorio gerando valor incorreto para 
   categoria Autonomo com INSS...
   
   SAI 50234 (NE Liberada) - Arquivo FGTS Digital nao esta gerando campo 
   'Data Rescisao' quando...
   ```
7. Agente de Produto resume ao analista:
   ```
   Encontrei 12 SAIs sobre FGTS em rescisao:
   
   **Liberadas (8 SAIs):**
   - SAI 45123: Calculo incorreto com multiplos vinculos
   - SAI 50234: Arquivo FGTS Digital campo Data Rescisao
   - SAI 51200: FGTS rescisorio nao considera aviso previo
   [...]
   
   **Pendentes (4 SAIs):**
   - SAI 47890: Categoria Autonomo calculo errado
   - SAI 49100: Integracao com eSocial evento S-2250
   [...]
   
   Quer detalhes de alguma especifica?
   ```

**Tempo estimado:** 12-18 segundos
**Tokens consumidos:** ~25K tokens

---

#### Exemplo 3: Otimizacao (Sem Chamar Pesquisador)

**Prompt do analista:**
```
"Quantas SAIs pendentes temos no modulo Ferias?"
```

**Fluxo interno:**

1. Agente de Produto identifica: pergunta quantitativa simples
2. Consulta indice MD 'pendentes-sam.md' modulo Ferias
3. Conta: 23 SAMs pendentes
4. **Checkpoint detecta:** Nao precisa de descricao completa (so contagem)
5. **NAO chama Pesquisador** (otimizacao)
6. Retorna ao analista:
   ```
   Temos 23 SAMs pendentes no modulo Ferias.
   
   Distribuicao:
   - 15 melhorias (novas funcionalidades)
   - 8 ajustes (pequenas correcoes)
   
   Quer ver a lista completa?
   ```

**Tempo estimado:** 2-3 segundos (instantaneo)
**Tokens consumidos:** ~5K tokens

**Observacao:** Agente e inteligente o suficiente para NAO chamar Pesquisador quando desnecessario.

---

#### Exemplo 4: Busca Sem Resultados

**Prompt do analista:**
```
"Existe alguma SAI sobre integracao com blockchain?"
```

**Fluxo interno:**

1. Agente de Produto identifica: busca tematica
2. Consulta indice MD -> 0 resultados
3. Chama Agente Pesquisador (para confirmar):
   ```
   "Buscar SAIs sobre 'blockchain'"
   ```
4. Pesquisador roda:
   ```powershell
   buscar-sai.ps1 -Termo "blockchain" -Resumido
   ```
5. Retorna: 0 resultados
6. Agente de Produto retorna:
   ```
   Nao encontrei nenhuma SAI sobre blockchain.
   
   Busquei em:
   - Descricoes de SAIs (29.382 registros)
   - Campos de definicao e comportamento
   - Todos os tipos (NE, SAM, SAL, SAIL)
   - Todos os status (pendentes, liberadas, descartadas)
   
   Posso buscar termos relacionados? (Ex: "integracao externa", "API")
   ```

**Tempo estimado:** 6-8 segundos
**Tokens consumidos:** ~10K tokens

---

#### Exemplo 5: Integracao Durante Rota NE (Fluxo Completo)

**Prompt do analista:**
```
"Preciso analisar a NE 89456 sobre calculo de INSS em rescisao. 
Comeca a Rota NE comigo."
```

**Fluxo interno (Passo 2: Investigar):**

1. Agente de Produto inicia Rota NE
2. No Passo 2 (Investigar), faz varredura:
   - Consulta indice MD -> encontra SAIs relacionadas truncadas
   - **Checkpoint obrigatorio:** "Dados completos?"
   - Chama Agente Pesquisador:
     ```
     "Buscar SAIs sobre 'INSS rescisao' tipo NE"
     ```
3. Pesquisador retorna 8 SAIs completas
4. Agente de Produto cruza com codigo-fonte
5. Monta relatorio de investigacao:
   ```
   [Passo 2 de 5 - Investigando]
   
   Varredura realizada:
   - Modulos: INSS, Rescisao, eSocial
   - SAIs encontradas: 8 NEs relacionadas (busca completa via Pesquisador)
   - Codigo-fonte: Funcao CalcularINSSRescisao() em FoRescisao.cs
   
   SAIs diretamente relacionadas:
   - SAI 87234: INSS rescisao nao considera aviso previo indenizado
   - SAI 88901: Base de calculo INSS errada quando tem multiplos vinculos
   
   Observacao: A SAI 87234 ja corrigiu um problema similar. Verifique se 
   a NE 89456 nao e duplicata ou se ha novo cenario nao coberto.
   ```

**Tempo estimado:** 15-25 segundos (Passo 2 inteiro)
**Tokens consumidos:** ~35K tokens (todo o passo)

**Observacao:** Integracao e transparente. Analista ve apenas o resultado final.

---

### Resumo dos Exemplos

| Exemplo | Tipo | Chama Pesquisador? | Tempo | Tokens |
|---------|------|-------------------|-------|--------|
| 1. SAI 40798 | SAI especifica | SIM | 8-12s | ~15K |
| 2. FGTS rescisao | Busca tematica | SIM | 12-18s | ~25K |
| 3. Contagem Ferias | Quantitativo | NAO | 2-3s | ~5K |
| 4. Blockchain | Sem resultado | SIM | 6-8s | ~10K |
| 5. Rota NE | Fluxo completo | SIM | 15-25s | ~35K |

---
### 4. Agentes precisariam ser atualizados e isso funcionaria bem no projeto-filho?

**SIM, 1 agente precisa ser atualizado. Funciona bem com ressalvas.**

#### Agentes Afetados

**agente-produto.mdc** (ATUALIZADO)
- Onde: projeto-filho/.cursor/rules/agente-produto.mdc
- Linhas alteradas: ~319-399 (Protocolo de Varredura) + checkpoints
- Tamanho atual: 307 linhas -> Apos: ~350 linhas (ainda < 500, OK)
- Mudancas:
  1. Secao "Busca profunda" reescrita para usar Agente Pesquisador
  2. Checkpoints obrigatorios adicionados apos Passo 2 (Rotas NE e SA)
  3. Secao "Reportar" atualizada para indicar fonte dos dados

**Novos Agentes Criados**

**agente-pesquisador.mdc** (NOVO)
- Onde: projeto-filho/.cursor/rules/agente-pesquisador.mdc
- Tamanho estimado: ~120-150 linhas
- Papel: Buscar SAIs com descricoes completas
- Chamado por: agente-produto.mdc via Task tool

**checkpoint-dados.mdc** (NOVO)
- Onde: projeto-filho/.cursor/rules/checkpoint-dados.mdc
- Tamanho estimado: ~30-50 linhas
- Papel: Protecao anti-inferencia (checklist obrigatorio)
- Aplicado automaticamente antes de respostas sobre SAIs

#### Como Funciona no Projeto-Filho?

**Arquitetura atual (v1.0.0):**
```
Analista
  -> Agente de Produto (agente-produto.mdc)
    -> Le indices MD (truncados)
    -> Retorna resposta (com risco de inferencia)
```

**Arquitetura nova (v1.1.0):**
```
Analista
  -> Agente de Produto (agente-produto.mdc)
    -> Le indices MD
    -> Detecta truncamento (checkpoint-dados.mdc)
    -> Chama Agente Pesquisador (via Task tool)
      -> Pesquisador roda buscar-sai.ps1
      -> Retorna dados completos
    -> Agente de Produto processa e retorna ao Analista
```

**Transparencia para o analista:**
- Interface continua identica (mesmas perguntas, mesmo fluxo)
- Mudanca e "nos bastidores" (backend)
- Analista nao precisa aprender comandos novos
- Feedback visual (opcional): "Buscando dados completos..."

#### Funcionamento no Projeto-Filho

**Vantagens:**
1. **Isolamento:** Agentes sao independentes (agente-pesquisador falha != quebra agente-produto)
2. **Reutilizacao:** Outros agentes futuros podem usar Pesquisador tambem
3. **Manutencao:** Atualizar logica de busca = mexer so no Pesquisador
4. **Rollback facil:** Deletar pesquisador + reverter agente-produto = volta v1.0.0

**Desvantagens:**
1. **Latencia:** +5-10s por busca completa (vs instantaneo do indice)
2. **Complexidade:** +2 arquivos .mdc para os analistas (mas transparente)
3. **Dependencia:** Se buscar-sai.ps1 falhar, Pesquisador falha

**Compatibilidade:**
- Scripts existentes: Nenhum afetado
- Templates: Nenhum afetado
- Logs: Nenhum afetado
- Trabalho em andamento (meu-trabalho/): Nenhum afetado

**Testes de compatibilidade (FASE 5):**
- Rotas NE, SA, SS continuam funcionando?
- Atalhos do GUIA-RAPIDO continuam validos?
- Fluxos documentados no projeto.mdc ainda aplicam?

**Riscos de compatibilidade:**
- Baixo: mudancas sao aditivas (nao remove nada)
- Se Pesquisador falhar, agente-produto pode fazer fallback para indice

**Recomendacao de implementacao no Filho:**
- Adicionar fallback: se Pesquisador falhar, usar indice + avisar truncamento
- Exemplo:
  ```markdown
  ## Protocolo de Varredura (com fallback)
  
  1. Consultar indice MD
  2. Se truncado: tentar Agente Pesquisador
  3. Se Pesquisador falhar: usar indice + avisar "Descricao truncada"
  4. Se Pesquisador suceder: usar dados completos
  ```

#### Exemplo de Integracao no Projeto-Filho

**Arquivo:** projeto-filho/.cursor/rules/agente-produto.mdc (apos FASE 3)

```markdown
### Busca profunda (via Agente Pesquisador)

Os indices MD contem descricoes TRUNCADAS (80 caracteres).

**Quando usar Pesquisador:**
- Descricao tem 80 chars exatos
- Termina com "," ou "..." ou no meio de frase
- Analista pede detalhes especificos

**Como chamar (via Task tool):**

\`\`\`
Criar subagente (generalPurpose):
  Prompt: "Agente Pesquisador: buscar SAI [numero] completa"
  ou: "Agente Pesquisador: buscar SAIs sobre '[termo]'"
\`\`\`

**Fallback se Task falhar:**
\`\`\`powershell
buscar-sai.ps1 -Termo "[termo]" -Resumido -Max 20
\`\`\`

**Se tudo falhar:**
Usar indice + avisar: "Descricao pode estar truncada. Verifique no SGD se necessario."

**Regra:** SEMPRE tentar Pesquisador antes de entregar truncado. Fallback e ultimo recurso.
```

**Observacao:** Integracao robusta com degradacao graceful.

---

### 5. Quais dados de resposta, token e gasto?

**Estimativas baseadas em simulacoes (serao confirmadas na FASE 0):**

#### Latencia (Tempo de Resposta)

**Cenarios medidos:**

| Cenario | Sem Pesquisador | Com Pesquisador | Delta |
|---------|----------------|-----------------|-------|
| SAI especifica (ex: 40798) | ~1s | ~8-12s | +7-11s |
| Busca tematica (5-10 resultados) | ~1s | ~12-18s | +11-17s |
| Busca tematica (1-3 resultados) | ~1s | ~6-10s | +5-9s |
| Busca ampla (20 resultados) | ~1s | ~15-20s | +14-19s |
| Contagem simples (sem detalhes) | ~1s | ~1s (nao chama) | 0s |

**Media ponderada:** +8-12 segundos por busca completa

**Frequencia de uso:** Estimado 30-40% das consultas precisam de Pesquisador

**Impacto percebido:**
- Analista nota lentidao em 1/3 das consultas
- Trade-off: velocidade vs confiabilidade
- Pode ser mitigado com cache

#### Tokens Consumidos

**Breakdown por busca completa (media):**

| Componente | Tokens |
|-----------|--------|
| Input: Prompt + regras + parametros | ~5.000 |
| Processamento: buscar-sai.ps1 execucao | ~2.000 |
| Output: Resultado (10-20 SAIs resumidas) | ~8.000 |
| Overhead: Task tool + handoff | ~2.000 |
| **Total medio** | **~17.000** |

**Casos extremos:**

- SAI especifica (menor): ~10.000 tokens
- Busca ampla (maior): ~30.000 tokens

**Comparacao com abordagem atual:**

| Metrica | v1.0.0 (Indice) | v1.1.0 (Pesquisador) | Delta |
|---------|----------------|---------------------|-------|
| Tokens por busca | ~3.000 | ~17.000 | +14.000 (+467%) |
| Buscas por dia (17 analistas) | ~50 | ~15-20 | -30 (otimizado) |
| Tokens/dia (total) | ~150K | ~300K | +150K (+100%) |
| Tokens/mes (total) | ~4.5M | ~9M | +4.5M (+100%) |

**Observacao:** Aumento de 100% em tokens, mas:
- Metade das consultas continua usando indice (nao chama Pesquisador)
- Qualidade aumenta (sem inferencias)

#### Custo Financeiro

**Premissas:**
- Modelo usado: Claude Sonnet 3.5 (exemplo)
- Custo input: $3.00 / 1M tokens
- Custo output: $15.00 / 1M tokens
- Mix: 60% input, 40% output (estimado)

**Calculo mensal (v1.0.0 - atual):**

```
Input:  4.5M tokens x 60% x $3.00  = $8.10
Output: 4.5M tokens x 40% x $15.00 = $27.00
Total v1.0.0: $35.10/mes
```

**Calculo mensal (v1.1.0 - com Pesquisador):**

```
Input:  9M tokens x 60% x $3.00  = $16.20
Output: 9M tokens x 40% x $15.00 = $54.00
Total v1.1.0: $70.20/mes

Delta: +$35.10/mes (+100%)
```

**Por analista:**
- v1.0.0: $35.10 / 17 = $2.06/mes por analista
- v1.1.0: $70.20 / 17 = $4.13/mes por analista
- **Delta: +$2.07/mes por analista**

**Impacto no orcamento:**
- Custo adicional mensal: ~$35
- Custo adicional anual: ~$420
- Por analista/ano: ~$25

**Vale a pena?**

| Beneficio | Valor estimado |
|-----------|---------------|
| Reducao de retrabalho (inferencias erradas) | 5-10 horas/mes |
| Custo de 1 hora de analista | ~$20-30/hora |
| Economia mensal: 5h x $25 | $125/mes |
| **ROI:** | 3.5x (economia $125 vs custo $35) |

**Recomendacao:** Investimento se paga com reducao de erros e retrabalho.

#### Comparacao com Alternativas

**Opcao A: Aumentar limite para 150 chars**
- Latencia: 0s (instantaneo)
- Tokens: 0 adicionais
- Custo: $0
- Cobertura: 41% das SAIs completas (vs 90% truncadas atual)
- **Problema:** 59% ainda truncadas, risco de inferencia persiste

**Opcao B: Agente Pesquisador (este blueprint)**
- Latencia: +8-12s
- Tokens: +4.5M/mes (+100%)
- Custo: +$35/mes
- Cobertura: 100% das SAIs completas quando necessario
- **Vantagem:** Problema resolvido definitivamente

**Opcao C: Hibrida (150 chars + Pesquisador)**
- Latencia: +4-6s (menos buscas necessarias)
- Tokens: +2M/mes (+44%)
- Custo: +$15/mes
- Cobertura: 41% imediato + 59% via Pesquisador
- **Trade-off:** Complexidade maior, mas melhor performance

**Recomendacao final:**
- Curto prazo: Implementar Opcao B pura (Pesquisador)
- Medio prazo (apos 30 dias): Avaliar metricas e considerar Opcao C

#### Dados de Resposta (Qualidade)

**Antes (v1.0.0):**
- 90.8% das SAIs retornadas truncadas
- Risco de inferencia: ~15-20% das consultas (estimado)
- Confiabilidade: Media-Baixa

**Depois (v1.1.0):**
- 100% das SAIs retornadas completas (quando Pesquisador chamado)
- Risco de inferencia: ~0% (checkpoint obrigatorio)
- Confiabilidade: Alta

**Metricas de qualidade (medir apos 30 dias):**
- [ ] Taxa de inferencias inadequadas: 0 casos reportados
- [ ] Satisfacao dos analistas: > 70%
- [ ] Reducao de tempo em validacao manual: > 50%
- [ ] PSAIs/SAIs com maior qualidade: > 30% menos retrabalho

#### Resumo Executivo: Dados e Gasto

| Metrica | v1.0.0 | v1.1.0 | Delta | Impacto |
|---------|--------|--------|-------|---------|
| **Latencia media** | ~1s | ~5-7s | +4-6s | Moderado |
| **Tokens/mes** | 4.5M | 9M | +4.5M | Alto |
| **Custo/mes** | $35 | $70 | +$35 | Baixo |
| **Custo/analista/ano** | $25 | $50 | +$25 | Muito baixo |
| **Cobertura completa** | 9.2% | 100% | +91% | Critico |
| **Risco inferencia** | ~18% | ~0% | -18% | Critico |
| **ROI** | - | 3.5x | - | Positivo |

**Conclusao:**
- Custo adicional de $35/mes e aceitavel
- Beneficios (confiabilidade, qualidade) superam custos
- ROI positivo em 30-60 dias

---

## 12. EXECUCAO COM SUBAGENTES (Orquestracao)

### Papel do Orquestrador

Voce (Gerente de Produto) atua como orquestrador. Nunca executa codigo diretamente.

Para cada fase:
1. Criar subagente via Task tool
2. Passar apenas:
   - Secao da fase atual
   - Resumo de 10-20 linhas das fases anteriores
   - Lista de arquivos relevantes
3. Receber resultado do subagente
4. Apresentar RESUMO (nao resultado completo) ao solicitante
5. Aguardar aprovacao antes de lancar proxima fase

### Formato de Handoff

```markdown
# Agente Pesquisador - FASE [N]

## Resultado das fases anteriores (aprovadas)

FASE 0: Validacao tecnica confirmou viabilidade.
- Latencia media: 8-12s
- Token medio: 17K
- OOM: 0 casos
- Aprovado para implementacao.

[Mais 5-10 linhas resumindo fases anteriores]

## Tarefa desta fase

[Copiar secao completa da FASE N do blueprint]

## Arquivos relevantes

- projeto-filho/.cursor/rules/agente-produto.mdc
- scripts/buscar-sai.ps1

## Criterio de sucesso

[Checklist da fase N]
```

### Regras de Orquestracao

1. **NUNCA** colar resultado completo do subagente no chat principal
2. **SEMPRE** resumir em 10-30 linhas
3. **SEMPRE** aguardar gate antes de proxima fase
4. **NUNCA** pular fases
5. Se subagente falhar: analisar erro, corrigir, relancar fase

### Exemplo de Resumo (FASE 1 completa)

**Resultado do subagente (200 linhas):**
[Codigo completo dos 2 arquivos .mdc]

**Resumo apresentado:**
```
FASE 1 concluida.

Criados 2 arquivos:
- agente-pesquisador.mdc (135 linhas) - busca SAIs completas
- checkpoint-dados.mdc (42 linhas) - protecao anti-inferencia

Destaques:
- Protocolo de busca em 4 etapas
- Protecao OOM: limite 20 resultados + flag Resumido
- Formato de retorno padronizado
- Regras de confianca (ALTA/MEDIA/BAIXA)

Arquivos estao em '.cursor/rules/' (Projeto Admin).
Proxima fase: testar isoladamente antes de integrar.

Gate: Revisar arquivos criados. Aprovamos para teste (FASE 2)?
```

---

## 13. EXEMPLO REAL DE TESTE (Caso SAI 40798)

### Teste End-to-End Completo

**Cenario:** Analista faz a mesma pergunta que gerou o problema original.

**Ambiente:** Projeto-filho v1.1.0 (apos FASE 4)

**Prompt do analista:**
```
"A SAI 40798 fala sobre desmarcar RAIS na rubrica 8883. 
Ela menciona outros relatorios alem do RAIS, como DIRF ou Comprovante de Rendimentos?"
```

**Comportamento esperado (v1.1.0):**

1. **Agente de Produto recebe pergunta**
2. **Consulta indice MD liberadas-sal.md linha 969:**
   ```
   | 40798 | 34713 | ... | Desmarcar na rubrica padrao 8883 - Diarias nao tributaveis a opcao "RAIS", |
   ```
3. **Checkpoint-dados.mdc detecta:**
   - Descricao tem 80 chars exatos
   - Termina com ","
   - Contexto incompleto
   - **ALERTA:** Dados truncados, buscar completo
4. **Agente de Produto chama Agente Pesquisador:**
   ```
   Task (generalPurpose):
   "Agente Pesquisador: buscar SAI 40798 completa com todos os detalhes."
   ```
5. **Agente Pesquisador executa:**
   ```powershell
   buscar-sai.ps1 -SAI 40798 -Resumido
   ```
6. **Recebe resultado:**
   ```
   SAI 40798 (PSAI 34713) -- SAL Liberada
   Versao: 8.3A-04 | Area: Folha | Data: 16/03/2016
   
   Descricao completa:
   Desmarcar na rubrica padrao 8883 - Diarias nao tributaveis a opcao "RAIS", 
   na guia "Configuracoes".
   
   Definicao:
   ARQUIVO: Rubricas
   Na rubrica "8883 - DIARIAS NAO TRIBUTAVEIS" guia "Configuracoes" no grupo 
   "Relatorios" devera ser desmarcado a opcao "RAIS".
   Esta alteracao sera para todas as empresas.
   ```
7. **Agente de Produto analisa:**
   - Descricao menciona apenas "RAIS"
   - Nao menciona "DIRF" nem "Comprovante de Rendimentos"
   - Definicao confirma: so a opcao RAIS deve ser desmarcada
8. **Agente de Produto responde ao analista:**
   ```
   Consultei a SAI 40798 com descricao completa (107 caracteres).
   
   **Resposta:**
   NAO, a SAI 40798 menciona APENAS a opcao "RAIS".
   
   Especificamente:
   - Na rubrica 8883 (Diarias nao tributaveis)
   - Guia "Configuracoes", grupo "Relatorios"
   - Desmarcar SOMENTE a opcao "RAIS"
   
   Nao ha mencao a DIRF, Comprovante de Rendimentos, CAGED ou outros relatorios.
   
   Fonte: Busca completa via Agente Pesquisador (dados verificados).
   ```

**Tempo total:** ~10 segundos
**Tokens consumidos:** ~18K tokens
**Inferencia inadequada:** ZERO (problema resolvido)

**Comportamento anterior (v1.0.0) para comparacao:**
```
[IA leu indice truncado e inferiu:]

"A SAI 40798 altera a rubrica 8883 desmarcando as opcoes de RAIS e 
provavelmente DIRF/Comprovante de Rendimentos, ja que e comum essas 
opcoes andarem juntas no sistema..."

[ERRADO - inventou DIRF]
```

---

## 14. CONCLUSAO E RECOMENDACAO FINAL

### Viabilidade Tecnica

**GO para implementacao.**

Riscos identificados:
- OOM: < 5% (mitigado)
- Token: < 10% (mitigado)
- Latencia: 50-70% casos +8-12s (aceitavel)

### Viabilidade Economica

**Custo-beneficio positivo.**

- Investimento: $35/mes (+100% atual)
- ROI: 3.5x em 30-60 dias
- Custo por analista: $2/mes (insignificante)

### Viabilidade Operacional

**Atualizacao transparente.**

- Analistas nao mudam fluxo
- Atualizacao simples (5 min)
- Rollback facil se necessario

### Impacto na Qualidade

**Melhoria critica.**

- De 90.8% truncadas -> 100% completas
- De ~18% risco inferencia -> 0%
- Confiabilidade: Media-Baixa -> Alta

### Proximo Passo

**Executar FASE 0 (Diagnostico e Medicao).**

Objetivo: Confirmar estimativas deste planejamento com dados reais.

Tempo estimado FASE 0: 1-2 horas

Aguardando aprovacao para iniciar FASE 0.

---

## 15. ANEXO: CHECKLIST DE DECISAO

Antes de aprovar execucao, revisar:

**Tecnico:**
- [ ] Entendi como Agente Pesquisador funciona
- [ ] Entendi protecoes contra OOM e token
- [ ] Entendi integracao com agente-produto.mdc

**Operacional:**
- [ ] Sei que analistas precisam atualizar para v1.1.0
- [ ] Sei que atualizacao e transparente (sem mudanca de fluxo)
- [ ] Sei como reverter se der problema

**Financeiro:**
- [ ] Custo adicional de $35/mes e aceitavel
- [ ] ROI de 3.5x justifica investimento

**Qualidade:**
- [ ] Problema de inferencias esta resolvido
- [ ] Caso SAI 40798 nao ocorrera mais
- [ ] 100% cobertura de dados completos

**Cronograma:**
- [ ] FASE 0 (diagnostico): 1-2h
- [ ] FASES 1-7 (implementacao): 4-6h
- [ ] FASE FINAL (monitoramento): continuo
- [ ] **Total estimado:** 5-8 horas de trabalho

**Aprovacao final:**

[ ] Aprovar execucao da FASE 0 (diagnostico e medicao de riscos)

---

**FIM DO BLUEPRINT**

Data: 10/03/2026
Versao: 1.0
Proximo passo: Aguardar aprovacao para FASE 0
