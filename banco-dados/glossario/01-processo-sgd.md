# Glossario: Processo e SGD

> Termos relacionados ao fluxo de trabalho de desenvolvimento (SAI/PSAI)

---

## SAI - Solicitacao de Alteracao Interna

| Campo | Valor |
|---|---|
| **Sigla** | SAI |
| **Modulos** | Todos |

**Definicao:** Unidade de trabalho de desenvolvimento. Cada alteracao no sistema (bug, melhoria, legislacao) gera uma SAI. Ciclo de vida: cadastro > estimativa > desenvolvimento > teste > liberacao/descarte.

**Tipos:**

| Tipo | Sigla | Descricao |
|------|-------|-----------|
| Notificacao de Erro | NE | Bug reportado pelo suporte (via SSC/SANE) |
| Melhoria | SAM | Melhoria funcional solicitada |
| Legislacao | SAL | Alteracao por mudanca de lei/regulamento |
| SA Interna Legislacao | SAIL | Implementacao interna de legislacao |

---

## PSAI - Pre-SAI

**Definicao:** Pre-analise que antecede a SAI. Agrupa o planejamento e pode gerar uma ou mais SAIs. Identificada por i_psai.

---

## SSC - Solicitacao de Suporte ao Cliente

**Definicao:** Chamado aberto pelo suporte tecnico quando o cliente reporta um problema. Pode gerar uma NE se confirmado como bug.

---

## SANE - Solicitacao de Atendimento NE

**Definicao:** Registro de atendimento vinculado a uma NE. Indica quantos clientes sao afetados pelo bug.

---

## Versao de Mercado

**Definicao:** Comportamento atual do sistema na versao liberada para os clientes. Frase padrao nas definicoes: "Os demais comportamentos nao mencionados, deverao permanecer conforme versao de mercado." (encontrada em ~1.250 SAIs).

---

## Tramite

**Definicao:** Transicao de situacao/status de uma SAI ou PSAI no workflow do SGD. Ex: "Aguardando Resposta do Desenvolvimento" > "Em Teste DEMO" > "Liberada".
