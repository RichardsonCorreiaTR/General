# Glossario: eSocial

> Termos do Sistema de Escrituracao Digital das Obrigacoes Fiscais,
> Previdenciarias e Trabalhistas

---

## Evento Periodico

**Definicao:** Eventos enviados mensalmente ao eSocial. Prazo: ate dia 15 do mes seguinte.

**Principais:**
| Evento | Descricao |
|---|---|
| S-1200 | Remuneracao do trabalhador |
| S-1210 | Pagamentos de rendimentos |
| S-1260 | Comercializacao producao rural |
| S-1270 | Contratacao avulsos nao portuarios |
| S-1299 | Fechamento eventos periodicos |

---

## Evento Nao Periodico

**Definicao:** Eventos enviados quando ocorrem (admissao, desligamento, afastamento).

**Principais:**
| Evento | Descricao | Prazo |
|---|---|---|
| S-2200 | Cadastro/Admissao | Ate vespera da admissao |
| S-2205 | Alteracao de dados cadastrais | Ate dia 15 do mes seguinte |
| S-2206 | Alteracao contratual | Ate dia 15 do mes seguinte |
| S-2230 | Afastamento temporario | Ate dia 15 do mes seguinte |
| S-2299 | Desligamento | Ate 10 dias do desligamento |
| S-2399 | TSVE - Termino | Ate dia 15 do mes seguinte |

---

## Leiaute / XSD

**Definicao:** Estrutura XML que define o formato dos eventos. Atualizado por Notas Tecnicas. Versao vigente: S-1.3.

---

## Nota Tecnica (NT)

**Definicao:** Documento da RFB que atualiza o leiaute do eSocial. Geralmente altera XSD, regras de validacao ou inclui novos campos.

---

## Agente de Comunicacao

**Definicao:** Componente do sistema que gerencia a comunicacao com o portal eSocial (envio, consulta retorno, exclusao). Implementado em forel20.
