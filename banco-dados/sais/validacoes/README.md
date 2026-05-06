# Histórico de validações por PSAI

Cada PSAI com número oficial tem **um ficheiro** `psai-<numero>.md` nesta pasta (ex.: `psai-129632.md`).

## Objetivo

1. **Persistir** cada validação (IA, GP ou analista) com data e contexto do SGD (**situação**, **trâmites** relevantes quando existirem — ex.: *Respondida pelo Coordenador*).
2. Na **próxima** validação, **ler o ficheiro**, inserir uma nova secção `## <data> — …` **logo abaixo** das duas primeiras linhas do ficheiro (a entrada **mais recente** fica no topo, as anteriores descem), comparando explicitamente:
   - **melhoras** nos pontos que tinham sido apontados;
   - **regressões** ou pendências que continuam;
   - alterações de texto após trâmites / resposta do coordenador.

Não apagar entradas antigas: o histórico é **append lógico** (novas entradas acima das mais antigas).

## Convenção do ficheiro

- Nome: `psai-<i_psai>.md` (número tal como no SGD, sem zeros à esquerda forçados).
- Estrutura sugerida: ver `templates/TEMPLATE-validacao-psai.md`.
- A regra do agente `revisar-psai.mdc` obriga a **consultar** este ficheiro antes do parecer e a **atualizá-lo** ao final.

## Projeto-filho (analistas)

No **projeto-filho**, `referencia/` é só leitura: os analistas **não** gravam aqui. O histórico pessoal fica em `meu-trabalho/validacoes-psai/` com as **mesmas regras** (`.cursor/rules/revisar-psai.mdc` no filho). O GP pode fundir entradas relevantes para esta pasta do Admin quando fizer sentido para o OneDrive.

## Relação com o SGD

Quando os trâmites não vierem no JSON da consulta Playwright, pode indicar-se *«trâmites não capturados no export»* e copiar manualmente a situação visível no SGD.
