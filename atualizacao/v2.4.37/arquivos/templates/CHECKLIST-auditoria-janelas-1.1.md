# Checklist de auditoria — Interface Desktop (Janelas) v1.1

> Referência: *Manual da Definição de Padrão de Interface de Desenvolvimento para Sistemas Desktop* **versão 1.1**. PDF exemplo: `Manual de Janelas 1.1 (1).pdf`.  
> Aplicar quando a PSAI **criar ou alterar** telas/janelas.

## 1. Tamanho (Manual §1)

- [ ] Formato **widescreen**, proporcional a **765 × 495** (respeitando **800×600**).

## 2. Nomes — maiúsculas/minúsculas (§2)

- [ ] Títulos de janelas, menus, submenus, guias: **primeira maiúscula**, restante minúscula; preposições (de, para, com, em, e…) minúsculas entre palavras.
- [ ] Grupos, botões, campos: só **primeira letra da primeira palavra** maiúscula.
- [ ] Siglas: **todas maiúsculas**.
- [ ] Nomes próprios: primeira maiúscula, resto minúsculo (exceto siglas).
- [ ] Colunas de grid: primeira letra da primeira palavra maiúscula.
- [ ] **Sem abreviações** em menus, submenus, janelas, campos, grupos.

## 3. Nome da janela (§3)

- [ ] Aberta **direto pelo menu** (sem submenu): nome **idêntico** ao menu.
- [ ] Aberta por **submenu**: `[Submenu] de [Menu]` (ex.: Emissão de Notas Fiscais).
- [ ] Aberta por **botão**: `[Janela pai] - [campo antes do botão ou nome do botão]` — exceto quando também aberta por menu (mantém nome do menu).

## 4. Janelas de cadastro (§4)

- [ ] Botões: **Novo, Editar, Gravar, Listagem** (direita ou abaixo, alinhados à direita).
- [ ] **Exclusão** só por botão auxiliar do mouse.
- [ ] Primeiros campos: **Código** e **Descrição/Nome** com setas de navegação.
- [ ] Com **guias**: identificação **acima** das guias.
- [ ] Com **grupos**: identificação **acima** dos grupos, sem grupo próprio para identificação.
- [ ] Demais campos em **grupos** nomeados; sem grupo sem nome; sem campo com mesmo nome do grupo.
- [ ] Guia com **apenas um grupo**: proibido (salvo exceção do manual com muitos nomes repetidos).
- [ ] **Só grid** na janela/guia: pode sem grupo; com outros campos: grupo para grid **e** para os outros campos.

## 5. Relatórios, informativos e guias (§5)

- [ ] Dados em **um grupo**; botões à **direita**; saída **Fechar**; emissão **OK**.

## 6. Alinhamento (§6)

- [ ] Grupos alinhados esquerda/direita, distribuição uniforme; mesma altura quando lado a lado.
- [ ] Grids ocupam **todo** o espaço do container.

## 7. Foco (§7) — alinhar ao manual geral §1.28.14

- [ ] Cadastro: foco inicial **Novo** (ou inserção); após ação, **segundo campo**; após último campo → **Gravar**; após Gravar → segundo campo.
- [ ] Processo/Relatório: foco no **primeiro campo**.
- [ ] Ordem Tab/Enter; grid: foco inicial em **Incluir**; botão em grid **sem foco** (mouse).

## 8. Maximizar (§8)

- [ ] Maximizar só em janelas **redimensionáveis**; PSAI deve dizer que a janela é redimensionável quando aplicável.

---

**Esta PSAI altera interface?** Sim / Não — se Não, N/A com uma linha.
