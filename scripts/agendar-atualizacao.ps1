# agendar-atualizacao.ps1
# Cria (ou remove) tarefa agendada no Windows Task Scheduler.
# Executar UMA VEZ para configurar a automacao.
#
# Uso:
#   .\agendar-atualizacao.ps1              Cria a tarefa
#   .\agendar-atualizacao.ps1 -Remover     Remove a tarefa

param(
    [switch]$Remover,
    [string]$HoraInicial = "09:00",
    # Por defeito corre seg-sex (PBCVS/VPN frequentemente offline em sab/dom).
    # Use -Diario para forcar comportamento legado (todos os dias).
    [switch]$Diario
)

$ErrorActionPreference = "Stop"
$taskName = "EscritaSDD-Atualizacao"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$silenciosoPath = Join-Path $scriptDir "atualizar-silencioso.ps1"

if ($Remover) {
    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existing) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "Tarefa '$taskName' removida com sucesso." -ForegroundColor Green
    } else {
        Write-Host "Tarefa '$taskName' nao encontrada." -ForegroundColor Yellow
    }
    exit 0
}

if (-not (Test-Path $silenciosoPath)) {
    Write-Host "ERRO: $silenciosoPath nao encontrado." -ForegroundColor Red
    exit 1
}

$tipoExecucao = if ($Diario) { "diariamente (todos os dias)" } else { "segunda a sexta" }

Write-Host "=== Configurando tarefa agendada ===" -ForegroundColor Cyan
Write-Host "Nome: $taskName"
Write-Host "Script: $silenciosoPath"
Write-Host "Hora inicial: $HoraInicial"
Write-Host "Repeticao: a cada 3h (ate ~17h)"
Write-Host "Dias: $tipoExecucao"
Write-Host ""

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -NonInteractive -File `"$silenciosoPath`""

$triggerLogon = New-ScheduledTaskTrigger -AtLogOn

if ($Diario) {
    $triggerPrincipal = New-ScheduledTaskTrigger -Daily -At $HoraInicial
} else {
    $triggerPrincipal = New-ScheduledTaskTrigger -Weekly -At $HoraInicial -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday
}
$triggerPrincipal.Repetition = (New-ScheduledTaskTrigger -Once -At $HoraInicial `
    -RepetitionInterval (New-TimeSpan -Hours 3) `
    -RepetitionDuration (New-TimeSpan -Hours 9)).Repetition

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 30) `
    -MultipleInstances IgnoreNew

$existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Tarefa ja existe. Atualizando..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $triggerLogon, $triggerPrincipal `
    -Settings $settings `
    -Description "Escrita SDD - Atualizacao automatica de SAIs/PSAIs e indices. Frequencia: $tipoExecucao a partir de $HoraInicial (repete a cada 3h ate ~17h). Modo: ODBC->BuscaSAI fallback." | Out-Null

Write-Host ""
Write-Host "=== Tarefa criada com sucesso! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Verificacao:" -ForegroundColor Yellow
$task = Get-ScheduledTask -TaskName $taskName
Write-Host "  Estado: $($task.State)"
Write-Host "  Triggers: $($task.Triggers.Count)"
foreach ($t in $task.Triggers) {
    Write-Host "    - $($t.CimClass.CimClassName): $($t.StartBoundary)"
}
Write-Host ""
Write-Host "Para remover: .\agendar-atualizacao.ps1 -Remover"
Write-Host "Para testar:  .\atualizar-silencioso.ps1"
