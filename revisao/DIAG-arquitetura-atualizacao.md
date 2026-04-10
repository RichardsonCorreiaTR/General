# FASE 0 — Diagnostico: Arquitetura de Atualizacao

Data: 2026-03-08
Status: Concluido, aguardando aprovacao do gerente

---

## 1. Situacao atual — O projeto hoje

O projeto tem **4 conceitos misturados** em pastas que se sobrepoem:

| Pasta na raiz | O que contem HOJE | Problema |
|---------------|-------------------|----------|
| projeto-filho/ | Copia mestre do projeto do analista | OK, mas serve de fonte E de referencia ao mesmo tempo |
| distribuicao/ | Pacote publicado para analistas (canal script) | Copia de projeto-filho, dessincroniza se esquecer |
| tualizacao/ | Status de importacao + pacote v1.1.0 + 35 docs de trabalho | 3 propositos misturados na mesma pasta |
| Raiz (.cursor/rules/, scripts/, 	emplates/) | Ferramentas do gerente (admin) | Versoes diferentes dos mesmos arquivos do projeto-filho |

---

## 2. Mapa de duplicacoes

### 2.1 Agentes (.mdc) — 3 copias identicas + 1 diferente

| Arquivo | projeto-filho | distribuicao | atualizacao/v1.1.0 | Raiz (.cursor) |
|---------|:---:|:---:|:---:|:---:|
| agente-produto.mdc | 16659 B | 16659 B | 16659 B | -- |
| agente-codigo.mdc | 4883 B | 4883 B | 4883 B | -- |
| guardiao.mdc | 13269 B | 13269 B | 13269 B | 2177 B (resumida) |
| onboarding.mdc | 3447 B | 3447 B | 3447 B | -- |
| projeto.mdc | 2556 B | 2556 B | 2556 B | 1392 B (resumida) |
| sdd-definicao.mdc | -- | 458 B (obsoleto) | -- | 1822 B (ativa) |

**Achado:** As 3 copias (projeto-filho, distribuicao, atualizacao) sao IDENTICAS.
A raiz tem versoes DIFERENTES (resumidas, para o admin).

### 2.2 Scripts (.ps1) — ate 4 copias

| Script | Raiz (admin) | projeto-filho | distribuicao | atualizacao/v1.1.0 | Status |
|--------|:---:|:---:|:---:|:---:|--------|
| buscar-sai.ps1 | 13019 B | 1955 B | 1955 B | 1955 B | DIVERGENTE — admin 6.6x maior |
| corrigir-symlinks.ps1 | -- | 6315 B | 6315 B | 6315 B | IDENTICO |
| verificar-ambiente.ps1 | -- | 8788 B | 8788 B | -- | IDENTICO |
| atualizar-projeto.ps1 | -- | 6283 B | 6283 B | -- | IDENTICO |
| atualizar-codigo.ps1 | 6427 B | 5122 B | 5122 B | -- | DIVERGENTE — admin 25% maior |
| setup-odbc.ps1 | 2223 B | 2223 B | 2223 B | -- | IDENTICO |

**Achado:** buscar-sai.ps1 do admin e a versao completa (busca profunda em 14 campos).
O projeto-filho tem uma versao wrapper que chama o original via caminho OneDrive.

### 2.3 Templates — divergencias entre admin e projeto-filho

| Template | Raiz (admin) | projeto-filho | distribuicao | Status |
|----------|:---:|:---:|:---:|--------|
| TEMPLATE-regra-negocio.md | 2397 B | 306 B | 306 B | Admin 8x maior |
| TEMPLATE-analise-impacto.md | 1538 B | 1534 B | 1534 B | Micro-divergencia |
| TEMPLATE-fluxo-processo.md | 2168 B | 2128 B | 2128 B | Pequena divergencia |
| TEMPLATE-glossario.md | 1104 B | 1070 B | 1070 B | Pequena divergencia |
| TEMPLATE-psai.md | -- | 2614 B | 2614 B | IDENTICO |
| TEMPLATE-sai.md | -- | 3158 B | 3158 B | IDENTICO |

### 2.4 Manifestos de versao — divergentes entre canais

| Arquivo | distribuicao | atualizacao/v1.1.0 |
|---------|:---:|:---:|
| MANIFESTO-UPDATE.json | 861 B | -- |
| manifesto.json | -- | 942 B |

**Achado:** Nomes diferentes, conteudo similar mas nao identico. O da atualizacao inclui buscar-sai.ps1 nos arquivos alterados.

---

## 3. Canais de atualizacao

### Canal 1: Script (atualizar-projeto.ps1)

`
Gerente roda gerar-atualizacao.ps1
        |
        v
distribuicao/ultima-versao/  (OneDrive sincroniza)
        |
        v
Analista roda atualizar-projeto.ps1 no terminal
        |
        v
Copia .cursor/, templates/, scripts/ para o projeto local
`

- **Publicacao:** Automatizada via gerar-atualizacao.ps1
- **Acionamento:** Manual (analista roda o script)
- **Status:** Funcional

### Canal 2: IA Silenciosa (guardiao.mdc)

`
Gerente cria MANUALMENTE atualizacao/v{X.Y.Z}/
        |
        v
atualizacao/v1.1.0/input.md + arquivos/  (OneDrive sincroniza)
        |
        v
Symlink referencia/atualizacao/ no projeto do analista
        |
        v
Guardiao le input.md na 1a interacao do dia
        |
        v
IA copia arquivos silenciosamente
`

- **Publicacao:** MANUAL (nao coberta por gerar-atualizacao.ps1)
- **Acionamento:** Automatico (guardiao verifica na 1a interacao)
- **Fallback:** Se referencia/atualizacao/ nao existir, tenta distribuicao/ultima-versao/
- **Status:** Funcional, mas com risco de dessincronizacao

### Conclusao sobre canais

O gerar-atualizacao.ps1 so alimenta o Canal 1. O Canal 2 depende de publicacao manual.
Resultado: na proxima atualizacao, e provavel que o Canal 2 fique esquecido.

---

## 4. Pasta atualizacao/ — 3 propositos misturados

| Categoria | Qtd arquivos | Exemplos | Pode mover? |
|-----------|:---:|---------|:-----------:|
| OPERACIONAL (importacao SAIs) | 9 | status.json, dashboard-extracao.html, logs | Nao |
| PACOTE-VERSAO (v1.1.0) | 10 | input.md, manifesto.json, arquivos/ | Nao |
| DOCUMENTO-TRABALHO | 35 | agentes/SWOT, specs/, testes/, revisao/ | SIM |

**Os 35 documentos de trabalho nao sao referenciados por nenhum script ou regra.**
Podem ser movidos sem quebrar nada.

---

## 5. Hipoteses — Resultado

| # | Hipotese | Resultado |
|---|----------|-----------|
| H1 | Canais redundantes podem ser unificados | CONFIRMADA — Canal 2 (IA) tem fallback para Canal 1. Pode-se simplificar. |
| H2 | atualizacao/ mistura 3 propositos | CONFIRMADA — 35 docs de trabalho misturados com operacional e pacotes. |
| H3 | gerar-atualizacao.ps1 nao cobre canal IA | CONFIRMADA — So publica em distribuicao/. |
| H4 | Docs de trabalho misturados com producao | CONFIRMADA — Nenhum dos 35 e referenciado. |
| H5 | projeto-filho e o mestre, distribuicao e copia | CONFIRMADA — gerar-atualizacao.ps1 copia DE projeto-filho PARA distribuicao. |

---

## 6. Proposta de definicao das 4 camadas

### PROJETO MAE (Gerenciamento)

**O que e:** O workspace que o gerente abre no Cursor. Contem as ferramentas de admin,
a base de dados, e o mestre do projeto-filho.

**Pasta raiz:** Tudo que esta na raiz EXCETO projeto-filho/ e distribuicao/.
**Inclui:** .cursor/rules/ (regras admin), scripts/ (ferramentas admin), templates/ (mestres),
banco-dados/, logs/, revisao/, atualizacao/ (operacional).

### PROJETO FILHO (O que o analista usa)

**O que e:** O projeto que cada analista abre no SEU Cursor.
**Fonte da verdade:** projeto-filho/ na raiz do Projeto Mae.
**O gerente edita AQUI** quando quer mudar agentes, templates ou scripts do analista.

### PLANEJAMENTO ATUALIZACAO (Preparacao)

**O que e:** Tudo que planejamos, testamos e revisamos ANTES de publicar uma versao.
**Hoje:** Misturado dentro de atualizacao/ (agentes/, v1.1.0/testes/, specs/, revisao/).
**Proposta:** Mover para pasta propria (ex: planejamento/ ou revisao/versoes/).

### ATUALIZACAO FINAL (Pronto para os analistas)

**O que e:** Pacote executado, testado, garantido, com arquivos prontos para os analistas
atualizarem dando input no seu Cursor.
**Hoje:** Existe em 2 lugares (distribuicao/ e atualizacao/v1.1.0/).
**Proposta:** Unificar em 1 unico local com script automatizado.

---

## 7. Proximo passo

Aguardando aprovacao do gerente para prosseguir para FASE 1 (Definir arquitetura-alvo).

Perguntas para o gerente:
1. Concorda com as 4 camadas propostas?
2. Quer manter os 2 canais de atualizacao ou unificar em 1?
3. Os 35 documentos de trabalho podem ir para revisao/v1.1.0/?
4. O nome  Planejamento Atualizacao esta bom ou prefere outro?
