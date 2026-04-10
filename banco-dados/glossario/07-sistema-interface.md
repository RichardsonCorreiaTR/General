# Glossario: Sistema e Interface

> Termos de navegacao e funcionalidades do sistema Folha

---

## Parametros

**Definicao:** Configuracoes gerais da empresa no sistema. Acesso: Controle > Parametros. Guias: Geral, Personaliza, Encargos, eSocial, Integracoes.

---

## Lancamento (de Eventos)

**Definicao:** Inclusao manual de valores em rubricas para um empregado. Acesso: Processos > Lancamentos.

**Tipos:**
| Tipo | Descricao |
|---|---|
| Fixo | Recorrente todo mes ate ser removido |
| Variavel | Pontual, apenas para a competencia informada |
| Primeira Folha | Usado apenas no primeiro calculo do empregado |

---

## Situacao (de Calculo)

**Definicao:** Estado do empregado durante o processamento (ativo, afastado, em ferias). Determina quais rubricas sao calculadas. Controlado por uo_calc_situacao.sru.

---

## Provisao

**Definicao:** Reserva contabil para despesas futuras de ferias e 13o salario. Calculada em Processos > Provisao Ferias e 13o. Implementada em uo_provisao_ferias.sru e uo_provisao_13.sru.

---

## Sindicato (Regras Parametricas)

**Definicao:** Cadastro que define regras de calculo especificas por convenção. Permite configurar medias, adicionais, pisos e vantagens sem necessidade de codigo. Motor de regras em uo_regra_sindicato.sru.

---

## Transferencia de Empregados

**Definicao:** Movimentacao de empregado entre empresas do mesmo grupo. Gera rescisao na origem e admissao no destino, com continuidade de direitos.

---

## Emprestimo Consignado / Credito do Trabalhador

**Definicao:** Funcionalidade para gestao de emprestimos consignados em folha (eConsignado). Introduzida pelas SAIs 93395/93653/93760, e a area mais referenciada no sistema atualmente.
