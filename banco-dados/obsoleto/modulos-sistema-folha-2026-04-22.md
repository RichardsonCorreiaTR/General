# Módulos do Sistema de Folha de Pagamento

> Este documento mapeia os módulos do sistema e suas dependências.
> Deve ser atualizado conforme o conhecimento do time evolui.

## Módulos

| ID | Módulo | Subpasta | Descrição |
|---|---|---|---|
| M01 | Admissão | admissao/ | Cadastro, contrato, dados do funcionário |
| M02 | Cálculo | calculo/ | Folha mensal, proventos, descontos |
| M03 | Férias | ferias/ | Programação, cálculo, abono pecuniário |
| M04 | 13º Salário | 13-salario/ | 1ª parcela, 2ª parcela, provisão |
| M05 | Rescisão | rescisao/ | Cálculo rescisório, verbas, homologação |
| M06 | Benefícios | beneficios/ | VT, VA, VR, plano saúde, outros |
| M07 | INSS | inss/ | Contribuições, tabelas, compensação |
| M08 | IRRF | irrf/ | Tabela progressiva, deduções, cálculo |
| M09 | FGTS | fgts/ | Depósitos, GRRF, conectividade social |
| M10 | eSocial | esocial/ | Eventos, leiautes, transmissão, retornos |
| M11 | Provisões | provisoes/ | Provisão férias, 13º, encargos |
| M12 | Integração Contábil | integracao-contabil/ | Lançamentos, centros de custo |

## Matriz de Dependências

> Marque "X" onde o módulo da LINHA impacta o módulo da COLUNA.

| | M01 | M02 | M03 | M04 | M05 | M06 | M07 | M08 | M09 | M10 | M11 | M12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **M01** Admissão | - | X | X | X | X | X | X | X | X | X | X | X |
| **M02** Cálculo | | - | | | | | X | X | X | X | X | X |
| **M03** Férias | | X | - | | X | | X | X | X | X | X | X |
| **M04** 13º Salário | | X | | - | X | | X | X | X | X | X | X |
| **M05** Rescisão | | X | X | X | - | | X | X | X | X | X | X |
| **M06** Benefícios | | X | | | | - | | | | X | | X |
| **M07** INSS | | X | X | X | X | | - | | | X | X | X |
| **M08** IRRF | | X | X | X | X | | | - | | X | | X |
| **M09** FGTS | | | | | X | | | | - | X | | X |
| **M10** eSocial | | | | | | | | | | - | | |
| **M11** Provisões | | | | | | | | | | | - | X |
| **M12** Integ. Contábil | | | | | | | | | | | | - |

> **Como ler**: Linha M03 (Férias) coluna M07 (INSS) = X → mudanças em Férias
> podem impactar cálculos de INSS.

## Instruções

Ao definir uma regra, o analista DEVE consultar esta matriz para identificar
quais módulos podem ser afetados. O agente SDD-Impacto usa esta matriz como
referência principal.
