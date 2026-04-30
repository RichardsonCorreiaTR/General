# Checklist de auditoria — Reflexos (Pré-SAI/SAI)

> Referência: *Manual de Padrão de Pré-SAI e SAI* — documento **“Análise de reflexos”** (PDF: `Manual de PSAI - Reflexos.pdf`).  
> Uso: para cada alteração, perguntar se o tema abaixo se aplica; se sim, a PSAI deve **tratar ou justificar** omissão.

## 1. ONVIO Portal do Cliente (§1.1)

- [ ] Avaliado impacto no **Portal do Cliente**.
- [ ] Relatório/guia a salvar no Portal: **pasta** indicada (criar se não existir).
- [ ] Relatório/guia **sem** reflexo no Portal: **não** mencionar na definição.
- [ ] Folha + processos integrados ao Portal: avaliar reflexo.
- [ ] Testes Portal: credenciais GP / comunicação ao time (conflito de testes).

## 2. Domínio Cliente (§1.2)

- [ ] Campos em **Produtos** ou **Movimentos de Notas**: tópico **Domínio Cliente** definido quando necessário.
- [ ] Lista de cadastros **já exportados** automaticamente: não redundar; **novos** processos/cadastros: avaliar disponibilização + utilitários + e-mail ao Especialista.

## 3. ONVIO Processos (§1.3)

- [ ] Processo novo/alterado: botão **"Concluir Atividade"** + e-mail ao Especialista para inclusão no módulo.

## 4. Importação Padrão (§1.4)

- [ ] Campo novo em notas/cupons/produtos/clientes/fornecedores/remetentes/destinatários: **reflexo na importação padrão** citado na SAI gerada.
- [ ] Novo **tipo** de importação de NF: comportamento do campo **"Origem"** definido.

## 5. Honorários (§1.5)

- [ ] Pontos que **exigem** e-mail ao Especialista + SAI em Honorários quando alterados (Pagamentos, e-CAC, Nota Entrada, Acumulador/Imposto/Produto integração, Cadastro Empresas, Lalur e-CAC, etc., conforme PDF).
- [ ] Pontos que **não** precisam SAI em Honorários (ex.: Fornecedores, Novos Impostos com reflexo automático) — não exigir redundância.

## 6. Domínio Auditoria (§1.6)

- [ ] Tela/processo novo: **auditado?** O quê auditar? **Nome da tabela** de auditoria?

## 7. Protocolo (§1.7)

- [ ] Imposto novo/alterado em Folha ou Escrita: e-mail ao Especialista Contábil para SAI no **Protocolo**.

## 8. Permissões de usuários (§1.8)

- [ ] Novos cadastros/movimentos/processos: permissões **Incluir/Alterar/Excluir** por usuário definidas quando aplicável.

## 9. Domínio WEB (§1.9)

- [ ] Geração de arquivo, importação web, preenchimento web: frase **“Esta implementação deve ser preparada para rodar no Domínio WEB.”** quando aplicável.
- [ ] Certificado digital: alinhamento gerência/diretoria.
- [ ] Alterações de **comunicação entre sistemas**: DevOps + Diretor + Gerente Sênior (e SAI 87776 como precedência citada no manual).
- [ ] Novas **FARMs**: processo de estudo / infra / prioridade Domínio WEB conforme manual.

## 10. Performance (§1.10)

- [ ] Grande volume: frase de **performance** + tipos/quantidades de dados para teste **ou** referência a processo semelhável aceitável **ou** contato com GP se não houver referência.

## 11. Patrimônio (§1.11)

- [ ] Alterações nos pontos listados (Outros créditos PIS/COFINS Imobilizado, Impostos Lançados Estadual ICMS imobilizado, Impostos Calculados ganho/perda capital): e-mail ao Especialista + SAI Patrimônio.

## 12. Contabilidade / SPED ECF (§1.12)

- [ ] Apuração **CSLL (6)** ou **IRPJ (7)** alterada na Escrita: e-mail ao Especialista Contabilidade.

## 13. Botão Conteúdo Contábil Tributário (§1.13)

- [ ] Melhoria / impl. legal / alt. legal: **Checkpoint** consultado; roteiros/legislação/tabelas e **caminho de busca** na PSAI quando aplicável.

---

**Resumo:** listar reflexos **esquecidos** com `[Seção PSAI → …]` e criticidade (bloqueante / importante / recomendada).
