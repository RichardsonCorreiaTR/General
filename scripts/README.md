# Scripts do Projeto — Documentacao Operacional

> Referencia completa de todos os scripts PowerShell e BAT do projeto.
> Para cada script: proposito, parametros, saida esperada, dependencias e recuperacao em caso de falha.

---

## Projeto Admin (`scripts/`)

### agendar-atualizacao.ps1

- **Proposito**: Agenda a execucao de atualizacao silenciosa via Task Scheduler do Windows.
- **Parametros**: Nenhum obrigatorio.
- **Saida esperada**: Tarefa agendada criada no Windows Task Scheduler.
- **Dependencias**: `atualizar-silencioso.ps1`.
- **Recuperacao**: Verificar Task Scheduler manualmente. Recriar a tarefa se necessario.

### analise-blob-html.ps1

- **Proposito**: Analisa campos BLOB com conteudo HTML das SAIs para extracao de dados estruturados.
- **Parametros**: Depende do contexto de extracao.
- **Saida esperada**: Dados extraidos dos BLOBs em formato estruturado.
- **Dependencias**: Dados brutos em `banco-dados/dados-brutos/`.
- **Recuperacao**: Re-executar. Nao altera dados de origem.

### arquivar-logs.ps1

- **Proposito**: Move logs antigos para pasta de arquivo, mantendo apenas os recentes.
- **Parametros**: Nenhum obrigatorio.
- **Saida esperada**: Logs antigos movidos; logs recentes mantidos.
- **Dependencias**: Nenhuma.
- **Recuperacao**: Logs arquivados podem ser restaurados manualmente da pasta de arquivo.

### atualizar-codigo.ps1

- **Proposito**: Baixa ou atualiza o codigo-fonte do sistema via git clone.
- **Parametros**: URL do repositorio git.
- **Saida esperada**: Codigo-fonte atualizado na pasta de referencia.
- **Dependencias**: Git instalado e acessivel no PATH.
- **Recuperacao**: Se falhar, codigo anterior e preservado. Re-executar apos resolver o problema de conectividade.

### atualizar-silencioso.ps1

- **Proposito**: Executa atualizacao do projeto filho sem interacao do usuario (modo batch).
- **Parametros**: Nenhum obrigatorio.
- **Saida esperada**: Projeto filho atualizado para a versao mais recente da distribuicao.
- **Dependencias**: `distribuicao/ultima-versao/` com pacote valido.
- **Recuperacao**: Verificar logs de execucao. Re-executar manualmente se necessario.

### atualizar-tudo.bat

- **Proposito**: Orquestrador principal — executa todos os passos de atualizacao em sequencia.
- **Parametros**: Nenhum.
- **Saida esperada**: Atualizacao completa do ambiente (extracao, indices, cache, distribuicao).
- **Dependencias**: Todos os scripts que ele invoca (ver sequencia interna).
- **Recuperacao**: Se falhar no passo N, identificar qual script falhou pelo log. Corrigir e re-executar o `atualizar-tudo.bat` — scripts ja executados com sucesso sao idempotentes.

### buscar-sai.ps1

- **Proposito**: Busca profunda em SAIs/PSAIs nos 14 campos dos dados brutos, sem risco de OOM.
- **Parametros**: `-Termo <texto>`, `-Tipo <NE|SAM|SAL|SAIL>`, `-Modulo <modulo>`, `-Pendentes`, `-Max <N>`, `-Resumido`, `-SAI <numero>`, `-VerPSAIs`, `-DataDe <data>`.
- **Saida esperada**: Lista de SAIs/PSAIs correspondentes com campos relevantes.
- **Dependencias**: Dados brutos em `banco-dados/dados-brutos/` acessiveis (via symlink).
- **Recuperacao**: Se symlink quebrado, rodar `corrigir-symlinks.ps1` no projeto filho. Se dados ausentes, executar extracao.

### consolidar-logs.ps1

- **Proposito**: Consolida logs diarios em relatorio resumido para revisao do gerente.
- **Parametros**: Nenhum obrigatorio.
- **Saida esperada**: Arquivo consolidado com resumo de atividades.
- **Dependencias**: Logs em `referencia/logs/`.
- **Recuperacao**: Re-executar. Nao altera logs originais.

### dashboard-extracao.ps1

- **Proposito**: Exibe painel de status das extracoes de SAIs (quantidades, pendencias, erros).
- **Parametros**: Nenhum obrigatorio.
- **Saida esperada**: Relatorio visual no terminal com contadores de status.
- **Dependencias**: Dados de extracao em `scripts/cache/`.
- **Recuperacao**: Apenas leitura — nenhuma acao de recuperacao necessaria.

### extrair-faltantes.ps1

- **Proposito**: Extrai SAIs que faltam no cache local (delta desde ultima extracao).
- **Parametros**: Depende da configuracao ODBC.
- **Saida esperada**: SAIs faltantes extraidas e adicionadas ao cache.
- **Dependencias**: Conexao ODBC configurada, `setup-odbc.ps1` executado previamente.
- **Recuperacao**: Re-executar. Extracao e incremental e idempotente.

### extrair-sais.ps1

- **Proposito**: Extracao completa de SAIs do banco de dados via ODBC.
- **Parametros**: Depende da configuracao ODBC.
- **Saida esperada**: Dados brutos de SAIs extraidos para `scripts/cache/`.
- **Dependencias**: Conexao ODBC configurada.
- **Recuperacao**: Re-executar. Pode demorar. Verificar conexao ODBC antes.

### gerar-atualizacao.ps1

- **Proposito**: Gera pacote de atualizacao para distribuicao aos projetos filhos.
- **Parametros**: `-Versao` (obrigatorio, semver), `-Changelog` (opcional), `-CompativelComAdmin` (opcional; padrao alinhado ao blueprint em `PROJETO.md` secao 9, ex. `2.5`).
- **Saida esperada**: `distribuicao/projeto-filho-vX.Y.Z.zip`, `distribuicao/ultima-versao/`, `atualizacao/vX.Y.Z/`; atualiza `projeto-filho/config/VERSION.json` com `hash_validacao` (MD5 de `guardiao.mdc`).
- **Dependencias**: Todos os arquivos do projeto-filho preparados em `projeto-filho/`.
- **Recuperacao**: Se interrompido, VERSION.json permanece na versao anterior (protecao R3). Re-executar com seguranca.

### gerar-indice-codigo.ps1

- **Proposito**: Gera indice navegavel do codigo-fonte para consulta pelo Cursor.
- **Parametros**: Nenhum obrigatorio.
- **Saida esperada**: Indice em `referencia/codigo-fonte/indices/`.
- **Dependencias**: Codigo-fonte presente em `referencia/codigo-fonte/`.
- **Recuperacao**: Re-executar. Nao altera codigo-fonte.

### gerar-indices-sais.ps1

- **Proposito**: Gera indices MD leves a partir dos dados brutos de SAIs para leitura segura pelo Cursor.
- **Parametros**: Nenhum obrigatorio.
- **Saida esperada**: Arquivos MD em `banco-dados/sais/indices/modulos/`.
- **Dependencias**: Dados brutos extraidos em `scripts/cache/` ou `banco-dados/dados-brutos/`.
- **Recuperacao**: Re-executar. Indices sao regeneraveis.

### importar-sais.ps1

- **Proposito**: Importa SAIs extraidas para a estrutura do banco de dados do projeto.
- **Parametros**: Depende do formato de entrada.
- **Saida esperada**: SAIs importadas e organizadas em `banco-dados/`.
- **Dependencias**: `extrair-sais.ps1` executado previamente.
- **Recuperacao**: Re-executar apos corrigir dados de entrada.

### instalar-jessica-vieira.ps1

- **Proposito**: Script de instalacao especifico para o ambiente da analista Jessica Vieira.
- **Parametros**: Nenhum obrigatorio.
- **Saida esperada**: Projeto filho configurado no ambiente da analista.
- **Dependencias**: Pacote de distribuicao em `distribuicao/ultima-versao/`.
- **Recuperacao**: Re-executar. Instalacao e idempotente.

### instalar-projeto-filho.ps1

- **Proposito**: Instala o projeto filho para um novo analista (generico).
- **Parametros**: Nome do analista, caminho de destino.
- **Saida esperada**: Projeto filho completo instalado e configurado.
- **Dependencias**: Pacote de distribuicao em `distribuicao/ultima-versao/`.
- **Recuperacao**: Apagar pasta de destino e re-executar.

### lib-lock.ps1

- **Proposito**: Biblioteca auxiliar de lock para evitar execucao concorrente de scripts.
- **Parametros**: N/A (importado por outros scripts).
- **Saida esperada**: Funcoes de lock disponiveis para uso.
- **Dependencias**: Nenhuma.
- **Recuperacao**: Se lock fica orfao, apagar arquivo `.lock` manualmente.

### reconstruir-cache.ps1

- **Proposito**: Reconstroi o cache monolitico de SAIs/PSAIs a partir dos dados brutos.
- **Parametros**: Nenhum obrigatorio.
- **Saida esperada**: Cache regenerado em `scripts/cache/`.
- **Dependencias**: Dados brutos disponiveis.
- **Recuperacao**: Re-executar. Processo demorado mas seguro.

### restaurar-fracionados.ps1

- **Proposito**: Restaura dados brutos fracionados a partir do cache monolitico.
- **Parametros**: Nenhum obrigatorio.
- **Saida esperada**: Arquivos fracionados regenerados em `banco-dados/dados-brutos/`.
- **Dependencias**: Cache em `scripts/cache/`.
- **Recuperacao**: Re-executar.

### revisar-definicao.ps1

- **Proposito**: Gerencia o fluxo de revisao de definicoes (listar pendentes, aprovar, rejeitar).
- **Parametros**: `-Acao <listar|aprovar|rejeitar>`, `-Arquivo <caminho>`.
- **Saida esperada**: Definicao movida entre pastas de revisao conforme acao.
- **Dependencias**: Estrutura `revisao/pendente/`, `revisao/aprovado/`, `revisao/rejeitado/`.
- **Recuperacao**: Mover arquivo manualmente entre pastas se necessario.

### setup-odbc.ps1

- **Proposito**: Configura conexao ODBC para extracao de dados do SGD.
- **Parametros**: Credenciais e servidor de banco.
- **Saida esperada**: DSN ODBC configurado no sistema.
- **Dependencias**: Driver ODBC instalado, acesso de rede ao servidor.
- **Recuperacao**: Verificar configuracao ODBC no painel do Windows. Re-executar.

### test-executar-query.ps1

- **Proposito**: Testa execucao de query ODBC para validar conectividade.
- **Parametros**: Query de teste.
- **Saida esperada**: Resultado da query exibido no terminal.
- **Dependencias**: `setup-odbc.ps1` executado.
- **Recuperacao**: Apenas leitura — nenhuma acao necessaria.

### test-odbc-context.ps1

- **Proposito**: Testa contexto ODBC (DSN, driver, servidor) para diagnostico.
- **Parametros**: Nenhum obrigatorio.
- **Saida esperada**: Status de conectividade ODBC.
- **Dependencias**: DSN ODBC configurado.
- **Recuperacao**: Apenas leitura.

---

## Projeto Filho (`projeto-filho/scripts/`)

### atualizar-codigo.ps1

- **Proposito**: Baixa ou atualiza o codigo-fonte do sistema no ambiente do analista via git.
- **Parametros**: URL do repositorio (se aplicavel).
- **Saida esperada**: Codigo-fonte atualizado em `referencia/codigo-fonte/`.
- **Dependencias**: Git instalado e acessivel.
- **Recuperacao**: Re-executar apos resolver problema de rede. Codigo anterior preservado.

### atualizar-projeto.ps1

- **Proposito**: Atualiza o projeto filho para a versao mais recente disponivel na distribuicao.
- **Parametros**: Nenhum obrigatorio (detecta versao automaticamente).
- **Saida esperada**: Regras .mdc, templates e config atualizados. VERSION.json incrementado.
- **Dependencias**: Acesso ao OneDrive sincronizado com pacote de atualizacao.
- **Recuperacao**: Se interrompido, re-executar. VERSION.json so e gravado ao final (protecao R3).

### buscar-sai.ps1

- **Proposito**: Copia local do buscar-sai.ps1 para uso do analista no terminal.
- **Parametros**: Mesmos do script admin (ver acima).
- **Saida esperada**: Resultados de busca no terminal.
- **Dependencias**: Symlink para dados brutos funcional.
- **Recuperacao**: Rodar `corrigir-symlinks.ps1` se symlink estiver quebrado.

### corrigir-symlinks.ps1

- **Proposito**: Recria symlinks para `referencia/banco-dados/` quando quebrados.
- **Parametros**: Nenhum obrigatorio.
- **Saida esperada**: Symlinks restaurados e acessiveis.
- **Dependencias**: Acesso de rede/OneDrive ao diretorio de dados.
- **Recuperacao**: Se falhar, verificar caminho de destino e permissoes. Acionar gerente se persistir.

### setup-odbc.ps1

- **Proposito**: Configura ODBC no ambiente do analista (se necessario para buscas diretas).
- **Parametros**: Credenciais fornecidas pelo gerente.
- **Saida esperada**: DSN ODBC configurado.
- **Dependencias**: Driver ODBC, acesso de rede.
- **Recuperacao**: Verificar painel ODBC do Windows.

### verificar-ambiente.ps1

- **Proposito**: Verifica se o ambiente do analista esta saudavel (symlinks, config, templates).
- **Parametros**: Nenhum obrigatorio.
- **Saida esperada**: Relatorio Pass/Fail de cada verificacao.
- **Dependencias**: Nenhuma.
- **Recuperacao**: Seguir instrucoes de cada item com falha.

---

## Scripts Novos (v2.4.0)

### admin/scripts/atualizar-codigo-fonte.ps1 (M11)

- **Proposito**: Substitui o codigo-fonte do sistema de forma segura, com backup e rollback automatico.
- **Parametros**: `-UrlGit <url>` (modo git, preferencial).
- **Saida esperada**: Codigo-fonte atualizado em `referencia/codigo-fonte/`, stamp de versao em `config/codigo-fonte-version.json`.
- **Dependencias**: `config/codigo-fonte.json` com configuracao valida. Git (modo 1) ou ZIP no OneDrive (modo 2).
- **Recuperacao**: Se falhar, backup e restaurado automaticamente. Mensagem de escalacao exibida com detalhes para o gerente.

### admin/scripts/verificar-saude.ps1 (R5)

- **Proposito**: Verifica saude do ambiente do projeto filho (cursorignore, VERSION.json, analista.json).
- **Parametros**: `-Projeto <caminho>` (padrao: diretorio atual).
- **Saida esperada**: Relatorio Pass/Fail com mensagens claras em portugues.
- **Dependencias**: Nenhuma.
- **Recuperacao**: Apenas leitura — seguir instrucoes de cada falha reportada.

### admin/scripts/gerar-indices-enriquecidos.ps1 (M13/P3)

- **Proposito**: Gera indices enriquecidos (~300 chars + campos-chave) a partir dos dados brutos de SAIs.
- **Dominios**: v2.5.0+ classifica por `banco-dados/config/modulos-keywords.json` (mesmos slugs Escrita que `gerar-indices-sais.ps1`); `por-modulo/{slug}.json` alinha a `sais/indices/modulos/{slug}.md`.
- **Parametros**: Nenhum obrigatorio (`-FonteDados`, `-Destino` opcionais).
- **Saida esperada**: JSON em `indices/enriquecidos/` (padrao), incluindo `por-modulo/{dominio-slug}.json`. Rodar fora do Cursor (OOM).
- **Dependencias**: Dados brutos em `banco-dados/dados-brutos/`.
- **Recuperacao**: Re-executar. Indices sao regeneraveis. Chamado automaticamente por `gerar-atualizacao.ps1`.

### admin/scripts/backup-pre-atualizacao.ps1

- **Proposito**: Cria backup completo de regras .mdc, config/ e templates/ do projeto filho antes de uma atualizacao.
- **Parametros**: `-ProjetoFilho <caminho>` (caminho para o projeto-filho).
- **Saida esperada**: Backup em `meu-trabalho/backup-v2.3/[TIMESTAMP]/` com verificacao de integridade.
- **Dependencias**: Projeto filho existente no caminho informado.
- **Recuperacao**: Se backup falhar, nenhum dado e alterado. Re-executar.

---

## Mapa de Dependencias entre Scripts

```
atualizar-tudo.bat
  |-- extrair-sais.ps1 (ou extrair-faltantes.ps1)
  |-- importar-sais.ps1
  |-- gerar-indices-sais.ps1
  |-- gerar-indices-enriquecidos.ps1 (v2.5.0)
  |-- reconstruir-cache.ps1
  |-- gerar-atualizacao.ps1
       |-- (grava VERSION.json ao final)

gerar-atualizacao.ps1
  |-- gerar-indices-enriquecidos.ps1 (v2.5.0)

atualizar-projeto.ps1 (filho)
  |-- le pacote de distribuicao/
  |-- verifica OneDrive sync (v2.4.0)
  |-- atualiza regras, templates, config
  |-- grava VERSION.json ao final

atualizar-codigo-fonte.ps1 (v2.4.0)
  |-- le config/codigo-fonte.json
  |-- git clone OU extrai ZIP
  |-- grava config/codigo-fonte-version.json
```
