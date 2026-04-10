# Spec de Correcao: agente-produto.mdc

> Correcoes: C1, C3 | Melhorias: M2, M4

## C1. Rota SS -- Resposta ao Suporte (D11)

**Onde**: Inserir APOS a Rota SA (depois da linha 226, antes de "Protocolo de varredura")

**Adicionar na secao "Identificacao da rota" (apos linha 45)**:

ANTES (linhas 47-52):
```
Se nao ficou claro, pergunte de forma natural: "Isso e uma correcao de
algo que esta errado, ou e algo novo que precisa ser criado?"

Se for consulta rapida (busca de SAI, glossario, duvida pontual), atenda
direto sem seguir rota nenhuma. Mas fique atento: se a "pergunta simples"
revelar algo complexo, escale naturalmente para a rota adequada.
```

DEPOIS:
```
- **SS** (Chamado de Suporte N3): O suporte encaminhou uma duvida ou
  problema de cliente que precisa de analise tecnica do analista.
  -> Siga a **Rota SS** (4 passos).

Se nao ficou claro, pergunte de forma natural: "Isso e uma correcao de
algo que esta errado, algo novo que precisa ser criado, ou uma resposta
que o suporte precisa sobre o comportamento do sistema?"

Se for consulta rapida (busca de SAI, glossario, duvida pontual), atenda
direto sem seguir rota nenhuma. Se o analista pergunta sobre fluxo ou
processo do sistema (ex: "como funciona o calculo mensal?"), consulte
referencia/banco-dados/mapa-sistema/mapa-folha.md como fonte primaria.
Apresente o processo em passos numerados, com telas e acoes do usuario.

Mas fique atento: se a "pergunta simples" revelar algo complexo, escale
naturalmente para a rota adequada.
```

**Adicionar NOVA secao "Rota SS" (apos linha 226, antes de "Protocolo de varredura")**:

```
---

## Rota SS -- Resposta ao Suporte (4 passos)

### Passo 1: Entender a pergunta do suporte

Entenda o que o suporte precisa saber. Identifique: qual o numero do
chamado (SS-XXXXX)? Qual o problema que o cliente relatou? Qual a
duvida especifica que o suporte tem?

O suporte geralmente quer saber: "Esse comportamento e esperado?" ou
"Como o sistema deveria funcionar nesse caso?"

Indicador: `[Passo 1 de 4 - Entendendo a pergunta do suporte]`

### Passo 2: Investigar o comportamento atual

Investigue como o sistema funciona HOJE para o cenario do chamado.
Use o Protocolo de varredura (abaixo) para buscar SAIs e regras.
Use o agente-codigo.mdc para verificar o que o codigo faz.

Objetivo: responder factualmente "o sistema faz X quando Y acontece".
Traga evidencias: SAI que define, regra de negocio que explica,
trecho de codigo que confirma.

Indicador: `[Passo 2 de 4 - Investigando comportamento atual]`

### Passo 3: Verificar se e esperado

Compare o comportamento encontrado com:
- Regras de negocio existentes (o que deveria fazer?)
- Legislacao aplicavel (o que a lei diz?)
- SAIs relacionadas (ja foi definido como deveria ser?)

Se o comportamento esta CORRETO: explique ao analista por que, com
evidencia. "O sistema faz isso porque a SAI-XXXXX define que..."

Se o comportamento parece INCORRETO: alerte o analista. "O codigo
faz X, mas a regra de negocio diz Y. Pode ser um bug. Quer que eu
aprofunde para gerar uma NE?"

Se NAO HA DEFINICAO: informe. "Nao encontrei nenhuma regra que defina
o comportamento esperado para esse cenario. Pode ser um gap."

Indicador: `[Passo 3 de 4 - Verificando se e esperado]`

### Passo 4: Redigir resposta tecnica

Ajude o analista a redigir a resposta para o suporte. A resposta deve:
- Ser clara e direta (o suporte nao e analista de produto)
- Explicar o comportamento atual do sistema
- Indicar se e esperado ou nao
- Se nao e esperado: informar que sera tratado (NE)
- Se e esperado: referenciar a regra/SAI que define

Apresente um rascunho de resposta para o analista revisar e ajustar
antes de enviar ao suporte.

Indicador: `[Passo 4 de 4 - Redigindo resposta]`
```

**Por que**: Resolve D11. Cenario frequente onde analista precisa responder
ao suporte N3 sobre comportamento do sistema. Sem rota, a IA improvisa.

---

## C3. Orientacao para perguntas de fluxo/processo (D10)

**Onde**: Ja incluido na alteracao de C1 acima (paragrafo sobre "consulta rapida").

**Trecho adicionado**:
"Se o analista pergunta sobre fluxo ou processo do sistema [...] consulte
referencia/banco-dados/mapa-sistema/mapa-folha.md como fonte primaria.
Apresente o processo em passos numerados, com telas e acoes do usuario."

**Por que**: Resolve D10. Duvidas de fluxo caiam em "consulta rapida"
sem orientacao de ONDE buscar.

---

## M2. Logs anteriores como fonte de contexto (D12)

**Onde**: Secao "Protocolo de varredura > Onde buscar" (apos linha 239)

ANTES:
```
5. `referencia/banco-dados/glossario/` -- termos relevantes
```

DEPOIS:
```
5. `referencia/banco-dados/glossario/` -- termos relevantes
6. `referencia/logs/` -- se existem entradas sobre o mesmo modulo/tema,
   leia as mais recentes para ver se o analista ja trabalhou nisso antes
```

**Por que**: Resolve D12. Logs anteriores tem contexto valioso que o
agente ignora hoje.

---

## M4. Tratamento de interrupcao pelo analista

**Onde**: Apos secao "Quando algo parece critico" (apos linha 289)

**Adicionar**:

```
## Quando o analista interrompe

Se o analista interromper no meio de um passo com outra pergunta ou
assunto, atenda a interrupcao normalmente. Depois ofereca retomar:
"Quer que a gente volte de onde paramos? Estavamos no [Passo X de N]."

Nao force a retomada. Se o analista mudou de assunto, siga o novo assunto.
```

**Por que**: Resolve ameaca SWOT #1. Sem instrucao, agente pode perder
contexto do passo atual quando interrompido.

---

## O que NAO muda

- Rota NE (5 passos) -- intacta
- Rota SA (6 passos) -- intacta
- Protocolo de varredura (estrutura, niveis de confianca) -- intacto,
  apenas adiciona fonte #6
- Secoes: postura, naming, log, quando critico -- intactas
- Header (description, globs, alwaysApply) -- intacto
