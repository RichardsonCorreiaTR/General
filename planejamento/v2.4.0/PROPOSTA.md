# Proposta v2.4.0 — Consolidação, Resiliência e Clareza

> **Status**: RASCUNHO — aguardando revisão do Gerente e validação do Cursor
>
> **Escopo**: Projeto Admin (v2.3 → v2.4) + Projeto Filho (v1.2.0 → v1.3.0)
>
> **Motivação**: Diagnóstico de redundâncias nas regras .mdc, riscos de falha
> identificados e oportunidades de melhoria na experiência do analista.
>
> **Como usar este arquivo com o Cursor**:
> Abra o projeto Admin no Cursor e diga:
> *"Leia planejamento/v2.4.0/PROPOSTA.md e avalie cada proposta contra
> as regras .mdc atuais. Identifique riscos, conflitos ou melhorias na proposta."*

---

## 1. Contexto

Diagnóstico realizado em 2026-03-19 identificou três categorias de problema:

| Categoria | Quantidade | Impacto |
|---|---|---|
| Redundâncias em regras .mdc | 6 ocorrências | IA inconsistente entre chats |
| Riscos de falha sem recuperação | 7 riscos | Analista trava, gerente vira suporte |
| Lacunas de workflow | 4 gaps | Trabalho cai entre as rachaduras |

---

## 2. Riscos Identificados e Resolução

### R1 — Symlink quebrado bloqueia 100% do analista

**Situação atual**: Se `referencia/banco-dados/` está inacessível (OneDrive lento,
sync parcial, rede instável), o guardião emite Mensagem Prioritária e para.
O analista fica sem nenhuma saída até o gerente intervir.

**Resolução proposta**:
- Adicionar "modo offline" no `guardiao.mdc` do filho:
  - Se symlink falhar, verificar se existe cache local em `meu-trabalho/cache-offline/`
  - Se cache existir (mesmo que desatualizado), continuar com aviso de data
  - Se não existir, emitir Mensagem Prioritária MAS sugerir ações concretas:
    *"Tente: (1) abrir o OneDrive e aguardar sync, (2) reiniciar o Cursor,
    (3) acione o gerente."*
- **Quem popula o cache**: o guardião cria/atualiza o snapshot em
  `meu-trabalho/cache-offline/` toda vez que o symlink estiver acessível
  na inicialização — automaticamente, sem ação do analista. O script
  `atualizar-projeto.ps1` também regenera o cache ao final de cada atualização.
- **Escopo do cache**: apenas os **índices leves** (`indices/modulos/`,
  `indices/rubricas/`, etc.) — nunca os dados brutos (`dados-brutos/`).
  Copiar dados brutos recriaria o problema de OOM que o cache visa contornar.
  O cache deve ser suficiente para o guardião inicializar e orientar o analista,
  não para processar dados completos.
- Adicionar verificação no `guardiao.mdc` admin: orientar gerente a rodar
  `scripts/verificar-saude.ps1` (novo) quando analista reportar bloqueio.

**Arquivos afetados**: `projeto-filho/.cursor/rules/guardiao.mdc`

---

### R2 — Task JSON corrompida causa falha silenciosa

**Situação atual**: Se o Cursor for fechado no meio de uma escrita de task,
o JSON fica truncado. Na próxima sessão, o guardião tenta ler e falha — o
analista acha que o agente "esqueceu" o trabalho sem explicação.

**Resolução proposta**:
- No guardião do filho, verificação 5 (tasks em andamento) passa a:
  1. Tentar parsear cada JSON de task — **ignorar arquivos `.corrupted.json`** (já processados)
  2. Se parse falhar, renomear para `{nome}.corrupted.json`
  3. Informar o analista: *"Task NE-1234 estava corrompida e foi arquivada.
     Você precisa retomar manualmente a partir dos artefatos."*
  4. Listar os artefatos disponíveis em `meu-trabalho/` relacionados
- Princípio: nunca crashar silenciosamente; sempre orientar a próxima ação.

**Arquivos afetados**: `projeto-filho/.cursor/rules/guardiao.mdc`

---

### R3 — VERSION.json inconsistente após atualização interrompida

**Situação atual**: Se `gerar-atualizacao.ps1` for interrompido após atualizar
`VERSION.json` mas antes de copiar os arquivos, a versão fica declarada como
"atual" mas os arquivos são da versão anterior. O guardião não re-aplica a
atualização porque acha que já está na versão correta.

**Resolução proposta**:
- Adicionar campo `hash_validacao` no `VERSION.json` (hash MD5 de um arquivo
  `.mdc` principal, ex: `guardiao.mdc`) — mais confiável que timestamp, pois
  o OneDrive pode alterar datas de arquivos ao sincronizar
- Guardião compara o hash atual do `guardiao.mdc` com `hash_validacao` do
  `VERSION.json`; se divergirem, emite alerta:
  *"Versão declarada como 1.3.0 mas arquivos de regras parecem desatualizados.
  Tente rodar a atualização novamente ou acione o gerente."*
- Em `gerar-atualizacao.ps1`: gravar `VERSION.json` **somente ao final**,
  após todos os arquivos copiados com sucesso (atômico), usando `try/finally`
  explícito para garantir que Ctrl+C não deixe estado inconsistente.

**Arquivos afetados**: `scripts/gerar-atualizacao.ps1`,
`projeto-filho/.cursor/rules/guardiao.mdc`, `templates/TEMPLATE-version.json` (novo)

---

### R4 — Colisão de timestamp nos logs

**Situação atual**: Formato `## HH:MM - [Tipo]` nos logs diários. Se dois
eventos ocorrem no mesmo minuto (comum em consultas rápidas), o log fica
ambíguo ou com entradas aparentemente duplicadas.

**Resolução proposta**:
- Alterar formato para `## HH:MM:SS - [Tipo]` nos logs do filho
- Atualizar instrução de log no `guardiao.mdc` do filho (seção de logging)
- Retrocompatível: logs antigos com `HH:MM` continuam legíveis, apenas
  novos logs usam `HH:MM:SS`

**Arquivos afetados**: `projeto-filho/.cursor/rules/guardiao.mdc`

---

### R5 — .cursorignore editado acidentalmente causa OOM

**Situação atual**: A proteção contra OOM dos 165 MB de JSON depende
inteiramente de uma linha no `.cursorignore`. Qualquer edição acidental
(ex: analista tentando "limpar" o arquivo) pode causar OOM e travar o Cursor.

**Resolução proposta**:
- **Camada 1 — IA** (guardião): verificar se `.cursorignore` contém
  `banco-dados/dados-brutos` na inicialização. Se não contiver, emitir
  **Mensagem Prioritária imediata** antes de qualquer outra ação:
  *"CRÍTICO: .cursorignore não protege dados-brutos/. NÃO prossiga.
  Reinsira a linha `banco-dados/dados-brutos` no arquivo e reinicie o Cursor."*
  Ler `.cursorignore` é seguro — arquivo tipicamente < 50 linhas, sem risco de OOM.
- **Camada 2 — Script** (mais confiável): adicionar a mesma verificação ao
  `verificar-saude.ps1` — lê o `.cursorignore` real via PowerShell e alerta
  o gerente se a proteção estiver ausente. A regra no `.mdc` é instrução para
  a IA; o script é a verificação garantida.
- Marcar `.cursorignore` como arquivo protegido na regra `arquitetura.mdc` do admin.
  **Nota**: `arquitetura.mdc` não existe atualmente — será criado na v2.4.0
  como parte desta proposta.

**Arquivos afetados**: `projeto-filho/.cursor/rules/guardiao.mdc`,
`.cursor/rules/arquitetura.mdc` (novo na v2.4.0),
`scripts/verificar-saude.ps1` (novo)

---

### R6 — buscar-sai.ps1 retornando +1000 resultados sem protocolo

**Situação atual**: O `agente-produto.mdc` tem protocolo de varredura com
14 campos mas não orienta o que fazer quando o script retorna volume massivo.
A IA pode tentar processar tudo e estourar o contexto.

**Resolução proposta**:
- Adicionar ao `agente-produto.mdc`, antes da execução da busca:
  *"Use o parâmetro `-Max 50` no `buscar-sai.ps1` para limitar resultados.
  Se ainda retornar próximo de 50, refine com `-Modulo`, `-Rubrica` ou `-DataDe`
  antes de processar. Nunca processe mais de 50 resultados de uma vez."*
  **Nota**: o `-Max` já existe no script — a regra referencia o parâmetro real,
  não cria lógica paralela.
- Adicionar ao `agente-codigo.mdc` mesma orientação para buscas no código-fonte.

**Arquivos afetados**: `projeto-filho/.cursor/rules/agente-produto.mdc`,
`projeto-filho/.cursor/rules/agente-codigo.mdc`

---

### R7 — Atualização rodando com OneDrive fora de sync

**Situação atual**: O script `atualizar-projeto.ps1` roda sem verificar se o
OneDrive está sincronizado. Se o analista executa a atualização enquanto o
OneDrive ainda está sincronizando (ícone girando ou com `X`), os arquivos
copiados podem estar desatualizados ou incompletos — e o analista não recebe
nenhum aviso.

**Resolução proposta**:
- Adicionar verificação de sync no início de `atualizar-projeto.ps1`:
  1. Verificar se os arquivos do pacote têm extensões temporárias (`.tmp`, prefixo `~`)
     ou se o arquivo-chave do pacote (`VERSION.json`) é legível e parseável —
     indicadores mais confiáveis que o processo `OneDrive.exe` (que roda mesmo
     com arquivos já sincronizados)
  2. Se sync em andamento ou não concluído:
     - Exibir aviso claro com ícone de alerta
     - Oferecer opções: **(R) Retry agora** | **(A) Aguardar 3 min e tentar** | **(S) Sair**
     - Se ainda falhar após retry, exibir **Mensagem de Escalação** (ver abaixo)
  3. Se sync OK: prosseguir normalmente

**Mensagem de Escalação para o Analista**:
```
========================================================
  ATUALIZAÇÃO BLOQUEADA — OneDrive não sincronizado
========================================================

Por favor, acione o Gerente Vitor Justino e informe:

--- COPIE A MENSAGEM ABAIXO ---

Vitor, tentei rodar a atualização do projeto mas o OneDrive
não estava sincronizado. Segue o que aconteceu:

- Script executado : atualizar-projeto.ps1
- Versão tentada   : v[VERSÃO_EXIBIDA]
- Status OneDrive  : [STATUS_DETECTADO]
- Data/hora        : [TIMESTAMP_AUTO]
- Tentativas feitas: [N] tentativas com intervalo de 3 min

Ações que já fiz:
  [x] Aguardei o OneDrive sincronizar
  [x] Cliquei em Retry
  [x] OneDrive ainda não sincronizou

--- FIM DA MENSAGEM ---

Vitor usará essa mensagem com a IA para diagnosticar.
========================================================
```

- Os campos entre `[colchetes]` são preenchidos automaticamente pelo script.
- Princípio: o analista nunca fica sem saber o próximo passo.

**Arquivos afetados**: `scripts/atualizar-projeto.ps1`

---

## 3. Melhorias de Qualidade

### M1 — Deduplicar regras .mdc redundantes

**Problema**: Naming conventions, proteção OOM e contexto do projeto aparecem
em 3+ arquivos diferentes com redações ligeiramente distintas. A IA pode
seguir versões diferentes dependendo do contexto carregado.

> **Conflitos reais identificados pelo Cursor (Rodada 3)**:
> Convenções de nomenclatura estão definidas em **4 lugares**:
> - `naming-conventions.mdc` (Admin, `alwaysApply: false`, `globs: "**/*.md"`)
> - `architecture.mdc` do Admin (linhas 29-41)
> - `guardiao.mdc` do filho (linhas 174-180)
> - `agente-produto.mdc` do filho (linhas 479-484)
>
> **Ação obrigatória ao implementar**: remover as seções das linhas acima
> do `guardiao.mdc` e `agente-produto.mdc` do filho ao criar `padroes.mdc`.
> No Admin, decidir se `naming-conventions.mdc` é absorvido ou mantido separado.
> Se coexistirem no mesmo projeto com `alwaysApply: true`, a IA recebe
> dois conjuntos de regras de nomenclatura simultaneamente.

**Proposta**:
- Criar `projeto-filho/.cursor/rules/padroes.mdc` como fonte única para:
  - Convenções de nomenclatura (PSAI/SAI/NE/SA/SS)
  - Regras de formatação de arquivos
  - Limites de tamanho (300 linhas/definição, 100 linhas/regra .mdc)
- `padroes.mdc` deve ter **`alwaysApply: true`** para que a IA o carregue em
  todos os contextos. Comentários `// Ver padroes.mdc` funcionam como nota
  humana, mas não fazem a IA carregar o arquivo automaticamente.
- Remover duplicatas do `guardiao.mdc` do filho (linhas 174-180) e
  `agente-produto.mdc` (linhas 479-484) — reduz guardião de ~351 para ~200 linhas

**Arquivos afetados**: Novo `projeto-filho/.cursor/rules/padroes.mdc`,
`projeto-filho/.cursor/rules/guardiao.mdc` (remover linhas 174-180),
`projeto-filho/.cursor/rules/agente-produto.mdc` (remover linhas 479-484)

---

### M2 — Quebrar agente-produto.mdc (492 linhas → 3 arquivos)

**Problema**: 492 linhas carregadas em todo chat do analista, independente
da rota que ele vai seguir. Rotas NE (5 passos) e SA (6 passos) e SS (4 passos)
têm pouca sobreposição e não precisam estar no mesmo arquivo.

**Proposta**:
- `agente-produto.mdc` (~100 linhas): orquestrador, identifica a rota e delega
- `agente-rota-ne.mdc` (~120 linhas): rota NE completa (correção de erro)
- `agente-rota-sa.mdc` (~150 linhas): rota SA completa (funcionalidade nova)
- `agente-rota-ss.mdc` (~80 linhas): rota SS completa (suporte N3)
- Consulta rápida permanece no orquestrador

**Benefício**: Cursor carrega ~200 linhas por chat em vez de 492.
**Risco confirmado pelo Cursor (Rodada 3)**: Quando o orquestrador instrui
"siga as instruções de `agente-rota-sa.mdc`", o Cursor **não carrega
automaticamente** esse arquivo se ele tiver `alwaysApply: false` e nenhum
glob ativo. A IA vê a instrução mas não tem o conteúdo.

**Três alternativas — escolher na Fase 5 após o Teste Zero:**

| Opção | Como funciona | Confiabilidade | Trade-off |
|---|---|---|---|
| **A — Instrução explícita de leitura** | Orquestrador: "Leia `.cursor/rules/agente-rota-sa.mdc` e siga" | Alta (se IA interpretar como tool call) | +1 tool call por sessão, latência leve |
| **B — Seções delimitadas** | Manter tudo em `agente-produto.mdc`; orquestrador instrui "ignore seções que não se aplicam" | 100% confiável | Não reduz o tamanho do arquivo |
| **C — Globs por rota** | `agente-rota-sa.mdc` com `globs: "meu-trabalho/**"` | Alta (nativa) | Carrega todas as rotas simultaneamente |

> **Recomendação**: iniciar com opção **A** no Teste Zero. Se falhar em qualquer
> dos 3 chats de teste, adotar opção **B** como fallback seguro.

**Dependências identificadas pelo Cursor:**
- `guardiao.mdc` do filho referencia `agente-produto.mdc` por nome na **linha 148**
  — atualizar essa referência ao reestruturar
- Os globs atuais de `agente-produto.mdc` (`meu-trabalho/**,templates/**,referencia/**`)
  precisam ser redistribuídos: quais ficam no orquestrador vs. nas rotas

**Arquivos afetados**: `projeto-filho/.cursor/rules/agente-produto.mdc` (reestruturado),
`projeto-filho/.cursor/rules/guardiao.mdc` (linha 148),
novos `agente-rota-ne.mdc`, `agente-rota-sa.mdc`, `agente-rota-ss.mdc`

---

### M3 — Templates PSAI/SAI disponíveis no Admin

> **Validação concluída (Rodada 3)**: Templates **NÃO existem** em `templates/`
> do Admin. O Cursor confirmou que os arquivos em `distribuicao/` e `atualizacao/`
> são cópias para empacotamento — não acessíveis pelos agentes do Admin.
> **Implementação é necessária.**

**Problema**: `TEMPLATE-psai.md` e `TEMPLATE-sai.md` existem apenas em:
- `projeto-filho/templates/` (local do filho)
- `distribuicao/ultima-versao/templates/` (pacote de distribuição)
- `atualizacao/v1.2.0/arquivos/templates/` (pacote de atualização)

Nenhum deles está em `templates/` na raiz do Admin, onde o agente
SDD-Definição busca ao criar definições de RN.

**Proposta**: Copiar os arquivos do filho para `templates/` do Admin —
baixo esforço, baixo risco.

**Arquivos afetados**: `templates/TEMPLATE-psai.md` (novo no Admin, cópia de `projeto-filho/templates/`),
`templates/TEMPLATE-sai.md` (novo no Admin, cópia de `projeto-filho/templates/`)

---

### M4 — Feedback visual do sistema de tasks

**Problema**: Tasks são criadas/atualizadas silenciosamente. O analista não
sabe o estado real e não consegue distinguir "agente lembrou" de "agente não encontrou".

**Proposta**:
- Ao iniciar qualquer rota, o agente confirma explicitamente:
  *"Criando task para NE-1234. Vou rastrear seu progresso automaticamente."*
- Ao retomar, lista claramente o passo e os achados salvos:
  *"Retomando NE-1234 do passo 3/5. Achados anteriores: [resumo dos achados]"*
- Ao concluir, confirma: *"Task NE-1234 marcada como concluída. Artefatos em
  meu-trabalho/concluido/NE-1234/."*
- Sem mudança na lógica de tasks — apenas mensagens ao usuário mais explícitas.

**Arquivos afetados**: `projeto-filho/.cursor/rules/agente-produto.mdc`

---

### M5 — Visibilidade do fluxo de revisão

**Problema**: Definições em `revisao/pendente/` ficam invisíveis após o envio.
Gerente pode esquecer; analista não sabe se foi rejeitado silenciosamente.

**Proposta** (visibilidade apenas — sem cobrança de prazo ou metas):
- `sdd-revisao.mdc` do admin passa a incluir:
  *"Ao listar pendentes, sempre exibir data de envio e dias em aberto."*
- Comando de listagem via `revisar-definicao.ps1 -Acao listar` exibe datas
  — sem rótulos de ATRASADO ou PRAZO, apenas data informativa
- Analista pode consultar status da sua definição via chat no projeto filho
  (verificando `revisao/pendente/` via symlink)

**Arquivos afetados**: `.cursor/rules/sdd-revisao.mdc`,
`scripts/revisar-definicao.ps1`

---

### M6 — Task concluída ≠ SGD submetido (falso encerramento)

**Problema**: Quando o analista move a análise para `meu-trabalho/concluido/`,
a task é marcada como `concluida`. Mas a submissão real no SGD é manual e
externa ao Cursor. Se o analista esquecer, a task parece encerrada mas o
trabalho real não foi entregue.

**Proposta** (lembrete passivo — sem interrupção no fluxo de conclusão):
- Adicionar campo `sgd_submetido: false` no `TEMPLATE-task.json`
- Ao concluir uma task, o agente **não pergunta ativamente** — apenas registra
  `sgd_submetido: false` e segue
- Na **próxima inicialização**, o guardião lista passivamente:
  *"NE-1234: análise concluída, aguardando submissão no SGD."*
- Analista confirma quando quiser: *"submeti a NE-1234"* → guardião atualiza
  o campo para `true` e remove da lista
- Não bloqueia, não interrompe — apenas mantém visibilidade.

**Atenção (Rodada 3)**: O `guardiao.mdc` do filho precisará de uma **adição**:
a varredura atual lê apenas tasks com `status = em-andamento` (linhas 76-81).
Precisará também listar tasks com `status = concluido` E `sgd_submetido = false`.
Isso é uma adição, não um conflito — não altera o comportamento existente.

**Arquivos afetados**: `templates/TEMPLATE-task.json`,
`projeto-filho/.cursor/rules/agente-produto.mdc`,
`projeto-filho/.cursor/rules/guardiao.mdc` (adicionar varredura na linha ~81)

---

### M7 — Scripts sem documentação operacional

**Problema**: 27+ scripts PowerShell com interdependências não documentadas.
Se `atualizar-tudo.bat` falha no passo 3 de 6, não está claro o que foi
executado, o que não foi, se é seguro re-rodar, e o que fazer manualmente.
O gerente vira refém de quem escreveu os scripts.

**Proposta**:
- Criar `scripts/README.md` com tabela de cada script:
  - Propósito, parâmetros, saída esperada, modo de verificar sucesso
  - Dependências (quais scripts chamam quais)
  - O que fazer se falhar (recovery step por script)
  - Quando rodar manual vs. agendado
- Não altera nenhum script — apenas documenta o que já existe.

**Arquivos afetados**: `scripts/README.md` (novo)

---

### M8 — Mapeamento cruzado entre projetos Admin e Filho

**Problema**: O filho trabalha com rotas NE/SA/SS e gera PSAIs/SAIs.
O admin trabalha com RNs e fluxo de revisão. Não existe documentação de
como os dois se conectam: quem decide o que, onde o trabalho passa de um
para o outro, e o que acontece quando uma PSAI do filho revela uma RN
nova que precisa ir para o admin.

**Proposta**:
- Adicionar seção "Conexão Admin↔Filho" em `arquitetura/` (novo arquivo
  `arquitetura/fluxo-admin-filho.md`):
  - Diagrama: Demanda → Filho (PSAI/SAI) → Admin (revisao/) → banco-dados/
  - Tabela: qual artefato do filho mapeia para qual fluxo do admin
  - Regra: quando uma PSAI implica criação de RN nova → como escalar
- Referenciar esse arquivo em `sdd-revisao.mdc` e `agente-produto.mdc`

**Arquivos afetados**: `arquitetura/fluxo-admin-filho.md` (novo),
`.cursor/rules/sdd-revisao.mdc`,
`projeto-filho/.cursor/rules/agente-produto.mdc`

---

### M9 — Tamanhos de zonas OOM hardcoded ficam obsoletos

**Problema**: `protecao-oom.mdc` lista tamanhos como "~165 MB", "~19 MB".
Com novas importações de SAIs, esses números crescem. Em 6 meses, as
estimativas estarão erradas — e um analista pode achar que está seguro
quando não está.

**Proposta**:
- Substituir tamanhos fixos por referência ao `atualizacao/status.json`:
  *"Para o tamanho atual do cache, consulte `status.json` campo
  `registrosProcessados`. Não carregue `dados-brutos/` no Cursor
  independente do tamanho."*
- Adicionar ao `consolidar-logs.ps1` ou `atualizar-silencioso.ps1`:
  gravar o tamanho atual dos diretórios críticos em `status.json`
  para consulta posterior.
- A proteção de não carregar `dados-brutos/` não muda — só remove
  números que envelhecem.

**Arquivos afetados**: `.cursor/rules/protecao-oom.mdc`,
`scripts/atualizar-silencioso.ps1` (alteração menor)

---

### M10 — Checklist estratégico ao criar PSAI/SAI (rota SA)

**Problema**: O analista produz PSAIs e SAIs tecnicamente corretas mas sem
reflexão sobre impacto de negócio. Pontos como onboarding, redução de custo,
performance, jornada do cliente e proposta de valor ficam de fora da análise —
não por descuido, mas porque ninguém pediu para pensar nisso.

**Proposta**:
- Ao iniciar rota SA, antes de construir a PSAI, o agente apresenta as
  10 perguntas em **blocos de 3-4** — nem bloco único (ignorado) nem uma por uma
  (lento demais):

```
Bloco 1 de 3 — Valor e impacto
  1. Dor resolvida: Você consegue descrever claramente qual dor esse item
     resolve? Acredita que a solução proposta realmente a resolve?
  2. Onboarding: Essa entrega facilita a chegada de novos clientes ou
     a ativação de funcionalidades por clientes existentes?
  3. Suporte: Essa entrega pode reduzir chamados? Ou pode gerar novos
     chamados se algo não for bem explicado?

[Responda brevemente ou diga "ignorar" para pular este bloco]
```

```
Bloco 2 de 3 — Técnico e jornada
  4. Custo: Há oportunidade de reduzir custo — DW, Cloud, manutenções,
     integrações, licenças?
  5. Performance: Existe risco de degradar performance? O que foi
     considerado para mitigar?
  6. Jornada do cliente: A entrega se integra bem com Processos, Messenger,
     Portal do Cliente, Serviços Financeiros?

[Responda brevemente ou diga "ignorar" para pular este bloco]
```

```
Bloco 3 de 3 — Futuro e comunicação
  7. Observabilidade: Como vamos medir que isso funcionou?
  8. IA: Essa jornada poderia ser reimaginada com IA? Vale registrar.
  9. Cloud: Estamos prevenindo a necessidade de reconstruir em cloud?
 10. Proposta de valor: As áreas comerciais poderão usar isso para
     vender ou reter clientes?

[Responda brevemente ou diga "ignorar" para pular este bloco]
```

- **Fluxo**: as perguntas entram na **construção da PSAI**, não na finalização
  da SAI. O raciocínio estratégico molda a análise desde o início:
  1. Ao iniciar rota SA, antes de construir a PSAI, o agente apresenta as
     10 perguntas e dialoga sobre cada uma com o analista
  2. As respostas alimentam a seção "Análise Estratégica" da **PSAI**
  3. A SAI herda essa seção da PSAI — sem necessidade de repetir o exercício
  4. Se alguma resposta mudar entre PSAI e SAI, o agente pergunta ao concluir:
     *"Algum dos 10 pontos mudou com a análise? Quer atualizar?"*
- **Se o analista quiser ignorar**: ao responder "ignorar", "pular" ou "continuar"
  em qualquer ponto, o agente registra `[não avaliado pelo analista]` e segue.
- **Aplicação**:
  - Rota SA: obrigatório oferecer na construção da PSAI
  - Rota NE (correção de erro): opcional — oferecer apenas se a correção
    implica mudança de comportamento relevante para o cliente
  - Rota SS (suporte N3): não aplicar

**Benefício para o analista**: não precisa lembrar dessas perguntas —
o agente traz na hora certa, no contexto certo.

**Benefício para o gerente**: SAIs com análise estratégica embutida, rastreável.

**Arquivos afetados**: `projeto-filho/.cursor/rules/agente-produto.mdc`
(e `agente-rota-sa.mdc` se M2 for implementado)

---

### M11 — Atualização automática do código-fonte do sistema

**Contexto**: Na semana de 2026-03-23 será lançada uma nova versão do código-fonte
do sistema. O projeto filho depende desse código para análise. Hoje, substituir
o código-fonte é manual, sem validação e sem fallback — qualquer erro deixa o
analista sem base de trabalho.

**Problema**: Não existe script nem procedimento definido para:
- Substituir o código-fonte antigo pelo novo de forma segura
- Lidar com o caso em que o git não está disponível ou a rede não permite clone
- Garantir que o código ficou no lugar certo e está íntegro após a substituição

**Proposta — script `scripts/atualizar-codigo-fonte.ps1`**:

```
Modo 1 — Git Clone (automático, preferencial):
  1. Verifica se `config/codigo-fonte.json` existe — se não existir, aborta
     com instrução clara para o gerente configurar o arquivo primeiro
  2. Verifica espaço em disco disponível (mínimo 2x o tamanho estimado do repo)
     Se insuficiente, aborta com Mensagem de Escalação
  3. Recebe o link do GitHub como parâmetro (-UrlGit)
  4. Verifica se git está instalado e acessível
  5. Faz backup do código atual em pasta temporária (segurança)
  6. Remove o código antigo da pasta esperada pelo projeto
  7. Executa git clone com timeout de 5 min e flag de progresso visível
     Em redes corporativas com proxy, usa as configurações de proxy do sistema
  8. Verifica integridade mínima (pasta existe, arquivos essenciais presentes)
  9. Se OK: confirma ao usuário e remove backup temporário
 10. Se falhar: restaura backup automaticamente e exibe Mensagem de Escalação

Modo 2 — Fallback ZIP (se git falhar ou não estiver disponível):
  1. Procura arquivo .zip mais recente em pasta configurada do OneDrive
     (ex: OneDrive/.../atualizacoes-codigo/)
  2. Se encontrar:
     - Faz backup do código atual
     - Remove código antigo
     - Extrai .zip completo na pasta correta
     - Verifica integridade
     - Se OK: confirma e remove backup
     - Se falhar: restaura backup e exibe Mensagem de Escalação
  3. Se não encontrar .zip: exibe Mensagem de Escalação com instruções
```

**Mensagem de Escalação** (preenchida automaticamente pelo script):
```
========================================================
  ATUALIZAÇÃO DO CÓDIGO-FONTE FALHOU
========================================================

O código antigo foi restaurado — nada foi perdido.

Acione o Gerente Vitor Justino com:

--- COPIE A MENSAGEM ABAIXO ---

Vitor, a atualização do código-fonte falhou.

- Script       : atualizar-codigo-fonte.ps1
- Modo tentado : [GIT / ZIP]
- Erro         : [MENSAGEM_ERRO_AUTO]
- URL/Arquivo  : [URL_OU_ARQUIVO_TENTADO]
- Data/hora    : [TIMESTAMP_AUTO]
- Código atual : [PRESERVADO / RESTAURADO]

--- FIM DA MENSAGEM ---
========================================================
```

**Configuração** (`config/codigo-fonte.json`):
```json
{
  "pasta_destino": "referencia/codigo-fonte",
  "pasta_zip_onedrive": "C:/Users/.../OneDrive/.../atualizacoes-codigo/",
  "arquivos_essenciais": ["arquivo1.ext", "arquivo2.ext"]
}
```

**Segurança**:
- Nunca apaga o código antigo sem ter o novo validado primeiro
- Backup sempre antes de qualquer remoção
- Rollback automático se extração ou clone falhar

**Arquivos afetados**: `scripts/atualizar-codigo-fonte.ps1` (novo),
`config/codigo-fonte.json` (novo)

---

### M12 — Rastreabilidade de versão do código-fonte por analista

**Problema**: Após o M11 ser implementado, não há como saber se cada analista
rodou a atualização. O gerente não consegue confirmar que todos estão trabalhando
com o código-fonte correto sem perguntar individualmente.

**Proposta — duas camadas integradas**:

**Camada 1 — Visibilidade local (analista)**:
- M11 grava `config/codigo-fonte-version.json` após cada atualização bem-sucedida:
  ```json
  {
    "versao": "2.1.0",
    "atualizado_em": "2026-03-24T09:15:00",
    "metodo": "git-clone",
    "referencia": "https://github.com/.../commit/abc123"
  }
  ```
- Guardião do filho lê esse arquivo na inicialização e exibe:
  *"Código-fonte: v2.1.0 — atualizado em 24/03/2026 ✓"*
- Se o arquivo não existir ou a versão for anterior à esperada
  (definida em `config/codigo-fonte.json` campo `versao_minima`):
  *"ATENÇÃO: Código-fonte desatualizado (v1.9.0). Execute
  `scripts/atualizar-codigo-fonte.ps1` para atualizar."*

**Camada 2 — Log centralizado (gerente)**:
- Para evitar conflito de escrita concorrente no OneDrive (dois analistas
  gravando no mesmo CSV ao mesmo tempo), o script grava um **arquivo individual
  por analista** em vez de um CSV compartilhado:
  `atualizacoes-codigo/logs/[USUARIO]-[TIMESTAMP].json`
  ```json
  {
    "usuario": "joao.silva",
    "data_hora": "2026-03-24T09:15:00",
    "versao": "2.1.0",
    "metodo": "git-clone",
    "status": "OK"
  }
  ```
- Gerente pergunta à IA do Admin: *"Quem ainda não atualizou para v2.1.0?"*
  A IA lê os arquivos da pasta `logs/` e consolida a resposta.
- Sem conflito de sync — cada analista escreve apenas no próprio arquivo.

**Integração com R3**:
- `versao_minima` em `config/codigo-fonte.json` é atualizada pelo gerente
  ao publicar nova versão — guardião do filho usa esse campo para saber
  se o analista está desatualizado (mesmo mecanismo do VERSION.json do R3)

**Arquivos afetados**: `scripts/atualizar-codigo-fonte.ps1` (extensão do M11),
`projeto-filho/.cursor/rules/guardiao.mdc`,
`config/codigo-fonte.json` (campo `versao_minima`)

---

### M14 — Higiene de contexto: conflitos, obsolescência e bloat

**Problema**: A análise das regras `.mdc` revelou conflitos entre arquivos,
conteúdo obsoleto que ainda é carregado, e ~522 linhas de regras com
`alwaysApply: true` no projeto filho — quando ~200 seriam suficientes.
Isso degrada a qualidade das respostas da IA (instruções contraditórias)
e consome tokens desnecessariamente em cada interação.

**Diagnóstico — 3 categorias de problemas:**

**Categoria 1 — Conflitos entre regras**

| Conflito | Onde | Impacto |
|---|---|---|
| `onedrive-escrita.mdc` (Admin) diz "NUNCA use Write, SEMPRE PowerShell" — `guardiao.mdc` do filho não menciona essa restrição | Admin vs Filho | Alto — analista pode causar falha de sync OneDrive |
| `guardiao.mdc` diz "NUNCA modifique `.cursor/rules/`" mas o próprio guardião executa auto-update que modifica esses arquivos | Filho | Médio — lógica circular confunde a IA |
| `agente-produto.mdc` diz "tasks são silenciosas" mas `onboarding.mdc` busca evidência em `meu-trabalho/` sem checar `meu-trabalho/tasks/` | Filho | Baixo — funciona mas documentação é imprecisa |

**Resolução**:
- Propagar regra de escrita do `onedrive-escrita.mdc` para o `guardiao.mdc` do filho
  (o filho não tem acesso ao `.mdc` do Admin)
- Documentar exceção explícita no guardião: "NUNCA modifique `.cursor/rules/`
  **exceto durante auto-update silencioso do guardião (seção X)**"
- Corrigir `onboarding.mdc` para checar `meu-trabalho/tasks/` além de `meu-trabalho/`

**Categoria 2 — Conteúdo obsoleto**

| Item | Onde | Ação |
|---|---|---|
| `obsoleto/sdd-definicao.mdc` (15 linhas, "substituído por agente-produto") | Filho `.cursor/rules/obsoleto/` | Mover para fora de `.cursor/rules/` (ex: `arquitetura/obsoleto/`) — Cursor pode indexar qualquer coisa dentro de `.cursor/rules/` |
| `duvidas.mdc` — 4 perguntas abertas desde 2026-03-04 (16 dias sem resolução) | Admin `.cursor/rules/` | Resolver ou fechar formalmente cada pergunta. Se resolvidas, mover para `banco-dados/sdd-decisoes.md` como ADR |
| `analista.json` → `versao_instalada: "1.0.0"` | Filho `config/` | Corrigir para `1.2.0` no template distribuído. Adicionar validação no guardião: se `versao_instalada` < `VERSION.json.versao`, alertar |

**Categoria 3 — Context bloat (excesso de regras carregadas)**

| Arquivo | Linhas | alwaysApply | Problema | Ação proposta |
|---|---|---|---|---|
| `guardiao.mdc` (filho) | 351 | true | Maioria é lógica de "primeira interação" — carregada em TODA interação | Já endereçado parcialmente por M1 (reduz para ~200). Para redução adicional: extrair verificações de primeira interação para bloco condicional |
| `onboarding.mdc` (filho) | 96 | true | Carregado sempre, mas conteúdo é "primeira vez" | Trocar para `alwaysApply: false` com `globs: "config/analista.json"` — carrega apenas quando contexto de setup é relevante |
| `projeto.mdc` (filho) | 75 | true | Duplica 80% do PROJETO.md | Reduzir para ~15 linhas com referência: "Para contexto completo, leia PROJETO.md". Manter apenas o mínimo necessário para a IA se orientar |

**Impacto da redução**:
- Antes: ~522 linhas carregadas em todo chat (guardião 351 + onboarding 96 + projeto 75)
- Depois: ~230 linhas (guardião ~200 via M1 + onboarding 0 na maioria dos chats + projeto ~15 + padroes ~15)
- **Economia de ~56% de tokens de contexto por interação**

**Categoria extra — Redundância entre arquivos**

| Tópico | Onde aparece | Sobreposição | Ação |
|---|---|---|---|
| Regras de logging | `guardiao.mdc` (140 linhas) + `agente-produto.mdc` | ~70% idêntico | Centralizar em `padroes.mdc` (M1). Remover duplicata do `agente-produto.mdc` |
| "O que é o projeto" | `PROJETO.md` + `projeto.mdc` | ~80% | Reduzir `projeto.mdc` como proposto acima |

> **Nota**: A redundância de naming conventions (4 lugares) já está coberta por M1.
> As ações de M14 complementam M1 sem conflitar.

**Arquivos afetados**:
- `projeto-filho/.cursor/rules/guardiao.mdc` (resolver conflito de escrita + exceção auto-update)
- `projeto-filho/.cursor/rules/onboarding.mdc` (trocar alwaysApply + corrigir detecção tasks)
- `projeto-filho/.cursor/rules/projeto.mdc` (reduzir para ~15 linhas)
- `projeto-filho/.cursor/rules/obsoleto/sdd-definicao.mdc` (mover para fora de `.cursor/rules/`)
- `projeto-filho/config/analista.json` (corrigir versão template)
- `.cursor/rules/duvidas.mdc` (Admin — resolver ou fechar perguntas)

---

### M13 — Busca assertiva: resultados completos para o analista

**Problema**: Quando o analista pesquisa uma SAI/PSAI no Cursor, os resultados
vêm dos índices MD que truncam descrições em 80 caracteres. Os dados completos
(14 campos incluindo `comportamento`, `definição`, `textoCompleto`) estão em
`dados-brutos/` (JSON bloqueado no `.cursorignore` por proteção OOM). O script
`buscar-sai.ps1` faz busca profunda nesses 14 campos, mas o agente raramente
o executa automaticamente — o analista recebe resultados parciais sem saber
que são incompletos.

**Diagnóstico detalhado:**
- **Tier 1 (índices MD)**: Cursor lê direto — 80 chars por entrada, sem BLOBs
- **Tier 2 (dados brutos JSON)**: bloqueado no `.cursorignore` — causa OOM se lido direto
- **Bridge**: `buscar-sai.ps1` busca nos 14 campos sem OOM, retornando resultados filtrados
- **Lacuna**: regra no `agente-produto.mdc` (linha ~321) diz "SEMPRE faça busca profunda"
  mas como sugestão textual — o Cursor nem sempre interpreta como "rodar o script via Shell"

**Proposta — 6 sub-melhorias integradas:**

**P1 — Auto-escalation obrigatória** (prioridade alta)
Reescrever o protocolo de busca no `agente-produto.mdc` como regra inviolável
em 2 passos, não sugestão:
```
PROTOCOLO DE BUSCA (obrigatório, sem exceção):
Passo 1 — Índices: ler resumo-pendentes.md e módulos adjacentes
Passo 2 — Busca profunda: SEMPRE rodar via Shell:
  powershell -File "scripts/buscar-sai.ps1" -Termo "<termo>" -Max 20

NÃO apresente resultados ao analista até completar os 2 passos.
Se Passo 2 falhar (symlink, script não encontrado), avise explicitamente.
```
**Impacto**: Elimina resultado incompleto — analista sempre recebe dados dos 14 campos.

**P2 — Transparência de busca** (prioridade média)
Obrigar o agente a mostrar resumo de origem dos dados ao apresentar resultados:
```
Busca realizada:
  Índices MD: 8 resultados (descrições resumidas)
  Busca profunda (14 campos): 3 com match em "comportamento"
  Confiança: ALTA — dados completos disponíveis
```
**Impacto**: Analista sabe se o resultado é parcial ou completo.

**P3 — Índices enriquecidos (tier intermediário)** (prioridade alta)
Criar um nível intermediário entre os 80 chars e os BLOBs completos:
- ~300 caracteres de descrição + campos-chave separados
- Formato: `indices/enriquecidos/{modulo}.md`
- Conteúdo por entrada:
  ```markdown
  ## SAI-12345 | NE | eSocial | Pendente
  **Descrição**: Cálculo de INSS retroativo não considera competências anteriores
  ao início do vínculo quando há transferência entre filiais com convenções
  coletivas diferentes. O sistema aplica a alíquota da filial destino...
  **Comportamento-chave**: Calcula base sobre salário da filial atual, ignorando histórico
  **Módulos impactados**: eSocial, FGTS, DIRF
  **Severidade**: Alta
  ```
- Gerado por novo script `gerar-indices-enriquecidos.ps1`, executado no
  `gerar-atualizacao.ps1` como passo adicional
- Leve o suficiente para Cursor ler diretamente — sem risco de OOM
- Resolve ~80% dos casos sem precisar rodar busca profunda via Shell

**P4 — Flags inteligentes no agente** (prioridade média)
Quando o agente roda `buscar-sai.ps1`, usar flags contextuais em vez de só `-Termo`:
```
Regra de flags automáticos:
- Se analista está em rota NE → adicionar: -Tipo NE -Pendentes
- Se analista mencionou módulo → adicionar: -Modulo "<módulo>"
- Se analista pediu "histórico" ou "evolução" → adicionar: -VerPSAIs
- Se analista pediu SAI específica → usar: -SAI <número>
- Sempre usar: -Max 20 (proteger contra resultado gigante)
```
**Impacto**: Resultados mais precisos sem o analista conhecer os flags.

**P5 — Indicador de completude** (prioridade baixa)
Ao final de toda busca, mostrar checklist de fontes consultadas:
```
Completude da pesquisa:
  ✓ Índices consultados
  ✓ Busca profunda (14 campos)
  ✓ Regras de negócio do módulo
  ✗ Módulos adjacentes — quer que eu amplie?
  ✗ Histórico de PSAIs — use "mostre a evolução" para ver
```
**Impacto**: Analista vê o que falta e decide se aprofunda.

**P6 — Cache de busca profunda** (prioridade baixa)
Ao rodar `buscar-sai.ps1`, salvar resultado em `meu-trabalho/cache-busca/ultimo-resultado.md`.
Na próxima consulta sobre o mesmo tema, ler o cache antes de re-executar o script.
**Impacto**: Menos latência em buscas repetidas.

**Resumo de esforço vs impacto:**

| Sub-melhoria | Esforço | Impacto | Onde muda |
|---|---|---|---|
| P1 — Auto-escalation | Baixo (regra .mdc) | Alto | `agente-produto.mdc` |
| P2 — Transparência | Baixo (regra .mdc) | Médio | `agente-produto.mdc` |
| P3 — Índices enriquecidos | Médio (novo script) | Alto | Novo script + índices |
| P4 — Flags inteligentes | Baixo (regra .mdc) | Médio | `agente-produto.mdc` |
| P5 — Completude | Baixo (regra .mdc) | Baixo | `agente-produto.mdc` |
| P6 — Cache busca | Baixo (regra .mdc) | Baixo | `agente-produto.mdc` |

**Recomendação**: **P1 + P3 + P4** juntas resolvem o problema raiz.
P1 garante que a busca profunda sempre roda. P3 reduz a necessidade de rodar
o script na maioria dos casos. P4 faz o script retornar dados precisos quando roda.

**Arquivos afetados**:
- `projeto-filho/.cursor/rules/agente-produto.mdc` (P1, P2, P4, P5, P6 — reescrita do protocolo de busca)
- `scripts/gerar-indices-enriquecidos.ps1` (P3 — novo script)
- `scripts/gerar-atualizacao.ps1` (P3 — chamar o novo script como passo adicional)
- `projeto-filho/referencia/banco-dados/sais/indices/enriquecidos/` (P3 — nova pasta)
- `projeto-filho/meu-trabalho/cache-busca/` (P6 — nova pasta)

---

### M15 — Detecção de similaridade SAI/PSAI em tempo real

**Problema**: O sistema Folha é grande e os times são numerosos. É comum
existirem PSAIs e SAIs com escopos similares ou sobrepostos — analistas
diferentes trabalhando no mesmo módulo, com definições que se cruzam sem
que um saiba do trabalho do outro. Isso causa:
- **Retrabalho**: dois analistas definindo a mesma correção em paralelo
- **Definições cruzadas**: SAIs publicadas com escopos conflitantes que
  geram erros no código ou duplicidade no sistema
- **Falta de alinhamento**: analista descobre a sobreposição só na revisão
  (ou pior, no desenvolvimento)

**O problema é especialmente grave quando a PSAI/SAI similar:**
- Ainda não foi liberada (em análise ou pendente)
- É recente (criada nas últimas semanas)
- É do mesmo módulo ou módulos adjacentes

**Proposta — detecção automática integrada ao fluxo de análise:**

**Passo 1 — Busca de similares (automático)**
Quando o analista inicia análise de uma PSAI/SAI (rotas NE ou SA), o agente
roda `buscar-sai.ps1` com o termo da PSAI sendo analisada e com flags
contextuais (módulo, tipo). Compara os resultados contra a PSAI atual:
- Mesmo módulo + descrição com termos-chave em comum → candidata a similar
- Mesmo comportamento afetado → candidata a similar
- Status "em análise" ou "pendente" → **prioridade de alerta** (risco ativo)

**Passo 2 — Alerta contextualizado (não-bloqueante)**
Se encontrar similares, o agente apresenta:
```
Atenção — PSAIs/SAIs com escopo similar detectadas:

  SAI-12345 (Ana Lígia) — Liberada — "Cálculo retroativo INSS com transferência"
  PSAI-128900 (Camila) — Em análise — "INSS retroativo competência anterior"

  A PSAI-128900 está em análise e pode ter sobreposição com o seu trabalho.
  Recomendo alinhar com Camila antes de prosseguir para evitar:
  - Definição cruzada sem conhecimento mútuo
  - Retrabalho na mesma área do código

  Quer que eu detalhe as diferenças entre elas?
```

**Passo 3 — Registro na task (sempre)**
Independentemente de o analista querer aprofundar ou não, o agente registra
na task JSON:
```json
{
  "similares_detectadas": [
    {
      "codigo": "PSAI-128900",
      "responsavel": "Camila",
      "status": "em_analise",
      "similaridade": "mesmo módulo + comportamento retroativo"
    }
  ],
  "alinhamento_sugerido": true,
  "alinhamento_realizado": false
}
```
Se o analista confirmar que alinhou: `"alinhamento_realizado": true`.

**Passo 4 — Visibilidade para o gerente**
Na inicialização do Admin, ao revisar definições, o agente pode listar:
*"Existem 3 PSAIs em análise com sobreposição detectada e alinhamento
ainda não confirmado."*

**Quando NÃO alertar** (para evitar ruído):
- SAI já liberada + PSAI atual é correção da mesma (evolução natural)
- Similaridade é apenas de módulo sem sobreposição de comportamento
- Analista já confirmou alinhamento em sessão anterior

**Integração com M13**:
A busca do Passo 1 já é executada pelo M13/P1 (auto-escalation). O M15
apenas adiciona a **comparação contra a PSAI sendo analisada** e o
**alerta + registro**. Não duplica a busca.

**Arquivos afetados**:
- `projeto-filho/.cursor/rules/agente-produto.mdc` (regra de detecção no início de cada rota)
- `templates/TEMPLATE-task.json` (novos campos: `similares_detectadas`, `alinhamento_sugerido`, `alinhamento_realizado`)
- `projeto-filho/.cursor/rules/guardiao.mdc` (listar tasks com alinhamento pendente na inicialização)

---

## 4. Princípios de Design desta Versão

1. **Não bloquear sem orientar**: Toda Mensagem Prioritária deve incluir
   pelo menos uma ação concreta que o analista pode tomar sozinho.
2. **Fonte única de verdade**: Cada conceito definido em apenas um lugar.
   Demais arquivos referenciam, não duplicam.
3. **Falha visível, não silenciosa**: Corrupção, inconsistência e erro
   devem ser comunicados claramente, nunca ignorados.
4. **Retrocompatível**: Nenhum dado de analista perdido. Logs antigos
   continuam legíveis. Tasks existentes continuam funcionando.
5. **Menor contexto possível**: Cada regra .mdc deve conter apenas o que
   é necessário para aquela função específica.

---

## 5. Arquivos Afetados (Resumo)

### Projeto Filho (v1.2.0 → v1.3.0)

| Arquivo | Tipo | Motivo |
|---|---|---|
| `.cursor/rules/guardiao.mdc` | Alteração | R1, R2, R3, R4, R5, M14, M15 (listar alinhamentos pendentes) |
| `.cursor/rules/agente-produto.mdc` | Reestruturação + Alteração | R6, M2, M4, M10, M13 (P1/P2/P4/P5/P6), M15 |
| `.cursor/rules/agente-codigo.mdc` | Alteração menor | R6 |
| `.cursor/rules/padroes.mdc` | Novo | M1 |
| `.cursor/rules/agente-rota-ne.mdc` | Novo | M2 |
| `.cursor/rules/agente-rota-sa.mdc` | Novo | M2, M10 |
| `.cursor/rules/agente-rota-ss.mdc` | Novo | M2 |
| `templates/TEMPLATE-task.json` | Alteração (campos novos) | M6, M15 (similares_detectadas, alinhamento) |
| `config/VERSION.json` | Alteração (campo novo) | R3 |
| `config/analista.json` | Correção (versão template) | M14 |
| `.cursor/rules/onboarding.mdc` | Alteração (alwaysApply → false, corrigir detecção tasks) | M14 |
| `.cursor/rules/projeto.mdc` | Redução (~75 → ~15 linhas) | M14 |
| `.cursor/rules/obsoleto/sdd-definicao.mdc` | Mover para `arquitetura/obsoleto/` | M14 |
| `referencia/banco-dados/sais/indices/enriquecidos/` | Nova pasta | M13 (P3) |
| `meu-trabalho/cache-busca/` | Nova pasta | M13 (P6) |

### Projeto Admin → Distribuição (v2.3 → v2.4)

| Arquivo | Tipo | Motivo |
|---|---|---|
| `scripts/atualizar-projeto.ps1` | Alteração | R7 |
| `scripts/verificar-saude.ps1` | Novo | R1 |
| `scripts/atualizar-codigo-fonte.ps1` | Novo | M11, M12 |
| `scripts/gerar-indices-enriquecidos.ps1` | Novo | M13 (P3) |
| `config/codigo-fonte.json` | Novo | M11, M12 |
| `config/codigo-fonte-version.json` | Gerado pelo script | M12 |

### Projeto Admin (v2.3 → v2.4)

| Arquivo | Tipo | Motivo |
|---|---|---|
| `.cursor/rules/arquitetura.mdc` | Alteração menor | R5 |
| `.cursor/rules/sdd-revisao.mdc` | Alteração | M5, M8 |
| `.cursor/rules/protecao-oom.mdc` | Alteração menor | M9 |
| `scripts/gerar-atualizacao.ps1` | Alteração | R3, M13 (P3 — chamar gerar-indices-enriquecidos) |
| `scripts/revisar-definicao.ps1` | Alteração menor | M5 |
| `scripts/atualizar-silencioso.ps1` | Alteração menor | M9 |
| `scripts/README.md` | Novo | M7 |
| `templates/TEMPLATE-psai.md` | Novo (cópia para admin) | M3 revisado |
| `templates/TEMPLATE-sai.md` | Novo (cópia para admin) | M3 revisado |
| `arquitetura/fluxo-admin-filho.md` | Novo | M8 |
| `PROJETO.md` (seção 9) | Registro de versão | Versionamento |
| `banco-dados/sdd-decisoes.md` | Novos ADRs | Decisões desta versão + M14 (dúvidas resolvidas) |
| `.cursor/rules/duvidas.mdc` | Resolver ou fechar | M14 |

---

## 6. Compatibilidade

- Retrocompatível com projeto filho v1.2.x
- Logs existentes em `HH:MM` continuam legíveis (novos usam `HH:MM:SS`)
- Tasks existentes não são afetadas
- Analistas NÃO precisam reinstalar manualmente — auto-atualização via guardião
- Código-fonte e banco-dados/ não são alterados

---

## 7. Sequência de Implementação Sugerida

```
Fase 0 (Urgente — atualização de código-fonte prevista semana de 2026-03-23)
  M11 — Script atualizar-codigo-fonte.ps1 (git clone + fallback ZIP)
  M12 — Rastreabilidade de versão: stamp local + log centralizado no OneDrive
  [Confirmado pelo Cursor: posição correta — deve preceder as demais fases pela urgência]

Fase 1 (Riscos críticos — prioridade máxima)
  R5 — Proteção do .cursorignore (impacto mais catastrófico: OOM trava Cursor)
  R7 — Verificação OneDrive sync antes da atualização
  R2 — Validação de task JSON corrompida
  R3 — VERSION.json atômico (hash em vez de timestamp)

Fase 2 (Riscos de qualidade)
  R1 — Modo offline para symlink quebrado
  R4 — Timestamp com segundos nos logs
  R6 — Protocolo de limite de resultados de busca

Fase 3 (Melhorias de experiência + busca assertiva + higiene)
  M4 — Feedback visual de tasks
  M6 — Controle de submissão no SGD (falso encerramento)
  M10 — Checklist estratégico ao criar PSAI (rota SA)
  M3 — Templates PSAI/SAI no admin (revisado)
  M5 — Visibilidade no fluxo de revisão
  M14 — Higiene de contexto (conflitos, obsoleto, bloat, configs)
  M15 — Detecção de similaridade SAI/PSAI em tempo real
  M13/P1 — Auto-escalation: protocolo de busca obrigatório em 2 passos
  M13/P3 — Índices enriquecidos: script + geração na atualização
  M13/P4 — Flags inteligentes no agente
  M13/P2 — Transparência de busca
  M13/P5 — Indicador de completude
  M13/P6 — Cache de busca profunda

Fase 4 (Documentação e arquitetura)
  M7 — README operacional dos scripts
  M8 — Mapeamento cruzado Admin↔Filho
  M9 — Remoção de tamanhos OOM hardcoded

Fase 5 (Refatoração estrutural — requer mais testes)
  TESTE ZERO — Validar mecanismo de referência de .mdc antes de qualquer implementação
  M1 — Deduplicação de regras .mdc
  M2 — Quebra do agente-produto.mdc em rotas
```

> **Nota para Fase 5 — Teste Zero obrigatório antes de M2**:
> Criar um `.mdc` de teste com `alwaysApply: false` no projeto filho e verificar
> se a IA consegue acessar seu conteúdo quando outro `.mdc` (`alwaysApply: true`)
> instrui a fazê-lo. Este teste valida o mecanismo sem risco para o ambiente real.
> Se o teste zero falhar, M2 não deve ser implementado na forma proposta —
> rever a estratégia antes de prosseguir.
> Documentar a versão do Cursor usada no teste (ex: 0.48.x).

---

## 8. Critérios de Aceite e Plano de Teste

> **Como usar**: Após implementar cada item, execute o teste correspondente.
> O item só está concluído quando o critério de aceite é atendido.

### Fase 0 — Urgente (M11)

| Item | Como Testar | Critério de Aceite |
|---|---|---|
| **M11 — Modo Git** | Rodar `atualizar-codigo-fonte.ps1 -UrlGit <url>` com git disponível | Código antigo removido, novo clonado na pasta correta, integridade verificada, backup limpo |
| **M11 — Modo ZIP** | Pausar git (renomear executável) e rodar com .zip no OneDrive | Script detecta falha do git, localiza .zip, extrai na pasta correta, verifica integridade |
| **M11 — Fallback falha** | Rodar sem git e sem .zip no OneDrive | Código original preservado, mensagem de escalação exibida com todos os campos preenchidos |
| **M11 — Rollback** | Forçar erro na extração do ZIP (arquivo corrompido) | Script restaura backup automaticamente e reporta o erro |
| **M12 — Stamp local** | Rodar M11 com sucesso e abrir projeto filho | Guardião exibe versão e data do código-fonte na inicialização |
| **M12 — Desatualizado** | Definir `versao_minima` maior que a instalada e abrir projeto filho | Guardião exibe aviso com instrução para rodar o script |
| **M12 — Log centralizado** | Rodar M11 em duas máquinas (sucesso e falha) | Pasta `logs/` no OneDrive contém um arquivo JSON por analista; ambos os arquivos presentes com usuário, versão, método e status corretos |
| **M12 — Consulta gerente** | Perguntar à IA do Admin "quem não atualizou para v2.1.0?" | IA lê os JSONs da pasta `logs/` e lista analistas desatualizados ou com falha |

### Fase 3 — M15 (Detecção de Similaridade)

| Item | Como Testar | Critério de Aceite |
|---|---|---|
| **M15 — Detecção** | Iniciar análise de PSAI em módulo que tem SAI/PSAI similar no banco | Agente alerta com nome do responsável, status e recomendação de alinhamento — sem bloquear |
| **M15 — Registro** | Verificar task JSON após alerta de similaridade | Campos `similares_detectadas` e `alinhamento_sugerido` preenchidos. Se analista ignorou, `alinhamento_realizado: false` |
| **M15 — Sem ruído** | Iniciar análise de PSAI que é evolução natural de SAI já liberada | Agente **não** alerta (caso de exclusão: evolução da mesma SAI) |
| **M15 — Visibilidade gerente** | No Admin, revisar definições pendentes | Agente lista PSAIs com sobreposição detectada e alinhamento não confirmado |

### Fase 3 — M14 (Higiene de Contexto)

| Item | Como Testar | Critério de Aceite |
|---|---|---|
| **M14 — Conflito escrita** | No projeto filho, tentar usar Write tool num arquivo dentro de `referencia/` | Guardião do filho intercepta e instrui: "Use PowerShell para escrita no OneDrive" (regra propagada de `onedrive-escrita.mdc`) |
| **M14 — Auto-update exceção** | Ler `guardiao.mdc` do filho e verificar se a regra "NUNCA modifique `.cursor/rules/`" tem exceção documentada | Existe parágrafo explícito: "exceto durante auto-update silencioso (seção X)" |
| **M14 — Obsoleto removido** | Verificar que `projeto-filho/.cursor/rules/obsoleto/` não existe mais (movido para `arquitetura/obsoleto/`) | Pasta `obsoleto/` não está dentro de `.cursor/rules/` |
| **M14 — Bloat reduzido** | Abrir projeto filho e contar linhas de regras com `alwaysApply: true` | Total < 250 linhas (vs. ~522 antes). `onboarding.mdc` tem `alwaysApply: false`. `projeto.mdc` tem < 20 linhas |
| **M14 — duvidas.mdc** | Verificar `duvidas.mdc` do Admin | Todas as 4 perguntas resolvidas ou formalmente fechadas, com decisões registradas em `sdd-decisoes.md` |
| **M14 — analista.json** | Verificar `config/analista.json` no template distribuído | `versao_instalada` reflete versão atual do projeto. Guardião alerta se campo estiver defasado |

### Fase 3 — M13 (Busca Assertiva)

| Item | Como Testar | Critério de Aceite |
|---|---|---|
| **M13/P1 — Auto-escalation** | Pedir ao agente "pesquise SAIs sobre FGTS retroativo" | Agente roda `buscar-sai.ps1` automaticamente após consultar índices — sem pedido manual. Resultado inclui dados de campos BLOB |
| **M13/P2 — Transparência** | Mesma busca acima | Agente exibe resumo com origem dos dados (índices + busca profunda) e nível de confiança |
| **M13/P3 — Índices enriquecidos** | Rodar `gerar-indices-enriquecidos.ps1` e abrir `indices/enriquecidos/{modulo}.md` | Cada entrada tem ~300 chars + campos-chave separados (comportamento, módulos impactados, severidade). Cursor lê sem OOM |
| **M13/P4 — Flags inteligentes** | Em rota NE, pedir "busque SAIs de eSocial" | Agente usa `-Tipo NE -Modulo eSocial -Pendentes` automaticamente — não só `-Termo` |
| **M13/P5 — Completude** | Qualquer busca | Agente mostra checklist de fontes consultadas ao final dos resultados |
| **M13/P6 — Cache busca** | Fazer mesma busca duas vezes | Segunda busca lê de `meu-trabalho/cache-busca/` sem re-executar o script |

### Fase 1 — Riscos Críticos

| Item | Como Testar | Critério de Aceite |
|---|---|---|
| **R7** | Rodar `atualizar-projeto.ps1` com OneDrive pausado | Script detecta sync pendente, exibe opções Retry/Aguardar/Sair e exibe mensagem de escalação completa com campos preenchidos |
| **R2** | Truncar manualmente um arquivo JSON de task (remover `}` final) e abrir o projeto | Guardião renomeia para `.corrupted.json`, informa o analista e lista artefatos disponíveis — sem crash silencioso |
| **R5** | Remover linha `banco-dados/dados-brutos` do `.cursorignore` e abrir o projeto | Guardião emite Mensagem Prioritária imediata como primeiro output, antes de qualquer outra ação |
| **R3** | Interromper `gerar-atualizacao.ps1` no meio (Ctrl+C após o passo 3) | `VERSION.json` permanece na versão anterior; ao tentar novamente, script completa sem erro |

### Fase 2 — Riscos de Qualidade

| Item | Como Testar | Critério de Aceite |
|---|---|---|
| **R1** | Renomear `referencia/banco-dados/` temporariamente e abrir o projeto filho | Guardião verifica cache offline, continua com aviso de data se existir; ou exibe 3 ações concretas se não existir |
| **R4** | Gerar dois eventos de log no mesmo minuto | Entradas no log exibem `HH:MM:SS` distintos; logs antigos com `HH:MM` continuam legíveis |
| **R6** | Executar busca que retorne >50 resultados no chat | Agente recusa processar e pede refinamento com `-Modulo`, `-Rubrica` ou `-DataDe` antes de continuar |

### Fase 3 — Melhorias de Experiência

| Item | Como Testar | Critério de Aceite |
|---|---|---|
| **M4** | Iniciar rota NE em novo chat | Agente confirma criação da task com número; ao retomar, lista passo atual e achados salvos |
| **M6** | Concluir uma task, mover para `concluido/` e reabrir o projeto | Agente **não** pergunta sobre SGD ao concluir; na próxima inicialização, guardião lista passivamente "NE-1234: aguardando submissão no SGD" |
| **M3** | Abrir projeto Admin e pedir para criar PSAI | Templates `TEMPLATE-psai.md` e `TEMPLATE-sai.md` disponíveis em `templates/` do admin (ou item já marcado concluído se já existirem) |
| **M5** | Listar pendentes em `revisao/pendente/` com item criado há 6 dias | Item aparece com a data de envio informativa — **sem rótulo ATRASADO ou PRAZO** |
| **M10** | Iniciar rota SA e iniciar construção da PSAI | Agente apresenta as 10 perguntas **antes de construir a PSAI**; respostas aparecem na seção "Análise Estratégica" da PSAI; SAI herda a seção sem repetir; ao responder "ignorar", registra `[não avaliado]` e continua |

### Fase 4 — Documentação e Arquitetura

| Item | Como Testar | Critério de Aceite |
|---|---|---|
| **M7** | Ler `scripts/README.md` | Cada script listado tem: propósito, parâmetros, saída esperada, recovery step |
| **M8** | Perguntar à IA no Admin: "como uma PSAI do filho vira uma RN aqui?" | IA referencia `arquitetura/fluxo-admin-filho.md` e responde corretamente |
| **M9** | Ler `protecao-oom.mdc` | Não contém tamanhos fixos em MB; referencia `status.json` para consulta dinâmica |

### Fase 5 — Refatoração Estrutural

| Item | Como Testar | Critério de Aceite |
|---|---|---|
| **M1** | Abrir chat do filho e perguntar sobre convenção de nomenclatura | IA cita `padroes.mdc` como fonte; não retorna respostas conflitantes entre chats |
| **M2** | Abrir rota NE, SA e SS em chats separados | Cada chat carrega apenas o arquivo de rota correspondente (verificar via Cursor Debug → Rules) |

---

## 9. Plano de Rollback — M2 (Alto Risco)

> M2 é a única proposta que destrói um arquivo e cria 4 em seu lugar.
> Se o Cursor não carregar corretamente as regras por trigger, o analista
> fica sem agente funcional. Este plano garante reversão em < 5 minutos.

**Antes de implementar M2**:
1. Copiar `agente-produto.mdc` original para:
   `planejamento/v2.4.0/arquivos/agente-produto-backup.mdc`
2. Confirmar cópia gravada antes de prosseguir

**Sinal de falha** (verificar após implementação):
- Analista inicia rota NE e o agente não reconhece a rota
- Cursor Debug → Rules não mostra `agente-rota-ne.mdc` carregado
- Qualquer comportamento diferente do pré-M2

**Reversão** (se falha detectada):
```
1. Apagar: agente-produto.mdc (novo orquestrador)
             agente-rota-ne.mdc
             agente-rota-sa.mdc
             agente-rota-ss.mdc

2. Restaurar: planejamento/v2.4.0/arquivos/agente-produto-backup.mdc
              → renomear para agente-produto.mdc

3. Reiniciar o Cursor

4. Verificar: abrir chat e iniciar rota NE — deve funcionar como antes
```

**Critério de aceite para M2 antes de publicar**:
- Testar em ambiente do Admin (não enviar para analistas) com as 3 rotas
- Apenas publicar via `gerar-atualizacao.ps1` após validação completa
- Documentar versão do Cursor usada no teste (ex: 0.48.x)

---

## 10. Perguntas para o Cursor Avaliar

Ao compartilhar este documento com o Cursor para validação, peça que responda:

1. ~~A proposta M2 (quebrar agente-produto.mdc em rotas) é viável com a
   versão atual do Cursor?~~
   **[Resolvido]** Cursor confirmou limitação real: arquivos com `alwaysApply: false`
   não são carregados automaticamente por referência textual. 3 alternativas
   documentadas em M2. Teste zero definido na Fase 5. Ver M2 revisado.

2. ~~A verificação de `.cursorignore` no guardião (R5) pode ser feita sem
   ler o arquivo inteiro? Existe risco de OOM nessa própria verificação?~~
   **[Resolvido]** Arquivo é tipicamente < 50 linhas — sem risco de OOM.
   Incorporado no corpo de R5.

3. ~~A pergunta sobre `sgd_submetido` (M6) ao concluir uma task interromperia
   o fluxo natural do analista? Há uma forma menos intrusiva de registrar isso?~~
   **[Resolvido]** Trocado para lembrete passivo na inicialização. Ver M6 revisado.

4. ~~O mapeamento Admin↔Filho (M8) faz sentido como arquivo em `arquitetura/`
   ou seria melhor como seção do `PROJETO.md`?~~
   **[Resolvido]** Cursor confirmou: arquivo separado em `arquitetura/`. Incorporado.

5. ~~Há alguma proposta que conflite com regras existentes que eu não identifiquei?~~
   **[Resolvido]** Cursor identificou 4 conflitos específicos: naming em 4 lugares
   (incorporado em M1), guardiao.mdc referencia agente-produto.mdc na linha 148
   (incorporado em M2), globs a redistribuir (incorporado em M2). Sem conflitos
   adicionais em R5, R6, M6.

6. ~~A sequência de implementação faz sentido ou alguma fase deveria ser
   reordenada por dependência técnica?~~
   **[Resolvido]** Cursor confirmou sequência OK. Único ajuste: M11/M12 devem
   permanecer na Fase 0 (urgência confirmada). Já aplicado.

7. ~~O checklist M10 (10 perguntas estratégicas) deve ser exibido em bloco único
   ou pergunta por pergunta aguardando resposta?~~
   **[Resolvido]** Adotados blocos de 3-4 com agrupamento temático. Ver M10 revisado.

8. ~~A detecção de sync do OneDrive (R7) via status do processo `OneDrive.exe`
   é confiável no PowerShell?~~
   **[Resolvido]** Trocado para verificação de extensões temporárias e
   legibilidade do `VERSION.json`. Ver R7 revisado.

> **Todas as 8 perguntas resolvidas.** Seção 10 encerrada.

---

## 11. Histórico

| Data | Autor | Ação |
|---|---|---|
| 2026-03-19 | Gerente + Agente IA | Criação da proposta inicial |
| 2026-03-20 | Gerente + Agente IA | Adicionado R7 (OneDrive sync), seção 8 (critérios de aceite e testes), seção 9 (rollback M2) |
| 2026-03-20 | Gerente + Agente IA | Adicionado M10 (checklist estratégico 10 perguntas em rota SA) |
| 2026-03-20 | Gerente + Agente IA | Adicionado M11 (atualização código-fonte via git clone + fallback ZIP OneDrive) e M12 (rastreabilidade de versão por analista + log centralizado), Fase 0 na sequência |
| 2026-03-20 | Gerente + Agente IA | Corrigidas 5 incoerências: contagem de riscos (6→7), agente-produto.mdc duplicado, M3 unificado, verificar-saude.ps1 adicionado à tabela, label M10 corrigido para PSAI |
| 2026-03-20 | Gerente + Agente IA (Claude Code Opus) | M15 adicionado (detecção de similaridade SAI/PSAI em tempo real — alerta, registro na task, visibilidade gerente); M14 adicionado (higiene de contexto — conflitos, obsoleto, bloat, configs); critérios de aceite, sequência e tabela de arquivos atualizados |
| 2026-03-20 | Gerente + Agente IA (Claude Code Opus) | M13 adicionado (busca assertiva — 6 sub-melhorias P1-P6), critérios de aceite M13, sequência atualizada na Fase 3, tabelas de arquivos afetados atualizadas |
| 2026-03-20 | Gerente + Agente IA | Revisão pós-Cursor 3ª rodada: M1 conflitos reais mapeados (4 fontes, linhas específicas), M2 limitação confirmada + 3 alternativas + dependência guardiao.mdc linha 148, M3 validado como necessário (templates não existem no Admin), M6 adição no guardião documentada, M11/M12 urgência na Fase 0 confirmada |
| 2026-03-20 | Gerente + Agente IA | Revisão pós-Cursor 2ª rodada: critérios M12/M5/M6 alinhados, teste zero M2 adicionado, escopo cache R1 definido (índices leves), seção 10 com perguntas resolvidas marcadas |
| 2026-03-20 | Gerente + Agente IA | Revisão pós-Cursor: 14 ajustes aplicados (R1 cache, R2 loop, R3 hash, R5 dupla camada, R6 -Max, R7 detecção, M1 alwaysApply, M2 trigger, M3 validar, M5 sem SLA, M6 passivo, M10 blocos, M11 pré-checks, M12 JSON individual); R5 promovido ao topo da Fase 1 |
