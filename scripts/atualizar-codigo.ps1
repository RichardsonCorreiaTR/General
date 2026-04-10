# atualizar-codigo.ps1
# Atualiza o codigo-fonte do Dominio Contabil (modulo Escrita)
# Destino: pasta LOCAL do usuario (5.584 arquivos PB nao cabem no OneDrive)
# Metadados leves vao para o projeto OneDrive (changelog, META.json)
#
# IMPORTANTE: Rodar em terminal SEPARADO (fora do Cursor)

param(
    [string]$Branch = "VC106A02",
    [string]$RepoUrl = "https://github.com/tr/brtap-dominio_contabil",
    [string]$RepoLocal = "",
    [string]$DadosDir = ""
)

# Determinar diretorio de dados: prioridade para C:\CursorEscrita, fallback para legado Folha (migracao)
if (-not $DadosDir) {
    $novoPadrao = "C:\CursorEscrita\codigo-sistema"
    $legado = Join-Path $env:USERPROFILE "EscritaSDD-dados-pesados"
    if (-not (Test-Path (Join-Path $legado "versao-atual"))) {
        $legado = Join-Path $env:USERPROFILE "FolhaSDD-dados-pesados"
    }
    if (Test-Path (Join-Path $legado "versao-atual")) {
        $DadosDir = $legado
    } else {
        $DadosDir = $novoPadrao
    }
}

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir
$destinoDir = Join-Path $DadosDir "versao-atual"
$changelogDir = Join-Path $projetoDir "banco-dados\codigo-sistema\changelog"
$metaFile = Join-Path $projetoDir "banco-dados\codigo-sistema\META.json"

. (Join-Path $scriptDir "lib-lock.ps1")
if (-not (Request-Lock $projetoDir "atualizar-codigo")) { exit 1 }

New-Item -ItemType Directory -Path $DadosDir -Force | Out-Null

Write-Host "=== Atualizador de Codigo-Fonte Escrita ===" -ForegroundColor Cyan
Write-Host "Branch: $Branch"
Write-Host "Destino (LOCAL): $destinoDir"
Write-Host ""

# Buscar repo local automaticamente
$possiveisLocais = @(
    $RepoLocal,
    "C:\1 - A\B\Programas\brtap-dominio",
    "C:\Users\$($env:USERNAME)\brtap-dominio_contabil",
    "D:\brtap-dominio_contabil"
)

$repoLocalDir = $null
foreach ($caminho in $possiveisLocais) {
    if ($caminho -and (Test-Path (Join-Path $caminho "escrita"))) {
        $branchLocal = (git -C $caminho branch --show-current 2>$null)
        if ($branchLocal -eq $Branch) {
            $repoLocalDir = $caminho
            break
        }
    }
}

if ($repoLocalDir) {
    Write-Host "[Modo: Repo Local] $repoLocalDir" -ForegroundColor Green
    Write-Host "[1/4] Atualizando repo local (git pull)..." -ForegroundColor Yellow
    git -C $repoLocalDir pull origin $Branch 2>&1 | Out-Host
    $origemEscrita = Join-Path $repoLocalDir "escrita"
    $commitHash = (git -C $repoLocalDir log -1 --format="%H").Trim()
    $commitMsg = (git -C $repoLocalDir log -1 --format="%s").Trim()
    $commitDate = (git -C $repoLocalDir log -1 --format="%ci").Trim()
    $fonte = "repo-local"
} else {
    Write-Host "[Modo: GitHub Clone] Repo local nao encontrado, clonando..." -ForegroundColor Yellow
    $tempDir = Join-Path $env:TEMP "escrita-sdd-clone-$(Get-Random)"
    Write-Host "[1/4] Clonando branch $Branch (shallow)..." -ForegroundColor Yellow
    Write-Host "  AVISO: Isso pode demorar bastante (repo grande)." -ForegroundColor DarkYellow
    git clone --depth 1 --branch $Branch --single-branch $RepoUrl $tempDir 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO: Falha no clone." -ForegroundColor Red
        Release-Lock $projetoDir
        exit 1
    }
    $origemEscrita = Join-Path $tempDir "escrita"
    $commitHash = (git -C $tempDir log -1 --format="%H").Trim()
    $commitMsg = (git -C $tempDir log -1 --format="%s").Trim()
    $commitDate = (git -C $tempDir log -1 --format="%ci").Trim()
    $fonte = "github-clone"
}

Write-Host "  Commit: $($commitHash.Substring(0,10)) ($commitDate)"

# Verificar se ja esta atualizado
if (Test-Path $metaFile) {
    $metaAtual = Get-Content $metaFile -Raw | ConvertFrom-Json
    if ($metaAtual.commit -eq $commitHash) {
        Write-Host ""
        Write-Host "Codigo ja esta atualizado (mesmo commit)." -ForegroundColor Green
        if ($tempDir -and (Test-Path $tempDir)) { Remove-Item -Recurse -Force $tempDir }
        Release-Lock $projetoDir
        exit 0
    }
}

# Limpar e copiar para pasta LOCAL
Write-Host "[2/4] Limpando destino LOCAL..." -ForegroundColor Yellow
if (Test-Path $destinoDir) {
    Get-ChildItem $destinoDir | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $destinoDir -Force | Out-Null

Write-Host "[3/4] Copiando modulo Escrita para LOCAL..." -ForegroundColor Yellow
Copy-Item -Path "$origemEscrita\*" -Destination $destinoDir -Recurse -Force
$arquivos = (Get-ChildItem -Recurse -File $destinoDir | Measure-Object)
$tamanhoSum = (Get-ChildItem -Recurse -File $destinoDir | Measure-Object -Property Length -Sum)
$tamanhoMB = [math]::Round($tamanhoSum.Sum / 1MB, 1)
Write-Host "  Copiados: $($arquivos.Count) arquivos ($tamanhoMB MB) -> $destinoDir"

# Metadados LEVES no projeto OneDrive
Write-Host "[4/4] Salvando metadados no projeto..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path (Split-Path $metaFile) -Force | Out-Null
$meta = @{
    branch = $Branch
    commit = $commitHash
    commitMsg = $commitMsg
    commitDate = $commitDate
    atualizadoEm = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    atualizadoPor = $env:USERNAME
    fonte = $fonte
    arquivos = $arquivos.Count
    tamanhoMB = $tamanhoMB
    dadosLocais = $destinoDir
} | ConvertTo-Json -Depth 2
Set-Content -Path $metaFile -Value $meta -Encoding UTF8

# Changelog LEVE no projeto OneDrive
New-Item -ItemType Directory -Path $changelogDir -Force | Out-Null
$changelogFile = Join-Path $changelogDir "$(Get-Date -Format 'yyyy-MM-dd')-$Branch.md"
$changelogContent = @"
# Atualizacao $Branch - $(Get-Date -Format 'dd/MM/yyyy HH:mm')

- **Branch:** $Branch
- **Commit:** $($commitHash.Substring(0,10))
- **Mensagem:** $commitMsg
- **Data commit:** $commitDate
- **Atualizado por:** $($env:USERNAME)
- **Fonte:** $fonte
- **Arquivos:** $($arquivos.Count)
- **Tamanho:** $tamanhoMB MB
- **Local:** $destinoDir
"@
Set-Content -Path $changelogFile -Value $changelogContent -Encoding UTF8

# Limpar clone temporario
if ($tempDir -and (Test-Path $tempDir)) {
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
}

# Mapa PBL -> area (JSON + lista MD) e indice de arquivos
$geradorMapaPbl = Join-Path $scriptDir "gerar-mapa-pbl-escrita.ps1"
$geradorIndice = Join-Path $scriptDir "gerar-indice-codigo.ps1"
if (Test-Path $geradorMapaPbl) {
    Write-Host ""
    Write-Host "[Extra] Gerando mapa PBL (pbl-area-escrita.json)..." -ForegroundColor Yellow
    & $geradorMapaPbl -CodigoDir $destinoDir
}
if (Test-Path $geradorIndice) {
    Write-Host ""
    Write-Host "[Extra] Gerando indice de arquivos..." -ForegroundColor Yellow
    & $geradorIndice -CodigoDir $destinoDir
}

Release-Lock $projetoDir

Write-Host ""
Write-Host "=== Concluido! ===" -ForegroundColor Green
Write-Host "Codigo da versao $Branch em: $destinoDir (LOCAL, fora do OneDrive)"
