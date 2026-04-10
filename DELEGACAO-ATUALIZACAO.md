# Delegacao de Atualizacao — Plano de Contingencia

## Problema

O `scripts\atualizar-tudo.bat` precisa rodar periodicamente para manter
SAIs/PSAIs atualizados. Se o gerente estiver ausente, os dados ficam defasados.

## Solucao 1 — Backup humano (recomendada)

### Quem pode ser backup
- Analista senior com acesso a maquina com ODBC pbcvs9 configurado
- Ou qualquer pessoa com acesso ao SharePoint CursorFolha como editor

### O que o backup precisa fazer
1. Abrir terminal (PowerShell) na pasta do projeto
2. Rodar: `scripts\atualizar-tudo.bat`
3. Aguardar conclusao (~5-10 min)
4. Verificar se deu erro (mensagens em vermelho)

### Checklist para preparar backup
- [ ] Pessoa identificada e aceita
- [ ] ODBC pbcvs9 configurado na maquina dela (`scripts\setup-odbc.ps1`)
- [ ] Acesso de escrita ao SharePoint CursorFolha
- [ ] Treinamento de 5 min (rodar o bat e verificar)

## Solucao 2 — Tarefa agendada (Windows Task Scheduler)

Para automatizar na maquina do gerente ou servidor compartilhado.

### Configuracao

1. Abrir Agendador de Tarefas (taskschd.msc)
2. Criar Tarefa Basica:
   - **Nome**: Atualizacao FolhaSDD
   - **Disparador**: Diariamente as 07:00 (ou semanalmente segunda)
   - **Acao**: Iniciar programa
   - **Programa**: `powershell.exe`
   - **Argumentos**: `-ExecutionPolicy Bypass -File "C:\Users\{usuario}\Thomson Reuters Incorporated\CursorFolha - General\scripts\importar-sais.ps1"`
   - **Iniciar em**: `C:\Users\{usuario}\Thomson Reuters Incorporated\CursorFolha - General`
3. Na aba **Geral**: Marcar "Executar estando o usuario conectado ou nao"
4. Na aba **Configuracoes**: Marcar "Se a tarefa falhar, reiniciar a cada 30 min"

### Limitacoes da tarefa agendada
- Requer que a maquina esteja ligada no horario
- ODBC pbcvs9 precisa estar acessivel (rede)
- OneDrive precisa estar sincronizando
- Se falhar, ninguem ve o erro automaticamente

## Solucao 3 — Hibrida (recomendada para producao)

1. Tarefa agendada roda automaticamente todo dia de manha
2. Backup humano sabe rodar manualmente se a automatica falhar
3. Um log de verificacao (abaixo) permite checar se esta tudo em dia

## Script de verificacao

Qualquer pessoa pode verificar se os dados estao atualizados olhando
os indices em `banco-dados\sais\indices\`. O campo "Atualizado em"
no topo de cada arquivo mostra a ultima atualizacao.

Se a data for de mais de 3 dias atras, rodar `scripts\atualizar-tudo.bat`.
