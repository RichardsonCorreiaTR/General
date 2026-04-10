# Regra de Negocio: RN-FER-003 — Ferias na Rescisao

## Metadados

| Campo | Valor |
|---|---|
| **ID** | RN-FER-003 |
| **Titulo** | Calculo de ferias vencidas e proporcionais na rescisao |
| **Modulo** | Ferias |
| **Autor** | Agente IA (extraida de NEs recorrentes) |
| **Data** | 2026-03-04 |
| **Versao** | 0.1 |
| **Status** | Rascunho |
| **Prioridade** | Alta |

## Contexto

Ferias na rescisao envolvem ate 3 parcelas diferentes (vencidas, proporcionais,
em dobro) com tratamentos tributarios distintos. E fonte frequente de NEs.

## Regra

1. Ferias vencidas na rescisao: o sistema DEVE pagar integralmente + 1/3.
   Sao consideradas gozadas para fins tributarios (incide INSS e IRRF).
2. Ferias proporcionais: o sistema DEVE calcular (salario/12) x meses do
   periodo aquisitivo incompleto + 1/3. Sao indenizatorias (NAO incide INSS,
   NAO incide IRRF).
3. Ferias em dobro: se o periodo concessivo venceu, o sistema DEVE pagar
   em dobro + 1/3 (CLT art. 137).
4. Medias de variaveis DEVEM ser incluidas conforme RN-FER-001.
5. A projecao do aviso previo (RN-RES-002) DEVE ser considerada para
   determinar se ha mais avos de ferias proporcionais.
6. Na justa causa, o sistema NAO DEVE pagar ferias proporcionais
   (apenas vencidas, se houver).

## Condicoes de Aplicacao

- [x] Rescisao de qualquer tipo (ver RN-RES-001 para matriz)

## Excecoes

| Excecao | Motivo |
|---|---|
| Justa causa | Sem ferias proporcionais |
| Contrato < 1 ano + pedido demissao (pre-Reforma) | Regra antiga, ja revogada |

## Exemplos Praticos

### Cenario: ferias vencidas + proporcionais
**Dado que**: empregado com 2 anos e 8 meses, 1 periodo de ferias vencido nao gozado
**Quando**: rescisao sem justa causa
**Entao**: pagar ferias vencidas simples + 1/3 (tributaveis) + ferias proporcionais
8/12 + 1/3 (indenizatorias)

### Cenario: ferias em dobro
**Dado que**: empregado com periodo concessivo vencido ha 3 meses
**Quando**: rescisao
**Entao**: ferias em dobro + 1/3 (sobre o valor dobrado)

## Areas de Impacto

- [x] Rescisao
- [x] Ferias
- [x] INSS / Previdencia (vencidas sim, proporcionais nao)
- [x] IRRF (vencidas sim, proporcionais nao)
- [x] FGTS
- [x] eSocial

## Dependencias

| Regra | Relacao |
|---|---|
| RN-FER-001 | Depende de (medias) |
| RN-RES-001 | Complementa (matriz de verbas) |
| RN-RES-002 | Depende de (projecao aviso previo) |
| RN-IRRF-001 | Complementa (tributacao) |

## Base Legal

- CLT Art. 146 — Ferias na rescisao
- CLT Art. 137 — Ferias em dobro
- Sumula 171 TST — Proporcionais na dispensa

## SAIs relacionadas

- NE 93425/PSAI 116837: Ferias e INSS sobre diferenca de ferias na rescisao
- NE 92874/PSAI 117075: INSS ferias alterado antes da rescisao
- NE 93562/PSAI 118049: Ferias indenizadas quando impedido de trabalhar
- NE 97663/PSAI 119813: Ferias na rescisao do comissionado

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao (extraida de NEs) |
