# Fluxo de Processo: FL-009 - Sindicato e CCT

## Metadados

| Campo | Valor |
|---|---|
| **ID** | FL-009 |
| **Titulo** | Cadastro de Sindicato e Aplicacao de CCT |
| **Modulo** | Sindicato |
| **Autor** | Agente IA (base: codigo-fonte + SAIs) |
| **Data** | 2026-03-04 |
| **Versao** | 0.2 (revisado - pendente aprovacao) |

## Objetivo do Fluxo

Descreve o processo de cadastro de sindicatos, registro de convencoes
coletivas e aplicacao de reajustes/regras da CCT nos calculos.

## Atores Envolvidos

| Ator | Papel no Fluxo |
|---|---|
| Departamento Pessoal | Cadastra sindicato, registra CCT |
| Sistema Folha | Aplica regras da CCT nos calculos |

## Fluxo Principal

```
INICIO
  |
  v
[1] Cadastrar sindicato (Cadastros > Sindicatos)
  |   (w_cad_sindicatos.srw)
  |
  v
[2] Registrar CCT vigente (data-base, vigencia, clausulas)
  |   (w_cad_sindicatos_cct.srw)
  |
  v
[3] Configurar regras da CCT no sistema
  |   (uo_regra_sindicato.sru)
  |   - Piso salarial, reajuste percentual
  |   - Pisos por cargo/funcao
  |   - Adicionais especificos (insalubridade, periculosidade)
  |   - Regras de calculo de medias
  |
  v
[4] Vincular empregados ao sindicato
  |
  v
[5] Aplicar reajuste (se retroativo, gera diferencas - ver RN-CAL-001)
  |
  v
[6] Configurar contribuicao sindical/assistencial
  |   (uo_contribuicao_sindical.sru)
  |
  v
[7] Conferir reflexos no calculo da folha
  |
  v
FIM
```

## Descricao dos Passos

### Passo 1 - Cadastrar sindicato
- **Ator**: Departamento Pessoal
- **Acao**: Registrar CNPJ, razao social, entidade sindical, base territorial.

### Passo 2 - Registrar CCT
- **Ator**: Departamento Pessoal
- **Acao**: Informar data-base, periodo de vigencia, numero do registro MTE. Registrar clausulas que impactam calculos.

### Passo 3 - Configurar regras
- **Ator**: Departamento Pessoal
- **Acao**: Traduzir clausulas da CCT em parametros do sistema: pisos, percentuais, adicionais, regras de media, PLR.

### Passo 4 - Vincular empregados
- **Ator**: Departamento Pessoal
- **Acao**: Associar cada empregado ao sindicato correto. O vinculo determina quais regras da CCT se aplicam.

### Passo 5 - Aplicar reajuste
- **Ator**: Sistema Folha
- **Acao**: Se reajuste com data-base retroativa, calcular diferencas de todos os meses (FL-001 + RN-CAL-001).

### Passo 6 - Contribuicao sindical
- **Ator**: Sistema Folha
- **Acao**: Calcular contribuicao sindical (se autorizada pelo empregado) e contribuicao assistencial conforme CCT.

### Passo 7 - Conferencia
- **Ator**: Departamento Pessoal
- **Acao**: Verificar que pisos estao sendo respeitados, reajustes aplicados, diferencas calculadas.

## Regras de Negocio Relacionadas

| Regra | Onde se aplica |
|---|---|
| RN-CAL-001 | Passo 5 (diferenca retroativa) |

## Observacoes

- CCT e o maior gerador de complexidade transversal (afeta todos os modulos).
- PLR tem regras especificas de tributacao (isento de INSS, IRRF com tabela propria).

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (rascunho) |
| 0.2 | 2026-03-04 | Agente IA | Revisao: cruzamento com regras e mapa |
