# Legislacao: eSocial — Leiautes e Obrigacoes

## Normas vigentes

| Norma | Assunto |
|---|---|
| Decreto 8.373/2014 | Institui o eSocial |
| Resolucao CDES 1 a 25 | Regulamentacao periodica |
| Leiaute S-1.3 | Versao vigente dos schemas XSD |
| MOS (Manual de Orientacao) | Regras de preenchimento |
| Notas Tecnicas periodicas | Atualizacoes de XSD e regras |

## Eventos relevantes para Folha

### Eventos de tabela (cadastrados uma vez, atualizados quando mudam)

| Evento | Descricao | Quando |
|---|---|---|
| S-1000 | Empregador | Cadastro inicial |
| S-1005 | Estabelecimentos | Cadastro inicial |
| S-1010 | Rubricas | Sempre que nova rubrica |
| S-1020 | Lotacoes tributarias | Cadastro inicial |

### Eventos nao-periodicos (gatilho: fato trabalhista)

| Evento | Descricao | Prazo |
|---|---|---|
| S-2190 | Admissao preliminar | Dia anterior ao inicio |
| S-2200 | Admissao | Dia anterior ao inicio |
| S-2205 | Alteracao dados cadastrais | Dia 15 mes seguinte |
| S-2206 | Alteracao contratual | Dia 15 mes seguinte |
| S-2230 | Afastamento temporario | Dia 15 mes seguinte |
| S-2299 | Desligamento | 10 dias apos |
| S-2399 | Desligamento TSVE | 10 dias apos |

### Eventos periodicos (mensais, apos calculo)

| Evento | Descricao | Prazo |
|---|---|---|
| S-1200 | Remuneracao trabalhador | Dia 15 mes seguinte |
| S-1210 | Pagamentos | Dia 15 mes seguinte |
| S-1260 | Comercializacao producao rural | Dia 15 mes seguinte |
| S-1299 | Fechamento eventos periodicos | Dia 15 mes seguinte |

## Processo no sistema

O modulo eSocial (forel20, ~471 arquivos) e o maior do sistema.
Principais telas: w_esocial.srw, w_painel_esocial.srw, uo_esocial.sru.

## SALs recentes

- SAL 100312: Adequacao a Nota Tecnica S-1.3 No 06/2026
- Nota Tecnica 01/2025: Ajustes de validacao

## NEs recorrentes

- S-1200 e S-2299 com valores divergentes da folha
- Competencia fechada bloqueando correcoes
- Valores retornados pelo eSocial nao demonstrados no painel
