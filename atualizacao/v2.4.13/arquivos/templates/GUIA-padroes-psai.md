# Guia de Padrões de Definição de PSAI/SAI

> Baseado em quatro documentos oficiais:
> - **Manual de Padrão de Pré-SAI e SAI v1.3.9** (16/10/2024) — Escrita/Geral
> - **Manual de Padrão de Pré-SAI e SAI de Importação v1.5** — módulo Importação
> - **Manual da Definição de Padrão de Interface de Desenvolvimento para Sistemas Desktop v1.1** — padrão de janelas
> - **Validação das NEs v1** — regras de NE → ver `GUIA-validacao-ne.md` (guia dedicado)
>
> Use como referência rápida durante a definição. Para detalhes e exemplos visuais, consulte o manual original de cada módulo.

---

## 1. Formatação geral

| Item | Regra |
|---|---|
| **Fonte** | Arial 12 em todo o texto |
| **Negrito** | Apenas onde o manual indicar (tópicos, títulos de exemplo, nome da quebra em relatórios) |
| **Alinhamento** | Textos, tabelas e relatórios → esquerda sem recuo. Telas → esquerda com 1 recuo |
| **Tópicos principais** | MAIÚSCULAS + negrito. Separados por linha horizontal. Ex: **PARÂMETROS**, **CADASTROS**, **LANÇAMENTOS**, **APURAÇÃO**, **GUIAS**, **LIVROS**, **INFORMATIVOS**, **RELATÓRIOS**, **CONTABILIZAÇÃO** |
| **Subtópicos** | Primeira letra maiúscula + negrito. Ex: **Acumuladores** |
| **Listas** | Sempre numeradas; reiniciar a cada tópico/subtópico. Detalhamentos com marcador + recuo |

---

## 2. Exemplos

- Obrigatório título **"Exemplo"** em negrito (primeira letra maiúscula).
- Mais de um exemplo → numerar: **Exemplo 1**, **Exemplo 2**.
- **Cálculos**: obrigatório incluir valores concretos.
- **Assunto complexo**: incluir mais de um exemplo.
- Se houver exemplo de cálculo + relatório: usar os **mesmos dados** nos dois exemplos (ou apresentar o cálculo completo para o relatório alternativo).

---

## 3. Telas

- Imagem **abaixo** do texto descritivo da modificação.
- Explicação dos campos **abaixo** da imagem.
- Tela com barra de rolagem: incluir **todas** as capturas (uma embaixo da outra).
- Alterações em telas já existentes (revisão): destacar em **laranja**.
- Destaques de alterações em telas/relatórios: **retângulo vermelho** ao redor.

---

## 4. Relatórios

| Item | Regra |
|---|---|
| **Ferramenta** | BROffice/LibreOffice Calc; fonte Tahoma 8 (corpo pode usar 7 se necessário) |
| **Cabeçalho** | Página + data + hora alinhados à direita. Nome da empresa em negrito, à esquerda |
| **Rodapé** | "Sistema licenciado para..." (padrão; exceções devem constar na SAI) |
| **Alinhamento de dados** | Alfanumérico → esquerda. Numérico → direita. Data → centralizado |
| **Tamanho de colunas** | Informar o tamanho de cada coluna numérica e alfanumérica na definição |
| **Linha em branco** | Uma linha em branco abaixo do cabeçalho antes dos dados |
| **Destaque de linhas** | Uma linha destacada, uma não (alternar); nunca duas seguidas iguais |
| **Totalizadores** | Linha separadora acima e abaixo. Apenas a *identificação* do totalizador em negrito |
| **Quebras** | Nome da quebra em negrito; linha em branco entre quebra e dados; traço separando quebras |
| **Impressão** | Testar em Retrato fonte 8; se não couber, Paisagem. Fator de escala = 100% |
| **Borda** | Incluir borda em todo o modelo para melhor visualização no BROffice |

> Dispensado o modelo do relatório apenas quando a alteração for simples e o ponto alterado estiver claro.

---

## 5. Tabelas (leiautes, contabilização, importação)

| Item | Regra |
|---|---|
| Cabeçalho | Negrito, Arial 12, fundo **azul** (azul 8 no BROffice Writer) |
| Células sem dados | Sem texto, fundo **cinza claro** |
| Células alteradas | Fundo **amarelo** |
| Demais células | Fonte normal, sem cor de fundo |

---

## 6. Mensagens

**Tipos permitidos:** Informativa · Advertência · Interrogativa · Erro

**Como definir:**
- Sem imagem da mensagem; apenas tipo, título da janela, texto e botões.
- Marcador **sem numeração**, sem aspas duplas (`"`). Aspas simples (`'`) só para opções do sistema.
- Botões entre colchetes individuais: `[Sim], [Não]`.
- Explicação dos botões: marcador sem numeração com recuo, abaixo da mensagem.
- Observar pontuação em todas as mensagens.

**Mensagem padrão — relatório sem dados:**
> Tipo: Advertência · Título: Aviso · Mensagem: Sem dados para emitir. `[OK]`

---

## 7. Campos novos ou alterados

| Tipo de campo | O que definir |
|---|---|
| **Combobox** | Opção padrão na atualização (qual opção ou em branco) |
| **Checkbox** | Se virá marcado na atualização (desmarcado não precisa constar) |
| **Valor** | Se será preenchido na atualização e qual valor; casas decimais > 2 devem ser definidas |
| **Data** | O que será preenchido na atualização |
| **Texto/Numérico** | Quantidade de caracteres; se é alfanumérico ou só numérico |
| **Campo obrigatório** | Definir mensagem quando não preenchido |
| **Campo com código** | Avaliar necessidade de mensagem "Código inválido." |
| **Grid** | Fundo cinza (cor "Control" no Sharp). Títulos centralizados. Alfanumérico → esquerda, numérico → direita, data → centralizado |

---

## 8. Regras específicas por módulo/domínio

### ONVIO Portal do Cliente
- Sempre avaliar se a alteração impacta o Portal.
- Relatório/guia a salvar: informar a **pasta** (criar se não existir).
- Relatório/guia sem reflexo no Portal: não mencionar na SAI.

### Domínio Cliente
- Campos em **Produtos** ou **Movimentos de Notas**: definir tópico do Domínio Cliente.
- Cadastros/processos novos: avaliar necessidade de disponibilizar no Domínio Cliente + utilitários de importação/exportação + notificar Especialista.
- Cadastros já exportados automaticamente (Escrita: Parâmetros, Grupos, Acumuladores, etc.) **não** precisam constar na definição.

### ONVIO Processos
- Processo novo/alterado: informar botão **"Concluir Atividade"** + e-mail ao Especialista.

### Importação Padrão
- Campo novo em notas, cupons, produtos, clientes, fornecedores, remetentes ou destinatários → informar reflexo na importação padrão na SAI.
- Novo tipo de importação de nota fiscal → definir comportamento do campo **"Origem"**.

### Domínio Auditoria
- Tela ou processo novo: definir se será auditado, o que auditar e o nome da tabela.

### Protocolo
- Imposto novo/alterado em Escrita ou Folha → e-mail ao Especialista da área Contábil para SAI no Protocolo.

### Honorários
Repassar e-mail ao Especialista para SAI em Honorários quando alterar:
- Escrita: Pagamento de Impostos, Pagamento via e-CAC, Nota de Entrada, Acumulador/Imposto/Produto (integração Escrita Fiscal), Cadastro de Empresas.
- **Não** precisam de SAI em Honorários: Cadastro de Fornecedores, Cadastro de Novos Impostos (refletem automaticamente).

### Domínio Patrimônio
Notificar Especialista para SAI no Patrimônio quando alterar em Escrita:
- Outros Créditos de PIS/COFINS / Imobilizado
- Impostos Lançados / Estadual (crédito/débito ICMS imobilizado)
- Impostos Calculados (Ganho/Perda de capital)

### Domínio Contabilidade / SPED ECF
- Apuração de CSLL (6) ou IRPJ (7) alterada em Escrita → e-mail ao Especialista de Contabilidade.

### Domínio WEB
- Geração de arquivo, importação web ou preenchimento em página web → incluir: *"Esta implementação deve ser preparada para rodar no Domínio WEB."*
- Certificado digital: alinhar com gerência/diretoria antes de definir arquitetura.
- Alterações de comunicação entre sistemas → envolver time DevOps + Diretor + Gerente Sênior de Desenvolvimento.

### Performance
- Nova funcionalidade com grande volume de dados → incluir: *"Na implementação desta funcionalidade deve existir a preocupação com a performance, e realizado testes em bancos com grande volume de dados em [descrever tipo e quantidade de movimentos/cadastros]."*
- Se semelhante a funcionalidade já existente: referenciar o processo atual para comparar tempo.

### Botão Conteúdo Contábil Tributário
- Melhoria, Implementação Legal ou Alteração Legal → verificar no **Checkpoint** se há roteiros/legislação/tabelas e definir o caminho de busca na SAI.

### Alíquota ICMS (DIFALI / ICMSA / ST-AT — impostos 8, 27, 31)
Use a hierarquia do manual (seção 1.17) para definir alíquota **interna** e **interestadual**; não resumir — detalhar cada passo de busca conforme o manual.

---

## 9. Padrões que NÃO devem ser informados na definição

| Situação | Por quê não consta |
|---|---|
| F2 (listagem do cadastro padrão) | Gerada automaticamente; só definir se a listagem for diferente do padrão |
| F7 | Sempre permitido, exceto em telas "response" (nesse caso, informar na SAI) |
| Vigências em Escrita/Patrimônio | Mensagem padrão automática; só informar se o comportamento for diferente |
| Campos somente com valores positivos | Padrão; só informar se aceitar negativos |
| Sigla UF no início da descrição | Já indica que é específico daquele Estado |
| Tamanho dos campos nos relatórios — truncamento | Alfanumérico: primeiros caracteres; numérico: últimos. Só informar se diferente |
| Data inválida → "Data inválida." | Validação padrão automática |
| Código inexistente → "Código inválido." | Validação padrão automática |
| Botão Seleção com seleção gravada | Descrição sublinhada + asterisco — padrão automático |
| Relatório sem dados → mensagem padrão | Só informar se a mensagem for "Sem movimento." ou diferente do padrão |
| Afastamentos novos no Botão Seleção de empregados | Criado automaticamente no botão ao criar novo afastamento |
| Alinhamento de Grid | Padrão (títulos centralizados, dados por tipo) — só informar diferenças |
| Campo de caminho de arquivo | 260 caracteres + botão reticências — padrão |
| Delimitadores nos campos dos informativos | Removidos automaticamente na geração do arquivo |
| Foco nas janelas | Seguir padrão do manual (sec. 1.28.14); só informar comportamentos diferentes |
| Ordem das mensagens de validação | Segue a ordem dos campos; só informar se diferente |
| Revisões: texto retirado | Destacar em laranja + tachado; remover na próxima revisão |
| Cabeçalho de relatórios | Não incluir no modelo; só se houver alteração no cabeçalho |
| Atualização do banco | Sempre informar se deve ou não ocorrer alteração |
| Botão em grid | Nunca recebe foco; só acessa com mouse — padrão |
| Botão Importar | Importa sem mensagem — padrão; só informar se precisar de confirmação |
| Linhas vazias nas grids | Excluídas ao gravar — padrão; só informar se diferente |
| Novos utilitários/instaladores | Mensagem padrão de diretório raiz; já está subentendida |

---

---

## 11. Regras específicas — módulo Importação (Manual v1.5)

> Aplicar **além** das seções 1–9 quando a PSAI for do módulo Importação.

### 11.1 Tópicos principais de Importação

Os tópicos específicos deste módulo (MAIÚSCULAS + negrito, separados por linha horizontal):
**GERAL · CONFIGURAÇÃO DE IMPORTAÇÃO · IMPORTAÇÃO · ERROS E ADVERTÊNCIAS · EXEMPLOS**

### 11.2 Exemplos com cálculo de impostos

Em exemplos de cálculo de impostos na importação, demonstrar:
- Quais valores da nota serão considerados.
- A **memória de cálculo** passo a passo.
- Mais de um exemplo quando houver variações.

### 11.3 Descrição (campo Descrição da PSAI)

- Citar **quais importações** estão sendo tratadas (exceto quando a definição cobrir todas).
- UF específica: iniciar com a sigla em maiúsculo.

### 11.4 Regras de definição exclusivas de Importação

| Regra | Detalhe |
|---|---|
| **Alteração originada por SAI na Escrita** | Tratar também: Portal NFe/CTe/CTe-OS, Importação XML e Importação SPED Fiscal. |
| **XML ↔ Portal** | Sempre que definir Importação XML, definir também para o Portal e vice-versa. |
| **Campo novo em telas importadas** | Se criado em Fornecedores, Produtos, Notas etc., definir o mesmo campo no leiaute completo com separador. |
| **Destaque de regra alterada** | Descrever a **regra completa existente** e destacar em **amarelo** apenas a parte alterada. |
| **Valor do ICMS para diferencial** | Primeiro: pegar o ICMS da própria nota. Se inexistente: definir se deve ou não ser encontrado automaticamente. |
| **Erros e Advertências** | Tratados de forma geral para todas as importações, salvo se especificado para um tipo. |
| **Campo com regra para habilitar/desabilitar** | Definir na SAI quais regras habilitam o campo para preenchimento. |
| **Campo sem valor** | Deixar claro se o campo fica em **branco/nulo** ou **zero**. |
| **Rotinas Automáticas** | Quando alterar telas de Configuração de Importação ou a importação em si: definir o impacto nas Rotinas Automáticas. |
| **Data considerada (Entrada ou Emissão)** | Comportamento novo ou opção em importação de entradas: informar qual data será usada. |
| **Resumo simultâneo** | Alteração que impacta a tela de Resumo da Importação: verificar se há possibilidade de importação de entrada e saída simultânea; se sim, separar a listagem das notas. |
| **ICMS — % base de cálculo do acumulador** | Ao definir base de 1-ICMS, 8-DIFALI, 27-ICMSA, 31-ST/AT ou Fundo de Combate à Pobreza: considerar a opção "Considerar o percentual de base de cálculo do ICMS do cadastro do acumulador". |
| **Threads** | Ao definir comportamento com Threads: criar obrigatoriamente a opção **"Nenhum"** para tornar o uso opcional. |

### 11.5 Alíquota ICMS — diferença específica para Importação

A hierarquia é a mesma do Manual Geral (seção 8), com uma diferença na **alíquota interestadual**:

> **1º passo (Importação):** pegar a alíquota do campo **"Alíquota do ICMS Normal"** ou da tag XML **`pICMS`**, somente se valor > zero.  
> Os demais passos seguem a mesma ordem do Manual Geral (tabela produto → acumulador → imposto → cadastro UF fornecedor).

### 11.6 Padrões que não devem constar — exclusivos de Importação

| Situação | Padrão |
|---|---|
| **Importador** | Nova tabela em tela da Escrita que já é importada pelo Importador: verificar impacto na rotina existente. Se positivo, solicitar SAI para liberar a nova tabela no Importador. |
| **UF da alteração** | Novo campo em configurações de importação fica **liberado para todas as UFs** mas **habilitado apenas para a UF da SAI**. Não precisa constar na definição. |

---

## 12. Padrão de interface de janelas — Desktop (Manual v1.1)

> Aplicar **sempre que a PSAI criar ou alterar telas/janelas** no sistema.

### 12.1 Tamanho

- Formato **widescreen**, proporcional a **765 × 495** (respeitando 800×600).

### 12.2 Nomes — uso de maiúsculas e minúsculas

| Elemento | Regra |
|---|---|
| Títulos de janelas, menus, submenus, guias | Primeira letra maiúscula, restante minúsculo. Preposições (de, para, com, em, e, etc.) permanecem minúsculas quando entre outras palavras. |
| Grupos, botões e todos os campos | Apenas a **primeira letra da primeira palavra** maiúscula; demais palavras minúsculas. |
| Siglas | **Todas as letras maiúsculas** em qualquer lugar. |
| Nomes próprios | Primeira letra maiúscula, resto minúsculo (exceto siglas). |
| Colunas de grid | Apenas a primeira letra da primeira palavra maiúscula. |
| Abreviações | **Proibidas** em menus, submenus, janelas, campos e grupos. |

### 12.3 Nome da janela

| Situação de abertura | Regra de nomenclatura |
|---|---|
| Diretamente por um menu (sem submenu) | Nome idêntico ao menu. |
| Por submenu | Combinação: `[submenu] de [menu]`. Ex: menu Notas Fiscais + submenu Emissão → **"Emissão de Notas Fiscais"**. |
| Por botão na tela | `[nome da janela pai] - [nome do campo que antecede o botão ou nome do botão]`. Ex: cadastro Empregados, botão ao lado do campo Estabilidade → **"Empregado - Estabilidade"**. |
| Janela acessível também por menu | Manter o nome do menu (não aplica a regra do botão). |

### 12.4 Janelas de cadastro

- Botões obrigatórios: **Novo, Editar, Gravar, Listagem** (direita ou abaixo alinhados à direita).
- **Exclusão**: sempre pelo botão auxiliar do mouse (botão direito).
- Primeiros campos: **Código** e **Descrição/Nome** com setas de navegação.
- Com guias: campos de identificação **acima das guias**.
- Com grupos: campos de identificação **acima dos grupos**, sem grupo próprio.
- Todos os demais campos **devem estar em grupos**; nenhum grupo pode ficar sem nome; nenhum campo pode ter o mesmo nome do grupo que o contém.
- Guia com apenas um grupo: proibido (salvo quando houver muitos campos com nomes repetidos dentro das guias).
- Grid sozinha na janela/guia: não precisa de grupo. Com outros campos: precisa de grupo tanto para a grid quanto para os outros campos.

### 12.5 Janelas de relatórios, informativos e guias

- Todos os dados devem estar em **um grupo**.
- Botões: sempre no **lado direito** da janela.
- Botão de saída: sempre **"Fechar"** (nunca "Cancelar").
- Botão de emissão: sempre **"OK"**.

### 12.6 Alinhamento de grupos, campos e grids

- Grupos: alinhados à esquerda e à direita, distribuição **uniforme**.
- Grupos lado a lado com alturas diferentes: o menor deve ter a **mesma altura** do maior.
- Grids: devem **ocupar todo o espaço disponível** (largura e altura do container).

### 12.7 Foco (consolidado com Manual Geral)

| Tipo de janela | Regra de foco |
|---|---|
| Cadastro | Foco inicial no botão **Novo** (ou de inserção). Após acionar: vai para o **segundo campo**. Após último campo: vai para **Gravar**. Após Gravar: retorna ao segundo campo. |
| Processo / Relatório | Foco no **primeiro campo** da janela. |
| Janela com Novo/Editar/Gravar/Listagem | Foco no botão **Novo**. |
| Ordem de mudança | Esquerda → direita, último da direita → primeiro abaixo. Em grupos: mesma lógica entre grupos. Em guias: último campo da guia → primeiro campo da próxima guia. Em grids: foco inicial no botão **Incluir**. |
| Mudança de foco | Sempre permitida com **Enter** e **Tab**. |
| Botão em grid | **Nunca recebe foco**; acessado somente com mouse. |

### 12.8 Maximizar

- Botão Maximizar: habilitado **somente** em janelas redimensionáveis.
- A informação de que a janela é redimensionável **deve constar na SAI**.

---

## 13. Referência cruzada

### Manual Geral (PSAI v1.3.9)

| Assunto | Seção |
|---|---|
| Formatação geral | 1.1–1.3 |
| Exemplos | 1.4 |
| Telas | 1.5 |
| Relatórios | 1.6 |
| Tabelas | 1.7 |
| Destacar alterações | 1.8 |
| Atualização de banco | 1.9 |
| Padrões de campos | 1.10 |
| ONVIO Portal / Domínio Cliente / ONVIO Processos | 1.11–1.13 |
| Mensagens | 1.14 |
| Descrição e Definição | 1.15–1.16 |
| Alíquota ICMS | 1.17 |
| Importação Padrão | 1.18 |
| Honorários / Auditoria / Protocolo / Permissões | 1.19–1.22 |
| Domínio WEB / Performance / Patrimônio / Contabilidade | 1.23–1.26 |
| ONVIO – Tabelas de Informativos | 1.27 |
| O que NÃO informar | 1.28 |
| Botão Conteúdo Contábil Tributário | 1.29 |
| **Checklist final** | **1.30** |

### Manual de Importação Padrão (v1.5)

| Assunto | Seção |
|---|---|
| Tópicos e formatação | 1.1–1.4 |
| Telas e tabelas | 1.5–1.6 |
| Destacar alterações | 1.7 |
| Atualização de banco / padrões de campos | 1.8–1.9 |
| Domínio Cliente / Mensagens | 1.10–1.11 |
| Descrição / Definição e regras específicas | 1.12–1.13 |
| Permissões / Domínio WEB | 1.14–1.15 |
| O que NÃO informar (incl. Importador e UF) | 1.16 |

### Manual de Janelas (v1.1)

| Assunto | Seção |
|---|---|
| Tamanho das janelas | 1 |
| Nomes — maiúsculas/minúsculas | 2 |
| Nomes de janelas | 3 |
| Janelas de cadastro | 4 |
| Janelas de relatórios, informativos e guias | 5 |
| Alinhamento de grupos, campos e títulos | 6 |
| Foco | 7 |
| Maximizar janelas | 8 |

### Validação das NEs (v1)

> Guia completo em `GUIA-validacao-ne.md`.

| Assunto | Seção do guia |
|---|---|
| Validação da NE recebida (descrição e comportamento) | 1 |
| Como montar Comportamento para geração da SAI | 2 |
| Informações sobre a análise | 3 |
| Classificação das NEs (Grave / Alta / Média) | 4 |
| SAIs no Board de desenvolvimento | 5 |
| Checklist rápido antes de colocar como "analisada" | 6 |
