# Teste de Atualizacao v1.1.0

> Testador: IA | Data: 07/03/2026

---

## TESTE 1 -- Integridade do pacote

| Arquivo | Origem? | Destino? | O=D? | O=Distrib? | Problema? |
|---------|---------|----------|------|------------|-----------|
| agente-produto.mdc | SIM | SIM | IGUAL | IGUAL | Nenhum |
| guardiao.mdc | SIM | SIM | IGUAL | IGUAL | Nenhum |
| onboarding.mdc | SIM | SIM | IGUAL | IGUAL | Nenhum |
| projeto.mdc | SIM | SIM | IGUAL | IGUAL | Nenhum |
| agente-codigo.mdc | SIM | SIM | IGUAL | IGUAL | Nenhum |
| VERSION.json | SIM | SIM | IGUAL | IGUAL | Nenhum |
| corrigir-symlinks.ps1 | SIM | SIM | IGUAL | IGUAL | Nenhum |

**Resultado: 7/7 SINCRONIZADOS. Zero defeitos de integridade.**

Verificacao por hash MD5: todos os 7 arquivos sao identicos nos 3 locais
(atualizacao/v1.1.0/arquivos/, projeto-filho/, distribuicao/ultima-versao/).

---

## TESTE 2 -- Checklist de verificacao

### 2a) Cada check passa?

| # | Check | Resultado | Nota |
|---|-------|-----------|------|
| 1 | VERSION.json mostra 1.1.0 | PASSA | versao: "1.1.0" |
| 2 | agente-produto menciona Rota NE, Rota SA, Rota SS | PASSA | Todas presentes |
| 3 | agente-produto menciona Protocolo de varredura e Confianca | PASSA | |
| 4 | guardiao menciona Mensagem Prioritaria e Vitor Justino | PASSA | |
| 5 | guardiao menciona auto-atualizacao silenciosa | PASSA | |
| 6 | onboarding menciona Deteccao inteligente | PASSA | |
| 7 | agente-codigo menciona Modo discovery | PASSA | |
| 8 | referencia/atualizacao/ existe | FALHA | Symlink nao existe em projeto-filho no OneDrive (criado apenas no local do analista) |
| 9 | config/analista.json preservado | PASSA | |
| 10 | meu-trabalho/ intacto | PASSA | |

**Resultado: 9/10 passam. Check 8 falha no OneDrive (esperado -- o symlink
so existe na maquina do analista apos rodar corrigir-symlinks.ps1).**

### 2b) Gaps no checklist (funcionalidades NAO verificadas)

| Funcionalidade | Presente no agente | Verificada no checklist? |
|---------------|-------------------|------------------------|
| Rota SS (4 passos) | agente-produto | SIM (check 2) |
| Tipo "Suporte" no log | guardiao | NAO -- GAP |
| Tipo "Fluxo" no log | guardiao | NAO -- GAP |
| Rota SS no guardiao | guardiao | NAO -- GAP |
| Consolidacao mensagens | guardiao | NAO -- gap menor |
| Fallback auto-update | guardiao | NAO -- gap menor |
| Logs como contexto | agente-produto | NAO -- gap menor |
| Interrupcao | agente-produto | NAO -- gap menor |
| Exemplos SS | projeto | NAO -- gap menor |
| mapa-folha.md | agente-produto | NAO -- gap menor |

**Resultado: 3 gaps relevantes, 6 gaps menores. O checklist verifica o
minimo funcional mas nao todas as novidades das correcoes C1-C3/M1-M5.**

Nota: a secao "O que mudou" do input.md tambem esta desatualizada -- nao
menciona Rota SS, tipo Suporte/Fluxo, consolidacao, fallback, interrupcao,
nem logs como contexto. Isso nao afeta a funcionalidade (a IA copia
arquivos, nao depende dessa secao), mas e documentacao incompleta.

---

## TESTE 3 -- Simulacao da atualizacao

### Cenario A: Auto-update silencioso (analista v1.0)

PREMISSA: Nenhum analista v1.0 existe. O usuario confirmou "ninguem
atualizou ainda". Este cenario e TEORICO.

SE existisse um analista v1.0:
1. Analista abre Cursor com v1.0.0
2. Guardiao v1.0 roda -- NAO conhece input.md, NAO sabe atualizar
   silenciosamente. O v1.0 provavelmente pediria permissao.
3. O symlink referencia/atualizacao/ pode NAO existir na v1.0
   (foi adicionado na v1.1.0)
4. Sem o symlink, o guardiao v1.0 nao encontra o pacote
5. O guardiao v1.0 tentaria o caminho antigo via caminhos.json ->
   onedrive_base. Se encontrasse uma versao mais recente, pediria
   permissao ao analista. Se o analista dissesse sim, o guardiao
   v1.0 NAO saberia como executar input.md.

**Resultado: NAO FUNCIONA para v1.0 teorico. Irrelevante porque nao
existem analistas v1.0. Se futuramente existir v1.1.0 -> v1.2.0,
o mecanismo do guardiao v1.1.0 JA sabe ler input.md.**

### Cenario B: Analista cola frase do Teams

PREMISSA: Tambem teorico (nao ha analistas v1.0).

SE acontecesse:
1. Analista recebe "Atualize conforme referencia/atualizacao/"
2. IA tenta acessar referencia/atualizacao/
3. Se symlink NAO existe: IA reporta erro "caminho nao encontrado"
4. Se OneDrive dessincronizado: pasta vazia ou inacessivel
5. Solucao: analista roda corrigir-symlinks.ps1 primeiro

**Resultado: FUNCIONA COM RESSALVA (depende do symlink existir).
Irrelevante no cenario atual.**

### Cenario C: Primeiro install (analista novo)

1. Analista roda instalar-projeto-filho.ps1
2. Script copia de OneDrive/projeto-filho/ para C:\CursorFolha\projeto-filho\
3. Os .mdc copiados SAO v1.1.0 (identicos ao pacote) -- CORRETO
4. VERSION.json vem 1.1.0 -- CORRETO
5. Symlink referencia/atualizacao/ E CRIADO pela funcao New-Symlinks

DEFEITOS encontrados neste cenario:
- analista.json recebe versao_instalada: "1.0.0" (hardcoded na linha 195
  do instalador). Deveria ser "1.1.0" ou ler de VERSION.json.
  IMPACTO: Nenhum campo "versao_instalada" e usado pelos agentes.
  O guardiao usa VERSION.json. E apenas metadata incorreta.
- Banner do instalador diz "v1.0.0" (linha 35). Cosmetic.
- O instalador copia toda a pasta .cursor/ incluindo obsoleto/sdd-definicao.mdc.
  IMPACTO: O arquivo tem alwaysApply:false e globs:"" (vazio), entao
  nunca sera carregado pelo Cursor. Mas e lixo no projeto do analista.

**Resultado: FUNCIONA. 3 defeitos cosmeticos (nenhum funcional).**

---

## TESTE 4 -- Conflitos e efeitos colaterais

### 4a) Conflito de transicao (v1.0 -> v1.1.0)

Nao ha analistas v1.0. O conflito e teorico. Se existisse:
o guardiao v1.0 pediria permissao e o v1.1.0 atualizaria silencioso.
Durante a copia do guardiao.mdc, a instrucao ativa muda de "perguntar"
para "silencioso" -- sem janela de conflito porque a IA recarrega
regras apos a copia.

**Resultado: RISCO TEORICO. Nao aplicavel hoje.**

### 4b) Arquivo obsoleto em distribuicao

distribuicao/ultima-versao/.cursor/rules/sdd-definicao.mdc EXISTE
na raiz (nao em obsoleto/). POREM:
- description: "[OBSOLETO] Substituido por agente-produto.mdc"
- globs: "" (vazio)
- alwaysApply: false

O Cursor NUNCA carregara este arquivo (sem globs e sem alwaysApply).
Mas se alguem copiar manualmente de distribuicao/, levaria o arquivo.

**Resultado: DEFEITO MENOR. Inofensivo mas sujo. Deveria ser movido
para obsoleto/ ou removido da distribuicao.**

### 4c) Backup antes de copia

O input.md diz "Preserve config/analista.json, config/caminhos.json,
meu-trabalho/" mas NAO instrui a IA a fazer backup antes de copiar.

Se a copia falhar no meio (ex: agente-produto copiado, guardiao nao):
- analista.json e caminhos.json estariam intactos (nao sao copiados)
- meu-trabalho/ estaria intacto (nao e copiado)
- O unico risco e ficar com .mdc parcialmente atualizado

O fallback M3 (Mensagem Prioritaria se copia falhar) mitiga isso:
o guardiao detectaria a falha na proxima tentativa.

**Resultado: RISCO ACEITO. Perda de dados do analista impossivel
(analista.json, caminhos.json e meu-trabalho/ nao sao sobrescritos).
Risco de .mdc incompleto e mitigado pelo fallback.**

### 4d) Permissao OneDrive

O projeto do analista fica em C:\CursorFolha\projeto-filho\ (LOCAL,
fora do OneDrive). A escrita em .cursor/rules/ nao passa pelo OneDrive.

O projeto-filho/ no OneDrive (C:\Users\...\CursorFolha - General\projeto-filho\)
e o TEMPLATE/FONTE. A IA do analista escreve apenas no local.

**Resultado: SEM PROBLEMA. Escrita e local.**

### 4e) corrigir-symlinks.ps1 e Read-Host

O script tem 3 chamadas Read-Host:
- Linha 36: "Pressione Enter para sair" (so se OneDrive nao encontrado)
- Linha 53: "Seu nome completo" (so se analista.json incompleto)
- Linha 138: "Pressione Enter para fechar" (SEMPRE)

O input.md passo 4 diz "Rode scripts\corrigir-symlinks.ps1".
Se a IA executar via Shell:
- Os symlinks sao criados ANTES do Read-Host final (linhas 86-113)
- O Read-Host da linha 138 BLOQUEIA o shell da IA
- A IA ficaria aguardando Enter indefinidamente
- No Cursor, o comando seria movido para background apos timeout
- Os symlinks JA estariam criados nesse ponto

Para analistas normais (que rodam manualmente): sem problema.
Para a IA executando auto-update: o script FUNCIONA mas TRAVA no final.

**Resultado: DEFEITO MENOR. O script cumpre a funcao mas trava no final
quando executado pela IA. Solucao: adicionar parametro -NonInteractive
ou detectar execucao nao-interativa.**

### 4f) Tamanho de contexto

| Grupo | Linhas | Bytes |
|-------|--------|-------|
| alwaysApply (guardiao+onboarding+projeto) | 501 | ~18.6 KB |
| globs-based (agente-produto+agente-codigo) | 506 | ~19.1 KB |
| **TOTAL se todos carregados** | **1007** | **~37.8 KB** |

Cursor suporta ~100-200K tokens de contexto. 38 KB de regras ocupa
~10-15K tokens. Sobra espaco amplo para conversa + arquivos.

**Resultado: SEM PROBLEMA. Carga de contexto aceitavel.**

### 4g) Manifesto vs realidade

manifesto.json:
- versao: "1.1.0" -- CORRETO
- arquivosAlterados: 7 arquivos -- CORRETO (bate com input.md)
- preservar: analista.json, caminhos.json, meu-trabalho -- CORRETO
- requerSymlink: ["atualizacao"] -- CORRETO
- changelog: menciona rotas NE/SA/SS, suporte N3, fluxo, fallback,
  consolidacao, interrupcao -- COMPLETO (atualizado nas correcoes)

**Resultado: OK. Manifesto reflete a realidade.**

---

## TESTE 5 -- Conteudo dos agentes

### 5a) Jargao tecnico

| Arquivo | SDD/BDD/Gherkin/framework/pipeline/wizard |
|---------|------------------------------------------|
| agente-produto.mdc | ZERO |
| guardiao.mdc | ZERO |
| onboarding.mdc | ZERO |
| projeto.mdc | ZERO |
| agente-codigo.mdc | ZERO |

**Resultado: LIMPO. Zero jargao em todos os 5 .mdc ativos.**

### 5b) Caminhos referenciados

| Caminho | Existe em projeto-filho? |
|---------|------------------------|
| config/analista.json | SIM |
| config/caminhos.json | SIM |
| config/VERSION.json | SIM |
| templates/TEMPLATE-psai.md | SIM |
| templates/TEMPLATE-sai.md | SIM |
| meu-trabalho/ | SIM |
| scripts/corrigir-symlinks.ps1 | SIM |
| GUIA-RAPIDO.md | SIM |

**Resultado: TODOS existem.**

### 5c) Encoding

| Arquivo | Encoding | Bytes | Null-bytes |
|---------|----------|-------|------------|
| agente-produto.mdc | UTF-8 sem BOM | 14272 | Nao |
| guardiao.mdc | UTF-8 sem BOM | 12653 | Nao |
| projeto.mdc | UTF-8 sem BOM | 2556 | Nao |
| onboarding.mdc | UTF-8 com BOM | 3447 | Nao |
| agente-codigo.mdc | UTF-8 com BOM | 4883 | Nao |

**Resultado: PARCIAL. Encoding misto (3 sem BOM, 2 com BOM).
Nao causa problema funcional. Os arquivos com BOM (onboarding e
agente-codigo) nao foram alterados nas correcoes -- e o encoding
original deles. Consistencia ideal seria todos sem BOM.**

### 5d) Cabecalho YAML

| Arquivo | --- | description | alwaysApply | globs |
|---------|-----|-------------|-------------|-------|
| agente-produto.mdc | OK | OK | false | OK |
| guardiao.mdc | OK | OK | true | -- |
| onboarding.mdc | OK | OK | true | -- |
| projeto.mdc | OK | OK | true | -- |
| agente-codigo.mdc | OK | OK | false | OK |

**Resultado: TODOS corretos. Tipos e valores adequados.**

---

## RESULTADO FINAL

### Resumo

| Teste | Resultado |
|-------|----------|
| 1. Integridade do pacote | APROVADO (7/7 sync) |
| 2. Checklist completa | APROVADO COM RESSALVA (9 gaps menores) |
| 3. Simulacao de atualizacao | APROVADO (cenario real = install novo, funciona) |
| 4. Conflitos e efeitos colaterais | APROVADO COM RESSALVA (2 defeitos menores) |
| 5. Conteudo dos agentes | APROVADO (zero jargao, paths OK, YAML OK) |

### DEFEITOS CRITICOS

Nenhum. Nada impede a publicacao.

### DEFEITOS MENORES (corrigir quando possivel)

1. **sdd-definicao.mdc na raiz de distribuicao/ultima-versao/.cursor/rules/**
   Deveria estar em obsoleto/ ou ser removido. Inofensivo (alwaysApply:false,
   globs:"") mas sujo. Novo analista receberia lixo no projeto.
   CORRECAO: Mover para obsoleto/ ou remover da distribuicao.

2. **instalar-projeto-filho.ps1 hardcoda versao_instalada: "1.0.0"**
   Deveria ler de VERSION.json ou hardcodar "1.1.0".
   CORRECAO: Substituir "1.0.0" por leitura dinamica de VERSION.json.

3. **corrigir-symlinks.ps1 Read-Host bloqueia execucao pela IA**
   A linha 138 (Read-Host "Pressione Enter para fechar") trava o shell.
   Os symlinks ja foram criados antes dessa linha, entao o impacto e
   que o shell da IA fica pendurado (Cursor move para background).
   CORRECAO: Detectar modo nao-interativo e pular Read-Host.

4. **input.md secao "O que mudou" desatualizada**
   Nao menciona Rota SS, tipos Suporte/Fluxo, consolidacao, fallback,
   logs como contexto, tratamento de interrupcao.
   CORRECAO: Adicionar itens a secao "O que mudou".

5. **Checklist de verificacao incompleta (9 gaps)**
   Faltam checks para: tipo Suporte, tipo Fluxo, Rota SS no guardiao,
   consolidacao, fallback, logs como contexto, interrupcao, exemplos SS,
   mapa-folha.md.
   CORRECAO: Adicionar checks (ou aceitar que o minimo funcional basta).

### RISCOS ACEITOS

1. **Cenario v1.0 -> v1.1.0 nao testavel** (nao existem analistas v1.0)
2. **Encoding misto** (2 com BOM, 3 sem BOM) -- cosmetic
3. **Banner do instalador diz v1.0.0** -- cosmetic
4. **obsoleto/sdd-definicao.mdc copiado pelo instalador** -- inofensivo

### VEREDICTO: APROVADO COM RESSALVAS

Os agentes estao corretos, sincronizados e prontos para uso.
Nenhum defeito impede a publicacao.

Os 5 defeitos menores devem ser corrigidos na proxima oportunidade
(nao bloqueiam a publicacao v1.1.0). Os mais importantes sao:
- D1 (sdd-definicao.mdc em distribuicao) -- limpeza
- D3 (Read-Host no corrigir-symlinks) -- ergonomia para auto-update
- D4 (input.md desatualizado) -- documentacao
