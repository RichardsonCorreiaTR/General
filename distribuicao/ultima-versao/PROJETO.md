# PROJETO -- Escrita: Projeto do Analista

> **ATENCAO AGENTE**: Nunca leia este arquivo inteiro. Busque a secao relevante.

---

## 1. O que e este projeto

Este e o **Projeto do Analista** -- sua ferramenta de trabalho para criar
PSAIs e SAIs do módulo Escrita Fiscal (Domínio Contábil) com apoio de IA.

A IA conduz uma analise profunda antes de gerar cada definicao:
- Busca SAIs e definicoes relacionadas automaticamente
- Analisa o codigo-fonte e traduz para linguagem de produto
- Identifica todos os cenarios e casos de borda
- Gera a PSAI ou SAI no formato tradicional, completa e sem ambiguidade

---

## 2. Estrutura de pastas

```
projeto-filho/
+-- .cursor/rules/          <-- Regras da IA (nao mexer)
|   +-- guardiao.mdc        <-- Protecao e padronizacao
|   +-- agente-produto.mdc  <-- Pipeline de analise de produto
|   +-- agente-codigo.mdc   <-- Analise de codigo traduzida
|   +-- onboarding.mdc      <-- Wizard de primeiro uso
|   +-- projeto.mdc         <-- Contexto do projeto
+-- PROJETO.md              <-- Este arquivo
+-- SETUP.md                <-- Guia de configuracao inicial
+-- GUIA-RAPIDO.md          <-- FAQ, atalhos e exemplos
+-- PILOTO.md               <-- Roteiro de teste
+-- config/
|   +-- analista.json       <-- Sua identificacao (nome, email)
|   +-- caminhos.json       <-- Paths configurados pelo instalador
|   +-- VERSION.json        <-- Versao do projeto
+-- templates/
|   +-- TEMPLATE-psai.md    <-- Modelo de PSAI
|   +-- TEMPLATE-sai.md     <-- Modelo de SAI (GERAL/PROCESSOS/ARQUIVO/CONTROLE/RELATORIOS)
+-- meu-trabalho/
|   +-- em-andamento/       <-- Seus rascunhos e definicoes em progresso
|   +-- concluido/          <-- Definicoes finalizadas (insumo para SGD)
+-- scripts/
|   +-- verificar-ambiente.ps1   <-- Diagnostico do ambiente
|   +-- atualizar-projeto.ps1    <-- Atualiza para versao mais recente
|   +-- atualizar-codigo.ps1     <-- Baixa codigo-fonte do git
+-- referencia/             <-- Links para pastas do OneDrive (somente leitura)
    +-- banco-dados/        <-- (sincronizado do OneDrive)
    +-- logs/               <-- (seus logs no OneDrive)
```

---

## 3. Como usar

### Passo 1 -- Trazer a demanda
Diga a IA o que recebeu:
- "Recebi a NE 95069 sobre FGTS CCT"
- "Preciso criar uma PSAI para a SAM 12345"
- "Quero revisar a SAI 67890"

### Passo 2 -- Analise automatica
A IA vai:
- Buscar SAIs e definicoes relacionadas
- Analisar o codigo-fonte e explicar o comportamento atual
- Identificar todos os cenarios que precisam ser cobertos

### Passo 3 -- Refinar juntos
Voce e a IA discutem os cenarios:
- "Esse cenario tambem precisa cobrir transferencia entre empresas"
- "O que acontece quando o funcionario tem multiplos vinculos?"

### Passo 4 -- Gerar a definicao
A IA gera a PSAI ou SAI completa no formato tradicional.
Voce revisa e ajusta o que precisar.

### Passo 5 -- Concluir
Mova o arquivo de `em-andamento/` para `concluido/`.
O artefato serve de insumo para preenchimento e submissao no SGD.

---

## 4. Regras importantes

- **NAO modifique** os templates em `templates/`
- **NAO modifique** nada em `referencia/` (e somente leitura)
- **NAO modifique** as regras em `.cursor/rules/`
- **SEMPRE** use o pipeline de analise para novas definicoes
- **SEMPRE** informe o codigo PSAI/SAI/NE ao iniciar uma demanda
- **SEMPRE** revise os cenarios antes de finalizar

---

## 5. Buscar SAIs e PSAIs

Os indices de SAIs estao em `referencia/banco-dados/sais/indices/`.
**IMPORTANTE**: Os indices contem descricoes truncadas (80 chars). Para
qualquer analise, a busca profunda e obrigatoria (ver abaixo).

### Para o analista (terminal manual)

Abra um terminal separado (fora do Cursor):
```
cd "C:\Users\{seu-usuario}\Thomson Reuters Incorporated\CursorEscrita - General"
powershell -File scripts\buscar-sai.ps1 -Termo "INSS"
powershell -File scripts\buscar-sai.ps1 -Termo "ferias" -Tipo NE -Pendentes
```

### Para a IA (automatico)

A IA DEVE rodar a busca profunda via Shell tool automaticamente em TODA
consulta sobre SAIs/PSAIs. O protocolo completo esta em agente-produto.mdc.
A IA NAO deve apresentar resultados baseados apenas nos indices MD.

---

## 6. O que esta disponivel para consulta

| Conteudo | Local | Descricao |
|---|---|---|
| Glossario | `referencia/banco-dados/glossario/` | Termos por categoria |
| Fluxos | `referencia/banco-dados/fluxos/` | Processos dos modulos |
| Legislacao | `referencia/banco-dados/legislacao/` | Normas por area |
| Mapa do sistema | `referencia/banco-dados/mapa-sistema/mapa-escrita.md` (+ `indice-mapas-areas.md`) | Estrutura do codigo Escrita e demais areas PBCVS |
| Indices de SAIs | `referencia/banco-dados/sais/indices/` | Pendentes, por versao |
| Definicoes aprovadas | `referencia/banco-dados/regras-negocio/` | Por modulo |

---

## 7. Scripts uteis

| Script | O que faz |
|--------|-----------|
| `.\scripts\verificar-ambiente.ps1` | Diagnostico completo do ambiente |
| `.\scripts\atualizar-projeto.ps1` | Atualiza para versao mais recente |
| `.\scripts\atualizar-codigo.ps1` | Baixa codigo-fonte do git |

---

## 8. Suporte

Duvidas sobre o processo? Pergunte a IA:
- "Como funciona o processo de analise?"
- "O que devo preencher no campo X?"
- "Como submeter minha definicao?"

Consulte tambem o `GUIA-RAPIDO.md` para FAQ e atalhos.
