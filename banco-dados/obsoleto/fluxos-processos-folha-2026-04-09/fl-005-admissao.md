# Fluxo de Processo: FL-005 - Admissao de Empregado

## Metadados

| Campo | Valor |
|---|---|
| **ID** | FL-005 |
| **Titulo** | Admissao e Cadastro de Empregado |
| **Modulo** | Admissao |
| **Autor** | Agente IA (base: codigo-fonte + SAIs) |
| **Data** | 2026-03-04 |
| **Versao** | 0.2 (revisado - pendente aprovacao) |

## Objetivo do Fluxo

Descreve o processo de admissao de um empregado no sistema de Folha,
desde o cadastro ate a geracao dos eventos eSocial de admissao.

## Atores Envolvidos

| Ator | Papel no Fluxo |
|---|---|
| Departamento Pessoal | Cadastra empregado, configura contrato |
| Sistema Folha | Valida dados, gera eSocial, aplica parametros |

## Fluxo Principal (Caminho Feliz)

```
INICIO
  |
  v
[1] Cadastrar empregado (Cadastros > Empregados)
  |   Dados pessoais, documentos, endereco
  |
  v
[2] Configurar contrato de trabalho
  |   Cargo, funcao, salario, jornada, sindicato
  |
  v
[3] Definir ambiente de trabalho e riscos (se aplicavel)
  |
  v
[4] Configurar beneficios (VT, VA, plano saude)
  |
  v
[5] Vincular bases de calculo e rubricas
  |
  v
[6] Gerar evento eSocial S-2200 (admissao)
  |
  v
[Admissao preliminar?] --SIM--> [6A] Gerar S-2190 antes
  |
  NAO
  |
  v
[7] Conferir cadastro completo
  |
  v
[8] Incluir na proxima folha de calculo
  |
  v
FIM
```

## Descricao dos Passos

### Passo 1 - Cadastrar empregado
- **Ator**: Departamento Pessoal
- **Acao**: Preencher dados em w_cad_empregados.srw: nome, CPF, PIS, CTPS, data nascimento, endereco, estado civil, dependentes (IRRF e salario-familia).
- **Regra**: CPF obrigatorio, validacao de duplicidade.

### Passo 2 - Configurar contrato
- **Ator**: Departamento Pessoal
- **Acao**: Definir data de admissao, tipo de contrato (indeterminado, determinado, intermitente), cargo, funcao, salario, jornada de trabalho, sindicato vinculado.
- **Regra**: Categoria do trabalhador (CLT, domestico, aprendiz, estagiario).

### Passo 3 - Ambiente de trabalho
- **Ator**: Departamento Pessoal
- **Acao**: Vincular empregado ao ambiente de trabalho (w_cad_ambientes_trabalho.srw) e fatores de risco para PPP/eSocial.

### Passo 4 - Configurar beneficios
- **Ator**: Departamento Pessoal
- **Acao**: Incluir vale-transporte (percentual de desconto), vale-alimentacao, plano de saude e outros beneficios conforme politica da empresa.

### Passo 5 - Bases de calculo
- **Ator**: Sistema Folha
- **Acao**: Vincular automaticamente as bases de calculo padrao (INSS, IRRF, FGTS) e rubricas fixas conforme parametros do sindicato/empresa.

### Passo 6 - Gerar eSocial
- **Ator**: Sistema Folha (forel20)
- **Acao**: Gerar evento S-2200 (cadastramento/admissao). Prazo: ate o dia anterior ao inicio das atividades. Para admissao preliminar, gerar S-2190 antes.

### Passo 7 - Conferir cadastro
- **Ator**: Departamento Pessoal
- **Acao**: Revisar todos os dados cadastrais, contratuais e de beneficios antes de incluir o empregado nos processos de calculo.

### Passo 8 - Incluir na folha
- **Ator**: Sistema Folha
- **Acao**: Empregado passa a ser considerado no proximo calculo de folha. Sistema aplica proporcionalidade se admissao for no meio do mes.

## Regras de Negocio Relacionadas

| Regra | Onde se aplica |
|---|---|
| RN-FGTS-001 | Passo 5 (bases FGTS na admissao) |
| RN-ESO-001 | Passo 6 (evento S-2200 admissao) |

## Observacoes

- Estagiarios e contribuintes individuais seguem fluxo similar com campos diferentes.
- Rascunho - precisa validacao do gerente de produto.

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (rascunho) |
| 0.2 | 2026-03-04 | Agente IA | Revisao: cruzamento com regras e mapa |
