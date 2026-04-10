<#
.SYNOPSIS
    Cria backup completo das regras, configuracoes e templates do projeto filho
    antes de aplicar uma atualizacao.

.DESCRIPTION
    Faz backup de:
    - Todos os arquivos .mdc em .cursor/rules/
    - Pasta config/ completa
    - Pasta templates/ completa
    Salva em meu-trabalho/backup-pre-atualizacao/[TIMESTAMP]/ e verifica integridade.

.PARAMETER ProjetoFilho
    Caminho para a raiz do projeto filho.

.EXAMPLE
    .\backup-pre-atualizacao.ps1 -ProjetoFilho "C:\Users\analista\projeto-folha"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ProjetoFilho
)

$ErrorActionPreference = "Stop"

# --- Validacao do caminho ---
if (-not (Test-Path $ProjetoFilho)) {
    Write-Host ""
    Write-Host "[ERRO] Caminho do projeto filho nao encontrado: $ProjetoFilho" -ForegroundColor Red
    Write-Host "       Verifique o caminho e tente novamente." -ForegroundColor Yellow
    exit 1
}

# --- Gerar timestamp e pasta de destino ---
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$backupBase = Join-Path $ProjetoFilho "meu-trabalho/backup-pre-atualizacao/$timestamp"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Backup Pre-Atualizacao"                 -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Projeto: $ProjetoFilho"
Write-Host "  Destino: $backupBase"
Write-Host "  Data/hora: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- Criar estrutura de destino ---
try {
    New-Item -Path "$backupBase/rules" -ItemType Directory -Force | Out-Null
    New-Item -Path "$backupBase/config" -ItemType Directory -Force | Out-Null
    New-Item -Path "$backupBase/templates" -ItemType Directory -Force | Out-Null
    Write-Host "[OK] Estrutura de backup criada." -ForegroundColor Green
} catch {
    Write-Host "[ERRO] Nao foi possivel criar a pasta de backup: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$totalOrigem = 0
$totalCopiados = 0

# --- Backup das regras .mdc ---
Write-Host ""
Write-Host "Copiando regras .mdc..." -ForegroundColor White
$rulesPath = Join-Path $ProjetoFilho ".cursor/rules"

if (Test-Path $rulesPath) {
    $mdcFiles = Get-ChildItem -Path $rulesPath -Filter "*.mdc" -ErrorAction SilentlyContinue
    $totalOrigem += $mdcFiles.Count

    foreach ($file in $mdcFiles) {
        try {
            Copy-Item -Path $file.FullName -Destination "$backupBase/rules/$($file.Name)" -Force
            $totalCopiados++
            Write-Host "  Copiado: $($file.Name)" -ForegroundColor Gray
        } catch {
            Write-Host "  [ERRO] Falha ao copiar $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Copiar subpastas (como obsoleto/) se existirem
    $subfolders = Get-ChildItem -Path $rulesPath -Directory -ErrorAction SilentlyContinue
    foreach ($folder in $subfolders) {
        $subFiles = Get-ChildItem -Path $folder.FullName -Filter "*.mdc" -ErrorAction SilentlyContinue
        $totalOrigem += $subFiles.Count
        if ($subFiles.Count -gt 0) {
            $destSubfolder = Join-Path "$backupBase/rules" $folder.Name
            New-Item -Path $destSubfolder -ItemType Directory -Force | Out-Null
            foreach ($file in $subFiles) {
                try {
                    Copy-Item -Path $file.FullName -Destination "$destSubfolder/$($file.Name)" -Force
                    $totalCopiados++
                    Write-Host "  Copiado: $($folder.Name)/$($file.Name)" -ForegroundColor Gray
                } catch {
                    Write-Host "  [ERRO] Falha ao copiar $($folder.Name)/$($file.Name): $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }

    Write-Host "  Regras .mdc: $($mdcFiles.Count + ($subfolders | ForEach-Object { (Get-ChildItem $_.FullName -Filter '*.mdc' -ErrorAction SilentlyContinue).Count } | Measure-Object -Sum).Sum) arquivo(s) encontrado(s)." -ForegroundColor White
} else {
    Write-Host "  [AVISO] Pasta .cursor/rules/ nao encontrada." -ForegroundColor Yellow
}

# --- Backup da pasta config/ ---
Write-Host ""
Write-Host "Copiando config/..." -ForegroundColor White
$configPath = Join-Path $ProjetoFilho "config"

if (Test-Path $configPath) {
    $configFiles = Get-ChildItem -Path $configPath -File -ErrorAction SilentlyContinue
    $totalOrigem += $configFiles.Count

    foreach ($file in $configFiles) {
        try {
            Copy-Item -Path $file.FullName -Destination "$backupBase/config/$($file.Name)" -Force
            $totalCopiados++
            Write-Host "  Copiado: $($file.Name)" -ForegroundColor Gray
        } catch {
            Write-Host "  [ERRO] Falha ao copiar $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "  Config: $($configFiles.Count) arquivo(s) encontrado(s)." -ForegroundColor White
} else {
    Write-Host "  [AVISO] Pasta config/ nao encontrada." -ForegroundColor Yellow
}

# --- Backup da pasta templates/ ---
Write-Host ""
Write-Host "Copiando templates/..." -ForegroundColor White
$templatesPath = Join-Path $ProjetoFilho "templates"

if (Test-Path $templatesPath) {
    $templateFiles = Get-ChildItem -Path $templatesPath -File -ErrorAction SilentlyContinue
    $totalOrigem += $templateFiles.Count

    foreach ($file in $templateFiles) {
        try {
            Copy-Item -Path $file.FullName -Destination "$backupBase/templates/$($file.Name)" -Force
            $totalCopiados++
            Write-Host "  Copiado: $($file.Name)" -ForegroundColor Gray
        } catch {
            Write-Host "  [ERRO] Falha ao copiar $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "  Templates: $($templateFiles.Count) arquivo(s) encontrado(s)." -ForegroundColor White
} else {
    Write-Host "  [AVISO] Pasta templates/ nao encontrada." -ForegroundColor Yellow
}

# --- Verificacao de integridade ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verificacao de Integridade"             -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$backupCount = (Get-ChildItem -Path $backupBase -Recurse -File -ErrorAction SilentlyContinue).Count

Write-Host "  Arquivos na origem: $totalOrigem"
Write-Host "  Arquivos copiados:  $totalCopiados"
Write-Host "  Arquivos no backup: $backupCount"

if ($totalCopiados -eq $totalOrigem -and $backupCount -eq $totalOrigem) {
    Write-Host ""
    Write-Host "  [SUCESSO] Backup completo e integro!" -ForegroundColor Green
    Write-Host "  Local: $backupBase" -ForegroundColor Green
    Write-Host ""

    # Gravar manifesto
    $manifesto = @{
        data_backup     = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        projeto_origem  = $ProjetoFilho
        arquivos_total  = $totalOrigem
        arquivos_backup = $backupCount
        integridade     = "OK"
    }
    $manifesto | ConvertTo-Json -Depth 2 | Set-Content -Path (Join-Path $backupBase "manifesto.json") -Encoding UTF8
    Write-Host "  Manifesto gravado: manifesto.json" -ForegroundColor Gray
    Write-Host ""
    exit 0
} else {
    Write-Host ""
    Write-Host "  [FALHA] Backup incompleto!" -ForegroundColor Red
    Write-Host "  Faltam $($totalOrigem - $totalCopiados) arquivo(s)." -ForegroundColor Yellow
    Write-Host "  Verifique permissoes e espaco em disco." -ForegroundColor Yellow
    Write-Host ""

    # Gravar manifesto mesmo com falha
    $manifesto = @{
        data_backup     = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        projeto_origem  = $ProjetoFilho
        arquivos_total  = $totalOrigem
        arquivos_backup = $backupCount
        integridade     = "FALHA"
        faltantes       = $totalOrigem - $totalCopiados
    }
    $manifesto | ConvertTo-Json -Depth 2 | Set-Content -Path (Join-Path $backupBase "manifesto.json") -Encoding UTF8
    Write-Host "  Manifesto de falha gravado: manifesto.json" -ForegroundColor Gray
    Write-Host ""
    exit 1
}
