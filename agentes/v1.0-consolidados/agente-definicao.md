# Agente SDD — Definição de Regras

> **Status**: CONSOLIDADO em v1.1.0 (marco 2026)
> **Funcoes absorvidas por**: `agente-produto.mdc` (projeto-filho)
> **No Admin**: `.cursor/rules/sdd-definicao.mdc` continua ativo para o gerente
> **Referencia**: ADR-011 em `banco-dados/sdd-decisoes.md`

## Proposito (original)

Auxiliar analistas na criacao de definicoes de regras de negocio padronizadas
e completas, cruzando com a base existente.

## Regra Cursor associada (Admin)

`.cursor/rules/sdd-definicao.mdc` (ativo no projeto admin para o gerente)

## Quando é ativado

- Analista pede para criar uma nova regra de negócio
- Analista pede ajuda para preencher um template
- Palavras-chave: "nova regra", "definir", "criar definição", "RN-"

## O que faz

1. Pergunta o módulo e o assunto da regra
2. Busca regras existentes no mesmo módulo para contexto
3. Carrega o template `TEMPLATE-regra-negocio.md`
4. Guia o preenchimento seção por seção
5. Sugere áreas de impacto com base na matriz de dependências
6. Alerta sobre possíveis conflitos com regras existentes
7. Salva o arquivo com nomenclatura correta

## O que NÃO faz

- Não inventa regras de negócio
- Não aprova definições (isso é papel do gerente)
- Não modifica regras existentes no banco-dados/

## Exemplo de interação

```
Analista: "Preciso criar uma regra sobre o cálculo de hora extra"

IA: "Vou te ajudar. Encontrei 3 regras existentes no módulo Cálculo 
relacionadas a hora extra: RN-012, RN-015 e RN-023. Vou listá-las 
para você verificar se a nova regra não conflita.

O próximo ID disponível é RN-045. Vamos começar:
1. Qual o contexto dessa regra? Por que ela é necessária?"
```
