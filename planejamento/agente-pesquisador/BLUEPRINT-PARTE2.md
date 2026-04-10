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

