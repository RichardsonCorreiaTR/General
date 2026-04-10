# Guia Rapido -- Projeto do Analista

Bem-vindo ao seu ambiente de trabalho para definicoes de PSAIs e SAIs!
Este guia mostra tudo que voce pode fazer aqui.

---

## Como funciona o processo de analise

Quando voce traz uma demanda, a IA conduz uma analise profunda:

```
1. RECEPCAO   -->  Voce informa a demanda (NE, SAM, SAL) e o codigo
       |
2. CONTEXTO   -->  IA busca SAIs relacionadas e definicoes existentes
       |
3. CODIGO     -->  IA analisa o codigo-fonte e traduz para linguagem de produto
       |
4. CENARIOS   -->  IA identifica todos os cenarios e casos de borda
       |
5. DIALOGO    -->  Voces discutem e refinam os cenarios juntos
       |
6. DEFINICAO  -->  IA gera a PSAI ou SAI completa no formato tradicional
       |
7. QUALIDADE  -->  IA revisa completude e clareza antes de entregar
```

O parceiro de analise adapta o processo conforme o tipo de demanda:
- **Rota NE** (correcao de erro): 5 passos — foco em entender, investigar e corrigir
- **Rota SA** (funcionalidade nova): 6 passos — foco em descobrir, desenhar e definir
- **Rota SS** (suporte N3): 4 passos — foco em investigar e responder
- **Consulta rapida**: atendimento direto, sem processo formal

---

## O que posso pedir a IA?

### Analisar uma demanda (analise completa)

- "Recebi a NE **95069** sobre FGTS CCT, me ajuda a analisar?"
- "Preciso criar uma **PSAI** para a SAM **12345**"
- "Quero detalhar a **SAI 67890** sobre ferias"
- "Revisar a PSAI **119453** que ja comecei"

### Consultar a base de conhecimento

- "Quais definicoes existem no modulo de **ferias**?"
- "Me mostre SAIs relacionadas a **FGTS retroativo**"
- "O que diz o glossario sobre **DSR**?"
- "Me mostre o fluxo de **rescisao**"
- "Quais modulos existem no sistema?"
- "Quais **areas** do produto existem para eu pesquisar?" / "Onde esta o **indice dos mapas** por area?"

### Analisar o codigo-fonte

- "O que o sistema faz hoje quando **calcula FGTS sobre CCT**?"
- "Me mostra o codigo da **tela de calculo mensal**"
- "Por que o sistema **calcula o FGTS sobre o salario integral**?"
- "Quais telas sao afetadas por **mudanca no INSS**?"

### Validar e concluir

- "Verificar se minha definicao esta **completa**"
- "Analisar o **impacto** da minha definicao nos outros modulos"
- "**Finalizar** minha definicao"

### Buscar SAIs

Os indices estao em `referencia/banco-dados/sais/indices/`.
Para busca detalhada, rode em terminal separado (fora do Cursor):

```
cd "C:\Users\{seu-usuario}\Thomson Reuters Incorporated\CursorEscrita - General"
powershell -File scripts\buscar-sai.ps1 -Termo "INSS"
powershell -File scripts\buscar-sai.ps1 -Termo "ferias" -Tipo NE -Pendentes
```

### Pesquisar em varias areas (PBCVS)

Alem do nucleo da **Escrita Fiscal**, o time trabalha com **outras areas** (ex.: **Importacao**, **Onvio Escrita**). Para analise e busca completas:

1. **Indice de mapas por area** — ponto de partida: `referencia/banco-dados/mapa-sistema/indice-mapas-areas.md` (qual mapa abre para cada area).
2. **Mapas por area** — alem de `mapa-escrita.md`, use os mapas indicados no indice quando o tema envolver importacao, integracao, etc.
3. **Filtrar SAIs por area** — no terminal, use `-Modulo` com trecho do nome da area (ex.: `Escrita`, `Importacao`, `Onvio`):
   ```
   powershell -File scripts\buscar-sai.ps1 -Termo "sped" -Modulo "Escrita"
   powershell -File scripts\buscar-sai.ps1 -Termo "layout" -Modulo "Importacao"
   ```
4. **Na conversa com a IA** — diga quando a demanda cruzar areas: *"Verifique tambem [area] usando o mapa e a busca de SAIs adequados."*

---

## Estrutura de pastas

| Pasta | O que tem | Posso editar? |
|-------|-----------|---------------|
| `meu-trabalho/em-andamento/` | Suas PSAIs e SAIs em progresso | Sim |
| `meu-trabalho/concluido/` | Finalizados (insumo para SGD) | Sim (mover para ca) |
| `meu-trabalho/tasks/` | Rastreamento automatico das suas analises | Nao (gerenciado pela IA) |
| `templates/` | Modelos de PSAI, SAI e task | Nao |
| `referencia/banco-dados/` | Base oficial (OneDrive) | Nao |
| `referencia/logs/` | Seus logs (OneDrive) | Automatico |
| `config/` | Sua identificacao | So no setup |
| `scripts/` | Ferramentas | Nao |

---

## Tipos de definicao

| Tipo | Template | Quando usar |
|------|----------|-------------|
| **PSAI** | `TEMPLATE-psai.md` | Pre-analise: quando recebe NE/SAM e precisa analisar |
| **SAI** | `TEMPLATE-sai.md` | Definicao detalhada: GERAL/PROCESSOS/ARQUIVO/CONTROLE/RELATORIOS |

### Naming dos arquivos

- PSAIs: `PSAI-119453-fgts-cct-retroativo.md`
- SAIs: `SAI-95069-ne-fgts-cct-alteracao.md`

---

## Scripts disponiveis

Rode estes comandos em um terminal:

| Comando | O que faz |
|---------|-----------|
| `.\scripts\verificar-ambiente.ps1` | Verifica se tudo esta OK |
| `.\scripts\atualizar-projeto.ps1` | Atualiza para versao mais recente |
| `.\scripts\atualizar-codigo.ps1` | Baixa codigo-fonte mais recente do git |

---

## FAQ

**P: Preciso saber BDD ou Gherkin?**
R: Nao! A IA usa BDD internamente para pensar nos cenarios, mas voce
interage em linguagem normal e recebe definicoes no formato tradicional.

**P: A IA vai me mostrar codigo?**
R: Por padrao, a IA explica o comportamento em linguagem de produto
(telas, campos, processos). Se voce quiser ver o codigo, e so pedir.

**P: O que faco se a IA errar?**
R: Corrija e diga o que estava errado. A fase de Dialogo serve exatamente
para isso -- refinar a analise juntos.

**P: O que sao as tasks em meu-trabalho/tasks/?**
R: O sistema salva automaticamente o progresso das suas analises. Se voce
fechar o Cursor e voltar, ele oferece retomar de onde parou. Voce nao
precisa fazer nada -- e tudo automatico.

**P: Como atualizo o projeto?**
R: Rode `.\scripts\atualizar-projeto.ps1` no terminal. A IA tambem avisa
quando ha versao nova.

**P: O OneDrive nao esta sincronizando**
R: Verifique se o OneDrive esta rodando (icone na bandeja). Se nao, abra
o app do OneDrive. Rode `.\scripts\verificar-ambiente.ps1` para diagnostico.

**P: Posso criar definicoes de qualquer modulo?**
R: Sim. A IA busca contexto no modulo relevante e, quando o assunto
cruza **outras areas** (Importacao, Onvio, etc.), deve consultar o
`indice-mapas-areas.md` e os mapas correspondentes — nao fique so no
`mapa-escrita.md` se a NE/SA envolver outra frente.

**P: Qual a diferenca entre PSAI e SAI?**
R: A PSAI e a pre-analise (entender o problema e planejar). A SAI e a
definicao detalhada com todas as secoes (GERAL, PROCESSOS, ARQUIVO, etc.).

**P: Onde vejo o codigo-fonte do sistema?**
R: Em `C:\CursorEscrita\codigo-sistema\versao-atual\` (se instalado; ou conforme `codigo_local` em `config/caminhos.json`).
Rode `.\scripts\atualizar-codigo.ps1` para baixar/atualizar.

---

## Atalhos uteis do Cursor

| Atalho | O que faz |
|--------|-----------|
| `Ctrl+L` | Abrir chat com a IA |
| `Ctrl+I` | IA inline (edita o arquivo direto) |
| `Ctrl+Shift+P` | Paleta de comandos |
| `Ctrl+P` | Abrir arquivo rapido |
| `Ctrl+Shift+F` | Buscar em todos os arquivos |

---

## Precisa de ajuda?

Pergunte a IA! Ela conhece todo o projeto, a base de dados, o codigo-fonte
e os templates. Comece com: "Recebi uma NE sobre..."
