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

