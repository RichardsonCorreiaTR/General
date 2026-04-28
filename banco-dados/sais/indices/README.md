# SAIs e PSAIs - Escrita Fiscal

> Base de conhecimento de solicitacoes de alteracao da area Escrita Fiscal (PBCVS nomeArea = Escrita, Importacao, Onvio Escrita nos caches).
> Atualizado em: 28/04/2026 15:46 | Total: 64958 registros

## Indices por dominio (modulos-keywords.json)

Cada arquivo em [modulos/](modulos/) agrupa SAIs por **slug de dominio** (palavras-chave). Conteudo: pendentes, liberadas recentes, temas frequentes, descartadas.

- [Resumo de Pendentes](resumo-pendentes.md) - Totais por dominio + top 20 novidades
- [modulos/](modulos/) - Um `.md` por slug (14 dominios em `banco-dados/config/modulos-keywords.json` + `nao-classificado.md` para o restante)

## Indices Gerais

- [Indice Geral](indice-geral.md) - Resumo com totais por tipo, status e versao
- [Estatisticas](estatisticas.md) - Numeros por ano, gravidade
- [Por Modulo](por-modulo.md) - Lista agregada por dominio (classificacao multi-dominio; ver `modulos-keywords.json`)

- [Por Cenario Complexo](por-cenario-complexo.md) - SAIs classificadas em 2+ dominios

## Pendentes

- [NEs Pendentes Recentes](pendentes-ne-recentes.md) - NEs de 2025+
- [NEs Pendentes Antigas](pendentes-ne-antigas.md) - NEs anteriores a 2025
- [SAM Pendentes](pendentes-sam.md) - Melhorias pendentes
- [SAL Pendentes](pendentes-sal.md) - Legislacao pendente
- [SAIL Pendentes](pendentes-sail.md) - Legislacao interna pendente

## Liberadas

- [NEs Liberadas Recentes](liberadas-ne-recentes.md) - NEs liberadas 2022+ (nivel SAI)
- [NEs Liberadas Antigas](liberadas-ne-antigas.md) - NEs liberadas anteriores a 2022 (nivel SAI)
- [SAM Liberadas](liberadas-sam.md) - Melhorias liberadas (nivel SAI)
- [SAL Liberadas](liberadas-sal.md) - Legislacao liberada (nivel SAI)
- [SAIL Liberadas](liberadas-sail.md) - Legislacao interna liberada (nivel SAI)

## Descartadas

- [NEs Descartadas](descartadas-ne.md) - NEs descartadas (nivel SAI)
- [SAM Descartadas](descartadas-sam.md) - Melhorias descartadas (nivel SAI)
- [SAL Descartadas](descartadas-sal.md) - Legislacao descartada (nivel SAI)
- [SAIL Descartadas](descartadas-sail.md) - Legislacao interna descartada (nivel SAI)

## Por versao (ultimas 5)

- [ZDuvidas](por-versao/ZDuvidas.md) - 2 registros
- [ParalelaPlatafo](por-versao/ParalelaPlatafo.md) - 2 registros
- [ONVIO Escrita -](por-versao/ONVIO_Escrita_-.md) - 29 registros
- [Escrita -Tribut](por-versao/Escrita_-Tribut.md) - 3 registros
- [AZ ONVIO - Escr](por-versao/AZ_ONVIO_-_Escr.md) - 1 registros


## Regenerar indices

Fluxo completo: `banco-dados/config/README.md` (`importar-sais.ps1` + `gerar-indices-sais.ps1`, **fora do Cursor**).

## Como usar

1. Abrir resumo-pendentes.md para visao geral
2. Identificar o dominio (slug) e abrir `modulos/{slug}.md`
3. Quando o tema cruzar areas, consultar dominios adjacentes (ex.: `sped-documentos-eletronicos` e `obrigacoes-relatorios-estaduais`)
4. Usar busca textual (Ctrl+Shift+F) nos indices
5. Pedir ao agente IA para cruzar informacoes

## JSONs fracionados (em dados-brutos/)

- `dados-brutos/psai/` - Todos os PSAIs individuais (NE, SAM, SAL, SAIL x pendentes, liberadas, descartadas)
- `dados-brutos/sai/` - SAIs unicas agrupadas (1 registro por SAI, com contagem de PSAIs)

## Buscar SAIs

Para buscar por termo: `scripts\buscar-sai.ps1 -Termo "palavra"` (terminal separado)
Para atualizar: `scripts\atualizar-tudo.bat` (terminal separado)
