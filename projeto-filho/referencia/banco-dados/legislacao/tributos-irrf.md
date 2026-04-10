# Legislacao: IRRF na Folha de Pagamento

## Normas vigentes

| Norma | Assunto | Impacto no sistema |
|---|---|---|
| RIR/2018 (Dec. 9.580/18) | Regulamento do IR | Base geral de calculo |
| IN RFB 2005 | Declaracoes obrigatorias | DIRF, informe de rendimentos |
| IN RFB 1787 | Procedimentos IRRF | Regras de retencao |
| Lei 15.270/2025 | Nova tabela progressiva | Faixas e deducoes alteradas |
| LC 224/2025 | Aliquota JCP 17,5% | Impacta calculo de JCP |

## Tabela progressiva (vigente)

Atualizada conforme Lei 15.270/2025. O sistema aplica automaticamente
via `tabela_calculo/uo_tab_calc_irrf.sru`.

## Incidencias na Folha

| Evento | Incide IRRF? | Observacao |
|---|---|---|
| Salario mensal | Sim | Tabela progressiva mensal |
| Ferias + 1/3 | Sim | Tributacao exclusiva na fonte |
| 13o salario | Sim | Tributacao exclusiva, tabela anual |
| PLR | Sim | Tabela especifica (separada) |
| Rescisao (verbas indenizatorias) | Nao | Ferias indenizadas, aviso previo indenizado |
| Rescisao (verbas remuneratorias) | Sim | Saldo salario, 13o proporcional |

## NEs recorrentes

Padroes de erro mais comuns em NEs relacionadas a IRRF:
- Base de IRRF incorreta quando ha multiplos vinculos
- Demonstracao incorreta no extrato/recibo
- Diferenca de 13o com calculo de IRRF errado
- IRRF sobre ferias na rescisao

## SALs recentes

- SAI 99515: Criar opcao para nao aplicar regras de reducao da Lei 15.270/2025
- SAI 99829: Alterar aliquota IRRF sobre JCP (LC 224/2025)
