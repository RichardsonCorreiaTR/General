# Guia de Validacao de PSAI/SAI - SAL (Solicitacao de Alteracao Legal)

> Aplica-se a PSAI/SAI tipo **SAL**: mudanca de comportamento imposta por **legislacao externa** (lei, decreto, MP, IN, portaria, resolucao, CCT, convencao coletiva, ato declaratorio).
>
> Complementa `GUIA-padroes-psai.md` (regras gerais) e — quando houver calculo — `GUIA-validacao-calculos-negativos.md`.
>
> Use durante a **definicao** (criacao da PSAI) e durante a **revisao** (Passo 5 do `revisar-psai.mdc`).
>
> Guias dedicados por tipo: **SAL** (este), **NE** (`GUIA-validacao-ne.md`), **Calculos com possibilidade de negativo** (`GUIA-validacao-calculos-negativos.md`). SAM e SAIL: guias dedicados em desenvolvimento.

---

## Distincao SAL vs SAIL vs SAM vs NE

| Tipo | Origem | Decisao do o que |
|---|---|---|
| **SAL** | Legislacao externa publicada | NAO ha escolha do conteudo — vem da norma |
| **SAIL** | Iniciativa interna **com base legal** (antecipar / interpretar / regulamentar internamente) | Ha escolha de momento e/ou interpretacao |
| **SAM** | Mercado (cliente, suporte, melhoria) | Decisao 100% da empresa |
| **NE** | Erro relatado | Correcao do que ja existe |

**Regra de desempate** entre SAL e SAIL: se a norma **obriga** o sistema a fazer X de forma especifica, e SAL; se a empresa **escolheu** implementar antes/diferente da norma, e SAIL.

---

## Etapa 1 - Identificacao da norma (obrigatorio)

A SAL **deve** declarar formalmente:

| Campo | Obrigatorio? | Exemplo |
|---|---|---|
| **Tipo da norma** | SIM | Lei, Decreto, MP, IN, Portaria, Resolucao, CCT, Convencao, Ato Declaratorio |
| **Numero e ano** | SIM | Lei 14.973/2024; IN RFB 2.110/2022; Decreto 11.322/2022 |
| **Orgao emissor** | SIM | Congresso Nacional; RFB; SEFAZ-SP; MTE; Banco Central |
| **Artigos / incisos / paragrafos** | SIM | Art. 5o §1o; Art. 12 caput; Art. 15 incisos II e III |
| **URL oficial** | SIM | planalto.gov.br, in.gov.br, dou.gov.br, portal SEFAZ da UF |
| **Versao consolidada** | Quando alterada | "Lei 14.973/2024 alterada pela Lei 14.999/2025" |

Se a SAL depender de **multiplas normas** (ex.: Lei + Decreto regulamentador + IN), citar **todas** com a hierarquia (lei prevalece sobre decreto, que prevalece sobre IN).

**Ferramenta de apoio** (extrair conteudo da norma para analise):

```
.\scripts\Consultar-Legislacao.ps1 -Url <URL>
.\scripts\Consultar-Legislacao.ps1 -Arquivo <PDF/DOCX/TXT>
```

Saida: `data/legislacao/analise-<slug>.json` com identificacao, objetivo, obrigacoes, prazos e pontos de atencao. Use o JSON para alimentar a secao de base legal da PSAI.

---

## Etapa 2 - Datas (vigencia, eficacia, retroatividade)

Sao **quatro datas distintas** que precisam estar claras:

| Data | O que e | Onde verificar |
|---|---|---|
| **Publicacao** | Quando a norma foi publicada (DOU/DOE) | Cabecalho da norma |
| **Vigencia** | Quando a norma passa a existir no mundo juridico | Artigo final ("Esta lei entra em vigor...") |
| **Eficacia** | Quando produz efeito (pode diferir de vigencia) | Clausulas transitorias |
| **Retroatividade** | Se gera efeitos para fatos passados | Texto explicito (ou interpretacao consolidada) |

**Anterioridade tributaria** (CF art. 150) — checar quando aplicavel:

- Tributos em geral: anterioridade do exercicio + nonagesimal (90 dias)
- Excecoes: II, IE, IPI, IOF, contribuicoes para seguridade social

**Periodo de transicao**: se a norma tem clausula transitoria (ex.: "vigora apos 180 dias da publicacao", "aplicavel apenas a fatos geradores apos data X"), essa data **e** a data de vigencia para efeitos da SAL.

**Retroatividade de norma benigna**: legislacao tributaria mais favoravel ao contribuinte pode retroagir (CTN art. 106). Avaliar se ha impacto retroativo em dados ja gravados.

---

## Etapa 3 - Comportamento anterior x novo

Toda SAL **deve** documentar a comparacao em secao dedicada da PSAI:

```
### Comportamento anterior (ate <vigencia>)
[Como o sistema operava]

### Comportamento novo (a partir de <vigencia>)
[Como o sistema deve operar]

### Periodo de transicao (se aplicavel)
[Regra durante a transicao: dual-mode, opt-in, migracao automatica]

### Tratamento de dados antigos
[Manter como esta / migrar / converter / nao tocar / reprocessar sob demanda]

### Retroatividade (se aplicavel)
[Quais lancamentos sao reprocessados, ate quando, com qual gatilho]
```

Se houver retroatividade, documentar tambem:
- Quais dados / lancamentos sao reprocessados
- Como o sistema valida fatos geradores anteriores
- Se ha aviso ao usuario para revisao manual ou se e automatico

---

## Etapa 4 - Versao de liberacao e cronograma

A SAL precisa indicar:

| Item | Detalhe |
|---|---|
| **Versao de mercado alvo** | Ex.: 13.2.5 |
| **Data prevista de liberacao** | Deve ser **antes** da vigencia |
| **Margem de seguranca** | Minimo **5 dias uteis** antes da vigencia |
| **Plano B** | Workaround temporario se nao houver tempo (configuracao manual, valor padrao, mensagem ao usuario) |

**Escalacao obrigatoria** se a vigencia for em **menos de 5 dias** e a versao alvo nao consegue cobrir: avisar GP imediatamente. Considerar release parcial / hotfix / orientacao de contorno.

---

## Etapa 5 - Conteudo Contabil Tributario (CCT) — quando aplicavel

Quando o modulo afetado tiver botao **Conteudo Contabil Tributario**:

- [ ] Verificar no **Checkpoint** se ha roteiros, legislacao consolidada e tabelas para a norma
- [ ] Definir o **caminho de busca** na SAI (qual roteiro consultar)
- [ ] Citar o codigo do roteiro Checkpoint quando existir (facilita a busca pelo cliente)

Ver `GUIA-padroes-psai.md` secao 8 (Botao Conteudo Contabil Tributario).

---

## Etapa 6 - Calculos com possibilidade de negativo

SAL frequentemente altera **base de calculo**, **aliquota**, **deducao**, **abatimento** ou **credito**. Toda SAL com calculo deve:

1. Aplicar `GUIA-validacao-calculos-negativos.md` (3 etapas: analise preventiva, tratamento, validacao em execucao)
2. Classificar cada calculo: pode/nao pode gerar negativo
3. Definir tratamento explicito (zerar, permitir negativo, bloquear, aviso, compensar, estornar)
4. **Validar conformidade com a norma**: a propria lei pode definir o tratamento (ex.: ICMS a recuperar permite saldo credor; prejuizo fiscal compensa-se nos exercicios seguintes)

Sem regra de tratamento definida → decisao **DEVOLVER** no parecer.

---

## Etapa 7 - Areas de impacto e reflexos

A SAL pode atravessar mais de um modulo. Verificar:

| Reflexo | Quando aplica |
|---|---|
| **Importacao** (XML, Portal, SPED) | Mudanca em campos de notas, tributos, base de calculo, layout |
| **ONVIO Portal/Processos/Contabil** | Mudanca em integracoes ou em relatorios visiveis ao cliente |
| **Patrimonio** | Mudanca em depreciacao, imobilizado, ganho/perda |
| **Honorarios** | Mudanca em pagamento de impostos, e-CAC, faturamento |
| **Folha** | Mudanca em obrigacoes trabalhistas, previdenciarias |
| **Auditoria** | Telas/processos que devem ser auditados |
| **Protocolo** | Imposto novo/alterado |
| **Apuracao CSLL/IRPJ (SPED ECF)** | Mudanca em apuracoes 6/7 |

Para cada reflexo: **enviar e-mail ao Especialista da area** alem de marcar "Areas de Impacto" na PSAI. Ver `GUIA-padroes-psai.md` secao 8 (Regras especificas por modulo).

---

## Etapa 8 - Comunicacao externa

Algumas SALs exigem comunicacao formal alem do release:

- [ ] **Aviso ao usuario** na atualizacao (mensagem na primeira execucao apos atualizar)?
- [ ] **Migracao com aceite** do usuario antes de aplicar a nova regra?
- [ ] **Comunicado a contadores/clientes** (release notes destacado, e-mail, video)?
- [ ] **Treinamento interno** do suporte (FAQ, roteiro de atendimento)?
- [ ] **Atualizacao do Checkpoint** (roteiro novo ou ajuste de existente)?

Se sim para qualquer item, registrar na secao **"Observacoes"** da PSAI e marcar para alinhamento com Marketing/Suporte.

---

## Etapa 9 - Analise Estrategica (Checklist 10 perguntas)

Como toda PSAI da Rota SA, a SAL deve responder o **Checklist Estrategico** (ver `agente-produto.mdc`). Foco para SAL:

- **Pergunta 3** (mitigar suporte): SAL bem definida evita avalanche de SSCs sobre nao-conformidade
- **Pergunta 5** (performance): retroativos podem custar caro em bancos grandes — provar antes
- **Pergunta 7** (medir sucesso): observabilidade para confirmar que a regra esta sendo aplicada (logs/contadores)

---

## Checklist final - antes de aprovar uma SAL

**Norma e datas:**
- [ ] Tipo + numero + ano + orgao emissor + artigos
- [ ] URL oficial (planalto/dou/sefaz)
- [ ] Datas: publicacao, vigencia, eficacia, retroatividade
- [ ] Anterioridade tributaria respeitada (se aplicavel)

**Definicao:**
- [ ] Comportamento anterior x novo descritos
- [ ] Periodo de transicao tratado (se houver)
- [ ] Tratamento de dados antigos definido
- [ ] Retroatividade documentada (se houver)
- [ ] Calculos: `GUIA-validacao-calculos-negativos.md` aplicado

**Liberacao:**
- [ ] Versao de mercado alvo + data prevista
- [ ] Margem de seguranca >= 5 dias antes da vigencia
- [ ] Plano B definido se nao couber na versao alvo

**Reflexos:**
- [ ] Areas de Impacto marcadas (Escrita/Importacao/Contabilidade/...)
- [ ] E-mail aos Especialistas das areas adjacentes (se reflexo)
- [ ] Botao CCT consultado (Checkpoint) quando o modulo tiver

**Padrao geral:**
- [ ] Checklist `GUIA-padroes-psai.md` (formatacao geral) cumprido
- [ ] Checklist secao 1.30 do Manual PSAI verificado
- [ ] Analise Estrategica preenchida (10 perguntas)

**Comunicacao:**
- [ ] Aviso ao usuario / migracao / comunicado / treinamento (registrar na PSAI)

**Decisao no parecer:**
- **APROVADO** se todos os itens cumpridos
- **DEVOLVER** se faltar norma, datas, comportamento anterior x novo, ou tratamento de calculos
- **ESCALAR** se a vigencia for < 5 dias e nao houver versao alvo

---

## Versao

- v1.0 — 2026-06-09 — criacao do guia (extracao das regras dispersas em revisar-psai.mdc, GUIA-padroes-psai.md e agente-produto.mdc).
