# PGAP: Busca Assertiva e Confiavel em SAIs/PSAIs

Blueprint gerado em: 2026-03-08
Solicitante: Gerente de Produto (Orquestrador)
Executor: IA-CURSOR + HUMANO-VALIDA

---

## 1. CONTEXTO DO PROBLEMA

**O que acontece:** O projeto possui 35.307 registros de SAI/PSAI extraidos
via ODBC e armazenados em JSONs fracionados (~185 MB). Existe um script de
busca (uscar-sai.ps1) e indices MD, mas nao ha garantia formal de que a
pesquisa cobre todos os campos relevantes, que os dados chegam limpos ao
analista, e que a infraestrutura e segura contra crash.

**O que deveria acontecer:** O analista deveria ter certeza de que ao pesquisar
 lotacao eSocial, a IA varre TODOS os campos de texto, retorna resultados
completos (nao truncados), e que isso funciona de forma estavel sem risco de
crash.

**Exemplo concreto:** Busca por lotacao eSocial nos indices MD retorna
descricoes truncadas em 80 chars. O campo comportamento (ate 38.357 chars)
e definicao (ate 310.891 chars) contem detalhes criticos que so aparecem
via uscar-sai.ps1 -- mas o script nao busca em 	extoCompleto nem

omeArea, e o campo modulo_caminho referenciado nao existe nos dados.

**Impacto:** Analistas podem tomar decisoes baseadas em buscas incompletas.
SAIs relevantes podem nao aparecer nos resultados, gerando retrabalho ou gaps
de cobertura em definicoes de negocio.

---

## 2. DORES DO SOLICITANTE

1. Projeto nao tem certeza que ha boa cobertura de localizacao das PSAI e SAI;
   a IA precisa dar credibilidade e condicoes que a pesquisa e assegurada.
2. Verificar se nas bases existem dados desnecessarios (HTML, hiperlinks,
   imagens) que aumentam tamanho dos arquivos e se isso pode ser reduzido.
3. Preciso de um mapa com garantia de quanto uma pesquisa e assertiva e
   abrangente.
4. Ao localizar novas PSAI/SAI e rodar a atualizacao, isso ja fica de facil
   acesso para os analistas? (RESPOSTA OBRIGATORIA)
5. Tudo que for atualizado vai estar no comando para os analistas rodarem
   na atualizacao v1.1.0?
6. Ha algo na parte dos agentes que precisa ser implementado para pesquisa?
7. Garantir que o projeto nao de crash por RAM ou limite de contexto.

---

## 3. ARQUIVOS/ARTEFATOS RELEVANTES

LEIA TODOS antes de propor qualquer coisa:

| Arquivo | Papel |
|---------|-------|
| scripts/buscar-sai.ps1 | Script principal de busca (11 campos, BLOBs incluidos) |
| anco-dados/dados-brutos/psai/*.json | 12 arquivos fracionados PSAI (~179 MB) |
| anco-dados/dados-brutos/sai/*.json | 12 arquivos fracionados SAI (~8 MB) |
| anco-dados/sais/indices/**/*.md | 51 indices MD (~19 MB total) |
| scripts/cache/sai-psai-folha.json | Cache monolitico (~166 MB) |
| projeto-filho/.cursor/rules/agente-produto.mdc | Regras da IA do analista |
| projeto-filho/.cursor/rules/guardiao.mdc | Guardiao do projeto-filho |
| projeto-filho/scripts/buscar-sai.ps1 | Wrapper que delega ao original |
| .cursor/rules/protecao-oom.mdc | Regras de protecao contra OOM |
| .cursorignore | Arquivos excluidos do Cursor |
| scripts/gerar-atualizacao.ps1 | Gerador de pacotes de atualizacao |
| tualizacao/v1.1.0/input.md | Manifesto da v1.1.0 |

---

## 4. HIPOTESES A INVESTIGAR

### H1: Campos criticos nao sao buscados
- **Verificar:** Listar campos dos fracionados vs campos no filtro do buscar-sai.ps1
- **Como:** Comparar Get-Member dos JSONs com o bloco Where-Object do script
- **Resultado:** CONFIRMADA. 	extoCompleto e 
omeArea nao sao buscados.
  modulo_caminho e buscado mas NAO EXISTE nos dados (sempre vazio/ausente).

### H2: Dados contem HTML/imagens desnecessarios
- **Verificar:** Regex <[a-zA-Z][^>]*> e <img|data:image nos BLOBs
- **Como:** Scan nos arquivos fracionados PSAI
- **Resultado:** DESCARTADA. O que parece HTML sao placeholders de especificacao
  (<Total rubrica periodo>) e tags eSocial (<dtTerm>). Remover perderia
  informacao. Economia seria <5 MB em 185 MB.

### H3: Atualizacao nao propaga busca profunda
- **Verificar:** Conteudo de gerar-atualizacao.ps1 e tualizacao/v1.1.0/
- **Como:** Ler scripts e manifesto
- **Resultado:** PARCIALMENTE CONFIRMADA. O wrapper e incluido, mas o script
  original nao. Depende de caminhos.json e OneDrive. A v1.1.0 NAO lista
  o buscar-sai.ps1.

### H4: Cache monolitico e risco de OOM
- **Verificar:** scripts/cache/ no .cursorignore e na protecao-oom.mdc
- **Como:** Ler ambos os arquivos
- **Resultado:** CONFIRMADA. scripts/cache/ (166 MB) NAO esta no
  .cursorignore. Cursor pode indexar e a IA pode tentar ler.

### H5: Agentes incompletos para pesquisa
- **Verificar:** Todas as regras .mdc sobre busca
- **Como:** Ler cada .mdc
- **Resultado:** PARCIALMENTE CONFIRMADA. gente-produto cobre busca profunda.
  guardiao e gente-codigo nao usam uscar-sai.ps1.

---

## 5. FASES DE EXECUCAO

### FASE 0: Diagnostico (CONCLUIDA)

- **Objetivo:** Mapear estado real da busca, dados e infraestrutura.
- **Entregavel:** Este blueprint com diagnostico completo.
- **Resultado:**
  - Cobertura de busca: ~83% (10 de 12 campos texto relevantes)
  - HTML nos BLOBs: especificacao tecnica, NAO deve ser removido
  - Propagacao: parcial -- wrapper sim, script original nao
  - OOM: 1 gap critico (cache monolitico fora do .cursorignore)
  - Agentes: agente-produto OK, guardiao e agente-codigo com gaps

- **Gate:** [HUMANO-VALIDA] Aprovar diagnostico e prioridades.

---

### FASE 1: Completar cobertura de busca (dores 1, 3)

- **Objetivo:** Atingir 100% de cobertura nos campos de texto relevantes.

- **O que fazer:**
  1. Adicionar 	extoCompleto ao filtro de busca em uscar-sai.ps1
  2. Adicionar 
omeArea ao filtro de busca
  3. Substituir modulo_caminho por 
omeArea no filtro por modulo
  4. Adicionar situacaoPsai ao filtro geral
  5. Gerar relatorio de cobertura (evisao/mapa-cobertura-busca.md):
     - Tabela: campo | tipo | buscado | presente nos indices | tamanho medio
     - Percentual de cobertura antes e depois
     - Exemplo de busca lotacao eSocial com resultado completo

- **Testes obrigatorios:**
  [ ] buscar-sai.ps1 -Termo lotacao retorna resultados de 	extoCompleto
  [ ] buscar-sai.ps1 -Modulo Folha filtra por 
omeArea
  [ ] buscar-sai.ps1 -Termo dtTerm encontra tags eSocial em BLOBs
  [ ] Nenhum campo de texto fica fora da busca

- **Arquivos alterados:** scripts/buscar-sai.ps1
- **Arquivo criado:** evisao/mapa-cobertura-busca.md
- **Rollback:** Reverter alteracoes no buscar-sai.ps1 (campos anteriores)
- **Delegacao:** [IA-CURSOR]
- **Gate:** [HUMANO-VALIDA] Revisar mapa de cobertura

---

### FASE 2: Proteger contra OOM e crash (dor 7)

- **Objetivo:** Eliminar todos os riscos de crash por memoria ou contexto.

- **O que fazer:**
  1. Adicionar scripts/cache/ ao .cursorignore
  2. Atualizar protecao-oom.mdc:
     - Mencionar scripts/cache/ como zona proibida
     - Adicionar regra: Evitar Grep em todos os indices MD de uma vez
     - Adicionar limite: Buscar por modulo ou tipo nunca todos
  3. Verificar se anco-dados/sais/indices/ precisa de protecao parcial
     (19 MB total; individual OK, todos de uma vez risco)
  4. Documentar tamanho de cada arquivo fracionado na protecao-oom.mdc
     para que a IA saiba o risco antes de ler

- **Testes obrigatorios:**
  [ ] scripts/cache/ nao aparece em resultados do Cursor (Grep/Glob)
  [ ] IA consegue usar indices MD por modulo sem estouro
  [ ] buscar-sai.ps1 com -Tipo NE -Pendentes carrega <5 MB

- **Arquivos alterados:** .cursorignore, .cursor/rules/protecao-oom.mdc
- **Rollback:** Remover linhas adicionadas
- **Delegacao:** [IA-CURSOR]
- **Gate:** [HUMANO-VALIDA]

---

### FASE 3: Garantir propagacao para analistas (dores 4, 5)

- **Objetivo:** Assegurar que ao rodar atualizacao, o analista recebe TUDO.

- **O que fazer:**
  1. Verificar que gerar-atualizacao.ps1 copia scripts/buscar-sai.ps1
     (wrapper) para o pacote
  2. Atualizar tualizacao/v1.1.0/input.md para incluir uscar-sai.ps1
  3. Melhorar o wrapper do projeto-filho: adicionar fallback que tenta
     eferencia/scripts/buscar-sai.ps1 (caminho direto no shared folder)
     quando caminhos.json nao existe
  4. Verificar que gente-produto.mdc atualizado (com busca profunda)
     esta no pacote
  5. Rodar gerar-atualizacao.ps1 e validar conteudo da distribuicao

- **Testes obrigatorios:**
  [ ] distribuicao/ultima-versao/scripts/buscar-sai.ps1 existe e e atual
  [ ] distribuicao/ultima-versao/.cursor/rules/agente-produto.mdc tem
      secao Busca profunda
  [ ] Wrapper funciona com eferencia/scripts/ como fallback
  [ ] No projeto-filho limpo, uscar-sai.ps1 -Termo FGTS retorna resultados

- **Arquivos alterados:** projeto-filho/scripts/buscar-sai.ps1 (wrapper),
  tualizacao/v1.1.0/input.md, scripts/gerar-atualizacao.ps1 (se necessario)
- **Rollback:** Reverter wrapper para versao anterior
- **Delegacao:** [IA-CURSOR] + [HUMANO-VALIDA]
- **Gate:** [HUMANO-VALIDA] Confirmar que distribuicao esta correta

---

### FASE 4: Completar agentes para pesquisa (dor 6)

- **Objetivo:** Todos os agentes relevantes sabem usar a busca profunda.

- **O que fazer:**
  1. Atualizar projeto-filho/.cursor/rules/guardiao.mdc: adicionar
     instrucao para sugerir busca profunda quando indices truncados
  2. Revisar se gente-codigo.mdc precisa de integracao com SAIs
     (cruzar codigo com SAIs relacionadas)
  3. Adicionar no gente-produto.mdc instrucao sobre o campo
     	extoCompleto e 
omeArea (novos campos buscaveis)
  4. Garantir que a IA mostra CONFIANCA na busca ao reportar:
     Busca profunda realizada em 14 campos. Cobertura: 100% dos campos texto.

- **Testes obrigatorios:**
  [ ] agente-produto reporta Busca profunda: SIM no resumo da varredura
  [ ] guardiao sugere busca profunda quando detecta resultado truncado
  [ ] Nenhum agente tenta ler fracionados diretamente (usa script)

- **Arquivos alterados:** projeto-filho/.cursor/rules/guardiao.mdc,
  projeto-filho/.cursor/rules/agente-produto.mdc
- **Rollback:** Reverter secoes adicionadas
- **Delegacao:** [IA-CURSOR]
- **Gate:** [HUMANO-VALIDA]

---

### FASE 5 (FINAL): Documentar e gerar mapa de assertividade (dor 3)

- **Objetivo:** Entregar documentacao que prove a qualidade da busca.

- **O que fazer:**
  1. Gerar evisao/mapa-assertividade-busca-2026-03-08.md com:
     - Tabela completa de campos e cobertura
     - Exemplos de busca em cada campo BLOB com resultado
     - Comparacao antes/depois (6 campos -> 14 campos)
     - Declaracao de cobertura: 100% dos campos texto sao buscaveis
  2. Atualizar PROJETO.md secao relevante (se houver) sobre busca
  3. Registrar no log consolidado

- **Testes obrigatorios:**
  [ ] Mapa de assertividade gerado e completo
  [ ] Todas as 7 dores enderecadas com resposta concreta
  [ ] Nenhum arquivo critico fora do .cursorignore

- **Arquivos criados:** evisao/mapa-assertividade-busca-2026-03-08.md
- **Rollback:** N/A (apenas documentacao)
- **Delegacao:** [IA-CURSOR] + [HUMANO-VALIDA]
- **Gate:** [HUMANO-VALIDA] Aprovar mapa e encerrar

---

## 6. REGRAS DE EXECUCAO

- NUNCA alterar JSONs fracionados sem aprovacao (sao dados-fonte)
- NUNCA rodar buscar-sai.ps1 sem filtro no terminal do Cursor (risco OOM)
- Fases devem ser executadas na ordem (1 -> 2 -> 3 -> 4 -> 5)
- Cada fase tem gate obrigatorio com o solicitante
- HTML nos BLOBs NAO deve ser removido (H2 descartada -- e especificacao)
- O orquestrador NUNCA cola resultado completo de subagentes

---

## 7. CRITERIO DE SUCESSO

[ ] buscar-sai.ps1 busca em 14+ campos (todos os texto relevantes)
[ ] Campo modulo_caminho substituido por 
omeArea
[ ] Campo 	extoCompleto incluido na busca
[ ] scripts/cache/ no .cursorignore
[ ] protecao-oom.mdc atualizada com limites documentados
[ ] Wrapper do projeto-filho funciona com fallback eferencia/
[ ] v1.1.0 inclui buscar-sai.ps1 no manifesto
[ ] agente-produto reporta cobertura e confianca da busca
[ ] guardiao sugere busca profunda quando apropriado
[ ] Mapa de assertividade gerado com tabela completa de cobertura
[ ] Dores 1-7 todas com resposta concreta e verificavel

---

## 8. ROLLBACK

| Fase | Estado anterior |
|------|-----------------|
| 1 | buscar-sai.ps1 com 11 campos; sem mapa |
| 2 | .cursorignore sem scripts/cache; protecao-oom sem detalhes |
| 3 | Wrapper sem fallback; v1.1.0 sem buscar-sai.ps1 |
| 4 | guardiao sem instrucao de busca profunda |
| 5 | Sem mapa de assertividade |

Nenhuma fase altera dados-fonte. Todas sao reversiveis.

---

## 9. BUDGET DE CONTEXTO

| Fase | Arquivos para ler | Arquivos para alterar | Estimativa |
|------|-------------------|-----------------------|------------|
| 1 | 2 (buscar-sai.ps1, 1 fracionado) | 1 + 1 novo | Leve |
| 2 | 3 (.cursorignore, protecao-oom, indices) | 2 | Leve |
| 3 | 4 (gerar-atualizacao, wrapper, input.md, agente-produto) | 3 | Moderado |
| 4 | 3 (guardiao, agente-produto, agente-codigo) | 2 | Leve |
| 5 | 2 (resultados anteriores) | 1 novo | Leve |

Nenhuma fase excede 60% do contexto. Todas cabem em 1 chat.

---

## 10. DELEGACAO

| Fase | Quem executa | Quem valida |
|------|--------------|-------------|
| 0 (Diagnostico) | [IA-CURSOR] | [HUMANO-VALIDA] |
| 1 (Cobertura) | [IA-CURSOR] | [HUMANO-VALIDA] |
| 2 (OOM) | [IA-CURSOR] | [HUMANO-VALIDA] |
| 3 (Propagacao) | [IA-CURSOR] | [HUMANO-VALIDA] |
| 4 (Agentes) | [IA-CURSOR] | [HUMANO-VALIDA] |
| 5 (Documentacao) | [IA-CURSOR] | [HUMANO-VALIDA] |

---

## 11. EXECUCAO COM SUBAGENTES

O agente principal atua como ORQUESTRADOR:
1. Le este blueprint
2. Para cada fase, cria subagente com a secao daquela fase
3. Recebe resultado e apresenta RESUMO ao solicitante
4. Aguarda aprovacao no gate antes da proxima fase

Handoff entre fases:
- Fase 0 -> 1: Diagnostico aprovou 5 gaps. Prioridade: campos nao buscados.
- Fase 1 -> 2: Busca expandida para 14 campos. Agora proteger contra OOM.
- Fase 2 -> 3: OOM protegido. Agora garantir propagacao para analistas.
- Fase 3 -> 4: Propagacao OK. Agora completar agentes.
- Fase 4 -> 5: Agentes OK. Gerar documentacao final.

---

## RESPOSTAS DIRETAS AS DORES

### DOR 4 (RESPOSTA OBRIGATORIA): Ao rodar atualizacao, o analista ja tem acesso?

**PARCIALMENTE.** Situacao atual:

| Item | Disponivel? | Como? |
|------|-------------|-------|
| agente-produto.mdc (busca profunda) | SIM | Incluido no pacote via .cursor/rules/ |
| buscar-sai.ps1 (wrapper) | SIM | Incluido em scripts/ |
| Script original (com BLOBs) | DEPENDE | Funciona se OneDrive sincronizado e caminhos.json correto |
| Dados fracionados (35.307 registros) | DEPENDE | Via shared folder (referencia/ symlink) |
| status.json | DEPENDE | Via shared folder (referencia/atualizacao/) |

**Gap critico:** Se o analista nao tem acesso ao shared folder ou caminhos.json
esta incorreto, o buscar-sai.ps1 NAO funciona. A FASE 3 corrige isso adicionando
fallback no wrapper.

### DOR 5: Tudo vai estar na v1.1.0?

**NAO AINDA.** A v1.1.0 atual nao inclui uscar-sai.ps1 no manifesto.
A FASE 3 corrige isso. Apos executar as 5 fases, sim -- tudo estara no comando
de atualizacao.

