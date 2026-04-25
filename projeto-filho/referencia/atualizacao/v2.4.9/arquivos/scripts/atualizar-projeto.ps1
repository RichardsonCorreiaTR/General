# atualizar-projeto.ps1 (Projeto Filho)
# Atualiza o projeto-filho com a versao mais recente.
# Canal principal: OneDrive (distribuicao/ultima-versao/)
# Fallback: ZIP local

param(
    [string]$Zip = ""
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir

$versionFile = Join-Path $projetoDir "config\VERSION.json"
$caminhosFile = Join-Path $projetoDir "config\caminhos.json"
$analistaFile = Join-Path $projetoDir "config\analista.json"

if (-not (Test-Path $versionFile)) {
    Write-Host "ERRO: VERSION.json nao encontrado." -ForegroundColor Red; exit 1
}
$versaoAtual = (Get-Content $versionFile -Raw | ConvertFrom-Json).versao

Write-Host "=== Atualizador do Projeto Filho ===" -ForegroundColor Cyan
Write-Host "Versao atual: v$versaoAtual"
Write-Host ""

$fonteDir = $null
$manifesto = $null

if ($Zip) {
    # Modo ZIP
    if (-not (Test-Path $Zip)) {
        Write-Host "ERRO: ZIP nao encontrado: $Zip" -ForegroundColor Red; exit 1
    }
    Write-Host "[ZIP] Extraindo $Zip..." -ForegroundColor Yellow
    $tempExtract = Join-Path $env:TEMP "projeto-filho-update-$(Get-Random)"
    Expand-Archive -Path $Zip -DestinationPath $tempExtract -Force
    $fonteDir = $tempExtract
} else {
    # Modo OneDrive
    if (-not (Test-Path $caminhosFile)) {
        Write-Host "ERRO: caminhos.json nao encontrado." -ForegroundColor Red; exit 1
    }
    $caminhos = Get-Content $caminhosFile -Raw | ConvertFrom-Json
    $ultimaVersaoDir = Join-Path $caminhos.onedrive_base "distribuicao\ultima-versao"
    if (-not (Test-Path $ultimaVersaoDir)) {
        Write-Host "Nenhuma atualizacao disponivel no OneDrive." -ForegroundColor Yellow
        Write-Host "Caminho esperado: $ultimaVersaoDir" -ForegroundColor Gray
        Write-Host "Use -Zip para atualizar via arquivo ZIP." -ForegroundColor Gray
        exit 0
    }
    $fonteDir = $ultimaVersaoDir
}

# Ler manifesto da atualizacao
$manifestoFile = Join-Path $fonteDir "MANIFESTO-UPDATE.json"
if (Test-Path $manifestoFile) {
    $manifesto = Get-Content $manifestoFile -Raw | ConvertFrom-Json
    Write-Host "Versao disponivel: v$($manifesto.versao)" -ForegroundColor Cyan
    if ($manifesto.versao -eq $versaoAtual) {
        Write-Host "Voce ja esta na versao mais recente." -ForegroundColor Green
        if ($fonteDir -like "*$($env:TEMP)*") { Remove-Item -Recurse -Force $fonteDir -ErrorAction SilentlyContinue }
        exit 0
    }
    Write-Host "Changelog: $($manifesto.changelog)" -ForegroundColor White
} else {
    $novaVersionFile = Join-Path $fonteDir "config\VERSION.json"
    if (Test-Path $novaVersionFile) {
        $novaVersao = (Get-Content $novaVersionFile -Raw | ConvertFrom-Json).versao
        Write-Host "Versao disponivel: v$novaVersao" -ForegroundColor Cyan
        if ($novaVersao -eq $versaoAtual) {
            Write-Host "Voce ja esta na versao mais recente." -ForegroundColor Green
            if ($fonteDir -like "*$($env:TEMP)*") { Remove-Item -Recurse -Force $fonteDir -ErrorAction SilentlyContinue }
            exit 0
        }
    }
}

$resp = Read-Host "Deseja atualizar? (S/N)"
if ($resp -ne "S" -and $resp -ne "s") {
    Write-Host "Atualizacao cancelada." -ForegroundColor Yellow; exit 0
}

# Backup dos dados do analista
Write-Host "[1/3] Fazendo backup dos seus dados..." -ForegroundColor Yellow
$backupDir = Join-Path $env:TEMP "projeto-filho-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
foreach ($item in @("config\analista.json", "config\caminhos.json", "config\status-ambiente.json")) {
    $src = Join-Path $projetoDir $item
    if (Test-Path $src) {
        $dst = Join-Path $backupDir $item
        New-Item -ItemType Directory -Path (Split-Path $dst) -Force | Out-Null
        Copy-Item -Path $src -Destination $dst -Force
    }
}
$meuTrabalhoSrc = Join-Path $projetoDir "meu-trabalho"
if (Test-Path $meuTrabalhoSrc) {
    Copy-Item -Path $meuTrabalhoSrc -Destination (Join-Path $backupDir "meu-trabalho") -Recurse -Force
}
Write-Host "  Backup salvo em: $backupDir" -ForegroundColor Green

# Atualizar arquivos (preservando dados do analista)
Write-Host "[2/3] Atualizando arquivos..." -ForegroundColor Yellow
$pastasAtualizar = @(".cursor", "templates", "scripts")
foreach ($pasta in $pastasAtualizar) {
    $src = Join-Path $fonteDir $pasta
    $dst = Join-Path $projetoDir $pasta
    if (Test-Path $src) {
        if (Test-Path $dst) { Remove-Item -Recurse -Force $dst -ErrorAction SilentlyContinue }
        Copy-Item -Path $src -Destination $dst -Recurse -Force
        Write-Host "  Atualizado: $pasta" -ForegroundColor Green
    }
}
foreach ($arq in @("PROJETO.md", "SETUP.md", "PILOTO.md", "GUIA-RAPIDO.md", ".cursorignore")) {
    $src = Join-Path $fonteDir $arq
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination (Join-Path $projetoDir $arq) -Force
        Write-Host "  Atualizado: $arq" -ForegroundColor Green
    }
}
# Atualizar VERSION.json
$srcVersion = Join-Path $fonteDir "config\VERSION.json"
if (Test-Path $srcVersion) {
    Copy-Item -Path $srcVersion -Destination $versionFile -Force
}

# Restaurar dados do analista
Write-Host "[3/3] Restaurando seus dados..." -ForegroundColor Yellow
foreach ($item in @("config\analista.json", "config\caminhos.json", "config\status-ambiente.json")) {
    $src = Join-Path $backupDir $item
    $dst = Join-Path $projetoDir $item
    if (Test-Path $src) { Copy-Item -Path $src -Destination $dst -Force }
}
# Atualizar versao_instalada no analista.json
if (Test-Path $analistaFile) {
    $analista = Get-Content $analistaFile -Raw | ConvertFrom-Json
    $novaVer = (Get-Content $versionFile -Raw | ConvertFrom-Json).versao
    $analista.versao_instalada = $novaVer
    $analista | ConvertTo-Json -Depth 2 | Set-Content -Path $analistaFile -Encoding UTF8
}

# Limpeza
if ($fonteDir -like "*$($env:TEMP)*") { Remove-Item -Recurse -Force $fonteDir -ErrorAction SilentlyContinue }

$novaVersaoFinal = (Get-Content $versionFile -Raw | ConvertFrom-Json).versao
Write-Host ""
Write-Host "=== Atualizado para v$novaVersaoFinal! ===" -ForegroundColor Green
Write-Host "Backup mantido em: $backupDir"
Write-Host "Reabra o Cursor para carregar as novas regras."
