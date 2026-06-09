# corrigir-symlinks.ps1
# Script de reparo: recria os links simbolicos para o OneDrive
# Rode dentro da pasta do projeto filho: C:\CursorEscrita\projeto-filho\

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir

Write-Host ""
Write-Host "  =============================================" -ForegroundColor Cyan
Write-Host "  |   Reparo de Symlinks - Projeto Filho       |" -ForegroundColor Cyan
Write-Host "  =============================================" -ForegroundColor Cyan
Write-Host ""

# --- Detectar OneDrive ---
Write-Host "[1/4] Detectando OneDrive..." -ForegroundColor Yellow
$possiblePaths = @(
    "$env:USERPROFILE\Thomson Reuters Incorporated\CursorEscrita - General",
    "$env:USERPROFILE\Thomson Reuters Incorporated\CursorEscrita - Documentos\General",
    "$env:OneDriveCommercial\Thomson Reuters Incorporated\CursorEscrita - General",
    "$env:OneDrive\Thomson Reuters Incorporated\CursorEscrita - General"
)
$onedrivePath = $null
$caminhosFile = Join-Path $projetoDir "config\caminhos.json"
if (Test-Path $caminhosFile) {
    try {
        $cj = Get-Content $caminhosFile -Raw | ConvertFrom-Json
        $cand = $cj.onedrive_base
        if ($cand -and (Test-Path (Join-Path $cand "banco-dados"))) {
            $onedrivePath = $cand
        }
    } catch {}
}
if (-not $onedrivePath) {
foreach ($p in $possiblePaths) {
    if ($p -and (Test-Path (Join-Path $p "banco-dados"))) { $onedrivePath = $p; break }
}
}
if (-not $onedrivePath) {
    Write-Host "  [X] OneDrive nao encontrado!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  O que fazer:" -ForegroundColor Yellow
    Write-Host "  1. Abra no navegador: https://trten.sharepoint.com/sites/CursorEscrita" -ForegroundColor White
    Write-Host "  2. Clique em Documentos > General > Sincronizar" -ForegroundColor White
    Write-Host "  3. Aguarde o OneDrive sincronizar" -ForegroundColor White
    Write-Host "  4. Rode este script novamente" -ForegroundColor White
    Write-Host ""
    Read-Host "  Pressione Enter para sair"
    exit 1
}
Write-Host "  [OK] OneDrive: $onedrivePath" -ForegroundColor Green

# --- Ler ou criar analista.json ---
Write-Host "[2/4] Verificando identidade..." -ForegroundColor Yellow
$analistaFile = Join-Path $projetoDir "config\analista.json"
$nomeKebab = ""
if (Test-Path $analistaFile) {
    $analista = Get-Content $analistaFile -Raw | ConvertFrom-Json
    if ($analista.nome) {
        $nomeKebab = ($analista.nome -replace '[aàáâãä]','a' -replace '[eèéêë]','e' -replace '[iìíîï]','i' -replace '[oòóôõö]','o' -replace '[uùúûü]','u' -replace '[cç]','c' -replace '\s+','-' -replace '[^a-zA-Z0-9-]','').ToLower()
        Write-Host "  [OK] Analista: $($analista.nome)" -ForegroundColor Green
    }
}
if (-not $nomeKebab) {
    $nome = Read-Host "  Seu nome completo"
    $nomeKebab = ($nome -replace '[aàáâãä]','a' -replace '[eèéêë]','e' -replace '[iìíîï]','i' -replace '[oòóôõö]','o' -replace '[uùúûü]','u' -replace '[cç]','c' -replace '\s+','-' -replace '[^a-zA-Z0-9-]','').ToLower()
}

# --- Atualizar caminhos.json ---
Write-Host "[3/4] Atualizando caminhos..." -ForegroundColor Yellow
$caminhosFile = Join-Path $projetoDir "config\caminhos.json"
$logsPath = Join-Path $onedrivePath "logs\analistas\$nomeKebab"
$caminhos = @{
    projeto_local = $projetoDir
    codigo_local = "C:\CursorEscrita\codigo-sistema\versao-atual"
    onedrive_base = $onedrivePath
    onedrive_logs = $logsPath
}
if (Test-Path $caminhosFile) {
    $atual = Get-Content $caminhosFile -Raw | ConvertFrom-Json
    if ($atual.codigo_local) { $caminhos.codigo_local = $atual.codigo_local }
}
$caminhos | ConvertTo-Json -Depth 2 | Set-Content -Path $caminhosFile -Encoding UTF8
Write-Host "  [OK] caminhos.json atualizado" -ForegroundColor Green

# --- Criar/recriar symlinks ---
Write-Host "[4/4] Criando links simbolicos..." -ForegroundColor Yellow
$refDir = Join-Path $projetoDir "referencia"
New-Item -ItemType Directory -Path $refDir -Force | Out-Null

$links = @(
    @{ Name = "banco-dados"; Target = (Join-Path $onedrivePath "banco-dados") },
    @{ Name = "logs"; Target = $logsPath },
    @{ Name = "atualizacao"; Target = (Join-Path $onedrivePath "atualizacao") }
)

$erros = 0
foreach ($link in $links) {
    $lp = Join-Path $refDir $link.Name
    if (Test-Path $lp) {
        Write-Host "  [OK] $($link.Name) ja existe" -ForegroundColor Green
        continue
    }
    if (-not (Test-Path $link.Target)) {
        New-Item -ItemType Directory -Path $link.Target -Force | Out-Null
    }
    $criado = $false
    # Tentativa 1: Junction (nao precisa de admin na maioria dos casos)
    try {
        cmd /c mklink /J "$lp" "$($link.Target)" 2>$null | Out-Null
        if (Test-Path $lp) { $criado = $true; Write-Host "  [OK] $($link.Name) -> junction criado" -ForegroundColor Green }
    } catch {}
    # Tentativa 2: Symlink (pode precisar de admin)
    if (-not $criado) {
        try {
            New-Item -ItemType SymbolicLink -Path $lp -Target $link.Target -ErrorAction Stop | Out-Null
            $criado = $true; Write-Host "  [OK] $($link.Name) -> symlink criado" -ForegroundColor Green
        } catch {}
    }
    if (-not $criado) {
        $erros++
        Write-Host "  [X] Falha ao criar link: $($link.Name)" -ForegroundColor Red
        Write-Host "      Abra PowerShell como ADMINISTRADOR e rode:" -ForegroundColor Yellow
        Write-Host "      cmd /c mklink /J `"$lp`" `"$($link.Target)`"" -ForegroundColor Gray
    }
}

# --- Verificacao final ---
Write-Host ""
Write-Host ("-" * 50) -ForegroundColor DarkGray
$bdOK = Test-Path (Join-Path $refDir "banco-dados\sais\indices\README.md")
$logsOK = Test-Path (Join-Path $refDir "logs")

if ($bdOK -and $logsOK) {
    Write-Host "  TUDO OK! Symlinks funcionando." -ForegroundColor Green
    Write-Host "  Indices de SAIs acessiveis: $(Join-Path $refDir 'banco-dados\sais\indices')" -ForegroundColor Green
} elseif ($bdOK) {
    Write-Host "  PARCIAL: banco-dados OK, logs com problema" -ForegroundColor Yellow
} else {
    Write-Host "  FALHA: Symlinks nao funcionaram." -ForegroundColor Red
    Write-Host ""
    Write-Host "  SOLUCAO ALTERNATIVA:" -ForegroundColor Yellow
    Write-Host "  Abra PowerShell como ADMINISTRADOR e rode:" -ForegroundColor White
    Write-Host "    cd `"$refDir`"" -ForegroundColor Cyan
    Write-Host "    cmd /c mklink /J `"banco-dados`" `"$(Join-Path $onedrivePath 'banco-dados')`"" -ForegroundColor Cyan
    Write-Host "    cmd /c mklink /J `"logs`" `"$logsPath`"" -ForegroundColor Cyan
}

Write-Host ""
Read-Host "  Pressione Enter para fechar"
