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
