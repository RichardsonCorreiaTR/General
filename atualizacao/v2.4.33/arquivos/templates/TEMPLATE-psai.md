# PSAI [CODIGO] -- [Titulo]

## Identificacao

| Campo | Valor |
|---|---|
| **PSAI** | [Codigo] |
| **Origem** | [NE/SAM/SAL/SAIL] [Codigo da SA/NE] |
| **Modulo** | Escrita / Importação / Contabilidade |
| **Gravidade** | [Normal / Alta / Urgente] |
| **Analista** | [Nome] |
| **Data** | AAAA-MM-DD |
| **Status** | Em definicao / Em revisao / Aprovada |

## Descricao do Problema / Necessidade

> O que esta acontecendo? Por que precisa de alteracao?
> **Para NE:** deve conter TRES informacoes — qual o erro, onde ocorre e quando ocorre.
>   Erro de banco de cliente: iniciar com "Em alguns casos..." (sem "quando").
>   UF especifica: sigla em maiusculo no inicio. Ver `GUIA-validacao-ne.md`.
> **Para SAM:** descreva a limitacao ou necessidade de melhoria.
> **Para SAL:** descreva a mudanca legal e a data de vigencia.

[Descricao]

## Analise de Contexto

> SAIs/PSAIs relacionadas, historico do problema, cenarios afetados.
> Esta secao e construida com apoio da IA durante a analise.

[Analise]

## Comportamento Atual do Sistema

> Como o sistema se comporta HOJE neste ponto.
> Descreva em linguagem de produto: telas, campos, processos, relatorios.
> Se necessario, a IA pode analisar o codigo-fonte e traduzir o comportamento.

[Comportamento atual]

## Comportamento Esperado

> Como o sistema DEVE se comportar apos a correcao/melhoria.
> Descreva cada cenario identificado na analise.

### Cenario 1: [Nome do cenario]
- **Situacao**: [condicoes iniciais]
- **Acao**: [o que acontece / o que o usuario faz]
- **Resultado esperado**: [o que o sistema deve fazer]
- **Exemplo**: [valores concretos quando aplicavel]

### Cenario 2: [Nome do cenario]
- **Situacao**: [condicoes iniciais]
- **Acao**: [o que acontece]
- **Resultado esperado**: [o que o sistema deve fazer]
- **Exemplo**: [valores concretos]

## Pontos de Atencao

> Casos ocultos, excecoes, cenarios de borda identificados durante a analise.
> Pontos que o desenvolvimento precisa considerar.

- [Ponto 1]
- [Ponto 2]

## Areas de Impacto

> Marque todos os domínios que podem ser afetados por esta alteração. Na dúvida, marque.

### Escrita

- [ ] Apuração / DRCST / Simples (`apuracao-impostos`)
- [ ] Escrituração e movimento fiscal (`escrituracao-movimento-fiscal`)
- [ ] SPED e documentos eletrônicos (`sped-documentos-eletronicos`)
- [ ] Obrigações e relatórios estaduais (`obrigacoes-relatorios-estaduais`)
- [ ] Parcelamento e planejamento tributário (`parcelamento-planejamento`)
- [ ] Utilitários e rotinas (`utilitarios-rotinas`)

### Importação

- [ ] Onvio e rotinas de importação (`onvio-importacao-dados`)

### Contabilidade

- [ ] Integrações e canais digitais / amarração contábil (`integracoes-canais-digitais`)

### Outros

- [ ] Outro: [especifique]

## SAIs que Serao Geradas

| SAI | Tipo | Descricao / Escopo |
|-----|------|--------------------|
| [A definir] | NE/SAM/SAL | [O que esta SAI vai cobrir] |

## Base Legal

> Legislacao, normativo ou documento oficial que fundamenta esta alteracao (quando aplicavel).

- [Referencia]

## Checklist de Definicao (Manual PSAI v1.3.9 — sec. 1.30)

> Preencha ao final da definicao. "Sim" = deve constar na propria SAI ou gerar SAI paralela. "N/A" = nao se aplica a esta demanda.

| Requisito | Sim | Nao | N/A |
|---|:---:|:---:|:---:|
| Atualizacao do banco de dados (combobox, checkbox, campos novos/alterados) | | | |
| Permissoes de Usuarios (novos cadastros/movimentos/processos) | | | |
| Importacao Padrao (novos campos em notas, produtos, clientes, fornecedores) | | | |
| ONVIO Portal do Cliente (relatorios/guias a salvar; pastas) | | | |
| ONVIO Processos (botao "Concluir Atividade"; notificar Especialista) | | | |
| Dominio Protocolo (impostos novos/alterados em Escrita ou Folha) | | | |
| Dominio Honorarios (campos em Pagamento de Impostos, Nota de Entrada, Acumulador/Imposto/Produto Escrita, Cadastro de Empresas) | | | |
| Dominio Auditoria (telas ou processos novos a auditar) | | | |
| Dominio Contabilidade / SPED ECF (apuracao CSLL/IRPJ alterada) | | | |
| Dominio Patrimonio (PIS/COFINS imobilizado, ICMS imobilizado, Ganho/Perda capital) | | | |
| Dominio Cliente (Produtos ou Movimentos de Notas alterados; novos cadastros/processos a exportar) | | | |
| Dominio WEB (geracao de arquivo, importacao web, preenchimento web, certificado digital) | | | |
| Performance (novo calculo, novo arquivo, grande volume de dados — definir massa de teste) | | | |
| Botao Conteudo Contabil Tributario (Melhoria/Implementacao Legal — verificar Checkpoint) | | | |
| **[Importacao]** XML e Portal NFe/CTe/CTe-OS tratados juntos | | | |
| **[Importacao]** Rotinas Automaticas impactadas (alteracao em Config de Importacao ou na importacao) | | | |
| **[Importacao]** Impacto no Importador (nova tabela em tela ja importada — solicitar SAI se necessario) | | | |
| **[Importacao]** Resumo simultaneo Entrada+Saida avaliado (separar listagem se houver) | | | |
| **[Janelas]** Nova tela segue padrao de interface: tamanho, nomenclatura, botoes, grupos, foco, maximizar | | | |
| **[NE]** Testado na versao de mercado + minimo 2 versoes anteriores (empresa nova) | | | |
| **[NE]** Topico "Banco de Dados" com codigo empresa+analista incluido ao final | | | |
| **[NE]** Backup do banco salvo no SharePoint | | | |
| **[NE]** Todos os "sendo correto" com base em SAI | | | |
| **[NE]** Classificacao da NE definida (Grave/Alta/Media/Sem prioridade) e Board atualizado | | | |

> **Lembrete:** se o requisito exigir SAI separada, informe ao Especialista para que ambas entrem na mesma versao.
> Itens **[Importacao]**: apenas PSAIs do modulo Importacao.
> Itens **[Janelas]**: apenas quando criar ou alterar telas.
> Itens **[NE]**: apenas para PSAIs originadas de Notificacao de Erro. Ver `GUIA-validacao-ne.md`.

## Observacoes

[Informacoes adicionais ou "Nenhuma"]

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 1.0 | AAAA-MM-DD | [Nome] | Criacao inicial |
