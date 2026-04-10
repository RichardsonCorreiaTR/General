# Regra de Negocio: RN-RES-001 — Verbas Rescisorias por Motivo de Desligamento

## Metadados

| Campo | Valor |
|---|---|
| **ID** | RN-RES-001 |
| **Titulo** | Verbas rescisorias conforme motivo de desligamento |
| **Modulo** | Rescisao |
| **Autor** | Agente IA (semente - precisa validacao) |
| **Data** | 2026-03-04 |
| **Versao** | 0.1 |
| **Status** | Rascunho |
| **Prioridade** | Alta |

## Contexto

O motivo do desligamento determina quais verbas sao devidas. Erros nessa
matriz sao criticos e geram passivos trabalhistas.

## Regra

O sistema DEVE calcular as verbas conforme a matriz abaixo:

| Verba | Sem justa causa | Pedido demissao | Justa causa | Acordo (484-A) | Termino contrato |
|---|---|---|---|---|---|
| Saldo salario | SIM | SIM | SIM | SIM | SIM |
| Aviso previo (indenizado) | SIM | NAO | NAO | 50% | NAO |
| Ferias vencidas + 1/3 | SIM | SIM | SIM | SIM | SIM |
| Ferias proporcionais + 1/3 | SIM | SIM | NAO | SIM | SIM |
| 13o proporcional | SIM | SIM | NAO | SIM | SIM |
| Multa FGTS 40% | SIM | NAO | NAO | 20% | NAO |
| Saque FGTS | SIM | NAO | NAO | 80% | SIM |
| Seguro-desemprego | SIM | NAO | NAO | NAO | NAO |

## Condicoes de Aplicacao

- [x] Desligamento de empregado CLT
- [x] Qualquer motivo de rescisao

## Excecoes

| Excecao | Motivo |
|---|---|
| Empregado domestico | Regras proprias (LC 150/2015) |
| Diretor sem vinculo | Sem verbas CLT |
| Falecimento | Verbas pagas a dependentes/heranca |

## Exemplos Praticos

### Cenario Sem Justa Causa
**Dado que**: empregado com 3 anos, salario R$ 5.000, dispensado sem justa causa
**Quando**: calculo rescisorio
**Entao**: saldo + aviso 39 dias (30+9) + ferias prop + 1/3 + 13o prop + multa 40% FGTS

### Cenario Acordo (Art. 484-A)
**Dado que**: empregado e empresa acordam rescisao
**Quando**: calculo rescisorio
**Entao**: saldo + 50% aviso + ferias + 13o + multa 20% FGTS + saque 80% FGTS

## Areas de Impacto

- [x] Rescisao
- [x] FGTS
- [x] INSS / Previdencia
- [x] IRRF
- [x] eSocial (S-2299)
- [x] Relatorios gerenciais

## Base Legal

- CLT Arts. 477 a 486
- CLT Art. 484-A (acordo bilateral - Reforma Trabalhista)
- Lei 12.506/2011 (aviso previo proporcional)
- LC 150/2015 (domesticos)

## Criterios de Aceite

1. [x] Cada motivo gera exatamente as verbas da matriz
2. [x] Acordo: multa 20% e saque 80% corretos
3. [x] Aviso proporcional calculado por tempo de servico
4. [x] TRCT demonstra todas as verbas corretamente

## SAIs relacionadas

- NE 91529/PSAI 115666: Rubrica de indenizacao 13o domestico nao calculada
- NE 95194/PSAI 120128: INSS mensal na rescisao complementar incorreto

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (semente) |
