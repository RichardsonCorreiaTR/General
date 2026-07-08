# publicar-dados-banco.ps1 (Projeto Admin)
# Publica dados brutos + indices/cache para o espelho SharePoint (OneDrive).
# O projeto-filho dos analistas consome via junction referencia/banco-dados.
#
# USO:
#   .\scripts\publicar-dados-banco.ps1
#   .\scripts\publicar-dados-banco.ps1 -DryRun
#   .\scripts\publicar-dados-banco.ps1 -Destino "C:\...\General"
#
# Apos a copia, chama sincronizar-sharepoint.ps1 (release padrao).

param(
    [string]$Destino = "",
    [switch]$DryRun,
    [switch]$SemSharePoint,
    [switch]$Verboso
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir

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
    exit 1
}

$statusPath = Join-Path $repoRoot "atualizacao\status.json"
$metaPath = Join-Path $repoRoot "banco-dados\sais\cache\importacao-meta.json"
if (-not (Test-Path -LiteralPath $statusPath)) {
    Write-Host "ERRO: atualizacao\status.json nao encontrado." -ForegroundColor Red
    exit 1
}

$status = Get-Content -LiteralPath $statusPath -Raw -Encoding UTF8 | ConvertFrom-Json
$dataPub = Get-Date -Format "yyyy-MM-dd"
$horaPub = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
$manifestDir = Join-Path $repoRoot "atualizacao\publicacao-dados"
$manifestPath = Join-Path $manifestDir "manifesto-$dataPub.json"

Write-Host "=== Publicar dados do banco -> SharePoint ===" -ForegroundColor Cyan
Write-Host "Origem:  $repoRoot"
Write-Host "Destino: $Destino"
Write-Host "Importacao: $($status.ultimaExecucao) ($($status.resultado))"
if ($DryRun) { Write-Host "MODO: DryRun" -ForegroundColor Yellow }
Write-Host ""

$logFile = Join-Path $env:TEMP ("publicar-dados-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$flagsRobocopy = @("/R:1", "/W:1", "/NP", "/NDL", "/NFL", "/XJ")
if (-not $Verboso) { $flagsRobocopy += "/NJH", "/NJS" }
if ($DryRun) { $flagsRobocopy += "/L" }

$pastasMir = @(
    "banco-dados\dados-brutos",
    "banco-dados\sais\validacoes"
)

$totalErros = 0
foreach ($p in $pastasMir) {
    $src = Join-Path $repoRoot $p
    $dst = Join-Path $Destino $p
    if (-not (Test-Path -LiteralPath $src)) {
        Write-Host "[SKIP] $p (origem nao existe)" -ForegroundColor DarkGray
        continue
    }
    Write-Host "[MIR ] $p" -ForegroundColor Yellow
    & robocopy $src $dst /MIR @flagsRobocopy /LOG+:$logFile | Out-Null
    if ($LASTEXITCODE -ge 8) {
        $totalErros++
        Write-Host "       ERRO robocopy $LASTEXITCODE" -ForegroundColor Red
    }
}

$arqs = @(
    "banco-dados\sais\cache\importacao-meta.json",
    "atualizacao\status.json"
)
foreach ($a in $arqs) {
    $src = Join-Path $repoRoot $a
    if (-not (Test-Path -LiteralPath $src)) {
        Write-Host "[SKIP] $a" -ForegroundColor DarkGray
        continue
    }
    $dst = Join-Path $Destino $a
    if ($DryRun) {
        Write-Host "[DRY ] $a" -ForegroundColor DarkYellow
    } else {
        $dDir = Split-Path -Parent $dst
        if (-not (Test-Path -LiteralPath $dDir)) { New-Item -ItemType Directory -Path $dDir -Force | Out-Null }
        Copy-Item -LiteralPath $src -Destination $dst -Force
        Write-Host "[COPY] $a" -ForegroundColor Green
    }
}

if (-not $SemSharePoint -and -not $DryRun) {
    Write-Host ""
    Write-Host "--- Sincronizar release padrao (indices, distribuicao, atualizacao) ---" -ForegroundColor Cyan
    & (Join-Path $scriptDir "sincronizar-sharepoint.ps1") -Destino $Destino
}

$manifest = [ordered]@{
    tipo = "publicacao-dados-banco"
    versaoManifesto = 1
    dataPublicacao = $horaPub
    origemRepo = $repoRoot
    destinoSharePoint = $Destino
    importacao = @{
        ultimaExecucao = $status.ultimaExecucao
        resultado = $status.resultado
        registrosProcessados = $status.registrosProcessados
        totalNoBanco = $status.totalNoBanco
        psaiMaisRecente = $status.psaiMaisRecente
        dataPsaiMaisRecente = $status.dataPsaiMaisRecente
        alertas = $status.alertas
    }
    pastasPublicadas = $pastasMir
    arquivosPublicados = $arqs
    incluiSincronizarSharePoint = (-not $SemSharePoint)
    instrucoesProjetoFilho = @(
        "Analistas: nao e necessario rodar atualizar-projeto.ps1 para dados brutos.",
        "A junction referencia/banco-dados aponta para o espelho OneDrive/SharePoint.",
        "Aguardar sync OneDrive (1-5 min) e reabrir o Cursor se indices estiverem em cache."
    )
}

if (-not $DryRun) {
    if (-not (Test-Path -LiteralPath $manifestDir)) {
        New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
    }
    $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    Write-Host ""
    Write-Host "Manifesto: $manifestPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Concluido ===" -ForegroundColor Green
if ($totalErros -gt 0) {
    Write-Host "ATENCAO: $totalErros erro(s). Log: $logFile" -ForegroundColor Red
    exit 1
}
Write-Host "Log robocopy: $logFile"
Write-Host ""
Write-Host "Git (repo local): commit indices + meta + manifesto (dados-brutos permanecem no .gitignore)."
