# buscar-sai.ps1 (wrapper para projeto filho)
# Redireciona para o script original via: caminhos.json > referencia/ > erro.
# IMPORTANTE: Rodar em terminal SEPARADO (fora do Cursor)
#
# Exemplos:
#   .\scripts\buscar-sai.ps1 -Termo INSS
#   .\scripts\buscar-sai.ps1 -Termo ferias -Tipo NE -Pendentes
#   .\scripts\buscar-sai.ps1 -SAI 12345
#   .\scripts\buscar-sai.ps1 -Termo rescisao -VerPSAIs

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir
$scriptOriginal = "

# Tentativa 1: via config/caminhos.json (onedrive_base)
$caminhosFile = Join-Path $projetoDir config\caminhos.json
if (Test-Path $caminhosFile) {
 $caminhos = Get-Content $caminhosFile -Raw | ConvertFrom-Json
 $onedriveBase = $caminhos.onedrive_base
 if ($onedriveBase) {
 $candidato = Join-Path $onedriveBase scripts\buscar-sai.ps1
 if (Test-Path $candidato) { $scriptOriginal = $candidato }
 }
}

# Tentativa 2: via referencia/scripts/ (symlink para shared folder)
if (-not $scriptOriginal) {
 $candidato = Join-Path $projetoDir referencia\scripts\buscar-sai.ps1
 if (Test-Path $candidato) {
 $scriptOriginal = $candidato
 $dadosRef = Join-Path $projetoDir referencia\banco-dados\dados-brutos
 if (Test-Path $dadosRef) {
 $env:BUSCAR_SAI_DADOS_DIR = $dadosRef
 }
 }
}

# Executar ou reportar erro
if ($scriptOriginal) {
 Write-Host Usando: $scriptOriginal -ForegroundColor DarkGray
 & $scriptOriginal @args
} else {
 Write-Host === Busca de SAIs === -ForegroundColor Cyan
 Write-Host 
 Write-Host ERRO: Script original nao encontrado. -ForegroundColor Red
 Write-Host 
 Write-Host Tentativas: -ForegroundColor Yellow
 Write-Host   1. config/caminhos.json (onedrive_base) -- nao encontrado -ForegroundColor Gray
 Write-Host   2. referencia/scripts/buscar-sai.ps1     -- nao encontrado -ForegroundColor Gray
 Write-Host 
 Write-Host Solucao: Verifique config/caminhos.json ou os symlinks em referencia/ -ForegroundColor Yellow
}
