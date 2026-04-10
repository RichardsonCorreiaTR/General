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
