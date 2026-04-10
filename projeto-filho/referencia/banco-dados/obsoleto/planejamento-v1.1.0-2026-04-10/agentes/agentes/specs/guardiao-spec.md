# Spec de Correcao: guardiao.mdc

> Correcoes: C2, C3 | Melhorias: M1, M3 | Consistencia: +2 ajustes

## C2. Tipo "Suporte" no log (D11)

**Onde**: Secao "Tipos de acao" (apos linha 281)

ANTES (linhas 280-285):
```
- **Consulta**: buscou definicoes, glossario, SAIs, codigo
- **Analise**: usou o processo (Rota NE ou Rota SA)
- **Definicao**: criou ou editou PSAI/SAI
- **Revisao**: revisou ou ajustou definicao existente
- **Conclusao**: finalizou e moveu para concluido/
- **Exploracao**: navegou pela base
```

DEPOIS:
```
- **Consulta**: buscou definicoes, glossario, SAIs, codigo
- **Analise**: usou o processo (Rota NE, Rota SA ou Rota SS)
- **Suporte**: respondeu chamado SS encaminhado pelo suporte N3
- **Fluxo**: explicou processo/fluxo do sistema
- **Definicao**: criou ou editou PSAI/SAI
- **Revisao**: revisou ou ajustou definicao existente
- **Conclusao**: finalizou e moveu para concluido/
- **Exploracao**: navegou pela base
```

**Por que**: C2 resolve D11 (log nao registrava tipo Suporte).
C3 resolve D10 (log nao registrava tipo Fluxo).
Nota: o tipo "Analise" tambem foi atualizado para incluir Rota SS.

---

## C3. Tipo "Fluxo" no log (D10)

Ja incluido na alteracao acima.

---

## Consistencia #1: Secao "Fluxo de trabalho" deve mencionar Rota SS

**Onde**: Secao "Fluxo de trabalho: Analise de Produto" (linhas 118-121)

ANTES:
```
O agente identifica se e NE (correcao) ou SA (funcionalidade nova)
e segue a rota adequada:
- **Rota NE**: 5 passos para correcao de erro
- **Rota SA**: 6 passos para discovery de funcionalidade
```

DEPOIS:
```
O agente identifica se e NE (correcao), SA (funcionalidade nova) ou
SS (resposta ao suporte) e segue a rota adequada:
- **Rota NE**: 5 passos para correcao de erro
- **Rota SA**: 6 passos para discovery de funcionalidade
- **Rota SS**: 4 passos para resposta ao suporte N3
```

**Por que**: Sem isso, guardiao so conhece 2 rotas e o agente-produto tem 3.
Inconsistencia cruzada detectada na auto-validacao.

---

## Consistencia #2: Formato de log "Trabalho" deve incluir Rota SS

**Onde**: Secao "Formato COMPLETO", campo "Trabalho" (linha 230)

ANTES:
```
- **Trabalho**: Rota NE passo X de 5 | Rota SA passo X de 6 | Consulta
```

DEPOIS:
```
- **Trabalho**: Rota NE passo X de 5 | Rota SA passo X de 6 | Rota SS passo X de 4 | Consulta | Fluxo
```

**Por que**: Sem isso, log nao sabe registrar trabalho de Rota SS nem Fluxo.

---

## M1. Consolidar multiplas Mensagens Prioritarias

**Onde**: Secao "Mensagem Prioritaria" (apos linha 109, antes de "---")

**Adicionar apos** "enquanto o gerente resolve.":

```

Se detectar MAIS DE UM problema, consolide em uma UNICA mensagem com
lista de problemas. Nao gere mensagens separadas para cada falha:

ALERTA PROJETO FOLHA - [Analista: {nome}]
Problemas detectados ({N}):
1. {problema 1} - {descricao}
2. {problema 2} - {descricao}
Detectado em: {data e hora}
Acao sugerida: Verificar itens acima e orientar analista.
```

**Por que**: Resolve ameaca SWOT #3. Multiplas mensagens confundem o analista.

---

## M3. Fallback para auto-atualizacao

**Onde**: Secao "1. Atualizacao do projeto (silenciosa)" (apos linha 34)

ANTES (linha 34):
```
   d. NAO fale nada ao analista. Continue normalmente.
```

DEPOIS:
```
   d. NAO fale nada ao analista. Continue normalmente.
   e. Se a copia falhar (erro de permissao, arquivo bloqueado), gere
      **Mensagem Prioritaria** informando que a auto-atualizacao falhou.
```

**Por que**: Resolve ameaca SWOT #2. Falha silenciosa deixa analista
preso em versao antiga sem ninguem saber.

---

## O que NAO muda

- Verificacoes automaticas (4 checks) -- intactas
- Formato Mensagem Prioritaria (template) -- intacto, apenas adiciona
  instrucao de consolidacao
- Log: formato COMPLETO e RAPIDO -- intactos (exceto campo Trabalho)
- Principios do log (7 itens) -- intactos
- Protecao de contexto/arquitetura -- intacta
- Header (description, alwaysApply) -- intacto
