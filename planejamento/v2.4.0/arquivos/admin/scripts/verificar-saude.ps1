<#
.SYNOPSIS
    Verifica a saude do ambiente do projeto filho.

.DESCRIPTION
    Executa verificacoes essenciais no ambiente do analista:
    - .cursorignore protege dados-brutos/
    - VERSION.json existe e e valido
    - analista.json tem campo nome preenchido
    Retorna Pass/Fail para cada verificacao.

.PARAMETER Projeto
    Caminho para a raiz do projeto filho. Padrao: diretorio atual.

.EXAMPLE
    .\verificar-saude.ps1
    .\verificar-saude.ps1 -Projeto "C:\Users\analista\projeto-filho"
#>

param(
    [string]$Projeto = (Get-Location).Path
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verificacao de Saude do Ambiente"       -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Projeto: $Projeto"
Write-Host "  Data/hora: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$totalTestes = 0
$totalOk = 0
$totalFalha = 0

function Resultado {
    param([string]$Teste, [bool]$Passou, [string]$Detalhe)
    $script:totalTestes++
    if ($Passou) {
        $script:totalOk++
        Write-Host "  [PASS] $Teste" -ForegroundColor Green
    } else {
        $script:totalFalha++
        Write-Host "  [FAIL] $Teste" -ForegroundColor Red
        Write-Host "         -> $Detalhe" -ForegroundColor Yellow
    }
}

# --- Teste 1: .cursorignore existe e protege dados-brutos ---
Write-Host "Verificacao 1: Protecao .cursorignore" -ForegroundColor White
$cursorignorePath = Join-Path $Projeto ".cursorignore"

if (Test-Path $cursorignorePath) {
    $conteudo = Get-Content $cursorignorePath -Raw -ErrorAction SilentlyContinue
    if ($conteudo -match "referencia/banco-dados/dados-brutos/") {
        Resultado "Arquivo .cursorignore existe" $true ""
        Resultado "Protecao de dados-brutos/ presente" $true ""
    } else {
        Resultado "Arquivo .cursorignore existe" $true ""
        Resultado "Protecao de dados-brutos/ presente" $false `
            "CRITICO: .cursorignore NAO contem 'referencia/banco-dados/dados-brutos/'. Risco de OOM! Adicione a linha e reinicie o Cursor."
    }
} else {
    Resultado "Arquivo .cursorignore existe" $false `
        "CRITICO: Arquivo .cursorignore nao encontrado em '$Projeto'. Crie o arquivo com a linha 'referencia/banco-dados/dados-brutos/' e reinicie o Cursor."
    Resultado "Protecao de dados-brutos/ presente" $false `
        "Nao foi possivel verificar — arquivo .cursorignore ausente."
}

Write-Host ""

# --- Teste 2: VERSION.json existe e e valido ---
Write-Host "Verificacao 2: VERSION.json" -ForegroundColor White
$versionPath = Join-Path $Projeto "config/VERSION.json"

if (Test-Path $versionPath) {
    Resultado "Arquivo VERSION.json existe" $true ""
    try {
        $versionJson = Get-Content $versionPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        Resultado "VERSION.json e JSON valido" $true ""

        if ($versionJson.versao) {
            Resultado "Campo 'versao' presente: $($versionJson.versao)" $true ""
        } else {
            Resultado "Campo 'versao' presente" $false `
                "VERSION.json nao contem o campo 'versao'. Verifique a integridade do arquivo."
        }
    } catch {
        Resultado "VERSION.json e JSON valido" $false `
            "Erro ao parsear VERSION.json: $($_.Exception.Message). O arquivo pode estar corrompido."
    }
} else {
    Resultado "Arquivo VERSION.json existe" $false `
        "Arquivo nao encontrado em '$versionPath'. Execute a atualizacao do projeto ou acione o gerente."
    Resultado "VERSION.json e JSON valido" $false `
        "Nao foi possivel verificar — arquivo ausente."
}

Write-Host ""

# --- Teste 3: analista.json tem nome preenchido ---
Write-Host "Verificacao 3: Identidade do analista" -ForegroundColor White
$analistaPath = Join-Path $Projeto "config/analista.json"

if (Test-Path $analistaPath) {
    Resultado "Arquivo analista.json existe" $true ""
    try {
        $analistaJson = Get-Content $analistaPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        Resultado "analista.json e JSON valido" $true ""

        if ($analistaJson.nome -and $analistaJson.nome.Trim() -ne "") {
            Resultado "Campo 'nome' preenchido: $($analistaJson.nome)" $true ""
        } else {
            Resultado "Campo 'nome' preenchido" $false `
                "O campo 'nome' em analista.json esta vazio. Preencha com o nome do analista antes de usar o projeto."
        }
    } catch {
        Resultado "analista.json e JSON valido" $false `
            "Erro ao parsear analista.json: $($_.Exception.Message). O arquivo pode estar corrompido."
    }
} else {
    Resultado "Arquivo analista.json existe" $false `
        "Arquivo nao encontrado em '$analistaPath'. Execute a instalacao do projeto ou acione o gerente."
    Resultado "analista.json e JSON valido" $false `
        "Nao foi possivel verificar — arquivo ausente."
}

Write-Host ""

# --- Resumo ---
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Resumo" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Total de verificacoes: $totalTestes"
Write-Host "  Aprovadas: $totalOk" -ForegroundColor Green
Write-Host "  Reprovadas: $totalFalha" -ForegroundColor $(if ($totalFalha -gt 0) { "Red" } else { "Green" })
Write-Host "========================================" -ForegroundColor Cyan

if ($totalFalha -gt 0) {
    Write-Host ""
    Write-Host "  ATENCAO: $totalFalha verificacao(oes) falharam." -ForegroundColor Red
    Write-Host "  Corrija os itens acima antes de continuar." -ForegroundColor Yellow
    Write-Host ""
    exit 1
} else {
    Write-Host ""
    Write-Host "  Ambiente saudavel! Todas as verificacoes passaram." -ForegroundColor Green
    Write-Host ""
    exit 0
}
