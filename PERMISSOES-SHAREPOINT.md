# Configuracao de Permissoes — SharePoint/OneDrive

## Objetivo

Garantir que analistas consigam LER a base de conhecimento mas NAO consigam
alterar arquivos do projeto principal.

## Acesso ao site

URL: https://trten.sharepoint.com/sites/CursorEscrita

Biblioteca sincronizada: **Documentos** > **General** (alinhado a `PROJETO.md` secao 5).

## Passo 1 — Acessar configuracoes do site

1. Abra https://trten.sharepoint.com/sites/CursorEscrita
2. Clique na engrenagem (canto superior direito) > **Configuracoes do site**
3. Em **Permissoes do site**, clique em **Permissoes avancadas**

## Passo 2 — Criar grupos de permissao

### Grupo: CursorEscrita - Gerentes
- **Nivel**: Controle Total (Full Control)
- **Membros**: Voce e quem mais precisar atualizar o projeto
- **O que pode fazer**: Criar, editar, excluir qualquer arquivo

### Grupo: CursorEscrita - Analistas
- **Nivel**: Leitura (Read)
- **Membros**: Os ~17 analistas de produto
- **O que pode fazer**: Ler e sincronizar arquivos, NAO pode editar

## Passo 3 — Configurar permissoes na biblioteca de documentos

1. Va para **Documentos > General**
2. Clique nos `...` > **Gerenciar acesso**
3. **Pare de herdar permissoes** (se estiver herdando do site)
4. Adicione:
   - CursorEscrita - Gerentes → Controle Total
   - CursorEscrita - Analistas → Leitura

## Passo 4 — Excecao: pasta para-revisao dos analistas

Para que analistas possam submeter definicoes, crie permissao especial:

1. Dentro de `General`, navegue ate `projeto-filho/meu-trabalho/para-revisao/`
2. Clique `...` > **Gerenciar acesso**
3. **Pare de herdar permissoes**
4. Adicione:
   - CursorEscrita - Gerentes → Controle Total
   - CursorEscrita - Analistas → **Contribuicao** (Contribute)

Isso permite que analistas subam arquivos para revisao sem alterar o resto.

## Passo 5 — Testar

### Como gerente:
- [ ] Consigo editar arquivos em `banco-dados/`
- [ ] Consigo editar arquivos em `scripts/`
- [ ] Consigo editar arquivos em `.cursor/rules/`

### Como analista (peca para um analista testar):
- [ ] Consigo sincronizar a pasta General
- [ ] Consigo LER arquivos em `banco-dados/`
- [ ] NAO consigo editar arquivos em `banco-dados/`
- [ ] NAO consigo editar arquivos em `scripts/`
- [ ] Consigo submeter arquivos em `projeto-filho/meu-trabalho/para-revisao/`

## Alternativa simplificada

Se a configuracao granular for complexa, uma alternativa mais simples:

1. Compartilhe a pasta `General` com analistas como **Somente leitura**
2. Crie uma pasta separada `Submissoes` no SharePoint com permissao de **Contribuicao**
3. Analistas colocam definicoes prontas nessa pasta
4. Voce move para o projeto principal apos revisao

## Observacoes

- Permissoes podem levar ate 15 minutos para propagar
- Usuarios precisam re-sincronizar o OneDrive apos alteracao de permissao
- O Cursor do analista abre o `projeto-filho` local (nao o OneDrive direto)
