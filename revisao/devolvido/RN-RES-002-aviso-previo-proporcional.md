# Regra de Negocio: RN-RES-002 — Aviso Previo Proporcional

## Metadados

| Campo | Valor |
|---|---|
| **ID** | RN-RES-002 |
| **Titulo** | Calculo do aviso previo proporcional ao tempo de servico |
| **Modulo** | Rescisao |
| **Autor** | Agente IA (extraida de NEs recorrentes) |
| **Data** | 2026-03-04 |
| **Versao** | 0.1 |
| **Status** | Rascunho |
| **Prioridade** | Alta |

## Contexto

A Lei 12.506/2011 instituiu o aviso previo proporcional. O calculo incorreto
da projecao impacta ferias e 13o proporcionais na rescisao.

## Regra

1. O aviso previo minimo DEVE ser 30 dias.
2. A cada ano completo de servico, o sistema DEVE acrescentar 3 dias.
3. O limite maximo DEVE ser 90 dias (30 + 60 de proporcionalidade).
4. Quando indenizado, a projecao do aviso DEVE ser somada ao tempo de
   servico para calculo de ferias e 13o proporcionais.
5. No acordo bilateral (art. 484-A), o aviso indenizado DEVE ser 50%
   do valor (metade dos dias).
6. Aviso previo trabalhado: empregado DEVE ter reducao de 2h/dia ou
   7 dias corridos no final (escolha do empregado).

## Condicoes de Aplicacao

- [x] Rescisao sem justa causa (aviso pelo empregador)
- [x] Pedido de demissao (aviso pelo empregado — sempre 30 dias)
- [x] Acordo bilateral (50% do indenizado)

## Excecoes

| Excecao | Motivo |
|---|---|
| Justa causa | Sem aviso previo |
| Termino contrato determinado | Sem aviso previo |
| Pedido de demissao | Sempre 30 dias (sem proporcionalidade) |

## Exemplos Praticos

### Cenario: 5 anos de servico
**Dado que**: empregado com 5 anos e 3 meses, dispensado sem justa causa
**Quando**: calculo rescisorio, aviso indenizado
**Entao**: 30 + (5 x 3) = 45 dias de aviso. Projecao de 45 dias integra
ferias e 13o proporcionais.

### Cenario: Acordo (art. 484-A)
**Dado que**: empregado com 10 anos, acordo bilateral
**Quando**: calculo rescisorio
**Entao**: aviso = 30 + (10 x 3) = 60 dias. Pago 50% = 30 dias indenizados.

## Areas de Impacto

- [x] Rescisao
- [x] Ferias (proporcionais com projecao)
- [x] 13o salario (proporcional com projecao)
- [x] FGTS (multa sobre base com aviso)
- [x] eSocial (S-2299)

## Base Legal

- Lei 12.506/2011 — Aviso previo proporcional
- CLT Art. 487 — Aviso previo
- CLT Art. 484-A — Acordo bilateral
- Nota Tecnica 184/2012 MTE — Orientacao

## Criterios de Aceite

1. [x] Calculo: 30 + (anos x 3), max 90
2. [x] Projecao integra ferias e 13o
3. [x] Acordo: 50% correto
4. [x] Pedido demissao: sempre 30

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao (extraida de NEs) |
