# Spec Tecnica - Fase 4: Atualizar Projeto-Filho

> Gerado em: 07/03/2026
> Base: PLANO.md secao Fase 4, PENDENTES.md D5/D10

---

## 1. RESUMO

Preparar mecanismo de atualizacao do projeto-filho via Cursor/IA.
O analista cola 1 frase, a IA le input.md e executa a atualizacao.

---

## 2. ARQUIVOS A CRIAR

### 2.1 atualizacao/v1.1.0/input.md
Instrucoes para a IA do analista executar a atualizacao.
Formato estruturado: o que mudou, backup, tabela origem->destino, nao tocar, verificacao.

### 2.2 atualizacao/v1.1.0/manifesto.json
Changelog maquina-legivel com versao, data, lista de arquivos alterados, preservar.

### 2.3 atualizacao/v1.1.0/arquivos/
Copia dos arquivos atualizados para a IA copiar:
- .cursor/rules/agente-produto.mdc (atualizado)
- .cursor/rules/guardiao.mdc (atualizado)
- config/VERSION.json (1.1.0)

---

## 3. ARQUIVOS A ALTERAR

### 3.1 projeto-filho/.cursor/rules/agente-produto.mdc

Secao FASE 2 CONTEXTO (linhas 47-64):
ANTES: "Busque em referencia/banco-dados/sais/indices/"
DEPOIS: Instrucao em 3 passos:
  1. Abrir resumo-pendentes.md
  2. Aprofundar em modulos/{slug}.md
  3. Cruzar com modulos adjacentes

### 3.2 projeto-filho/.cursor/rules/guardiao.mdc

Adicionar na secao "Verificacao de versao":
  **4. Frescor dos dados de SAIs:**
  Verificar referencia/atualizacao/status.json

Adicionar secao "Mecanismo de atualizacao via Cursor/IA":
  Quando versao disponivel > local, oferecer atualizacao.
  Ler input.md e executar passo a passo.

### 3.3 projeto-filho/config/VERSION.json
ANTES: versao "1.0.0"
DEPOIS: versao "1.1.0"

### 3.4 scripts/corrigir-symlinks.ps1 (projeto-filho)
Adicionar "atualizacao" ao array $links:
  @{ Name = "atualizacao"; Target = (Join-Path $onedrivePath "atualizacao") }

### 3.5 scripts/instalar-projeto-filho.ps1 (admin)
Adicionar "atualizacao" ao symlink na funcao New-Symlinks.

### 3.6 distribuicao/ultima-versao/
Atualizar: VERSION.json, agente-produto.mdc, guardiao.mdc,
MANIFESTO-UPDATE.json, scripts/corrigir-symlinks.ps1

### 3.7 distribuicao/CHANGELOG.md
Adicionar entrada v1.1.0.

---

## 4. CRITERIOS DE SUCESSO

| Criterio | Como medir |
|----------|------------|
| input.md legivel pela IA | Estrutura clara, 5 secoes |
| manifesto.json valido | ConvertFrom-Json funciona |
| VERSION.json = 1.1.0 | Leitura direta |
| Symlink atualizacao/ no corrigir-symlinks | Grep no codigo |
| agente-produto.mdc menciona resumo-pendentes e modulos | Grep |
| guardiao.mdc verifica status.json | Grep |
| distribuicao/ultima-versao/ atualizada | Comparar com projeto-filho |

---

## Validacao

(sera preenchido na Etapa 2)

---

## Validacao (Etapa 2 - 07/03/2026)

### Checklist PLANO.md Fase 4

- [x] 4A: input.md, manifesto.json, arquivos/
- [x] 4B: symlink atualizacao/ no corrigir-symlinks e instalar
- [x] 4C: agente-produto.mdc com modulos, guardiao.mdc com status.json
- [x] VERSION.json bumped para 1.1.0
- [x] distribuicao/ultima-versao/ atualizada

### Checklist PENDENTES.md

- [x] D5: Guardiao verifica status.json
- [x] D10: Atualizacao via Cursor/IA, analista cola 1 frase
- [x] D13: Backup meu-trabalho/.backup/, feedback no log

### Paths verificados

- [x] projeto-filho/.cursor/rules/agente-produto.mdc: EXISTE (184 linhas)
- [x] projeto-filho/.cursor/rules/guardiao.mdc: EXISTE (243 linhas)
- [x] projeto-filho/config/VERSION.json: EXISTE (1.0.0)
- [x] projeto-filho/scripts/corrigir-symlinks.ps1: EXISTE
- [x] scripts/instalar-projeto-filho.ps1: EXISTE
- [x] distribuicao/ultima-versao/: EXISTE

### RESULTADO

Validada em 07/03/2026. Nenhuma inconsistencia.
