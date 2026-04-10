# Spec Tecnica - Fase 1: Indices Inteligentes + Classificacao Melhorada

> Gerado em: 07/03/2026
> Base: PLANO.md secao Fase 1 + analise do gerar-indices-sais.ps1

---

## 1. RESUMO

Alterar gerar-indices-sais.ps1 para:
- Carregar keywords de arquivo externo (modulos-keywords.json)
- Classificar SAIs com multi-modulo (Nivel B)
- Gerar 22 arquivos de modulo inteligentes (indices/modulos/*.md)
- Gerar resumo-pendentes.md
- Gerar indice-geral.md (orfao)
- Manter TODOS os indices existentes (D8)

---

## 2. ARQUIVOS A CRIAR

### 2.1 banco-dados/config/modulos-keywords.json
ACAO: Mover de raiz para banco-dados/config/
Conteudo: JSON com 22 modulos, cada um com nome_exibicao, tags_origem, keywords
Ja gerado pelo subagente. Verificado: 22 modulos, 87 tags agrupadas.

### 2.2 banco-dados/sais/indices/modulos/ (diretorio)
ACAO: Criar diretorio. Sera populado com ~22 arquivos .md.

### 2.3 banco-dados/sais/indices/modulos/{slug}.md (22 arquivos)
ACAO: Gerar pelo script. Um por modulo.
Formato de cada arquivo:

```
# {Nome Exibicao} - Modulo Folha

> Atualizado em: DD/MM/AAAA HH:MM
> Pendentes: N | Liberadas: N | Descartadas: N | Total SAIs: N

## Pendentes (N)

Todas as SAIs pendentes do modulo, DETALHADAS.

| SAI | PSAI | Tipo | Gravidade | Cadastro | Resumo |
|-----|------|------|-----------|----------|--------|

## Liberadas Recentes (30 mais recentes)

| SAI | PSAI | Tipo | Liberacao | Resumo |
|-----|------|------|-----------|--------|

## Temas Frequentes (liberadas)

Top 5 keywords mais recorrentes nas liberadas deste modulo.

## Descartadas Recentes (10 mais recentes)

| SAI | PSAI | Tipo | Descarte | Resumo |
|-----|------|------|----------|--------|

## Busca Completa

Para lista completa, use: powershell -File scripts\buscar-sai.ps1 -Modulo "{nome}"
```

### 2.4 banco-dados/sais/indices/resumo-pendentes.md
Formato:
```
# Resumo de Pendentes - Folha

> Atualizado em: DD/MM/AAAA HH:MM
> Total pendentes: N (de M modulos)

## Totais por Modulo

| Modulo | Pendentes | % do Total |

## Top 20 Novidades (pendentes mais recentes)

| SAI | PSAI | Tipo | Modulo | Cadastro | Resumo |
```

### 2.5 banco-dados/sais/indices/indice-geral.md (orfao corrigido)
Resumo com totais por tipo, status e versao.

---

## 3. ARQUIVO A ALTERAR: scripts/gerar-indices-sais.ps1

### Mudanca 1: Carregar keywords do JSON externo

LOCAL: Apos linha 33 (apos carregar dados do cache)
SUBSTITUI: Bloco hardcoded linhas 252-272

Pseudo-codigo:
```
kwFile = projetoDir + "banco-dados\config\modulos-keywords.json"
SE kwFile existe:
  kwJson = ler JSON
  Para cada modulo em kwJson.modulos:
    moduloKeywords[slug] = keywords[]
    moduloNomes[slug] = nome_exibicao
SENAO:
  AVISO e usar fallback hardcoded
```

### Mudanca 2: Classificacao multi-modulo

LOCAL: Substituir logica de linhas 274-299
ANTES: Primeira keyword encontrada define O modulo (single-match).
DEPOIS: SAI pertence a TODOS os modulos com keyword match.

Pseudo-codigo:
```
saiModulos = {}  (mapa: i_psai -> lista de slugs)
Para cada item em dados:
  Para cada modulo em moduloKeywords:
    Para cada keyword do modulo:
      SE descricao contem keyword:
        Adicionar modulo ao saiModulos[i_psai]
        BREAK (proxima keyword do mesmo modulo nao precisa)
```

### Mudanca 3: Manter por-modulo.md (D8 legado)

NAO REMOVER secao B5.
Adaptar para usar moduloNomes[slug] em vez de chave direta.
Adaptar para usar saiModulos em vez de classificadosSet.
por-modulo.md continua com formato identico ao atual.

### Mudanca 4: Gerar modulos inteligentes (NOVA secao B5b)

LOCAL: Apos geracao do por-modulo.md (nova secao)
CRIA: indices/modulos/{slug}.md para cada modulo

Para cada modulo:
  1. Filtrar SAIs deste modulo via saiModulos
  2. Agrupar por i_sai (PSAI mais recente)
  3. Separar em pendentes/liberadas/descartadas
  4. PENDENTES: TODOS, com SAI, PSAI, Tipo, Gravidade, Cadastro, Resumo(80ch)
  5. LIBERADAS: 30 mais recentes, com SAI, PSAI, Tipo, Liberacao, Resumo
  6. TEMAS FREQUENTES: contar keywords mais comuns nas liberadas
  7. DESCARTADAS: 10 mais recentes
  8. Escrever arquivo com formato da secao 2.3

Nao Classificado = modulo especial "nao-classificado.md"

### Mudanca 5: Gerar resumo-pendentes.md (NOVA secao B5c)

LOCAL: Apos modulos inteligentes
CRIA: indices/resumo-pendentes.md
Conteudo: tabela de totais + top 20 novidades (por data cadastro desc)

### Mudanca 6: Gerar indice-geral.md (NOVA secao B8)

LOCAL: Antes de gerar README.md
CRIA: indices/indice-geral.md
Conteudo: totais por tipo, status, versao, link para indices

### Mudanca 7: Atualizar README.md (secao B7 existente)

Adicionar links para:
- modulos/ (diretorio)
- resumo-pendentes.md
- indice-geral.md
Manter todos os links existentes

---

## 4. ARQUIVOS NAO ALTERADOS (D8)

Todos estes continuam sendo gerados exatamente como hoje:
- pendentes-ne-recentes.md, pendentes-ne-antigas.md
- liberadas-ne-recentes.md, liberadas-ne-antigas.md
- descartadas-ne.md
- pendentes-sam.md, pendentes-sal.md, pendentes-sail.md
- liberadas-sam.md, liberadas-sal.md, liberadas-sail.md
- descartadas-sam.md, descartadas-sal.md, descartadas-sail.md
- por-versao/*.md
- estatisticas.md
- por-modulo.md (legado, mantido)
- por-rubrica-detalhado.md

---

## 5. DEPENDENCIAS E ORDEM

1. Mover modulos-keywords.json para banco-dados/config/ (PRIMEIRO)
2. Alterar gerar-indices-sais.ps1 (todas as mudancas)
3. Diretorio indices/modulos/ criado automaticamente pelo script

Sem dependencias externas. Nao altera extrair-sais.ps1 nem importar-sais.ps1.

---

## 6. CRITERIOS DE SUCESSO MENSURAVEIS

| Criterio | Meta | Como medir |
|----------|------|------------|
| Modulos gerados | 22 + 1 (nao-classificado) | Contar arquivos em indices/modulos/ |
| Nao Classificado | menos de 1500 SAIs unicas | Ler nao-classificado.md |
| Tamanho max modulo | menor que 35 KB | Get-Item |
| Tamanho tipico modulo | 5-15 KB | Media dos 22 |
| resumo-pendentes.md | menor que 10 KB | Get-Item |
| indice-geral.md | menor que 5 KB | Get-Item |
| Indices flat existentes | TODOS presentes | Comparar lista antes/depois |
| por-modulo.md | Continua existindo | Test-Path |
| Script roda sem erro | Exit code 0 | Executar |
| RAM | Mesma (~2 GB, nao muda nesta fase) | Get-Process |

---

## 7. PLANO DE TESTE (SWOT W5)

1. Rodar script com output em pasta temporaria
2. Verificar todos os criterios da secao 6
3. Se OK: mover para producao
4. Se NOK: ajustar e re-rodar

IMPORTANTE: Script carrega monolitico (165 MB, ~2 GB RAM).
RODAR EM TERMINAL SEPARADO (fora do Cursor).

---

## 8. RISCOS

| Risco | Probabilidade | Mitigacao |
|-------|---------------|----------|
| Keywords amplas (falsos positivos) | Media | Revisar contagem |
| Keywords estreitas (poucos matches) | Baixa | 87 tags e amplo |
| Modulo muito grande (maior que 35 KB) | Baixa | Ajustar formato |
| Script falha | Baixa | Testar em temp |

---

## Validacao

(sera preenchido na Etapa 2)

---

## Validacao (Etapa 2 - 07/03/2026)

### Checklist PLANO.md

- [x] Fase 1A: Keywords expandidas (87 tags BuscaSaiFolha) -> 23 modulos, 331 kw
- [x] Fase 1A: Keywords em banco-dados/config/modulos-keywords.json
- [x] Fase 1A: Nivel B multi-modulo
- [x] Fase 1A: Meta Nao Classificado menor que 1500
- [x] Fase 1B: Pasta indices/modulos/ com ~22 arquivos
- [x] Fase 1B: Formato: pendentes + liberadas + temas + descartadas
- [x] Fase 1B: resumo-pendentes.md
- [x] Fase 1B: Corrigir 3 indices orfaos
- [x] D8: Manter TODOS indices flat existentes
- [x] D8: Manter por-modulo.md (legado)

### Checklist PENDENTES.md

- [x] D1: Smart sync (nao aplica Fase 1)
- [x] D8: Indices flat mantidos (secao 4)
- [x] D9: Keywords expandidas + multi-modulo
- [x] D12: Nivel 1 eliminado. Sem mudanca no SQL.
- [x] D13/AC4: Keywords externalizadas em JSON

### Checklist SWOT.md

- [x] W5: Teste em pasta temporaria (secao 7)
- [x] W6: Criterios mensuraveis (secao 6)
- [x] AC1: BuscaSaiFolha absorvido (87 tags -> 23 modulos)
- [x] AC4: Keywords em arquivo externo

### Inconsistencias CORRIGIDAS na validacao

1. CORRIGIDO: Spec faltava 2 indices orfaos (por-cenario-complexo.md, por-rubrica.md)
   -> Adicionados como secoes B8a e B8b no script
   -> por-cenario-complexo.md: gerado a partir de SAIs multi-modulo (2+ modulos)
   -> por-rubrica.md: gerado a partir de regex 4 digitos em descricoes pendentes

2. CORRIGIDO: Modulo "RPA e Contribuintes" faltava no JSON
   -> Adicionado como rpa-contribuintes (15 keywords)
   -> Total agora: 23 modulos (19 originais + 4 novos)

3. CORRIGIDO: 67 keywords originais nao estavam no JSON do BuscaSaiFolha
   -> Mergidas: cada modulo agora tem keywords originais + BuscaSaiFolha
   -> Total: 331 keywords (antes 264)

### Verificacao de paths reais

- [x] banco-dados/config/modulos-keywords.json: EXISTE (39 KB)
- [x] banco-dados/sais/indices/: EXISTE
- [x] banco-dados/sais/indices/modulos/: SERA CRIADO pelo script
- [x] scripts/gerar-indices-sais.ps1: EXISTE
- [x] 3 orfaos existem no disco mas NAO sao gerados pelo script

### RESULTADO

Validada em 07/03/2026. Todas as inconsistencias corrigidas.
Spec pronta para implementacao.
