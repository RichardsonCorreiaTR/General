# Regra de Negocio: RN-CAL-002 — Calculo com Multiplos Vinculos

## Metadados

| Campo | Valor |
|---|---|
| **ID** | RN-CAL-002 |
| **Titulo** | Tratamento de empregado com multiplos vinculos empregaticos |
| **Modulo** | Calculo |
| **Autor** | Agente IA (extraida de NEs recorrentes) |
| **Data** | 2026-03-04 |
| **Versao** | 0.1 |
| **Status** | Rascunho |
| **Prioridade** | Alta |

## Contexto

Empregados com mais de um vinculo (na mesma empresa ou em empresas distintas)
geram erros frequentes em INSS, IRRF e FGTS. E um dos cenarios mais complexos
e com maior volume de NEs.

## Regra

1. O sistema DEVE permitir indicar que o empregado possui vinculo em outra empresa.
2. Para INSS: o sistema DEVE somar remuneracoes de todos os vinculos para
   determinar a faixa progressiva e respeitar o teto. Se o desconto total ja
   atingiu o teto, o sistema NAO DEVE descontar no segundo vinculo.
3. Para IRRF: cada vinculo DEVE calcular IRRF independentemente (sem somar
   rendimentos de outro empregador).
4. Para FGTS: cada vinculo DEVE calcular 8% sobre sua propria base (sem teto).
5. Para 13o: cada vinculo calcula independente, mas INSS do 13o segue regra
   de soma dos vinculos.
6. Na transferencia entre empresas do mesmo grupo, o sistema DEVE tratar
   como continuidade (sem novo periodo aquisitivo de ferias zerado).

## Condicoes de Aplicacao

- [x] Empregado com 2+ vinculos ativos simultaneos
- [x] Transferencia entre empresas do mesmo grupo

## Excecoes

| Excecao | Motivo |
|---|---|
| Vinculo CLT + estatutario | Regimes previdenciarios distintos |
| Vinculo CLT + autonomo | Autonomo contribui por conta propria |

## Exemplos Praticos

### Cenario: INSS com 2 vinculos
**Dado que**: empregado com salario R$ 4.000 (empresa A) + R$ 3.500 (empresa B)
**Quando**: calculo da folha em ambas
**Entao**: INSS progressivo sobre R$ 7.500 total, cada empresa desconta proporcionalmente

### Cenario: Transferencia
**Dado que**: empregado transferido da empresa A para B em 15/mar
**Quando**: calculo da folha de marco
**Entao**: empresa A paga 15 dias, empresa B paga 16 dias; ferias continuam do periodo original

## Areas de Impacto

- [x] Calculo mensal
- [x] Ferias
- [x] 13o salario
- [x] Rescisao
- [x] INSS / Previdencia
- [x] IRRF
- [x] FGTS
- [x] eSocial

## Base Legal

- CLT Art. 138 — Empregado com 2 empregos
- IN RFB 971 Art. 78 — Multiplas fontes pagadoras INSS

## SAIs relacionadas

- NE 91727/PSAI 115973: INSS 13o incorreto com multiplos vinculos
- NE 92120/PSAI 115825: Base INSS incorreta com multiplos vinculos
- NE 93306/PSAI 117960: Medias incorretas quando transferido

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao (extraida de NEs) |
