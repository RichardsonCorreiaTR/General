# Consistencia entre Agentes

> Auditoria: 07/03/2026

## a) Caminhos referenciados pelo guardiao.mdc existem?

| Caminho | Existe | Nota |
|---------|--------|------|
| config/VERSION.json | SIM | |
| config/analista.json | SIM | |
| config/caminhos.json | SIM | |
| referencia/atualizacao/ | DEPENDE | Symlink. Existe se corrigir-symlinks.ps1 foi rodado |
| referencia/atualizacao/status.json | DEPENDE | Criado pelo atualizar-silencioso.ps1 |
| referencia/banco-dados/sais/indices/README.md | DEPENDE | Existe se indices foram gerados |
| referencia/banco-dados/codigo-sistema/META.json | DEPENDE | Existe se gerente publicou codigo |
| {codigo_local}/../META.json | DEPENDE | Existe se analista tem codigo local |

**Veredicto**: Paths corretos. Dependencias explicitas sao esperadas.
Guardiao trata corretamente o caso "nao existe" para cada um.

## b) agente-produto.mdc referencia modulos inteligentes?

| Referencia | Presente | Linha |
|------------|----------|-------|
| resumo-pendentes.md | SIM | 235 |
| modulos/{slug}.md | SIM | 236 |
| regras-negocio/{modulo}/ | SIM | 238 |
| glossario/ | SIM | 239 |

**Veredicto**: OK. Protocolo de varredura cobre todas as fontes inteligentes.

## c) onboarding.mdc verifica os mesmos paths que guardiao?

| Check | Guardiao | Onboarding | Alinhado? |
|-------|----------|------------|-----------|
| README.md (base SAIs) | SIM (check 3) | SIM (linha 51) | SIM |
| VERSION.json | SIM (check 1) | NAO | PARCIAL |
| caminhos.json | SIM (check 2) | SIM (linha 52) | SIM |
| META.json (codigo) | SIM (check 2) | NAO | PARCIAL |
| status.json (frescor) | SIM (check 4) | NAO | PARCIAL |
| TEMPLATE-psai.md | NAO | SIM (linha 53) | -- |

**Veredicto**: PARCIAL. O onboarding verifica um subconjunto dos checks do
guardiao. Nao e necessariamente um problema -- o guardiao ja faz os checks
completos na 1a interacao do dia. Mas se o onboarding roda ANTES do guardiao,
poderia perder problemas de versao e frescor. Como ambos sao alwaysApply,
a ordem de execucao depende do Cursor. RISCO BAIXO: guardiao vai pegar
de qualquer forma.

## d) agente-codigo.mdc sabe onde esta o codigo-fonte?

- Linha 28: "Leia config/caminhos.json para obter codigo_local"
- Linha 29: "Padrao: C:\CursorFolha\codigo-sistema\versao-atual\"
- Linhas 30-35: Fallback com mapa-sistema se indice-arquivos.md existir
- Linhas 37-40: Gera Mensagem Prioritaria se codigo ausente

**Veredicto**: OK. Caminho documentado, fallback definido, erro tratado.

## e) projeto.mdc alinhado com rotas NE/SA?

- Linha 16-17: "NE recebida, SAM para analisar, SAL para pesquisar"
- Nao menciona explicitamente "Rota NE" ou "Rota SA"
- Exemplos cobrem NE e SA: "Recebi a NE 95069" e "A SAM 12345 pede
  uma funcionalidade nova de abono"

**Veredicto**: OK. Nao precisa detalhar rotas -- isso e papel do agente-produto.
Projeto.mdc faz o papel de contexto informacional, nao de instrucao.

## f) Templates referenciados existem?

| Template | Referenciado por | Existe? |
|----------|-----------------|---------|
| TEMPLATE-psai.md | agente-produto (linhas 99, 203), onboarding (53) | SIM |
| TEMPLATE-sai.md | agente-produto (linha 100) | SIM |

**Veredicto**: OK.

## g) Instrucoes contraditorias entre agentes?

| Conflito potencial | Avaliacao |
|-------------------|-----------|
| guardiao diz "atenda diretamente" vs agente-produto tem rotas | NAO e conflito. Guardiao delega ao agente-produto quando e demanda, atende direto quando e consulta simples. |
| guardiao "NUNCA modifique .cursor/rules/" vs auto-atualizacao modifica | RESOLVIDO. Excecao explicita: "exceto durante auto-atualizacao silenciosa" (guardiao linha 171). |
| onboarding verifica ambiente vs guardiao verifica ambiente | DUPLICACAO BENIGNA. Onboarding so roda no 1o uso; guardiao roda sempre. Nao conflita. |

**Veredicto**: Zero contradicoes encontradas.

## h) Instrucoes duplicadas desnecessariamente?

| Duplicacao | Agentes | Problema? |
|-----------|---------|-----------|
| Naming (PSAI-/SAI-) | agente-produto + guardiao | BENIGNA. Reforco intencional. |
| "Consulta simples atenda direto" | agente-produto + guardiao | BENIGNA. Consistente. |
| Mencao a Mensagem Prioritaria | guardiao + onboarding + agente-codigo | BENIGNA. Cada um referencia o formato do guardiao. |
| Log proativo | agente-produto + guardiao | BENIGNA. agente-produto diz "registre", guardiao define formato. |

**Veredicto**: Duplicacoes sao reforcos intencionais, nao inconsistencias.

## i) Simulacao de fluxos completos

### Fluxo 1: Analista abre Cursor pela 1a vez

1. Cursor carrega todas as regras alwaysApply: guardiao, onboarding, projeto
2. Onboarding le config/analista.json -> onboarding_completo: false
3. Onboarding verifica meu-trabalho/ e logs -> vazio -> inicia boas-vindas
4. Guardiao roda verificacoes: versao, codigo, base, frescor
5. Se algo falha: Mensagem Prioritaria gerada
6. Se tudo OK: boas-vindas + primeira consulta pratica
7. Marca onboarding_completo: true

**Resultado**: FUNCIONA. Mas NOTA: se guardiao detecta problema E onboarding
quer fazer boas-vindas, ambas mensagens podem competir. O onboarding deveria
verificar problemas ANTES de iniciar boas-vindas (ja faz: linhas 50-56).

### Fluxo 2: Analista traz NE-95069

1. Guardiao identifica demanda -> ativa agente-produto
2. agente-produto identifica "NE" -> Rota NE
3. Passo 1: [Passo 1 de 5 - Entendendo o erro] -- pergunta detalhes
4. Passo 2: [Passo 2 de 5 - Investigando] -- Protocolo de varredura +
   agente-codigo investiga o codigo
5. Passo 3: [Passo 3 de 5 - Cenarios de impacto] -- exemplos numericos
6. Passo 4: [Passo 4 de 5 - Gerando definicao] -- template carregado
7. Passo 5: [Passo 5 de 5 - Revisando] -- apresenta ao analista
8. Log proativo gerado automaticamente

**Resultado**: FUNCIONA.

### Fluxo 3: Analista traz SAM de funcionalidade nova

1. agente-produto identifica "SA" -> Rota SA
2. Passo 1: Entender necessidade (pode nao existir nada)
3. Passo 2: Descobrir -- varredura + analogias + legislacao + gaps
4. Passo 3: Desenhar solucao -- linguagem de produto, opcoes
5. Passo 4: Cenarios -- incluindo cenarios de integracao
6. Passo 5: Gerar definicao -- com racional e alternativas
7. Passo 6: Revisao
8. Log proativo gerado

**Resultado**: FUNCIONA. Passo 2 e o diferencial -- bem estruturado.

### Fluxo 4: Symlink quebrado

1. Guardiao check 3: README.md nao existe -> gera Mensagem Prioritaria
2. Formato: ALERTA PROJETO FOLHA - [Analista: nome] - Symlinks quebrados
3. Analista copia e envia pro Vitor Justino via Teams
4. Guardiao tenta continuar com o que tem

**Resultado**: FUNCIONA.

### Fluxo 5: Versao nova disponivel (auto-update)

1. Guardiao check 1: le VERSION.json -> 1.0.0
2. Verifica referencia/atualizacao/ -> encontra v1.1.0/
3. Le input.md -> executa copias silenciosamente
4. Preserva analista.json, caminhos.json, meu-trabalho/
5. NAO fala nada ao analista
6. Continua normalmente

**Resultado**: FUNCIONA. Mas RISCO: se o input.md tiver instrucao de rodar
script (corrigir-symlinks.ps1), a IA consegue executar? Sim, se o Cursor
tiver permissao de Shell. Se nao tiver, fica silencioso e ignora.

### Fluxo 6 (NAO COBERTO): Analista recebe SS do suporte

1. Analista diz: "Recebi um chamado SS-12345 sobre erro no calculo
   de FGTS do cliente. O suporte precisa de resposta."
2. Agente nao tem rota para isso.
3. Provavelmente cai em "consulta rapida" ou tenta Rota NE.
4. Nao ha orientacao para: entender pergunta do suporte, verificar
   comportamento esperado vs real, redigir resposta tecnica.

**Resultado**: NAO FUNCIONA adequadamente. Gap D11.
