# Guia de Validacao de Calculos com Possibilidade de Valor Negativo

> Use este guia ao **definir** ou **revisar** PSAI/SAI dos tipos **SAM, SAL ou SAIL** que envolvam calculo, subtracao, desconto, abatimento, ajuste, credito/debito, retroativo ou qualquer formula com entradas variaveis.
>
> Complementa `GUIA-padroes-psai.md` e e independente de `GUIA-validacao-ne.md`.
>
> ## Escopo de aplicacao
>
> | Tipo | Aplica? | Razao |
> |---|---|---|
> | **SAM** | SIM | Funcionalidade nova ou melhoria — calculos novos exigem definicao explicita de tratamento. |
> | **SAL / SAIL** | SIM | Mudanca legal pode introduzir formulas novas ou alterar limites/sinais de operacoes existentes. |
> | **NE** | **NAO** | NE corrige comportamento ja definido. O tratamento de negativos deve estar herdado da SAI original; revalidacao preventiva nao se aplica. |
>
> Para NE, seguir apenas `GUIA-validacao-ne.md` e `GUIA-padroes-psai.md`. Se a NE revelar que a definicao original **nao tinha** regra para negativo, isso e gap da SAI original — escalar para o GP em vez de tratar dentro da NE.

---

## Objetivo

Garantir que toda PSAI/SAI cujo escopo inclua **calculo** seja avaliada quanto a **possibilidade de gerar valor negativo** e que o tratamento esteja **explicitamente definido** — nunca assumido, nunca implicito.

Resultado negativo sem regra de tratamento e **bug latente**: pode aparecer como saldo invalido, base de calculo invalida, divergencia de fechamento, erro em obrigacao acessoria ou inconsistencia em integracao (eSocial, SPED, ECF, EFD).

---

## Etapa 1 — Analise preventiva (na definicao da PSAI)

> Aplicavel a **SAM, SAL e SAIL**. Nao executar para NE.

Antes de fechar a definicao, avalie a **formula ou estrutura** do calculo e identifique se existe possibilidade **matematica ou logica** de gerar resultado negativo. Considere:

- **Subtracoes** entre valores variaveis (ex.: base bruta − deducoes − retencoes)
- **Descontos, abatimentos ou ajustes** (faltas, atrasos, adiantamentos, compensacoes)
- **Entradas que podem assumir valores menores que zero** ou proximos de zero (estornos, devolucoes, notas de credito)
- **Cenarios extremos ou limites** (mes com poucos dias, periodo aquisitivo incompleto, retroativo cruzando exercicios)
- **Acumuladores** que recebem operacoes mistas (debito e credito)
- **Saldos a transportar** (DCTFWeb, ECF, IRPJ/CSLL com prejuizo fiscal, ICMS a recuperar)

Classifique o calculo em uma das tres categorias:

| Classificacao | Significado | Acao |
|---|---|---|
| Nao pode gerar valor negativo | Comprovado matematicamente que o resultado e sempre >= 0 | Documentar a justificativa na PSAI |
| Pode gerar valor negativo (com regra) | E possivel, e existe regra de tratamento definida | Documentar a regra na PSAI/SAI |
| Pode gerar valor negativo (SEM regra) | E possivel e **nao ha regra definida** | **Bloquear a PSAI** ate o analista definir |

---

## Etapa 2 — Tratamento quando houver possibilidade

Se o calculo **pode gerar valor negativo**, aplicar este fluxo:

### 2.1 Verificar se ja existe regra de negocio definida

Procurar em:

1. SAIs anteriores do mesmo modulo (`buscar-sai.ps1 -Termo "<calculo>" -Modulo "<modulo>"`)
2. Regras de negocio em `referencia/banco-dados/regras-negocio/{modulo}/`
3. Glossario do modulo
4. Mapa do sistema (`mapa-escrita.md`, `mapa-importacao.md`, `mapa-onvio-escrita.md`)
5. Legislacao aplicavel (quando o tratamento e imposto por norma — ex.: ICMS a recuperar, prejuizo fiscal acumulado)

### 2.2 Se NAO existe regra clara

A PSAI **nao pode ser concluida**. O agente deve:

1. **Alertar o analista** com a mensagem padrao da secao "Mensagem de alerta" (abaixo).
2. **Listar os elementos**: nome do calculo, motivo da possibilidade de negativo, contexto de aplicacao.
3. **Solicitar definicao explicita** entre as opcoes da tabela 2.3.
4. **Registrar** a decisao na propria PSAI (secao **"Tratamento de valor negativo"** — ver modelo abaixo).

### 2.3 Se existe regra definida

Aplicar **explicitamente** o tratamento na definicao. Opcoes padrao:

| Tratamento | Quando usar | Exemplo no dominio Escrita |
|---|---|---|
| **Ajustar para zero** | Quando o negativo nao tem significado de negocio | Base de calculo de imposto que zerou apos deducoes |
| **Permitir negativo** | Quando o negativo tem significado contabil/fiscal | Saldo credor de ICMS, prejuizo fiscal a compensar |
| **Bloquear processamento** | Quando o negativo indica inconsistencia de cadastro | Estoque que ficaria negativo apos baixa |
| **Gerar erro / aviso ao usuario** | Quando o usuario deve corrigir antes de prosseguir | Apuracao com base negativa antes de fechar periodo |
| **Compensar em periodo seguinte** | Quando legislacao manda transportar saldo | Saldo a recuperar de periodos anteriores |
| **Estornar/registrar como ajuste** | Quando o negativo deve gerar lancamento contrario | Devolucao que reduz faturamento do mes |

A definicao deve indicar **qual** tratamento, **onde** e **quando** se aplica.

---

## Etapa 3 — Validacao em tempo de execucao (pos-implementacao)

A revisao da PSAI/SAI deve garantir que **alem da definicao**, exista **comportamento de execucao** descrito:

- Sempre que o resultado do calculo for **menor que zero**, o sistema:
  1. Reavalia se a regra existente foi aplicada corretamente.
  2. Garante que o tratamento definido foi efetivado **antes** de gravar/transmitir o valor.
  3. Registra log/aviso quando aplicavel (para auditoria contabil/fiscal).

Se a PSAI cobre apenas a Etapa 1 (definicao) sem descrever a Etapa 3 (execucao), o analista deve **complementar** ou justificar a omissao.

---

## Mensagem de alerta (padrao)

Quando faltar regra definida, o agente emite **literalmente**:

```
O calculo [nome do calculo] possui possibilidade de gerar valor negativo
com base em sua definicao.

Motivo: [subtracao / desconto / acumulador misto / cenario extremo]
Contexto: [modulo / tela / operacao / processo]

Nao ha regra de negocio definida para este cenario.
Favor avaliar e definir o tratamento adequado entre as opcoes:
  - Ajustar para zero
  - Permitir negativo
  - Bloquear processamento
  - Gerar erro/aviso
  - Compensar em periodo seguinte
  - Estornar/registrar como ajuste
```

Esta mensagem **bloqueia** a conclusao da PSAI ate haver resposta.

---

## Modelo de secao na PSAI/SAI

Adicionar na PSAI/SAI envolvendo calculo:

```
### Tratamento de valor negativo

**Calculo avaliado**: [nome / formula resumida]
**Pode gerar valor negativo?**: SIM / NAO
**Justificativa**: [matematica/logica para SIM ou NAO]
**Cenarios que levam a negativo** (se SIM):
  1. [cenario] — [exemplo numerico]
  2. [cenario] — [exemplo numerico]
**Tratamento definido**: [ajustar zero / permitir / bloquear / aviso / compensar / estornar]
**Validacao em execucao**: [como o sistema valida no momento do calculo]
**Base legal/SAI de referencia** (se aplicavel): [SAI-XXXXX / artigo da lei]
```

---

## Criterios de qualidade (checklist obrigatorio)

Antes de aprovar uma PSAI/SAI com calculo:

- [ ] Toda formula/subtracao/acumulador foi **classificada** quanto a possibilidade de negativo.
- [ ] Para cada calculo que **pode** gerar negativo, ha **regra explicita** de tratamento.
- [ ] Para cada cenario, ha **exemplo numerico concreto** (nao abstrato).
- [ ] A PSAI descreve tanto a **prevencao** (definicao) quanto a **reacao** (execucao).
- [ ] Quando aplicavel, a **base legal** ou **SAI de referencia** esta citada.
- [ ] **Nenhum** calculo deixou a definicao com "vamos ver na implementacao" ou "o desenvolvedor decide".

Se algum item ficar em aberto, a PSAI **deve voltar** para o analista (decisao DEVOLVER no parecer de revisao).

---

## Integracao com revisao (`revisar-psai.mdc`)

No **Passo 5 — Conformidade com padroes** da revisao, este guia e referencia obrigatoria sempre que a PSAI for **SAM, SAL ou SAIL** e envolver calculo. **Nao se aplica a NE.**

O parecer (apenas para SAM/SAL/SAIL) deve incluir uma linha explicita:

```
Calculos com possibilidade de valor negativo:
  - [nome do calculo]: classificacao [SIM/NAO] / tratamento [...] — Conforme/Nao conforme
```

Se houver calculo nao classificado ou sem regra, o parecer e **DEVOLVER** com motivo "Falta tratamento de valor negativo (ver `GUIA-validacao-calculos-negativos.md`)".

---

## Exemplos rapidos no dominio Escrita

| Situacao | Pode negativar? | Tratamento tipico |
|---|---|---|
| Base de ICMS apos deducoes (frete, IPI, descontos) | SIM | Ajustar para zero |
| Saldo de ICMS a recuperar (creditos > debitos) | SIM | Permitir negativo (saldo credor) |
| Estoque apos baixa de saida | SIM | Bloquear / gerar aviso |
| Valor a pagar em DARF apos retencoes | SIM | Ajustar para zero (compensar em periodo seguinte se previsto) |
| Lucro real apos compensacao de prejuizo | SIM | Permitir negativo (prejuizo do periodo) |
| Quantidade em nota fiscal de saida | NAO | N/A (validacao impede entrada negativa) |
| Total de imposto retido em folha | Geralmente NAO | Validar se ha estorno no mesmo mes |

---

## Versao

- v1.0 — 2026-06-09 — criacao do guia.
