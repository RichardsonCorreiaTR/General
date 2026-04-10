# Veredicto -- Redesign dos Agentes v1.1.0

> Auditoria: 07/03/2026

## VEREDICTO: COM RESSALVAS

Os agentes estao prontos para uso basico (NE e SA), mas tem 3 gaps
que afetam cenarios reais do dia-a-dia dos analistas.

Das 12 dores avaliadas: 9 resolvidas, 1 parcial, 2 nao resolvidas.
Consistencia entre agentes: OK (zero contradicoes, hashes sincronizados).
Fluxos simulados: 5 de 6 funcionam; fluxo SS/N3 NAO funciona.

---

## CORRECOES OBRIGATORIAS (bloqueia publicacao)

### C1. Criar Rota SS no agente-produto.mdc

**Dor**: D11 (NAO RESOLVIDA)
**O que fazer**: Adicionar uma 3a rota para chamados de suporte:

Rota SS -- Resposta ao Suporte (4 passos):
1. Entender a pergunta do suporte (SS-XXXXX, qual o problema do cliente)
2. Investigar comportamento atual (codigo + base, como o sistema faz hoje)
3. Verificar se e esperado (regras de negocio, legislacao, SAIs existentes)
4. Redigir resposta tecnica (para o analista enviar ao suporte)

Indicador: `[Passo X de 4 - Respondendo suporte]`

Na secao "Identificacao da rota", adicionar:
- **SS** (Chamado de Suporte N3): O suporte encaminhou uma duvida
  ou problema de cliente que precisa de analise tecnica.
  -> Siga a **Rota SS** (4 passos).

**Arquivo**: agente-produto.mdc
**Impacto**: +30-40 linhas

### C2. Adicionar tipo "Suporte" nos tipos de acao do log

**Dor**: D11
**O que fazer**: No guardiao.mdc, secao "Tipos de acao", adicionar:
- **Suporte**: respondeu chamado SS encaminhado pelo suporte N3

**Arquivo**: guardiao.mdc
**Impacto**: +1 linha

### C3. Adicionar tipo "Fluxo" e orientacao para perguntas de processo

**Dor**: D10 (PARCIAL)
**O que fazer**: No guardiao.mdc, secao "Tipos de acao", adicionar:
- **Fluxo**: explicou processo/fluxo do sistema

No agente-produto.mdc, na secao "consulta rapida", adicionar orientacao:
"Se o analista pergunta sobre fluxo ou processo do sistema (ex: 'como
funciona o calculo mensal?'), consulte referencia/banco-dados/mapa-sistema/
mapa-folha.md como fonte primaria. Apresente o processo em passos
numerados, com telas e acoes do usuario."

**Arquivo**: agente-produto.mdc + guardiao.mdc
**Impacto**: +5-10 linhas

---

## MELHORIAS RECOMENDADAS (nao bloqueiam, mas agregam valor)

### M1. Consolidar multiplas Mensagens Prioritarias

**Problema**: Se ambiente tem 3 falhas, gera 3 mensagens separadas.
**Sugestao**: Instruir guardiao a consolidar em uma unica mensagem
com lista de problemas quando detectar mais de 1 falha.
**Arquivo**: guardiao.mdc

### M2. Logs anteriores como fonte de contexto

**Dor**: D12
**Sugestao**: No Protocolo de varredura do agente-produto.mdc, adicionar
passo opcional: "Se referencia/logs/ tiver entradas sobre o mesmo
modulo/tema, leia as mais recentes para ver se o analista ja trabalhou
nisso antes."
**Arquivo**: agente-produto.mdc

### M3. Fallback para auto-atualizacao silenciosa

**Problema**: Se auto-update falha, ninguem sabe.
**Sugestao**: Se a copia de arquivos falhar, gerar Mensagem Prioritaria
em vez de falhar silenciosamente.
**Arquivo**: guardiao.mdc

### M4. Tratamento de interrupcao pelo analista

**Problema**: Se analista interrompe no meio de um passo, agente nao
sabe como retomar.
**Sugestao**: Adicionar instrucao no agente-produto.mdc: "Se o analista
interromper com outra pergunta, atenda a interrupcao e depois ofereca
retomar: 'Quer que a gente volte de onde paramos? Estavamos no
[Passo X de N - Acao].'"
**Arquivo**: agente-produto.mdc

### M5. Exemplos de SS no projeto.mdc

**Sugestao**: Adicionar na secao "Exemplos do dia-a-dia":
- "Recebi um chamado SS-12345 sobre erro no FGTS do cliente"
- "O suporte quer saber se o comportamento de rescisao esta correto"
**Arquivo**: projeto.mdc

---

## ARQUIVOS AFETADOS

| Arquivo | Correcoes | Melhorias |
|---------|-----------|-----------|
| agente-produto.mdc | C1 (+30-40 linhas), C3 (+5 linhas) | M2 (+3 linhas), M4 (+5 linhas) |
| guardiao.mdc | C2 (+1 linha), C3 (+1 linha) | M1 (+5 linhas), M3 (+3 linhas) |
| projeto.mdc | -- | M5 (+2 linhas) |
| onboarding.mdc | -- | -- |
| agente-codigo.mdc | -- | -- |

---

## PROXIMO PASSO

Aplicar C1, C2, C3 (correcoes obrigatorias) antes de publicar.
Aplicar M1-M5 se houver apetite (recomendado M1, M2, M4).
Depois: atualizar input.md, manifesto.json, arquivos/ e distribuicao/.
