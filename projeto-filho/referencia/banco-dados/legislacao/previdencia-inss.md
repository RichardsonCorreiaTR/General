# Legislacao: INSS na Folha de Pagamento

## Normas vigentes

| Norma | Assunto | Impacto no sistema |
|---|---|---|
| Lei 8.212/91 | Custeio da Previdencia | Base de calculo, aliquotas |
| IN RFB 971 | Normas gerais previdenciarias | Regras detalhadas |
| EC 103/2019 | Reforma da Previdencia | Aliquotas progressivas |
| Port. Interministerial (anual) | Teto e faixas INSS | Atualizacao de tabela |

## Tabela progressiva INSS (vigente)

Aliquotas progressivas conforme EC 103/2019. O sistema aplica via
`tabela_calculo/uo_tab_calc_inss.sru`.

## Incidencias na Folha

| Evento | Incide INSS? | Observacao |
|---|---|---|
| Salario mensal | Sim | Segurado + patronal |
| Ferias gozadas + 1/3 | Sim | Na competencia do gozo |
| 13o salario | Sim | Recolhimento em dezembro (integral) |
| Rescisao (indenizatorias) | Nao | Ferias indenizadas, aviso indenizado |
| Rescisao (remuneratorias) | Sim | Saldo salario, 13o proporcional |
| PLR | Nao | Isento de INSS |

## NEs recorrentes

Padroes de erro mais comuns em NEs relacionadas a INSS:
- INSS 13o incorreto com multiplos vinculos
- Base INSS CCT divergente nos relatorios
- INSS sobre diferenca de ferias
- INSS segurado na rescisao complementar
- Base interna de INSS incorreta com antecipacao salarial

## Contribuicao patronal (RAT/FAP)

Calculada via `uo_tab_calc_fap.sru`. Depende de:
- RAT (Risco Ambiental do Trabalho): 1%, 2% ou 3%
- FAP (Fator Acidentario de Prevencao): 0,5 a 2,0
- Resultado: RAT x FAP = aliquota patronal adicional
