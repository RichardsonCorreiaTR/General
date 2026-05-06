# Checklist de auditoria — Manual Pré-SAI/SAI Importação Padrão v1.5

> Referência: *Manual de Padrão de Pré-SAI e SAI de Importação* **versão 1.5**. PDF exemplo: `Manual de PSAI da Importação Padrão 1.5 NOVO (1).pdf`.  
> Aplicar **além** do checklist do manual geral v1.3.9 quando a PSAI for de **Importação Padrão** (e correlatos XML/Portal).

## 1. Estrutura própria do módulo (§1.2)

- [ ] Tópicos principais em MAIÚSCULAS + negrito, com linha horizontal: **GERAL · CONFIGURAÇÃO DE IMPORTAÇÃO · IMPORTAÇÃO · ERROS E ADVERTÊNCIAS · EXEMPLOS**.
- [ ] Subtópicos = menus do módulo, primeira maiúscula + negrito.
- [ ] Listas numeradas reiniciadas; detalhes com marcador + recuo.

## 2. Exemplos com impostos (§1.4)

- [ ] Em cálculo de imposto na importação: indicar **valores da nota** considerados e **memória de cálculo** passo a passo.
- [ ] Variações: **mais de um** exemplo.

## 3. Descrição (§1.12)

- [ ] Deixa claro o pedido; cita **quais importações** estão no escopo (exceto se for todas).
- [ ] UF específica: **sigla em maiúsculo no início** da descrição.

## 4. Definição — regras específicas (§1.13)

- [ ] **Origem Escrita** (§1.13.1): tratar também Portal NF-e/CT-e/CTe-OS, Importação XML e Importação SPED Fiscal quando a alteração vier da Escrita.
- [ ] **XML ↔ Portal** (§1.13.2): alteração espelhada nos dois sentidos.
- [ ] **Campo novo em telas importadas** (§1.13.3): mesmo campo no **leiaute completo com separador**, quando aplicável.
- [ ] **Destaque de regra alterada** (§1.13.5): regra **completa** existente + **amarelo** só na parte alterada.
- [ ] **ICMS para diferencial** (§1.13.6): priorizar ICMS da nota; se inexistente, definir busca automática ou não.
- [ ] **Erros e advertências** (§1.13.7): escopo geral por tipo de importação, salvo exceção explícita.
- [ ] **Campo habilitado por regra** (§1.13.8): na PSAI, quais regras habilitam o preenchimento.
- [ ] **Campo sem valor** (§1.13.9): **branco/nulo** vs **zero** explícito.
- [ ] **Rotinas automáticas** (§1.13.10): impacto ao mudar configuração ou importação.
- [ ] **Datas** (§1.13.11): entrada vs emissão (ou opção) quando comportamento novo.
- [ ] **Resumo da importação** (§1.13.12): entrada/saída simultânea — verificar listagem separada se necessário.
- [ ] **% base ICMS acumulador** (§1.13.13): considerar opção do cadastro do acumulador quando definir bases 1, 8, 27, 31, FCP, etc.
- [ ] **Threads** (§1.13.14): comportamento com threads exige opção **"Nenhum"** para uso opcional.

## 5. Alíquota ICMS importação (§1.13.4 e hierarquia)

- [ ] **Interestadual (importação)**: 1º passo — alíquota do campo **"Alíquota do ICMS Normal"** ou tag **`pICMS`** se > 0; depois alinhar demais passos ao manual geral (produto → acumulador → imposto → UF fornecedor).

## 6. Domínio Cliente, permissões, WEB (§1.10, 1.14–1.15)

- [ ] Exportações automáticas: não redundar na definição; **novos** cadastros/processos: avaliar Domínio Cliente + notificar Especialista.
- [ ] Permissões: novos cadastros/movimentos/processos — incluir/excluir/alterar conforme manual.
- [ ] Domínio WEB: frase padrão e envolvimentos DevOps/direção quando comunicação entre sistemas.

## 7. O que não informar — importação (§1.16)

- [ ] **Importador** (§1.16.13): nova tabela em tela já importada — verificar impacto e possível SAI no Importador.
- [ ] **UF da alteração** (§1.16.14): regra de liberação por UF vs habilitação — não repetir o óbvio se o manual dispensar.

---

**Escopo desta PSAI toca Importação?** Sim / Não — se Não, marcar N/A o bloco inteiro com justificativa de uma linha.
