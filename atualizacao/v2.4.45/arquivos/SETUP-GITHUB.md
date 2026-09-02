# Acesso ao codigo-fonte do BR Contabil -- Setup do analista

> **Publico**: analista (voce). Tempo na primeira vez: ~5 min.
> Depois disso, e automatico. Para o fluxo completo (Team, Fernando,
> politicas), ver `referencia/banco-dados/.../arquitetura/acesso-github-codigo.md`
> ou pedir ao gestor.

## Por que voce precisa fazer isso

A IA precisa LER o codigo-fonte PowerBuilder do BR Contabil (modulo
Escrita Fiscal) para investigar como o sistema realmente calcula. O
repositorio e privado (`tr/brtap-dominio_contabil`). Sem acesso, a IA
fica sem o "porque tecnico" -- responde apenas com base em SAIs/PSAIs.

## Pre-requisitos

1. Voce esta no Team **`fiscont-gp-codigo-leitura`** na org `tr` no GitHub.
   - Verifique em https://github.com/orgs/tr/teams (deve aparecer como
     **Active**, nao "Pending").
   - Se nao estiver, fale com o gestor (Richardson) para te incluir.
2. O Fernando Pizetti ja liberou o Team com acesso `Read` ao repo.
   - Se o passo final aqui der 404, e isso que esta faltando -- fale
     com o gestor.

## Passo a passo (PowerShell, ~5 min)

### A. Verificar ferramentas

```
git --version
gh --version
```

Se faltar git:
```
winget install --id Git.Git
```

Se faltar gh:
```
winget install --id GitHub.cli
```

Feche e reabra o PowerShell apos instalar (PATH).

### B. Logar no GitHub com sua conta TR

```
gh auth login --web --hostname github.com
```

- Selecione `GitHub.com` -> `HTTPS` -> `Login with a web browser`.
- O navegador abre. **Use sua conta corporativa TR** (NAO a conta pessoal).
- Autorize o gh CLI.

Se a TR exigir SSO na org `tr`:

```
gh auth refresh -h github.com -s read:org
```

### C. Confirmar a autenticacao

```
gh auth status
```

Deve mostrar `Logged in to github.com as <seu-handle>`.

### D. Testar acesso ao repositorio

```
gh repo view tr/brtap-dominio_contabil --json name,visibility,defaultBranchRef
```

- **Sem erro** -> acesso OK, voce esta pronto.
- **Erro 404 / Repository not found** -> falta liberacao do Team
  (Fernando ainda nao incluiu) ou voce nao esta no Team. Fale com o
  gestor (Richardson). Use a tabela de troubleshooting abaixo.

## Como a IA usa esse acesso (v2.4.39: unico modo)

Voce NAO precisa clonar o codigo. A IA consulta o GitHub diretamente
sob demanda via `gh api`. Isso significa:

- **Voce nao roda mais** `atualizar-codigo.ps1` nem `atualizar-codigo-fonte.ps1`
  (esses scripts foram removidos do pacote).
- **Voce nao tem mais** uma pasta `C:\CursorEscrita\codigo-sistema`.
- **A IA usa o GitHub** sempre que precisa olhar uma funcao, tela ou PBL.

A branch que ela consulta esta declarada em
`config/codigo-fonte-branches.json` (campo `vigente.branch`). Para
investigar uma mudanca futura, peca explicitamente: *"olha em em_dev"*.

## Sem acesso GitHub ainda? (solucao temporaria)

Enquanto voce nao esta com acesso ativo, a IA continua atendendo
demandas com SAIs/PSAIs e os mapas em `referencia/banco-dados/`. Ela
te avisa de forma clara quando a investigacao precisaria do codigo
mas nao consegue. Acione o gestor (Richardson) com a Mensagem
Prioritaria que a IA gera nesses casos.

## Regras de seguranca (NUNCA quebrar)

- **NUNCA** cole token (PAT) ou senha no chat do Cursor.
- **NUNCA** salve token em arquivo do projeto (nem `.env`, nem
  `config/`, nem comentario em script).
- Use o `gh CLI` -- ele guarda o token no keyring do Windows.
- Se precisar mesmo de PAT (caso raro), use `setx GITHUB_TOKEN ...` na
  variavel de ambiente da maquina; com scope minimo `repo` e validade
  curta (90 dias).
- A IA nao vai te pedir token. Se a IA pedir, e bug -- reporte ao gestor.

## Troubleshooting

| Sintoma | Causa | Acao |
|---|---|---|
| `gh: command not found` | gh CLI nao instalado | `winget install --id GitHub.cli` e reabrir PowerShell |
| `Repository not found` (404) ao testar passo D | Falta liberacao (Team nao incluido OU Fernando nao liberou) | Fale com o gestor; mande print do `gh auth status` |
| `Not logged in` | Sessao expirou | `gh auth login --web --hostname github.com` |
| Erro de SSO da TR | Token sem scope `read:org` | `gh auth refresh -h github.com -s read:org` |
| Erro 407 (proxy) | Proxy corporativo bloqueando | Configurar `HTTP_PROXY` / `HTTPS_PROXY` (peca ao TI) |
| IA diz "codigo nao disponivel" | gh sem autenticacao OU sem rede | Rode `gh auth status`; se OK, teste `gh repo view tr/brtap-dominio_contabil` |

## Como verificar tudo de uma vez

```
.\scripts\verificar-ambiente.ps1
```

A partir da v2.4.38, esse script confere `gh`, `gh auth status` e o
acesso ao repo.
