# Regra de Negocio: RN-13S-001 — Proporcionalidade do 13o Salario

## Metadados

| Campo | Valor |
|---|---|
| **ID** | RN-13S-001 |
| **Titulo** | Calculo proporcional do 13o salario |
| **Modulo** | 13o Salario |
| **Autor** | Agente IA (semente - precisa validacao) |
| **Data** | 2026-03-04 |
| **Versao** | 0.1 |
| **Status** | Rascunho |
| **Prioridade** | Alta |

## Contexto

O 13o e calculado proporcionalmente aos meses trabalhados no ano.
NEs recorrentes envolvem troca de categoria, admissao/rescisao no meio
do ano, e afastamentos que reduzem ou nao o 13o.

## Regra

1. O sistema DEVE calcular: (remuneracao dezembro / 12) x meses trabalhados.
2. Mes com 15 ou mais dias trabalhados DEVE contar como avo integral.
3. Mes com menos de 15 dias trabalhados NAO DEVE contar como avo.
4. Afastamentos por doenca/acidente: primeiros 15 dias contam; a partir do
   16o dia (auxilio-doenca), o avo NAO DEVE contar.
5. Afastamento por acidente de trabalho: DEVE contar integralmente (13o
   integral garantido).
6. Na troca de categoria no mesmo ano, o sistema DEVE manter a
   proporcionalidade continua (nao zerar avos).
7. Medias de variaveis DEVEM seguir mesma logica de RN-FER-001 (12 meses).

## Condicoes de Aplicacao

- [x] Todo empregado CLT ativo ou desligado no exercicio
- [x] 1a parcela, 2a parcela e diferenca

## Excecoes

| Excecao | Motivo |
|---|---|
| Estagiario | Sem direito a 13o |
| Empregado admitido e demitido antes de 15 dias | Sem avo |

## Exemplos Praticos

### Cenario Normal
**Dado que**: empregado admitido em 01/04, salario R$ 6.000
**Quando**: calculo do 13o integral
**Entao**: R$ 6.000 / 12 x 9 avos = R$ 4.500

### Cenario Troca de Categoria
**Dado que**: empregado muda de aprendiz para CLT em julho
**Quando**: calculo do 13o
**Entao**: 12 avos (nao zera, conta continuamente)

## Areas de Impacto

- [x] 13o salario
- [x] Rescisao (13o proporcional)
- [x] INSS / Previdencia
- [x] IRRF
- [x] FGTS
- [x] Provisoes contabeis
- [x] eSocial

## Base Legal

- Lei 4.090/62 Art. 1o — Direito ao 13o
- Lei 4.749/65 — Pagamento em 2 parcelas
- Decreto 57.155/65 Art. 1o — Proporcionalidade

## Criterios de Aceite

1. [x] Calculo proporcional correto por avos
2. [x] Regra de 15 dias respeitada
3. [x] Afastamento INSS: nao conta avo apos 15o dia
4. [x] Acidente trabalho: conta integralmente
5. [x] Troca de categoria: continuidade

## SAIs relacionadas

- NE 96147/PSAI 119702: 13o nao proporcional na troca de categoria
- NE 93357/PSAI 118123: Valor novo do 13o integral incorreto na memoria

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (semente) |
