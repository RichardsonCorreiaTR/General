# Regra de Negocio: RN-IRRF-001 — Incidencia de IRRF sobre Ferias

## Metadados

| Campo | Valor |
|---|---|
| **ID** | RN-IRRF-001 |
| **Titulo** | Tributacao de IRRF sobre ferias (exclusiva na fonte) |
| **Modulo** | IRRF |
| **Autor** | Agente IA (semente - precisa validacao) |
| **Data** | 2026-03-04 |
| **Versao** | 0.1 |
| **Status** | Rascunho |
| **Prioridade** | Alta |

## Contexto

O IRRF sobre ferias tem tributacao exclusiva na fonte, separada da folha
mensal. Erros na base de calculo e na demonstracao nos relatorios sao
frequentes, especialmente quando ferias incidem na rescisao.

## Regra

1. O sistema DEVE calcular o IRRF de ferias separadamente da folha mensal
   (tributacao exclusiva na fonte).
2. A base de calculo DEVE ser: ferias brutas + 1/3 + medias - INSS ferias
   - dependentes.
3. Ferias indenizadas na rescisao NAO DEVEM ter incidencia de IRRF
   (natureza indenizatoria).
4. Ferias gozadas na rescisao DEVEM ter IRRF com tributacao exclusiva.
5. O abono pecuniario (1/3 vendido) NAO DEVE ter incidencia de IRRF.
6. No extrato/recibo, o sistema DEVE demonstrar separadamente: base IRRF
   ferias, IRRF ferias retido, base IRRF mensal, IRRF mensal retido.

## Condicoes de Aplicacao

- [x] Ferias gozadas (individuais, coletivas, em grupo)
- [x] Ferias na rescisao (apenas gozadas/vencidas)

## Excecoes

| Excecao | Motivo |
|---|---|
| Ferias indenizadas | Natureza indenizatoria, isenta de IRRF |
| Abono pecuniario + 1/3 | Isentos de IRRF |

## Exemplos Praticos

### Cenario Normal
**Dado que**: ferias brutas R$ 4.000 + 1/3 R$ 1.333 = R$ 5.333, INSS R$ 500
**Quando**: calculo de IRRF ferias
**Entao**: base = R$ 5.333 - R$ 500 - dependentes; aplicar tabela progressiva separada

### Cenario Rescisao
**Dado que**: empregado com ferias vencidas (gozadas) e proporcionais (indenizadas) na rescisao
**Quando**: calculo rescisorio
**Entao**: IRRF incide sobre ferias vencidas; NAO incide sobre proporcionais indenizadas

## Areas de Impacto

- [x] Ferias
- [x] Rescisao
- [x] IRRF
- [x] DIRF / Informe de rendimentos
- [x] eSocial
- [x] Relatorios gerenciais

## Base Legal

- RIR/2018 Art. 677 — Tributacao exclusiva
- IN RFB 1500/2014 Art. 12 — Ferias
- ADI SRF 28/2000 — Abono pecuniario isento

## Criterios de Aceite

1. [x] IRRF ferias calculado separadamente do mensal
2. [x] Base correta (bruto + 1/3 + medias - INSS - dependentes)
3. [x] Ferias indenizadas sem IRRF
4. [x] Extrato demonstra separacao correta

## SAIs relacionadas

- NE 91697/PSAI 116078: Campo base IRRF no extrato incorreto
- NE 92874/PSAI 117075: INSS ferias alterado antes da rescisao afetando IRRF

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (semente) |
