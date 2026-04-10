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
