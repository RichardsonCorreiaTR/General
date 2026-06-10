# Acesso ao codigo-fonte do BR Contabil (Fiscont GP) via GitHub

> **Publico**: gestor (Gerente de Produto) + IA do Projeto Admin.
> Para o analista, ver `projeto-filho/SETUP-GITHUB.md` (versao curta).

Este documento padroniza como o time obtem acesso de **LEITURA** ao
codigo-fonte PowerBuilder do BR Contabil (modulo Escrita Fiscal) no
repositorio privado `tr/brtap-dominio_contabil`.

O fluxo tem **tres etapas**:

1. Criar um Team no GitHub e adicionar todos os usuarios.
2. Pedir ao Fernando Pizetti a liberacao do Team com permissao `Read`.
3. Cada usuario autentica o Cursor dele no GitHub.

---

## 1. Etapa 1 -- Criar o Team `fiscont-gp-codigo-leitura`

Quem faz: o gestor.

1. Acesse https://github.com/orgs/tr/teams
2. **New team** -> nome `fiscont-gp-codigo-leitura`, visibilidade `Visible`.
3. Descricao sugerida: "Acesso Read ao repo do BR Contabil (Fiscont GP -
   escrita fiscal e contabil) para o time (analistas + IA)."
4. Adicione cada usuario em **Members > Add a member**.
5. Cada usuario precisa **aceitar o convite** (e-mail ou
   https://github.com/orgs/tr).
6. Confira que todos aparecem em "Members" como **Active** (nao "Pending").

Pre-requisito de cada usuario:
- Conta GitHub vinculada a TR (corporativa, NAO pessoal).
- Se a TR usa SSO, conta autorizada para a org `tr`.

CLI equivalente:

```
gh api -X POST orgs/tr/teams -f name="fiscont-gp-codigo-leitura" -f privacy="closed"
gh api -X PUT orgs/tr/teams/fiscont-gp-codigo-leitura/memberships/USUARIO -f role="member"
```

---

## 2. Etapa 2 -- Liberacao Read pelo Fernando Pizetti

O Team criado nao ve o repositorio. E necessario que o **Fernando
Pizetti** (admin do `tr/brtap-dominio_contabil`) conceda permissao
`Read` ao Team.

Mensagem-modelo (Teams/e-mail):

```
Assunto: [Fiscont GP] Liberar Team de leitura no repo do BR Contabil

Ola Fernando,

Criei um Team no GitHub (org "tr") chamado "fiscont-gp-codigo-leitura".

Poderia conceder a esse Team acesso "Read" ao repositorio
"tr/brtap-dominio_contabil" (codigo-fonte PowerBuilder do BR Contabil /
Fiscont GP - escrita fiscal e contabil)?

Precisamos apenas de leitura (visualizar/clonar) - sem write/push.
O objetivo e permitir que os analistas e a IA do time investiguem o
comportamento do sistema no codigo-fonte.

Membros do Team (Nome -> handle GitHub):
  - <Nome 1> -> <handle1>
  - <Nome 2> -> <handle2>
  - ...

Obrigado!
```

Como o Fernando libera (caso ele pergunte):

```
Settings do repo tr/brtap-dominio_contabil
  -> Collaborators and teams
  -> Add teams
  -> escolher "fiscont-gp-codigo-leitura"
  -> Role/Permission: "Read"
  -> confirmar.
```

Teste rapido (qualquer membro pode rodar):

```
gh repo view tr/brtap-dominio_contabil --json name,visibility
```

Se voltar o nome do repo sem 404/403, o acesso esta ativo.

---

## 3. Etapa 3 -- Cada usuario configura o Cursor dele

Cada usuario faz isso na propria maquina, com a propria conta. A IA
conduz; o usuario executa. Detalhes do passo a passo do analista estao
em `projeto-filho/SETUP-GITHUB.md` (consultar la antes de instruir).

Resumo dos comandos (PowerShell):

```
git --version
gh --version
# se faltar:
winget install --id Git.Git
winget install --id GitHub.cli

gh auth login --web --hostname github.com
gh auth refresh -h github.com -s read:org   # se SSO da TR exigir
gh auth status
gh repo view tr/brtap-dominio_contabil --json name,visibility,defaultBranchRef
```

Alternativa PAT (apenas se `gh` nao for viavel):
- PAT pessoal com scope **minimo `repo`** e validade curta (90 dias).
- Guardar em variavel de ambiente: `setx GITHUB_TOKEN "valor"`.
- NUNCA em arquivo do projeto, log ou cache.

---

## 4. Branches de referencia

O guia define tres branches conceituais. A branch real (codigo
PowerBuilder) e declarada pelo gestor a cada release e fica registrada
em `config/codigo-fonte-branches.json`.

| Conceito | Significado | Hoje (preencher pelo gestor) |
|---|---|---|
| `vigente` | Como o sistema CALCULA HOJE | ver `config/codigo-fonte-branches.json` -> `vigente.branch` |
| `vigente_anterior` | Clientes em release anterior | idem -> `vigente_anterior.branch` |
| `em_dev` | Onde a mudanca nova vai aterrissar | idem -> `em_dev.branch` |

Scripts e regras leem essa config. Quando o gestor confirma a nova
branch vigente (apos liberar a versao), atualize o JSON e bumpe a
`atualizadoEm`.

---

## 5. Como a IA consulta o codigo

A IA NAO precisa clonar tudo para responder. Dois modos suportados:

### Modo A -- Codigo local (preferido para investigacao profunda)

Caminho declarado em `projeto-filho/config/caminhos.json` -> `codigo_local`
(default `C:\CursorEscrita\codigo-sistema\versao-atual`). Atualizado
por `scripts/atualizar-codigo.ps1` (clone ou pull da branch vigente).

### Modo B -- Consulta leve via `gh api` (sem clonar)

Quando o codigo local nao esta disponivel (pasta vazia/desatualizada,
ou analise envolve outra branch que nao a vigente local).

Exemplos:

```
gh api "repos/tr/brtap-dominio_contabil/branches?per_page=100"
gh api "repos/tr/brtap-dominio_contabil/contents/escrita/CAMINHO?ref=BRANCH"
```

A regra `projeto-filho/.cursor/rules/agente-codigo.mdc` instrui a IA
a usar Modo A por padrao e Modo B como fallback.

---

## 6. Seguranca de tokens (regra dura)

A IA do projeto **NUNCA** deve:

- Pedir ao usuario para colar token/PAT/senha no chat.
- Usar token de uma pessoa para outra (quebra auditoria).
- Gravar token em arquivo do projeto, log, cache ou backup.
- Sugerir PAT com scope "Full access" ou validade longa.

Preferencia:
1. `gh auth login --web` (token vai para o keyring do Windows).
2. PAT em variavel de ambiente da maquina (`setx GITHUB_TOKEN`).
3. PAT em arquivo do projeto -- **proibido**.

Essa regra esta replicada em `.cursor/rules/guardiao.mdc` (General e
projeto-filho).

---

## 7. Troubleshooting

| Sintoma | Causa provavel | Acao |
|---|---|---|
| `Repository not found` (404) mesmo autenticado | Falta liberacao do Team | Conferir Etapa 1 (Active) e Etapa 2 (Fernando liberou) |
| `Not logged in` | Sessao expirou | `gh auth login --web --hostname github.com` |
| Erro de SSO da TR | Token sem scope `read:org` | `gh auth refresh -h github.com -s read:org` |
| Erro 407 (proxy) | Proxy corporativo | Configurar `HTTP_PROXY` / `HTTPS_PROXY` |
| PAT expirado | Validade vencida | Gerar novo PAT (scope `repo`, curto) + `setx GITHUB_TOKEN ...` |

Solucao temporaria enquanto o acesso nao chega: o gestor publica um
ZIP do codigo-fonte no OneDrive (pasta declarada em
`projeto-filho/config/codigo-fonte.json -> pasta_zip_onedrive`).
`atualizar-codigo-fonte.ps1` ja usa esse fallback.

---

## 8. Referencias

- Config das branches: `config/codigo-fonte-branches.json`
- Doc do analista (Etapa 3 detalhada): `projeto-filho/SETUP-GITHUB.md`
- Regra de IA (investigacao do codigo): `projeto-filho/.cursor/rules/agente-codigo.mdc`
- Regra de seguranca: `.cursor/rules/guardiao.mdc` e `projeto-filho/.cursor/rules/guardiao.mdc`
- Scripts: `scripts/atualizar-codigo.ps1` (General) e
  `projeto-filho/scripts/atualizar-codigo.ps1` (filho).
