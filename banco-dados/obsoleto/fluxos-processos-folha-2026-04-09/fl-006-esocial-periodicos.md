# Fluxo de Processo: FL-006 - eSocial Eventos Periodicos

## Metadados

| Campo | Valor |
|---|---|
| **ID** | FL-006 |
| **Titulo** | Geracao e Transmissao de Eventos Periodicos do eSocial |
| **Modulo** | eSocial |
| **Autor** | Agente IA (base: codigo-fonte + SAIs) |
| **Data** | 2026-03-04 |
| **Versao** | 0.2 (revisado - pendente aprovacao) |

## Objetivo do Fluxo

Descreve o processo de geracao dos eventos periodicos do eSocial
(S-1200, S-1210, S-1299) apos o calculo da folha mensal.

## Atores Envolvidos

| Ator | Papel no Fluxo |
|---|---|
| Departamento Pessoal | Confere dados, autoriza transmissao |
| Sistema Folha | Gera XMLs, valida esquemas, transmite |
| Governo (eSocial) | Recebe eventos, retorna protocolo |

## Fluxo Principal

```
INICIO
  |
  v
[1] Calculo da folha finalizado (FL-001)
  |
  v
[2] Gerar S-1200 - Remuneracao (Processos > eSocial)
  |
  v
[3] Validar XMLs gerados (esquemas XSD)
  |
  v
[Erros?] --SIM--> [3A] Corrigir dados na folha e regerar
  |
  NAO
  |
  v
[4] Transmitir S-1200
  |
  v
[5] Gerar S-1210 - Pagamentos
  |
  v
[6] Transmitir S-1210
  |
  v
[7] Gerar S-1299 - Fechamento dos eventos periodicos
  |
  v
[8] Transmitir S-1299 e obter protocolo de fechamento
  |
  v
[Retorno OK?] --NAO--> [8A] Analisar retorno, corrigir e retransmitir
  |
  SIM
  |
  v
FIM
```

## Descricao dos Passos

### Passo 1 - Folha finalizada
- **Pre-requisito**: Calculo mensal concluido e conferido (FL-001).

### Passo 2 - Gerar S-1200
- **Ator**: Sistema Folha (forel20, uo_esocial.sru)
- **Acao**: Gerar eventos de remuneracao para cada trabalhador. Inclui rubricas, bases de calculo, descontos.

### Passo 3 - Validar XMLs
- **Ator**: Sistema Folha
- **Acao**: Validar contra esquemas XSD do eSocial. Verificar CPFs, matriculas, rubricas cadastradas.

### Passo 4 - Transmitir S-1200
- **Ator**: Sistema Folha
- **Acao**: Enviar eventos ao ambiente do eSocial. Obter recibo de entrega.

### Passo 5 - Gerar S-1210
- **Ator**: Sistema Folha
- **Acao**: Gerar eventos de pagamento com data efetiva, forma de pagamento.

### Passo 6 - Transmitir S-1210
- **Ator**: Sistema Folha
- **Acao**: Enviar e aguardar protocolo.

### Passo 7 - Gerar S-1299
- **Ator**: Sistema Folha
- **Acao**: Gerar fechamento dos eventos periodicos da competencia.

### Passo 8 - Fechamento
- **Ator**: Sistema Folha
- **Acao**: Transmitir S-1299. Se rejeitado, analisar erros, corrigir e retransmitir.

## Eventos nao-periodicos relacionados

| Evento | Quando |
|---|---|
| S-2190 | Admissao preliminar |
| S-2200 | Admissao (FL-005) |
| S-2206 | Alteracao contratual |
| S-2230 | Afastamento (ferias, licenca) |
| S-2299 | Desligamento (FL-003) |

## Regras de Negocio Relacionadas

| Regra | Onde se aplica |
|---|---|
| RN-ESO-001 | Passos 2, 5 e 7 (eventos periodicos eSocial) |

## Observacoes

- Painel eSocial (w_painel_esocial.srw) permite monitorar status de todos os eventos.
- Rascunho - precisa validacao do gerente de produto.

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (rascunho) |
| 0.2 | 2026-03-04 | Agente IA | Revisao: cruzamento com regras e mapa |
