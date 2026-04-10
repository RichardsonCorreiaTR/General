# TESTE FINAL -- Correcoes dos Agentes v1.1.0

> Data: 07/03/2026

## a) Testes funcionais (simulacao mental)

### Fluxo 1: Analista novo (onboarding)

1. Cursor carrega alwaysApply: guardiao, onboarding, projeto
2. Onboarding le config/analista.json -> onboarding_completo: false
3. Verifica meu-trabalho/ e logs -> vazio -> inicia boas-vindas
4. Guardiao roda 4 verificacoes silenciosas
5. Se falha: Mensagem Prioritaria (consolidada se >1 problema)
6. Se OK: boas-vindas + primeira consulta pratica
7. Marca onboarding_completo: true

**Resultado**: FUNCIONA.

### Fluxo 2: NE-95069 (Rota NE completa)

1. agente-produto identifica "NE" -> Rota NE
2. [Passo 1 de 5 - Entendendo o erro]
3. [Passo 2 de 5 - Investigando] -> Protocolo (6 fontes) + agente-codigo
4. [Passo 3 de 5 - Cenarios de impacto]
5. [Passo 4 de 5 - Gerando definicao] -> template carregado
6. [Passo 5 de 5 - Revisando] -> apresenta ao analista
7. Log proativo com tipo "Analise" e confianca registrada

**Resultado**: FUNCIONA.

### Fluxo 3: SAM de funcionalidade nova (Rota SA completa)

1. agente-produto identifica "SA" -> Rota SA
2. [Passo 1 de 6 - Entendendo a necessidade]
3. [Passo 2 de 6 - Descobrindo] -> varredura + analogias + legislacao
4. [Passo 3 de 6 - Desenhando a solucao]
5. [Passo 4 de 6 - Cenarios]
6. [Passo 5 de 6 - Gerando definicao]
7. [Passo 6 de 6 - Revisando]
8. Log proativo gerado

**Resultado**: FUNCIONA.

### Fluxo 4: Symlink quebrado (escalonamento)

1. Guardiao check 3: README.md nao existe -> Mensagem Prioritaria
2. Se outros checks tambem falharem -> mensagem CONSOLIDADA (M1)
3. Analista copia e envia pro Vitor Justino
4. Guardiao tenta continuar com o que tem

**Resultado**: FUNCIONA. MELHORADO com consolidacao (M1).

### Fluxo 5: Versao nova (auto-update)

1. Guardiao check 1: VERSION.json -> versao atual
2. Encontra versao mais recente em referencia/atualizacao/
3. Le input.md -> copia silenciosamente
4. Se copia falhar -> Mensagem Prioritaria (M3 fallback) -- NOVO
5. Preserva analista.json, caminhos.json, meu-trabalho/
6. NAO fala nada ao analista

**Resultado**: FUNCIONA. MELHORADO com fallback (M3).

### Fluxo 6: SS do suporte (Rota SS completa) -- NOVO

1. Analista: "Recebi chamado SS-12345 sobre erro no FGTS do cliente"
2. agente-produto identifica "SS" -> Rota SS
3. [Passo 1 de 4 - Entendendo a pergunta do suporte]
4. [Passo 2 de 4 - Investigando comportamento atual] -> Protocolo + codigo
5. [Passo 3 de 4 - Verificando se e esperado] -> regras + legislacao + SAIs
6. [Passo 4 de 4 - Redigindo resposta] -> rascunho para o analista revisar
7. Log com tipo "Suporte" ou "Analise" (Rota SS passo X de 4)

**Resultado**: FUNCIONA. NOVO (C1).

### Fluxo 7: Pergunta de fluxo/processo -- NOVO

1. Analista: "Como funciona o calculo mensal?"
2. agente-produto identifica como pergunta de fluxo
3. Consulta referencia/banco-dados/mapa-sistema/mapa-folha.md
4. Apresenta processo em passos numerados
5. Log com tipo "Fluxo"

**Resultado**: FUNCIONA. NOVO (C3).

### Fluxo 8: Interrupcao durante analise -- NOVO

1. Analista esta no [Passo 2 de 5 - Investigando]
2. Interrompe: "Antes, me explica o que e CCT?"
3. Agente responde a pergunta sobre CCT
4. Oferece: "Quer que a gente volte de onde paramos? [Passo 2 de 5]"
5. Analista decide se retoma ou muda de assunto

**Resultado**: FUNCIONA. NOVO (M4).

---

## b) Testes de cruzamento

### Rotas entre agentes

| Conceito | agente-produto | guardiao | projeto |
|----------|---------------|----------|---------|
| Rota NE (5 passos) | SIM (lin 66) | SIM (lin 135) | SIM (exemplos) |
| Rota SA (6 passos) | SIM (lin 134) | SIM (lin 136) | SIM (exemplos) |
| Rota SS (4 passos) | SIM (lin 239) | SIM (lin 137) | SIM (exemplos) |

**Resultado**: COERENTE.

### Tipos de acao no log

| Tipo | guardiao tipos | guardiao formato | agente-produto |
|------|---------------|-----------------|----------------|
| Consulta | SIM | SIM | -- |
| Analise (NE/SA/SS) | SIM | SIM | SIM (log) |
| Suporte | SIM | -- | -- |
| Fluxo | SIM | SIM | -- |
| Definicao | SIM | -- | -- |
| Revisao | SIM | -- | -- |
| Conclusao | SIM | -- | -- |
| Exploracao | SIM | -- | -- |

**Resultado**: COERENTE.

### Paths referenciados

| Path | Referenciado por | Existe? |
|------|-----------------|---------|
| referencia/banco-dados/mapa-sistema/mapa-folha.md | agente-produto (C3), agente-codigo | SIM (se base importada) |
| referencia/logs/ | agente-produto (M2), guardiao (log) | DEPENDE (criado pelo log) |
| config/analista.json | guardiao, onboarding, agente-produto | SIM |
| config/caminhos.json | guardiao, agente-codigo | SIM |
| templates/TEMPLATE-psai.md | agente-produto, onboarding | SIM |

**Resultado**: OK. Sem paths novos inventados.

### Jargao tecnico

Busca por SDD|BDD|Gherkin|framework|pipeline|wizard nos 5 .mdc ativos:
**Zero ocorrencias.** Unica ocorrencia em obsoleto/sdd-definicao.mdc (inativo).

**Resultado**: OK.

---

## c) Teste do pacote de atualizacao

### Arquivos alterados vs pacote

| Arquivo | Modificado? | No input.md? | No manifesto.json? |
|---------|------------|-------------|-------------------|
| agente-produto.mdc | SIM (C1,C3,M2,M4) | SIM | SIM |
| guardiao.mdc | SIM (C2,C3,M1,M3) | SIM | SIM |
| projeto.mdc | SIM (M5) | SIM | SIM |
| onboarding.mdc | NAO | SIM | SIM |
| agente-codigo.mdc | NAO | SIM | SIM |
| VERSION.json | NAO | SIM | SIM |
| corrigir-symlinks.ps1 | NAO | SIM | SIM |

**Resultado**: Lista de arquivos OK. Nao precisa adicionar nem remover.

### input.md: verificacao pos-atualizacao

O checklist ATUAL nao verifica "Rota SS". Precisa adicionar:
- `[ ] agente-produto.mdc menciona "Rota SS"`

**Acao necessaria**: Adicionar 1 linha ao checklist em input.md.

### manifesto.json: changelog

O changelog ATUAL nao menciona Rota SS nem melhorias de fluxo. Precisa:
- Adicionar "Rota SS para resposta ao suporte N3" ao changelog.

**Acao necessaria**: Atualizar campo changelog no manifesto.json.

### Sincronizacao de pacotes

| Arquivo | projeto-filho | atualizacao/arquivos | distribuicao/ultima-versao |
|---------|--------------|---------------------|---------------------------|
| agente-produto.mdc | ATUALIZADO | DESATUALIZADO | DESATUALIZADO |
| guardiao.mdc | ATUALIZADO | DESATUALIZADO | DESATUALIZADO |
| projeto.mdc | ATUALIZADO | DESATUALIZADO | DESATUALIZADO |
| onboarding.mdc | OK | OK | OK |
| agente-codigo.mdc | OK | OK | OK |

**Acao necessaria**: Copiar 3 .mdc corrigidos para ambos os pacotes.

### Teste de executabilidade do input.md

Se outra IA executasse o input.md:
1. Le o arquivo -> OK
2. Verifica analista.json e caminhos.json -> OK
3. Copia 7 arquivos da tabela -> OK (lista completa)
4. Roda corrigir-symlinks.ps1 -> OK
5. Confere VERSION.json -> OK
6. Checklist de verificacao -> QUASE OK (falta check de Rota SS)

**Resultado**: Executavel com 1 ajuste menor no checklist.

---

## Contagem de linhas

| Agente | Antes | Depois | Delta |
|--------|-------|--------|-------|
| agente-produto.mdc | 303 | 383 | +80 |
| guardiao.mdc | 316 | 334 | +18 |
| projeto.mdc | 70 | 72 | +2 |
| onboarding.mdc | 95 | 95 | 0 |
| agente-codigo.mdc | 123 | 123 | 0 |
| **TOTAL** | **907** | **1007** | **+100** |

AlwaysApply (sempre carregados): guardiao 334 + onboarding 95 + projeto 72 = 501 linhas.

---

## Veredicto do teste

| Categoria | Resultado |
|-----------|----------|
| 8 fluxos simulados | 8/8 FUNCIONAM |
| Cruzamento de rotas | COERENTE |
| Cruzamento de tipos log | COERENTE |
| Paths referenciados | OK |
| Zero jargao tecnico | OK |
| Lista de arquivos pacote | OK |
| Sync pacotes | 3 PENDENTES (ETAPA 5) |
| input.md checklist | 1 AJUSTE MENOR |
| manifesto.json changelog | 1 AJUSTE MENOR |

**APROVADO para publicacao**, condicionado a ETAPA 5 (sync + ajustes).
