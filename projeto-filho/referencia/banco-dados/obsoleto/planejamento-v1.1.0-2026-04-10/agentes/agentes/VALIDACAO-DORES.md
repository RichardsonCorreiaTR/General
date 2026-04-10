# Validacao contra as 12 Dores

> Auditoria: 07/03/2026

## D1. SA exige discovery criativo, diferente de NE

**Veredicto: RESOLVIDA**

- agente-produto.mdc secao "Identificacao da rota" (linhas 33-52): bifurca NE vs SA.
- Rota SA (linhas 124-226): 6 passos com passo dedicado "Descobrir" (linhas 140-167)
  que inclui: pesquisar base, buscar analogias, pensar legislacao, mapear gaps,
  pensar em voz alta.
- agente-codigo.mdc secao "Modo discovery" (linhas 76-100): quando nao encontra
  codigo, busca analogias, mapeia vizinhanca, identifica integracao.
- Transicao natural entre rotas quando tipo nao e claro.

---

## D2. Varredura incompleta, sem feedback de confianca

**Veredicto: RESOLVIDA**

- agente-produto.mdc secao "Protocolo de varredura" (linhas 229-273):
  5 fontes ordenadas, variar termos, bloco padrao de reporte.
- 3 niveis de confianca (ALTA/MEDIA/BAIXA) com definicao clara (linhas 260-269).
- Comportamento proativo quando BAIXA: "Preciso de mais tempo..." (linha 268).
- Instrucao para reportar o que NAO achou (linhas 271-273).

---

## D3. Comunicacao pouco clara, analista nao sabe onde esta

**Veredicto: RESOLVIDA**

- Indicador de progresso em cada passo: `[Passo X de N - Acao]`
  (linhas 64, 79, 95, 106, 120, 138, 167, 184, 199, 212, 225).
- Bloco de varredura com resumo estruturado visivel ao analista.

---

## D4. Auto-atualizacao pede permissao

**Veredicto: RESOLVIDA**

- guardiao.mdc secao "1. Atualizacao do projeto (silenciosa)" (linhas 25-38):
  "NAO fale nada ao analista. Continue normalmente." (linha 34).

---

## D5. Onboarding nao auto-completa

**Veredicto: RESOLVIDA**

- onboarding.mdc secao "Deteccao inteligente" (linhas 8-24):
  verifica evidencias de uso (meu-trabalho/, logs recentes).
  "Marque onboarding_completo: true silenciosamente e pule" (linhas 20-22).

---

## D6. Log nao e gerado proativamente

**Veredicto: RESOLVIDA**

- guardiao.mdc secao "Regra de log proativo" (linhas 182-189):
  "gere o log IMEDIATAMENTE -- sem perguntar ao analista" (linha 185).
  Consolidado automatico apos 5 interacoes (linhas 186-187).
- agente-produto.mdc secao "Log de atividades" (linhas 297-303):
  "Nao espere o analista pedir -- registre automaticamente" (linha 303).

---

## D7. Problemas de infra nao geram mensagem clara para gerente

**Veredicto: RESOLVIDA**

- guardiao.mdc secao "Mensagem Prioritaria" (linhas 66-109):
  formato OBRIGATORIO copiavel, menciona Vitor Justino (linha 76).
  5 cenarios com acao sugerida especifica (linhas 87-105).
- agente-codigo.mdc (linhas 37-40): gera Mensagem Prioritaria se codigo ausente.
- onboarding.mdc (linhas 55-56): gera Mensagem Prioritaria se ambiente falha.

---

## D8. Referencias a SDD/BDD/Gherkin confundem analistas

**Veredicto: RESOLVIDA**

- Busca automatizada por SDD|BDD|Gherkin|framework|pipeline|wizard nos 5 .mdc:
  zero ocorrencias. Unica ocorrencia e no arquivo obsoleto/sdd-definicao.mdc
  que nao e ativo (esta na pasta obsoleto/).
- Linguagem usada: "parceiro de analise", "passos", "processo".

---

## D9. Pipeline de 7 fases pouco intuitivo

**Veredicto: RESOLVIDA**

- Pipeline de 7 fases eliminado. Substituido por:
  Rota NE (5 passos) e Rota SA (6 passos).
- Cada passo com indicador simples e nome descritivo.
- Passos nao sao "fases" rigidas -- sao guias de conversa.

---

## D10. Duvidas pontuais (sem PSAI/SAI) -- fluxos e como seguir

**Veredicto: PARCIAL**

- agente-produto.mdc (linhas 50-52): "Se for consulta rapida (busca de SAI,
  glossario, duvida pontual), atenda direto sem seguir rota nenhuma."
- guardiao.mdc (linhas 123-124): "Para consultas simples [...] atenda
  diretamente sem o processo completo."
- projeto.mdc (linhas 27-38): exemplos incluem "O que o sistema faz hoje
  quando tem retroativo de FGTS?" e "Me mostra o codigo da tela de rescisao".

**O que falta**:
- Nao ha orientacao estruturada para duvidas sobre FLUXOS do sistema
  (ex: "Qual o passo a passo do calculo mensal?", "Como funciona o processo
  de rescisao complementar?").
- Nao ha instrucao para o agente usar o mapa-folha.md ou mapa-sistema
  proativamente para responder perguntas de fluxo.
- Nao ha tipo "Fluxo" nos tipos de acao do log (so Consulta, Analise, etc).

---

## D11. SS encaminhado N3 -- analista responde ao suporte

**Veredicto: NAO RESOLVIDA**

- Nenhum dos 5 .mdc menciona: SS, N3, suporte, chamado, cliente.
- Esse e um cenario DISTINTO de NE e SA:
  - Nao e correcao (NE) nem funcionalidade nova (SA).
  - E uma analise tecnica de comportamento atual do sistema para
    responder uma duvida do suporte sobre um problema do cliente.
  - Requer: entender a pergunta do suporte, investigar como o sistema
    se comporta, verificar se e o comportamento esperado, redigir
    resposta tecnica.
- Deveria ser uma 3a rota ou sub-modo no agente-produto.mdc.

---

## D12. Logs existentes com experiencia aproveitavel

**Veredicto: NAO RESOLVIDA**

- referencia/logs/ no projeto-filho esta VAZIO (nenhum .md encontrado).
  Nao ha logs historicos para analisar ainda.
- Mais importante: nenhum agente tem instrucao para CONSULTAR logs
  anteriores como fonte de contexto. O agente-produto busca SAIs,
  regras e codigo, mas nunca olha logs anteriores do analista para
  ver se ja trabalhou no mesmo tema ou modulo antes.
- Oportunidade: no Protocolo de varredura, incluir busca em logs
  anteriores como fonte secundaria de contexto.

---

## Resumo

| Dor | Status | Gap |
|-----|--------|-----|
| D1  | RESOLVIDA | -- |
| D2  | RESOLVIDA | -- |
| D3  | RESOLVIDA | -- |
| D4  | RESOLVIDA | -- |
| D5  | RESOLVIDA | -- |
| D6  | RESOLVIDA | -- |
| D7  | RESOLVIDA | -- |
| D8  | RESOLVIDA | -- |
| D9  | RESOLVIDA | -- |
| D10 | PARCIAL | Falta orientacao para perguntas de fluxo/processo |
| D11 | NAO RESOLVIDA | Falta rota para SS/N3 (suporte) |
| D12 | NAO RESOLVIDA | Falta instrucao para consultar logs anteriores |
