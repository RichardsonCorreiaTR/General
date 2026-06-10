# sincronizar-sharepoint.ps1 (Projeto Admin)
# Espelha pastas de release do repo local para a pasta sincronizada com
# SharePoint (via OneDrive Files On-Demand). Apos a copia, o OneDrive
# faz upload automatico para o site SharePoint.
#
# CONTEXTO:
#   Repo Git principal: C:\1 - A\B\Programas\General  (NAO sincronizado)
#   Espelho SharePoint: C:\Users\<user>\OneDrive - Thomson Reuters Incorporated\
#                       CursorEscrita - CursorEscrita\General  (sincronizado)
#
# USO:
#   .\scripts\sincronizar-sharepoint.ps1                  Sync padrao (release)
#   .\scripts\sincronizar-sharepoint.ps1 -DryRun          Simula
#   .\scripts\sincronizar-sharepoint.ps1 -Destino "..."   Destino customizado
#
# Pode ser chamado no final de gerar-atualizacao.ps1 (etapa [7/7]).

param(
    [string]$Destino = "",
    [switch]$DryRun,
    [switch]$Verboso
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

# Auto-detectar destino se nao informado
if (-not $Destino) {
    $candidatos = @(
        "$env:OneDriveCommercial\CursorEscrita - CursorEscrita\General",
        "$env:USERPROFILE\OneDrive - Thomson Reuters Incorporated\CursorEscrita - CursorEscrita\General"
    )
    foreach ($c in $candidatos) {
        if (Test-Path -LiteralPath $c) { $Destino = $c; break }
    }
}

if (-not $Destino -or -not (Test-Path -LiteralPath $Destino)) {
    Write-Host "ERRO: Destino SharePoint nao encontrado." -ForegroundColor Red
    Write-Host "Tentado:" -ForegroundColor Yellow
    Write-Host "  $env:OneDriveCommercial\CursorEscrita - CursorEscrita\General"
    Write-Host "Informe via -Destino 'C:\caminho\sincronizado'" -ForegroundColor Yellow
    exit 1
}

Write-Host "=== Sincronizar repo -> SharePoint ===" -ForegroundColor Cyan
Write-Host "Origem:  $repoRoot"
Write-Host "Destino: $Destino"
if ($DryRun) { Write-Host "MODO: DryRun (nada sera copiado)" -ForegroundColor Yellow }
Write-Host ""

$logFile = Join-Path $env:TEMP ("sync-sharepoint-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))

# Pastas espelhadas inteiras (com /MIR para refletir remocoes)
$pastasMir = @(
    "distribuicao",
    "atualizacao"
)

# Arquivos individuais (configs e scripts core que mudam frequente)
$arqsCopia = @(
    # --- General root ---
    ".gitignore",
    "PROJETO.md",
    "DELEGACAO-ATUALIZACAO.md",
    "arquitetura\acesso-github-codigo.md",          # v2.4.38: doc canonico do processo GitHub
    "config\time-analistas.json",
    "config\codigo-fonte-branches.json",            # v2.4.38: branches declaradas pelo gestor
    "banco-dados\config\modulos-keywords.json",
    "banco-dados\codigo-sistema\REFERENCIA.md",     # v2.4.38: branch via config + acesso Team
    "banco-dados\codigo-sistema\META.json",
    "agentes\agente-codigo.md",                     # v2.4.38: Modo B (gh api) documentado
    # --- General/scripts ---
    "scripts\buscar-sai.ps1",
    "scripts\gerar-atualizacao.ps1",
    "scripts\sync-sgd-consulta-para-projeto-filho.ps1",
    "scripts\configurar-cursor-auto-run.ps1",
    "scripts\instalar-projeto-filho.ps1",
    "scripts\sincronizar-sharepoint.ps1",
    "scripts\relatorio-versoes-analistas.ps1",
    "scripts\importar-sais.ps1",
    "scripts\extrair-sais.ps1",
    "scripts\gerar-indices-sais.ps1",
    "scripts\consolidar-logs.ps1",
    "scripts\Publicar-LogAnalista.ps1",
    "scripts\agendar-atualizacao.ps1",
    "scripts\atualizar-silencioso.ps1",
    "scripts\atualizar-codigo.ps1",                 # v2.4.38: -BranchConceito + config
    # --- Projeto-filho config ---
    "projeto-filho\config\VERSION.json",
    "projeto-filho\config\analista.json",
    "projeto-filho\config\codigo-fonte.json",
    "projeto-filho\config\codigo-fonte-branches.json", # v2.4.38: branches via config (filho)
    "projeto-filho\config\cursor-rules-manifest.json",  # v2.4.38: inclui acesso-github.mdc
    # --- Projeto-filho docs (raiz) ---
    "projeto-filho\CORRECAO-SYMLINKS.md",
    "projeto-filho\SETUP.md",                       # v2.4.38: pre-requisitos gh CLI
    "projeto-filho\SETUP-GITHUB.md",                # v2.4.38: guia setup gh do analista
    "projeto-filho\PROMPT-INSTALACAO.md",           # v2.4.38: passo 8b GitHub no instalador
    # --- Projeto-filho scripts ---
    "projeto-filho\scripts\atualizar-projeto.ps1",
    "projeto-filho\scripts\atualizar-codigo.ps1",
    "projeto-filho\scripts\atualizar-codigo-fonte.ps1",
    "projeto-filho\scripts\buscar-sai.ps1",
    "projeto-filho\scripts\verificar-ambiente.ps1",
    "projeto-filho\scripts\corrigir-symlinks.ps1",
    "projeto-filho\scripts\Publicar-LogParaConsolidacao.ps1",
    "projeto-filho\scripts\setup-odbc.ps1",
    "projeto-filho\scripts\setup-sgd-python.ps1",
    "projeto-filho\scripts\configurar-cursor-auto-run.ps1",
    "projeto-filho\scripts\verificar-regras-cursor.ps1",
    "projeto-filho\scripts\Consultar-Legislacao.ps1",
    # --- Projeto-filho regras .mdc ---
    "projeto-filho\.cursor\rules\acesso-github.mdc",  # v2.4.38: regra dedicada de seguranca GitHub
    "projeto-filho\.cursor\rules\agente-codigo.mdc",
    "projeto-filho\.cursor\rules\agente-produto.mdc",
    "projeto-filho\.cursor\rules\guardiao.mdc",
    "projeto-filho\.cursor\rules\onboarding.mdc",
    "projeto-filho\.cursor\rules\padroes.mdc",
    "projeto-filho\.cursor\rules\projeto.mdc",
    "projeto-filho\.cursor\rules\revisar-psai.mdc",
    "projeto-filho\.cursor\rules\sgd-enriquecer-psai.mdc",
    "projeto-filho\.cursor\rules\consultar-legislacao.mdc",
    # --- Outros ---
    "logs\README.md"
)

# Pastas espelhadas seletivas (banco-dados/sais/indices, mas SEM dados-brutos pesados)
$pastasMirSeletivas = @(
    @{ src = "banco-dados\sais\indices"; dst = "banco-dados\sais\indices" },
    @{ src = "banco-dados\mapa-sistema"; dst = "banco-dados\mapa-sistema" }
)

$flagsRobocopy = @("/R:1", "/W:1", "/NP", "/NDL", "/NFL", "/XJ")
if (-not $Verboso) { $flagsRobocopy += "/NJH", "/NJS" }
if ($DryRun)       { $flagsRobocopy += "/L" }

$totalCopiados = 0
$totalErros = 0

# 1) Pastas com /MIR
foreach ($p in $pastasMir) {
    $src = Join-Path $repoRoot $p
    $dst = Join-Path $Destino $p
    if (-not (Test-Path -LiteralPath $src)) {
        Write-Host "[SKIP] $p (origem nao existe)" -ForegroundColor DarkGray
        continue
    }
    Write-Host "[MIR ] $p" -ForegroundColor Yellow
    & robocopy $src $dst /MIR @flagsRobocopy /LOG+:$logFile | Out-Null
    if ($LASTEXITCODE -ge 8) { $totalErros++; Write-Host "       ERRO (robocopy code $LASTEXITCODE)" -ForegroundColor Red }
}

# 2) Pastas seletivas com /MIR (subpastas especificas)
foreach ($ps in $pastasMirSeletivas) {
    $src = Join-Path $repoRoot $ps.src
    $dst = Join-Path $Destino $ps.dst
    if (-not (Test-Path -LiteralPath $src)) {
        Write-Host "[SKIP] $($ps.src) (origem nao existe)" -ForegroundColor DarkGray
        continue
    }
    Write-Host "[MIR ] $($ps.src)" -ForegroundColor Yellow
    & robocopy $src $dst /MIR @flagsRobocopy /LOG+:$logFile | Out-Null
    if ($LASTEXITCODE -ge 8) { $totalErros++; Write-Host "       ERRO (robocopy code $LASTEXITCODE)" -ForegroundColor Red }
}

# 3) Arquivos individuais
foreach ($a in $arqsCopia) {
    $src = Join-Path $repoRoot $a
    $dst = Join-Path $Destino $a
    if (-not (Test-Path -LiteralPath $src)) {
        Write-Host "[SKIP] $a (origem nao existe)" -ForegroundColor DarkGray
        continue
    }
    if ($DryRun) {
        Write-Host "[DRY ] $a" -ForegroundColor DarkYellow
    } else {
        $dDir = Split-Path -Parent $dst
        if (-not (Test-Path -LiteralPath $dDir)) { New-Item -ItemType Directory -Path $dDir -Force | Out-Null }
        Copy-Item -LiteralPath $src -Destination $dst -Force
        Write-Host "[COPY] $a" -ForegroundColor Green
        $totalCopiados++
    }
}

Write-Host ""
Write-Host "=== Concluido ===" -ForegroundColor Green
Write-Host "  Pastas /MIR: $($pastasMir.Count + $pastasMirSeletivas.Count)"
Write-Host "  Arquivos individuais copiados: $totalCopiados"
if ($totalErros -gt 0) {
    Write-Host "  ATENCAO: $totalErros erro(s) de robocopy. Veja log: $logFile" -ForegroundColor Red
} else {
    Write-Host "  Log: $logFile" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Proximos passos:" -ForegroundColor White
Write-Host "  1. OneDrive vai detectar mudancas e fazer upload para SharePoint."
Write-Host "  2. Tempo tipico de sync: 1-5 min dependendo do volume."
Write-Host "  3. Para acompanhar: clique no icone do OneDrive na barra de tarefas."
