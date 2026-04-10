# atualizar-codigo.ps1 (Projeto Filho)
# Atualiza o codigo-fonte do Dominio Contabil para pasta local.
# Le paths de config/caminhos.json.
#
# IMPORTANTE: Rodar em terminal SEPARADO (fora do Cursor)

param(
    [string]$Branch = "VC106A02",
    [string]$RepoUrl = "https://github.com/tr/brtap-dominio_contabil",
    [string]$RepoLocal = ""
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir

$caminhosFile = Join-Path $projetoDir "config\caminhos.json"
if (-not (Test-Path $caminhosFile)) {
    Write-Host "ERRO: config/caminhos.json nao encontrado. Rode o instalador primeiro." -ForegroundColor Red
    exit 1
}
$caminhos = Get-Content $caminhosFile -Raw | ConvertFrom-Json
$destinoDir = $caminhos.codigo_local
$onedriveBase = $caminhos.onedrive_base

$metaDir = Split-Path $destinoDir
$metaFile = Join-Path $metaDir "META.json"
$changelogDir = Join-Path $onedriveBase "banco-dados\codigo-sistema\changelog"

Write-Host "=== Atualizador de Codigo-Fonte Escrita ===" -ForegroundColor Cyan
Write-Host "Branch: $Branch"
Write-Host "Destino: $destinoDir"
Write-Host ""

$possiveisLocais = @($RepoLocal, "C:\1 - A\B\Programas\brtap-dominio", "C:\Users\$($env:USERNAME)\brtap-dominio_contabil", "D:\brtap-dominio_contabil")
$repoLocalDir = $null
foreach ($caminho in $possiveisLocais) {
    if (-not $caminho) { continue }
    if (-not (Test-Path (Join-Path $caminho "escrita"))) { continue }
    if ((git -C $caminho branch --show-current 2>$null) -eq $Branch) {
        $repoLocalDir = $caminho; break
    }
}

if ($repoLocalDir) {
    Write-Host "[Modo: Repo Local] $repoLocalDir" -ForegroundColor Green
    Write-Host "[1/4] Atualizando repo local (git pull)..." -ForegroundColor Yellow
    git -C $repoLocalDir pull origin $Branch 2>&1 | Out-Host
    $origemModulo = Join-Path $repoLocalDir "escrita"
    if (-not (Test-Path $origemModulo)) {
        Write-Host "ERRO: Pasta 'escrita' nao encontrada em $repoLocalDir" -ForegroundColor Red
        exit 1
    }
    $commitHash = (git -C $repoLocalDir log -1 --format="%H").Trim()
    $commitMsg = (git -C $repoLocalDir log -1 --format="%s").Trim()
    $commitDate = (git -C $repoLocalDir log -1 --format="%ci").Trim()
    $fonte = "repo-local"
} else {
    Write-Host "[Modo: GitHub Clone] Clonando..." -ForegroundColor Yellow
    $tempDir = Join-Path $env:TEMP "escrita-sdd-clone-$(Get-Random)"
    Write-Host "[1/4] Clonando branch $Branch (shallow)..." -ForegroundColor Yellow
    git clone --depth 1 --branch $Branch --single-branch $RepoUrl $tempDir 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO: Falha no clone." -ForegroundColor Red; exit 1
    }
    $origemModulo = Join-Path $tempDir "escrita"
    if (-not (Test-Path $origemModulo)) {
        Write-Host "ERRO: Clone nao contem a pasta 'escrita'. Verifique branch e repositorio." -ForegroundColor Red
        if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
        exit 1
    }
    $commitHash = (git -C $tempDir log -1 --format="%H").Trim()
    $commitMsg = (git -C $tempDir log -1 --format="%s").Trim()
    $commitDate = (git -C $tempDir log -1 --format="%ci").Trim()
    $fonte = "github-clone"
}

Write-Host "  Commit: $($commitHash.Substring(0,10)) ($commitDate)"

if (Test-Path $metaFile) {
    $metaAtual = Get-Content $metaFile -Raw | ConvertFrom-Json
    if ($metaAtual.commit -eq $commitHash) {
        Write-Host ""; Write-Host "Codigo ja esta atualizado (mesmo commit)." -ForegroundColor Green
        if ($tempDir -and (Test-Path $tempDir)) { Remove-Item -Recurse -Force $tempDir }
        exit 0
    }
}

Write-Host "[2/4] Limpando destino..." -ForegroundColor Yellow
if (Test-Path $destinoDir) {
    Get-ChildItem $destinoDir | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $destinoDir -Force | Out-Null

Write-Host "[3/4] Copiando modulo Escrita..." -ForegroundColor Yellow
Copy-Item -Path "$origemModulo\*" -Destination $destinoDir -Recurse -Force
$arquivos = (Get-ChildItem -Recurse -File $destinoDir | Measure-Object)
$tamanhoMB = [math]::Round(($arquivos | Measure-Object).Count / 1000, 1)
$totalArqs = $arquivos.Count
Write-Host "  Copiados: $totalArqs arquivos -> $destinoDir"

Write-Host "[4/4] Salvando metadados..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $metaDir -Force | Out-Null
$meta = @{
    branch = $Branch; commit = $commitHash; commitMsg = $commitMsg
    commitDate = $commitDate
    atualizadoEm = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    atualizadoPor = $env:USERNAME; fonte = $fonte
    arquivos = $totalArqs; dadosLocais = $destinoDir
} | ConvertTo-Json -Depth 2
Set-Content -Path $metaFile -Value $meta -Encoding UTF8

if ($onedriveBase -and (Test-Path $onedriveBase)) {
    New-Item -ItemType Directory -Path $changelogDir -Force | Out-Null
    $changelogContent = "# Atualizacao $Branch - $(Get-Date -Format 'dd/MM/yyyy HH:mm')`n`n- **Branch:** $Branch`n- **Commit:** $($commitHash.Substring(0,10))`n- **Mensagem:** $commitMsg`n- **Data commit:** $commitDate`n- **Atualizado por:** $($env:USERNAME)`n- **Fonte:** $fonte`n- **Arquivos:** $totalArqs`n- **Local:** $destinoDir"
    Set-Content -Path (Join-Path $changelogDir "$(Get-Date -Format 'yyyy-MM-dd')-$Branch.md") -Value $changelogContent -Encoding UTF8
}

if ($tempDir -and (Test-Path $tempDir)) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }

Write-Host ""
Write-Host "=== Concluido! ===" -ForegroundColor Green
Write-Host "Codigo da versao $Branch em: $destinoDir"
