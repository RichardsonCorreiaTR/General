# Guia de Piloto -- Teste do Fluxo Completo do Analista

## Objetivo

Validar que o analista consegue executar todo o fluxo de analise de produto:
trazer uma demanda, analisar com apoio da IA, criar PSAI/SAI e finalizar como insumo para o SGD.

## Pre-requisitos do piloto

- [ ] Projeto do analista instalado na maquina (ver SETUP.md)
- [ ] OneDrive sincronizado (CursorEscrita - General)
- [ ] Symlink `referencia/banco-dados/` criado
- [ ] Cursor instalado e aberto no projeto
- [ ] `config/analista.json` preenchido

## Roteiro de Teste (20-25 min)

### Teste 1 -- IA responde sobre o projeto (2 min)
Pergunte a IA:
- `Quais sao os modulos da Escrita Fiscal?`
- `O que e uma NE?`
- `Quais areas do produto tenho para pesquisar alem da Escrita? Onde esta o indice dos mapas?`

**Esperado**: IA responde com base no glossario e mapas; para areas, indica
`referencia/banco-dados/mapa-sistema/indice-mapas-areas.md` e mapas por area quando aplicavel.
**Resultado**: [ ] OK  [ ] Falha  Obs: ___

### Teste 2 -- Consultar base existente (3 min)
Pergunte a IA:
- `Quais definicoes existem no modulo de ferias?`
- `Me mostre SAIs relacionadas a ferias`

**Esperado**: IA encontra e exibe definicoes sobre ferias.
**Resultado**: [ ] OK  [ ] Falha  Obs: ___

### Teste 3 -- Consultar glossario (2 min)
Pergunte a IA:
- `O que e CCT?`
- `O que significa DSR?`

**Esperado**: IA localiza no glossario e explica.
**Resultado**: [ ] OK  [ ] Falha  Obs: ___

### Teste 4 -- Consultar fluxo de processo (2 min)
Pergunte a IA:
- `Me mostre o fluxo de rescisao`
- `Quais passos tem o processo de escrituracao na Escrita Fiscal?`

**Esperado**: IA exibe o fluxo do processo solicitado.
**Resultado**: [ ] OK  [ ] Falha  Obs: ___

### Teste 5 -- Analisar demanda e criar PSAI (8 min)
Peca a IA:
- `Recebi a NE 99999 sobre calculo de horas extras no modulo de calculo`

**Esperado**: IA conduz o pipeline de analise:
1. Busca SAIs e definicoes relacionadas
2. Analisa o contexto e codigo (se disponivel)
3. Identifica cenarios e casos de borda
4. Apresenta cenarios para discussao
5. Gera a PSAI completa no formato tradicional
6. Salva em `meu-trabalho/em-andamento/PSAI-99999-calculo-horas-extras.md`
**Resultado**: [ ] OK  [ ] Falha  Obs: ___

### Teste 6 -- Finalizar definicao (2 min)
Peca a IA:
- `Finalizar minha definicao`

**Esperado**: Arquivo movido de `em-andamento/` para `concluido/`.
O artefato fica disponivel para usar como insumo no SGD.
**Resultado**: [ ] OK  [ ] Falha  Obs: ___

### Teste 7 -- Pedir analise de codigo (3 min)
Pergunte a IA:
- `O que o sistema faz hoje quando calcula horas extras?`
- `Me mostra o codigo dessa parte`

**Esperado**: IA explica em linguagem de produto. Se pedir codigo, mostra.
**Resultado**: [ ] OK  [ ] Falha  Obs: ___

### Teste 8 -- Buscar SAI em terminal (3 min)
Em terminal separado (fora do Cursor), rode:
`powershell -File scripts\buscar-sai.ps1 -Termo "horas extras"`

**Esperado**: Resultados de SAIs relacionadas a horas extras.
**Resultado**: [ ] OK  [ ] Falha  Obs: ___

## Apos o piloto

### Se tudo OK:
1. Registrar como piloto bem-sucedido
2. Iniciar rollout para os demais analistas (em ondas de 3-5)
3. Criar canal de suporte (Teams/chat para duvidas)

### Se houver falhas:
1. Documentar cada falha com print/descricao
2. Priorizar correcao antes do rollout
3. Re-testar apos correcao

## Checklist de rollout

- [ ] Piloto aprovado
- [ ] Permissoes SharePoint configuradas (ver PERMISSOES-SHAREPOINT.md)
- [ ] Comunicado enviado aos analistas
- [ ] Sessao de onboarding agendada (30 min)
- [ ] Canal de suporte criado
