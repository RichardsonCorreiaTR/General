# Resultado: Simplificacao da Arquitetura de Atualizacao

Data: 2026-03-08
Status: Concluido e testado

> **2026-04-10**: O pacote que estava em `planejamento/v1.1.0/` foi movido para
> `banco-dados/obsoleto/planejamento-v1.1.0-2026-04-10/`. O texto abaixo descreve
> a reorganizacao original; os caminhos historicos equivalem a essa pasta em obsoleto.

---

## O que foi feito

### FASE 1 - Reorganizacao de pastas

35 documentos de trabalho movidos de atualizacao/ para planejamento/v1.1.0/
(hoje: `banco-dados/obsoleto/planejamento-v1.1.0-2026-04-10/`):
- agentes/ (10 arquivos: specs, SWOT, validacao, mapa, testes)
- testes/ (14 arquivos: outputs, scripts de teste, logs)
- revisao/ (4 arquivos: revisoes por fase)
- specs/ (4 arquivos: especificacoes por fase)
- Docs avulsos: SWOT.md, PLANO.md, PENDENTES.md, DIAGNOSTICO.md

### FASE 2 - Unificacao da publicacao

gerar-atualizacao.ps1 atualizado de 4 para 6 passos:
- [1/6] Atualiza VERSION.json no projeto-filho
- [2/6] Coleta arquivos para o pacote
- [3/6] Gera ZIP (fallback)
- [4/6] Publica Canal 1 (distribuicao/ultima-versao/) -- EXISTIA
- [5/6] Publica Canal 2 (atualizacao/v{X.Y.Z}/) -- NOVO
- [6/6] Atualiza CHANGELOG

O passo 5/6 gera automaticamente: input.md, manifesto.json e arquivos/.
Tambem limpa versoes antigas do Canal 2.

### FASE 3 - Documentacao de proposito

Criados READMEs com proposito claro:
- planejamento/README.md -- o que e e como usar
- atualizacao/README.md -- dois propositos (operacional + pacotes)

---

## As 4 camadas (definicao final)

### 1. PROJETO MAE (raiz)

O workspace que o gerente abre no Cursor.
Contem ferramentas de admin, base de dados e orquestracao.

Pastas: .cursor/rules/ (admin), scripts/ (admin), templates/ (mestres),
banco-dados/, logs/, revisao/, atualizacao/ (operacional)

### 2. PROJETO FILHO (projeto-filho/)

Fonte da verdade do que o analista usa.
O gerente edita AQUI quando quer mudar agentes, templates ou scripts.
De aqui sai tudo quando roda gerar-atualizacao.ps1.

### 3. PLANEJAMENTO ATUALIZACAO (planejamento/)

Tudo que planejamos e preparamos para uma atualizacao.
Specs, testes, SWOT, revisoes, diagnosticos.
Organizado por versao: `planejamento/v{X.Y.Z}/` (v1.1.0 arquivado em obsoleto; ver acima).

### 4. ATUALIZACAO FINAL (distribuicao/ + atualizacao/v{X.Y.Z}/)

Pacote executado, testado, garantido e pronto para os analistas.
Dois canais de entrega:
- Canal Script: distribuicao/ultima-versao/ (analista roda atualizar-projeto.ps1)
- Canal IA: atualizacao/v{X.Y.Z}/ (guardiao.mdc aplica silenciosamente)

Ambos sao gerados por um UNICO script: gerar-atualizacao.ps1.

---

## Fluxo de atualizacao (simplificado)

1. Gerente edita agentes/scripts em projeto-filho/
2. Gerente documenta mudancas em planejamento/v{X.Y.Z}/
3. Gerente roda: scripts\gerar-atualizacao.ps1 -Versao  X.Y.Z -Changelog ...
4. Script publica nos 2 canais automaticamente
5. Analistas recebem por:
   a. Script: rodam .\scripts\atualizar-projeto.ps1 no terminal
   b. IA: guardiao.mdc aplica na proxima sessao do Cursor

---

## Testes realizados

### Teste de estrutura de pastas
- [x] planejamento v1.1.0 com todos os 35 docs de trabalho (hoje em obsoleto/planejamento-v1.1.0-2026-04-10/)
- [x] atualizacao/ limpa (so operacional + pacote v1.1.0)
- [x] Agentes identicos nas 3 copias (projeto-filho, distribuicao, atualizacao)
- [x] VERSION.json identicos nas 3 copias
- [x] Dados operacionais preservados (status.json, dashboard, logs)
- [x] Nenhum script quebrado

### Teste de fluxo de atualizacao
- [x] gerar-atualizacao.ps1 com 6 passos (Canal 1 + Canal 2)
- [x] atualizar-projeto.ps1 busca de distribuicao/ultima-versao/
- [x] guardiao.mdc verifica referencia/atualizacao/ com fallback
- [x] input.md coerente com manifesto.json
- [x] Todos os 8 arquivos referenciados existem em arquivos/

---

## Instrucao para os analistas

Abram o terminal no Cursor e rodem:

    .\scripts\atualizar-projeto.ps1

Digitem S para confirmar. Depois reabram o Cursor.

(Analistas com symlink referencia/atualizacao/ recebem automaticamente pela IA.)
