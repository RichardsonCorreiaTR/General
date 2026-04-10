<#
.SYNOPSIS
    Gerencia o fluxo de revisao de definicoes SDD.
.DESCRIPTION
    Move definicoes entre as pastas de revisao (pendente, aprovado, devolvido)
    e registra no log.
.PARAMETER Acao
    Acao a executar: submeter, aprovar, devolver, listar
.PARAMETER Arquivo
    Nome do arquivo da definicao (ex: RN-FER-001-calculo-medias.md)
.PARAMETER Motivo
    Motivo da devolucao (obrigatorio para acao 'devolver')
.EXAMPLE
    .\revisar-definicao.ps1 -Acao listar
    .\revisar-definicao.ps1 -Acao aprovar -Arquivo RN-FER-001-calculo-medias.md
    .\revisar-definicao.ps1 -Acao devolver -Arquivo RN-FER-001.md -Motivo "Falta base legal"
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("submeter","aprovar","devolver","listar")]
    [string]$Acao,

    [string]$Arquivo,
    [string]$Motivo
)

$projetoRaiz = Split-Path -Parent $PSScriptRoot
$revisao = Join-Path $projetoRaiz "revisao"
$pendente = Join-Path $revisao "pendente"
$aprovado = Join-Path $revisao "aprovado"
$devolvido = Join-Path $revisao "devolvido"
$logDir = Join-Path $projetoRaiz "logs"
$logFile = Join-Path $logDir "revisao.log"

if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

function Write-Log {
    param([string]$Mensagem)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $linha = "$timestamp | $Mensagem"
    Add-Content -Path $logFile -Value $linha -Encoding UTF8
    Write-Host $linha
}

switch ($Acao) {
    "listar" {
        Write-Host "`n=== PENDENTES ===" -ForegroundColor Yellow
        $pend = Get-ChildItem $pendente -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.md" }
        if ($pend) { $pend | ForEach-Object { Write-Host "  $_" } } else { Write-Host "  (nenhum)" }

        Write-Host "`n=== APROVADOS (recentes) ===" -ForegroundColor Green
        $apr = Get-ChildItem $aprovado -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.md" } | Sort-Object LastWriteTime -Descending | Select-Object -First 10
        if ($apr) { $apr | ForEach-Object { Write-Host "  $($_.Name) ($($_.LastWriteTime.ToString('dd/MM/yyyy')))" } } else { Write-Host "  (nenhum)" }

        Write-Host "`n=== DEVOLVIDOS ===" -ForegroundColor Red
        $dev = Get-ChildItem $devolvido -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "README.md" }
        if ($dev) { $dev | ForEach-Object { Write-Host "  $_" } } else { Write-Host "  (nenhum)" }
    }

    "submeter" {
        if (-not $Arquivo) { Write-Host "ERRO: Informe -Arquivo" -ForegroundColor Red; exit 1 }
        $origem = Get-ChildItem $projetoRaiz -Recurse -File -Filter $Arquivo -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch "\\revisao\\" } | Select-Object -First 1
        if (-not $origem) { Write-Host "ERRO: Arquivo '$Arquivo' nao encontrado" -ForegroundColor Red; exit 1 }
        Copy-Item $origem.FullName (Join-Path $pendente $origem.Name) -Force
        Write-Log "SUBMETIDO | $($origem.Name) | Origem: $($origem.FullName)"
        Write-Host "Definicao submetida para revisao." -ForegroundColor Green
    }

    "aprovar" {
        if (-not $Arquivo) { Write-Host "ERRO: Informe -Arquivo" -ForegroundColor Red; exit 1 }
        $origem = Join-Path $pendente $Arquivo
        if (-not (Test-Path $origem)) { Write-Host "ERRO: '$Arquivo' nao esta em pendente/" -ForegroundColor Red; exit 1 }

        $destModulo = $null
        $conteudo = Get-Content $origem -Raw -Encoding UTF8
        if ($conteudo -match '\*\*Modulo\*\*\s*\|\s*(.+)') {
            $modulo = $Matches[1].Trim().ToLower() -replace '[^a-z0-9]','-' -replace '-+','-' -replace '^-|-$',''

            # Mapeia slugs legados (Folha / template) -> dominios Escrita em regras-negocio/
            $aliasModulo = @{
                "13o-salario"            = "escrituracao-movimento-fiscal"
                "decimo-terceiro"        = "escrituracao-movimento-fiscal"
                "13-salario"             = "escrituracao-movimento-fiscal"
                "integracao"             = "integracoes-canais-digitais"
                "integracao-contabil"    = "integracoes-canais-digitais"
                "esocial"                = "sped-documentos-eletronicos"
                "calculo-mensal"         = "apuracao-impostos"
                "calculo"                = "apuracao-impostos"
                "ferias"                 = "escrituracao-movimento-fiscal"
                "rescisao"               = "escrituracao-movimento-fiscal"
                "admissao"               = "escrituracao-movimento-fiscal"
                "beneficios"             = "escrituracao-movimento-fiscal"
                "provisoes"              = "parcelamento-planejamento"
                "inss"                   = "apuracao-impostos"
                "fgts"                   = "apuracao-impostos"
                "irrf"                   = "apuracao-impostos"
            }
            if ($aliasModulo.ContainsKey($modulo)) { $modulo = $aliasModulo[$modulo] }

            $pastaModulo = Join-Path $projetoRaiz "banco-dados\regras-negocio\$modulo"
            if (Test-Path $pastaModulo) { $destModulo = $pastaModulo }
        }

        Move-Item $origem (Join-Path $aprovado $Arquivo) -Force
        Write-Log "APROVADO | $Arquivo"

        if ($destModulo) {
            Copy-Item (Join-Path $aprovado $Arquivo) (Join-Path $destModulo $Arquivo) -Force
            Write-Log "COPIADO para banco-dados | $Arquivo -> $destModulo"
            Write-Host "Aprovado e copiado para $destModulo" -ForegroundColor Green
        } else {
            Write-Host "Aprovado. (modulo nao identificado, copie manualmente para banco-dados)" -ForegroundColor Yellow
        }
    }

    "devolver" {
        if (-not $Arquivo) { Write-Host "ERRO: Informe -Arquivo" -ForegroundColor Red; exit 1 }
        if (-not $Motivo) { Write-Host "ERRO: Informe -Motivo para devolucao" -ForegroundColor Red; exit 1 }
        $origem = Join-Path $pendente $Arquivo
        if (-not (Test-Path $origem)) { Write-Host "ERRO: '$Arquivo' nao esta em pendente/" -ForegroundColor Red; exit 1 }
        Move-Item $origem (Join-Path $devolvido $Arquivo) -Force
        Write-Log "DEVOLVIDO | $Arquivo | Motivo: $Motivo"
        Write-Host "Devolvido com motivo: $Motivo" -ForegroundColor Yellow
    }
}
