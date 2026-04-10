# Mapa dos Agentes -- Redesign v1.1.0

> Auditoria: 07/03/2026

## 1. agente-produto.mdc (304 linhas)

**Papel**: Parceiro de analise para criacao de PSAIs e SAIs.
**Ativacao**: Quando analista abre arquivo em meu-trabalho/, templates/ ou referencia/ (globs).
  Nao e alwaysApply -- precisa ser invocado pelo guardiao ou pelo contexto de arquivos.
**Produz**: Definicoes PSAI/SAI em meu-trabalho/em-andamento/, logs em referencia/logs/.

**Secoes principais**:
| Secao | Conteudo |
|-------|----------|
| Sua postura | 5 principios de comportamento (explorar, instigar, aprofundar, facilitar, dialogar) |
| Identificacao da rota | Bifurca NE vs SA. Menciona consulta rapida como atalho. |
| Rota NE (5 passos) | Entender erro, Investigar, Cenarios impacto, Gerar definicao, Revisar |
| Rota SA (6 passos) | Entender necessidade, Descobrir, Desenhar, Cenarios, Gerar definicao, Revisar |
| Protocolo de varredura | Onde buscar (5 fontes), variar termos, reportar com confianca (ALTA/MEDIA/BAIXA) |
| Quando critico | Desacelerar, alertar, buscar mais |
| Naming | PSAI-{codigo}-{desc}.md, SAI-{codigo}-{tipo}-{desc}.md |
| Log | Instrucao para registrar proativamente |

**Dependencias (le)**:
- config/analista.json
- referencia/banco-dados/sais/indices/resumo-pendentes.md
- referencia/banco-dados/sais/indices/modulos/{slug}.md
- referencia/banco-dados/regras-negocio/{modulo}/
- referencia/banco-dados/glossario/
- templates/TEMPLATE-psai.md, TEMPLATE-sai.md

**Dependencias (escreve)**:
- meu-trabalho/em-andamento/*.md
- meu-trabalho/concluido/*.md (move)
- referencia/logs/{AAAA-MM-DD}.md (via guardiao)

**Interacoes**:
- Chama agente-codigo.mdc no Passo 2 (Investigar)
- Segue formato de log definido pelo guardiao.mdc

---

## 2. guardiao.mdc (316 linhas)

**Papel**: Checklist obrigatoria -- protecao, padronizacao, escalonamento.
**Ativacao**: alwaysApply = true. Ativo em TODA interacao.
**Produz**: Mensagens Prioritarias, logs em referencia/logs/, atualizacoes silenciosas.

**Secoes principais**:
| Secao | Conteudo |
|-------|----------|
| Identidade | Parceiro do Analista de Produto |
| Identificacao do analista | Le config/analista.json |
| Verificacoes automaticas (1a interacao) | 4 checks: versao projeto, codigo-fonte, base SAIs, frescor dados |
| Mensagem Prioritaria | Formato copiavel para Teams, 5 cenarios de alerta |
| Fluxo de trabalho | Referencia ao agente-produto.mdc, menciona Rota NE e SA |
| Antes/depois de definicao | Pre-checks e pos-checks |
| Naming | Padrao de nomes |
| Escopo | Ferramenta de analise, submissao no SGD |
| Protecao contexto/arquitetura | NUNCA le dados-brutos, NUNCA altera referencia/ |
| Log proativo | Regra: gerar imediatamente, consolidar a cada 5 interacoes |
| Formato de log | 2 niveis (COMPLETO e RAPIDO), 7 principios |

**Dependencias (le)**:
- config/VERSION.json
- config/analista.json
- config/caminhos.json
- referencia/atualizacao/vX.Y.Z/input.md
- referencia/atualizacao/status.json
- referencia/banco-dados/sais/indices/README.md
- referencia/banco-dados/codigo-sistema/META.json
- {codigo_local}/../META.json

**Dependencias (escreve)**:
- referencia/logs/{AAAA-MM-DD}.md
- .cursor/rules/*.mdc (durante auto-atualizacao)
- config/VERSION.json (durante auto-atualizacao)

**Interacoes**:
- Ativa agente-produto.mdc quando analista traz demanda
- Define formato de log usado por todos os agentes
- Outros agentes referenciam "Mensagem Prioritaria (ver guardiao.mdc)"

---

## 3. onboarding.mdc (95 linhas)

**Papel**: Primeiro uso e dicas contextuais.
**Ativacao**: alwaysApply = true. Verifica onboarding_completo na 1a mensagem.
**Produz**: Boas-vindas, verificacao de ambiente, marca onboarding_completo.

**Secoes principais**:
| Secao | Conteudo |
|-------|----------|
| Deteccao inteligente | Verifica evidencias de uso antes de iniciar wizard |
| Boas-vindas | Saudacao + explicacao em 4 passos naturais |
| Verificacao do ambiente | 3 checks silenciosos (README, caminhos, templates) |
| Primeira consulta pratica | Guia busca no modulo do analista |
| Finalizacao | Marca onboarding, registra log, menciona GUIA-RAPIDO |
| Dicas contextuais | 3 dicas para quem ja usa |
| Sugestoes | 6 frases exemplo |

**Dependencias (le)**:
- config/analista.json
- meu-trabalho/em-andamento/, meu-trabalho/concluido/
- referencia/logs/ (data recente)
- referencia/banco-dados/sais/indices/README.md
- config/caminhos.json
- templates/TEMPLATE-psai.md

**Dependencias (escreve)**:
- config/analista.json (onboarding_completo: true)
- referencia/logs/ (registro de primeiro uso)

**Interacoes**:
- Referencia guardiao.mdc para Mensagem Prioritaria em caso de falha

---

## 4. projeto.mdc (70 linhas)

**Papel**: Contexto do projeto para o analista.
**Ativacao**: alwaysApply = true. Fornece contexto em toda interacao.
**Produz**: Nada diretamente. E informacional.

**Secoes principais**:
| Secao | Conteudo |
|-------|----------|
| O que e | Espaco para PSAIs/SAIs com parceiro de analise |
| Como trabalha | 4 passos naturais |
| Exemplos do dia-a-dia | 8 frases exemplo |
| Onde fica cada coisa | 5 pastas |
| Se algo nao funcionar | Menciona Mensagem Prioritaria e Vitor Justino |
| Scripts | 4 scripts uteis |
| Buscar SAIs | Caminho dos indices + buscar-sai.ps1 |
| Guia rapido | Referencia GUIA-RAPIDO.md |

**Dependencias (le)**: Nenhuma diretamente.
**Dependencias (escreve)**: Nenhuma.
**Interacoes**: Referencia indireta ao guardiao (Mensagem Prioritaria).

---

## 5. agente-codigo.mdc (123 linhas)

**Papel**: Investigador do codigo-fonte, traduz para linguagem de produto.
**Ativacao**: Quando analista abre arquivo em meu-trabalho/ ou referencia/ (globs).
  Invocado pelo agente-produto.mdc no Passo 2.
**Produz**: Traducoes de codigo para produto, descobertas de inconsistencias.

**Secoes principais**:
| Secao | Conteudo |
|-------|----------|
| Sua postura | Detetive, segue rastro, traz surpresas |
| Onde buscar | 4 fontes (caminhos.json, indice-arquivos, mapa-folha, Grep) |
| Como traduzir | Exemplo antes/depois (tecnico vs produto) |
| Como investigar | 4 perguntas (quem chama, quem usa, tem parecido, o que muda) |
| Modo discovery | 4 acoes para funcionalidade inexistente (analogias, vizinhanca, integracao, proposta) |
| Quando chama atencao | 4 tipos de descoberta (duplicacao, calculo errado, codigo morto, hardcode) |
| Protecao contexto | Limite 500 linhas, Grep, mapa primeiro |

**Dependencias (le)**:
- config/caminhos.json (codigo_local)
- referencia/banco-dados/mapa-sistema/indice-arquivos.md
- referencia/banco-dados/mapa-sistema/mapa-folha.md
- {codigo_local}/ (codigo-fonte)

**Dependencias (escreve)**: Nenhuma diretamente.
**Interacoes**:
- Referencia guardiao.mdc para Mensagem Prioritaria quando codigo ausente
- Invocado pelo agente-produto.mdc

---

## Diagrama de interacao

```
guardiao.mdc (alwaysApply)
  |
  +-- verifica ambiente -> Mensagem Prioritaria (se falha)
  +-- auto-atualiza silenciosamente
  +-- ativa agente-produto.mdc (quando demanda)
  |
  agente-produto.mdc
  |
  +-- Rota NE (5 passos) ou Rota SA (6 passos)
  +-- Protocolo de varredura (le indices, regras, glossario)
  +-- Chama agente-codigo.mdc (Passo 2)
  +-- Gera definicao (templates) -> meu-trabalho/
  +-- Registra log (formato guardiao)
  |
  agente-codigo.mdc
  |
  +-- Investiga codigo-fonte (config/caminhos.json)
  +-- Modo discovery (para SA sem codigo existente)
  +-- Mensagem Prioritaria (se codigo ausente)

onboarding.mdc (alwaysApply)
  |
  +-- Detecta primeiro uso vs usuario ativo
  +-- Wizard simplificado ou pula silenciosamente
  +-- Mensagem Prioritaria (se ambiente falha)

projeto.mdc (alwaysApply)
  |
  +-- Contexto informacional (sempre presente)
```
