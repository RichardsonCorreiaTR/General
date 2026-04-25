# Guia de Validação e Geração de SAI — NE (Notificação de Erro)

> Baseado no documento **"Validação das NEs v1"** (Escrita Fiscal).
> Use como referência durante a análise de NEs e montagem do comportamento para geração da SAI.

---

## 1. Validação da NE recebida

### 1.1 Descrição da NE

- Deve ser **breve e resumida**, mas suficiente para compreender o erro.
- **Não deve** ter quebra de linhas.
- **Erro de banco de dados:** o erro de banco **não entra na descrição** — vai no Comportamento.

### 1.2 Comportamento da NE

- Deve conter **passo a passo** reproduzível em **empresa nova**.
- Todos os cadastros principais e lançamentos necessários para reproduzir o erro precisam estar descritos de forma clara.
- Se houver indicação de anexo: **confirmar se o anexo foi incluído na NE**.
- **Banco de dados de cliente:** devem constar obrigatoriamente:
  - Caminho do banco
  - Senha para descompactar
  - Usuário e senha (ou resposta da pergunta secreta)
- **Banco de dados de cliente + erro de BD:** necessário informar o **número da SS** onde o desenvolvimento avaliou o erro.
  - Exceção: erros de sistema ou de banco de dados puros podem ser cadastrados direto, sem análise do desenvolvimento na SS.
- **Antes de gerar PSAI:** avaliar na SS as SAIs que foram observadas pelo suporte (podem ajudar a verificar se é erro da versão de mercado ou não).

---

## 2. Como montar o Comportamento para geração da SAI

### 2.1 Descrição da SAI de NE

A descrição deve ser **breve e resumida**, mas conter **três informações**:
1. **Qual** é o erro.
2. **Onde** o erro está ocorrendo.
3. **Quando** o erro ocorre.

**Exemplos corretos:**
- *"Está sendo gerado indevidamente valor nas linhas 012, 014 e 016 do relatório 'Registro de IPI', quando a empresa for optante do Simples Nacional e o modelo for 8II."*
- *"SP - Está sendo setada a base de cálculo incorreta na grade 'Impostos' do imposto 27-ICMSA da janela de lançamento de nota de entrada, quando o regime do fornecedor for diferente de ME/EPP-Simples Nacional e houver valor nos campos IPI e/ou ICMS ST."*

**Regras adicionais de descrição:**
- UF específica: sigla em maiúsculo **no início** da descrição.
- **Erro de banco de dados de cliente:** sempre iniciar com **"Em alguns casos..."** e **não usar "quando"** (não há um gatilho fixo — é algo específico do banco).
  - *"Em alguns casos está considerando o campo incorreto do mês do arquivo da DMA ao realizar o Cruzamento SPED Fiscal x DMA."*

### 2.2 Comportamento da SAI

- Informar **todos os processos** feitos para reproduzir o erro.
- **Sempre separar por tópicos** (Menu/Submenu do sistema) para clareza entre todos os setores.
- Cada item **não deve mencionar novamente o tópico** (o menu/submenu já indica o caminho).
- Informações adicionais importantes → tópico **"Observações"**.
- **Foco no erro do cliente.** Outros casos testados → vão para Observações.
  - *Ex: erro relatado em Entradas, mas verificado que também ocorre em Saídas e Serviços → Comportamento mostra Entradas; Observações informa os demais.*
- Mais de um comportamento na SAI: raro, mas possível; avaliar caso a caso.
- Mais de um **"sendo correto"** na SAI: cada um deve estar **destacado em amarelo**.

### 2.3 Tópico "Banco de Dados" (obrigatório quando reproduzido no banco próprio)

Incluir ao final da análise quando a situação for reproduzida no banco de dados próprio:

```
Banco de Dados
Código da empresa: [número da NE ou PSAI]-[Nome do analista]
Exemplo: 1111-Jennifer
```

- Cada analista deve ter pasta no SharePoint com seu nome e atualizar o banco ao final de cada dia.
- Banco de cliente: o tópico "Banco de Dados" deve ser o **primeiro tópico** da análise, com caminho, senha, usuário/senha e código da empresa.
- Banco de cliente deve ser disponibilizado no SharePoint na pasta **"PSAI XXXX"** (XXXX = número da PSAI).

---

## 3. Informações sobre a análise

| Regra | Detalhe |
|---|---|
| **Empresa nova** | O comportamento sempre deve ser feito em **empresa nova**. Cada NE tem sua própria empresa (exceto quando o erro é específico do ambiente do cliente). |
| **NE de banco de cliente** | A SS vinculada deve ter passado obrigatoriamente pela análise do desenvolvimento ou GP (exceto algumas situações de erro de banco de dados). |
| **Campo "Erro da versão anterior"** | Preencher **somente** quando houver certeza de qual versão provocou o erro. |
| **Anotações** | Incluir todas as SAIs usadas como base, informações relevantes, testes feitos e todas as SAIs consultadas. |
| **"Sendo correto"** | Todo "sendo correto" precisa ter base em uma SAI. Se não houver, avaliar se é NE com definição ou SA. Conversas com outras pessoas também devem ser anotadas. |
| **Versão de teste** | Testar na **versão de mercado** com o último arquivo disponível. |
| **Testes em versões anteriores** | Mínimo de **2 versões anteriores** para confirmar que o erro não surgiu apenas na última versão. Sempre com empresa nova. Nunca testar em empresas existentes. |
| **Banco de cliente: versão anterior** | Apenas o teste da versão anterior, via modo de desenvolvimento. |
| **NE grave ou possível propagação** | Ao colocar como "analisada", avisar o Especialista. |
| **NE grave: prioridade máxima** | Para análise de GP, desenvolvimento e testes. |
| **Colocar como "analisada"** | Somente quando houver certeza de que é um erro. |
| **Não conseguiu reproduzir** | Fazer dúvida para a unidade informando isso. |
| **Certificado digital** | Nunca incluir no comportamento da NE. Enviar ao teste/desenvolvimento após a SAI ser gerada. |
| **NE interna** | Incluir **"NE Interna"** em amarelo no início do comportamento. No campo "Unidade": selecionar **"Unidade de Produção e Gestão - UpeG"**. Não entra no controle de metas. |
| **Classificação funcional** | Todas as NEs da Escrita são **funcionais**. Se a UN cadastrar como "Técnica", o analista deve corrigir. Não invalida pela classificação. |
| **Campo "Ocorre em versão anterior"** | Preencher se o erro for da versão de mercado ou da versão anterior. Senão: selecionar "Não provocado pela versão anterior". |
| **Campo "Erro da versão anterior"** | Preencher somente com certeza de qual versão provocou. |

---

## 4. Classificação das NEs para geração de SAIs

| Classificação | Critério | Prazo | Arquivo |
|---|---|---|---|
| **Grave** | Mais de 4 SSCs. Ou processo grave, erro de versão com alto risco de impacto em vários clientes. | Até **5 dias** | Próximo arquivo disponível |
| **Prioridade Alta** | Podem se tornar graves se demorar. Informativos, cálculo, utilitário com erro surgido na versão. | O mais rápido possível (não há prazo fixo, mas se ultrapassar 5 dias e virar grave → impacta meta / RDM) | Próximo arquivo de atualização |
| **Prioridade Média** | Informativos ou cálculo sem urgência grave; alternativa para o cliente não é viável. | Sem urgência extrema | Arquivos de **quinta-feira** |
| **Sem prioridade** | Demais casos. | — | — |

> Se uma NE começar a acumular SSCs após ser gerada → reclassificar para grave e alinhar entre setores para adiantar o arquivo.

---

## 5. SAIs incluídas no Board (desenvolvimento)

| Campo do Board | O que informar |
|---|---|
| **Tipo** | Bug |
| **Descrição** | Número da SAI + descrição |
| **Repro Steps** | Link da SAI |
| **Severity** | "1-Critical" (somente para NE grave) |
| **Customer Reported** | "True" (NE de cliente) / "False" (NE interna) |
| **Tags** | "Banco de Dados" (se for erro de banco); "NE Interna" (se for interna); tag com **dia e mês** da liberação (se for para arquivo) |
| **Coluna** | "Backlog" (sem prioridade) / "Sort NE" (para liberar em arquivo) |
| **Notificação** | NEs graves ou prioridade alta: marcar Especialista de Testes e Desenvolvimento |

---

## 6. Checklist rápido — antes de colocar a NE como "analisada"

- [ ] Descrição com as três informações (qual, onde, quando) ou formato "Em alguns casos..." (banco cliente).
- [ ] Comportamento com passo a passo em empresa nova, separado por tópicos de Menu/Submenu.
- [ ] Banco de dados: informações completas (se aplicável) e disponibilizado no SharePoint.
- [ ] SS do desenvolvimento informada (se banco de cliente — exceto erro de BD puro).
- [ ] Testado na versão de mercado + mínimo 2 versões anteriores.
- [ ] Todas as SAIs consultadas anotadas; "sendo correto" com base em SAI.
- [ ] Tópico "Banco de Dados" ao final com código empresa + nome do analista.
- [ ] Backup do banco feito e salvo no SharePoint.
- [ ] Classificação funcional confirmada (não "Técnica").
- [ ] Campo "Ocorre em versão anterior" / "Erro da versão anterior" preenchidos corretamente.
- [ ] NE interna: "NE Interna" em amarelo no comportamento + Unidade "UpeG".
- [ ] Especialista avisado (se NE grave ou possível propagação).
