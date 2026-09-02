<#
.SYNOPSIS
    Analisa legislacao (lei, decreto, portaria, IN, resolucao) via Claude AI.

.DESCRIPTION
    Envia o conteudo de uma URL ou arquivo local para o Claude AI e retorna
    um resumo estruturado ou responde perguntas especificas sobre a legislacao.

    Requer ANTHROPIC_API_KEY configurada em scripts\sgd_consulta\.env ou no ambiente.

.PARAMETER Url
    URL da legislacao a analisar (pagina web ou PDF online).

.PARAMETER Arquivo
    Caminho para arquivo local (PDF, TXT, DOCX, MD).

.PARAMETER Pergunta
    Pergunta especifica sobre a legislacao. Sem pergunta, gera resumo completo.

.PARAMETER Modelo
    Modelo Claude a usar. Padrao: claude-sonnet-4-6.

.PARAMETER Json
    Imprime a saida completa em formato JSON.

.EXAMPLE
    .\scripts\Consultar-Legislacao.ps1 -Url "https://www.planalto.gov.br/ccivil_03/..."
    .\scripts\Consultar-Legislacao.ps1 -Arquivo "C:\Downloads\instrucao-normativa.pdf"
    .\scripts\Consultar-Legislacao.ps1 -Url "https://..." -Pergunta "Qual o prazo para entrega?"
    .\scripts\Consultar-Legislacao.ps1 -Url "https://..." -Json
#>
[CmdletBinding()]
param(
    [string]$Url,
    [string]$Arquivo,
    [string]$Pergunta,
    [string]$Modelo = "claude-sonnet-4-6",
    [switch]$Json
)

$ErrorActionPreference = "Stop"

# Determinar raiz do projeto (pasta pai de scripts/)
$Root = Split-Path $PSScriptRoot -Parent
$PythonScript = Join-Path $Root "scripts\sgd_consulta\consultar_legislacao.py"
$SaidaDir = Join-Path $Root "data\legislacao"
$EnvFile = Join-Path $Root "scripts\sgd_consulta\.env"

if (-not $Url -and -not $Arquivo) {
    Write-Host ""
    Write-Host "Uso:" -ForegroundColor Yellow
    Write-Host "  .\scripts\Consultar-Legislacao.ps1 -Url 'https://...'"
    Write-Host "  .\scripts\Consultar-Legislacao.ps1 -Arquivo 'C:\caminho\lei.pdf'"
    Write-Host "  .\scripts\Consultar-Legislacao.ps1 -Url 'https://...' -Pergunta 'Qual o prazo?'"
    Write-Host "  .\scripts\Consultar-Legislacao.ps1 -Url 'https://...' -Json"
    Write-Host ""
    exit 1
}

# Carregar .env para o processo atual
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match "^\s*([^#=\s][^=]*?)\s*=\s*(.*?)\s*$") {
            $varName  = $Matches[1]
            $varValue = $Matches[2]
            if (-not [System.Environment]::GetEnvironmentVariable($varName, "Process")) {
                [System.Environment]::SetEnvironmentVariable($varName, $varValue, "Process")
            }
        }
    }
}

# Verificar API key
if (-not $env:ANTHROPIC_API_KEY) {
    Write-Warning "ANTHROPIC_API_KEY nao encontrada."
    Write-Host ""
    Write-Host "Configure adicionando ao arquivo:" -ForegroundColor Yellow
    Write-Host "  $EnvFile" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Conteudo a adicionar:" -ForegroundColor Yellow
    Write-Host "  ANTHROPIC_API_KEY=sk-ant-..." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Ou exporte no terminal antes de rodar o script:" -ForegroundColor Yellow
    Write-Host "  `$env:ANTHROPIC_API_KEY = 'sk-ant-...'" -ForegroundColor Cyan
    exit 1
}

# Verificar que o script Python existe
if (-not (Test-Path $PythonScript)) {
    Write-Error "Script nao encontrado: $PythonScript"
    exit 1
}

# Montar argumentos para o Python
$PyArgs = @($PythonScript)

if ($Url)      { $PyArgs += "--url";      $PyArgs += $Url }
if ($Arquivo)  { $PyArgs += "--arquivo";  $PyArgs += $Arquivo }
if ($Pergunta) { $PyArgs += "--pergunta"; $PyArgs += $Pergunta }
if ($Modelo)   { $PyArgs += "--modelo";   $PyArgs += $Modelo }
if ($Json)     { $PyArgs += "--json" }

$PyArgs += "--saida"
$PyArgs += $SaidaDir

# Criar pasta de saida se nao existir
if (-not (Test-Path $SaidaDir)) {
    New-Item -ItemType Directory -Path $SaidaDir -Force | Out-Null
}

# Executar a partir da raiz do projeto
Push-Location $Root
try {
    python @PyArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Consulta falhou com codigo $LASTEXITCODE"
        exit $LASTEXITCODE
    }
}
finally {
    Pop-Location
}
