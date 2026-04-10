# Diagnostico Tecnico - Base de SAIs/PSAIs

> Gerado em: 07/03/2026
> Fonte: Analise da conversa de planejamento

## Estado Atual dos Dados

### Ultima atualizacao
- JSONs brutos: 06/03/2026 16:30
- Maioria dos indices: 06/03/2026 16:31
- Excecoes desatualizadas:
  - indice-geral.md: 04/03/2026 (NAO gerado pelo script)
  - por-cenario-complexo.md: 04/03/2026 (NAO gerado pelo script)
  - por-rubrica.md: 04/03/2026 (NAO gerado pelo script, so o detalhado e)
- Mapa do sistema: 04/03 a 06/03/2026

### Volumes
- Total de registros: 29.296
- Monolitico: 165.39 MB
- PSAIs fracionados: 159.6 MB (12 arquivos)
- SAIs fracionados: 5.76 MB (12 arquivos)
- Indices MD: 4.57 MB (21 arquivos + 5 por-versao)
- Total no OneDrive: ~335 MB

### Divisao ativo vs imovel
- Pendentes (muda diariamente): ~14.5 MB PSAI + 0.23 MB SAI = ~14.7 MB
- Imoveis (muda raramente): ~145.4 MB PSAI + 5.5 MB SAI = ~150.9 MB

### Indices problematicos para contexto IA
- por-modulo.md: 2.041 KB, 20.086 linhas (408% do contexto)
- liberadas-ne-antigas.md: 858 KB (172%)
- liberadas-sam.md: 342 KB (68%)
- 4 outros > 200 KB (40-55% cada)
- Total: ~1.17M tokens (914% do contexto de 128K)

## Scripts Envolvidos

### extrair-sais.ps1 (extracao do banco)
- Conecta ao SGD via ODBC (DSN pbcvs9)
- Modo completo: ~20 min, extrai tudo
- Modo incremental: extrai so alterados desde ultima rodada
- Grava monolitico: sai-psai-folha.json (165 MB)
- Pico de RAM: nao medido (provavelmente ~1-2 GB no merge)

### gerar-indices-sais.ps1 (fracionamento + indices)
- Carrega monolitico inteiro na RAM (~2 GB PowerShell)
- Fase A: Gera 24 JSONs fracionados (12 psai + 12 sai)
- Fase B: Gera 21+ indices Markdown
- NAO gera: indice-geral.md, por-cenario-complexo.md, por-rubrica.md

### importar-sais.ps1 (orquestrador)
- Tenta ODBC primeiro, fallback para BuscaSaiFolha
- Chama gerar-indices-sais.ps1 ao final
- Grava metadados em cache/importacao-meta.json

### atualizar-tudo.bat (entry point manual)
- Chama importar-sais.ps1 -Incremental
- Chama atualizar-codigo.ps1
- Requer terminal separado (pause interativo)

## Projeto Filho - Estado

### Versao atual: 1.0.0 (05/03/2026)
### Distribuicao: v1.0.0 (mesma)
### Mecanismo de dados: symlink para OneDrive
### .cursorignore: bloqueia referencia/banco-dados/dados-brutos/
### Busca de SAIs: wrapper que redireciona para script do OneDrive
### Verificacao automatica: guardiao.mdc checa versao na 1a interacao
