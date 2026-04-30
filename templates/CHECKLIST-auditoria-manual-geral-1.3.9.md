# Checklist de auditoria — Manual Pré-SAI/SAI (Escrita/Geral) v1.3.9

> Referência: *Manual de Padrão de Pré-SAI e SAI* **versão 1.3.9** (16/10/2024). PDF exemplo: `Manual de PSAI 1.3.9 (1).pdf`.  
> Uso: marcar ✓ / ✗ / N/A durante auditoria; cada ✗ exige citação `[Seção PSAI → …]`.

## 1. Formatação e estrutura (Manual §1.1–1.3)

- [ ] Fonte **Arial 12** no corpo; negrito só onde o manual exige.
- [ ] Textos/tabelas/relatórios alinhados à **esquerda sem recuo**; telas com **1 recuo**.
- [ ] Tópicos principais em **MAIÚSCULAS + negrito**, separados por **linha horizontal** (Parâmetros, Cadastros, Lançamentos, Apuração, Cálculo Folha, Guias, Livros, Informativos, Relatórios, Contabilização).
- [ ] Subtópicos = menus: **primeira maiúscula + negrito** no restante.
- [ ] Listas **numeradas**, reiniciadas a cada tópico/subtópico; detalhes com **marcador + recuo**.

## 2. Exemplos (§1.4)

- [ ] Título **"Exemplo"** em negrito (só primeira maiúscula); múltiplos exemplos numerados na descrição.
- [ ] Assuntos de **cálculo**: valores concretos; conferir se o cálculo bate com a regra.
- [ ] Assunto **complexo**: mais de um exemplo.
- [ ] Exemplo de **cálculo + relatório/informativo**: mesmos dados **ou** cálculo explícito para o segundo exemplo.

## 3. Telas (§1.5)

- [ ] Imagem **abaixo** do texto da alteração; explicação de campos **abaixo** da imagem.
- [ ] Tela com rolagem: **todas** as capturas, empilhadas.
- [ ] Revisão de tela existente: alterações em **laranja**; destaques em **retângulo vermelho**.

## 4. Relatórios (§1.6)

- [ ] Modelo **BROffice Calc**; fonte **Tahoma 8** (7 no corpo se necessário).
- [ ] Cabeçalho: página, data, hora à **direita**; exceções descritas na PSAI se houver.
- [ ] Rodapé **"Sistema licenciado para..."** quando obrigatório; exceções (ex. DIME) **justificadas na PSAI**.
- [ ] Alinhamento de dados: alfanumérico esquerda, numérico direita, data centro.
- [ ] **Largura de colunas** declarada para campos numéricos e alfanuméricos.
- [ ] **Linha em branco** abaixo do cabeçalho antes dos dados.
- [ ] **Destaque de linhas**: alternância; sem duas iguais seguidas.
- [ ] **Totalizadores**: separadores; só identificação do total em negrito.
- [ ] **Quebras**: nome em negrito; linha em branco entre quebra e dados; traço entre quebras.
- [ ] Impressão: testar Retrato 8; Paisagem se necessário; escala 100%.
- [ ] **Borda** no modelo Calc para visualização.

## 5. Tabelas (§1.7)

- [ ] Cabeçalho: negrito, Arial 12, fundo **azul** (azul 8 Writer).
- [ ] Células sem dados: sem texto, fundo **cinza claro**.
- [ ] Células alteradas: fundo **amarelo**.

## 6. Destaque e atualização (§1.8–1.9)

- [ ] Alterações destacadas conforme manual (retângulo / laranja em revisões).
- [ ] **Atualização de banco**: comportamento na atualização para campos novos/alterados (combo, checkbox, valor, data, etc.).

## 7. Mensagens (§1.14)

- [ ] Tipos: Informativa, Advertência, Interrogativa, Erro.
- [ ] Sem imagem; tipo + título + texto + botões em **`[colchetes]`** separados por vírgula se vários.
- [ ] Explicação de botões: marcador sem numeração, com recuo.
- [ ] Pontuação revisada.

## 8. Descrição e definição (§1.15–1.16)

- [ ] **Descrição** (NE): qual / onde / quando; UF no início em maiúsculas quando estadual; sem quebras de linha indevidas na NE.
- [ ] **Definição** técnica: menus, guias, opções suficientes para implementação.

## 9. Tópicos especiais do manual geral

- [ ] **Alíquota ICMS** interna/interestadual (§1.17): hierarquia completa quando aplicável.
- [ ] **Importação Padrão** (§1.18): reflexos em notas/cupons/produtos/clientes/fornecedores/remetentes/destinatários; campo **Origem** em novo tipo de NF.
- [ ] **ONVIO Portal / Domínio Cliente / ONVIO Processos** (§1.11–1.13) avaliados se pertinentes.
- [ ] **Honorários, Auditoria, Protocolo, Permissões, WEB, Performance, Patrimônio, Contabilidade/ECF, Informativos ONVIO, Conteúdo Contábil Tributário** (§1.19–1.29) quando o escopo tocar o tema.

## 10. O que não deve constar (§1.28)

- [ ] A PSAI **não** repete padrões já cobertos automaticamente pelo sistema, salvo exceção real (ver enumeração longa no manual — F2/F7, vigências padrão, mensagens padrão, etc.).

## 11. Checklist final do manual (§1.30)

- [ ] Itens do **checklist §1.30** do PDF foram considerados explicitamente (sim/N/A com justificativa).

---

**Conclusão rápida deste checklist:** ✓ conforme / ✗ não conforme / N/A — uma linha por dimensão crítica.
