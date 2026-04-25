# relatorio-versoes-analistas.ps1
# Consolida o status de ambiente de todos os analistas do time e gera um
# relatorio em Markdown comparando a versao instalada de cada um com a
# versao atual do pacote em distribuicao/ultima-versao.
#
# Fontes lidas:
#   - config/time-analistas.json                              (cadastro central)
#   - logs/analistas/{pasta_log}/status-ambiente.json         (publicado por
#                                                              verificar-ambiente.ps1)
#   - distribuicao/ultima-versao/config/VERSION.json          (versao alvo)
#
# Saida:
#   - logs/relatorios/versoes-analistas.md
#   - logs/relatorios/versoes-analistas.json (dados estruturados)
#
# Uso:
#   .\scripts\relatorio-versoes-analistas.ps1
#   .\scripts\relatorio-versoes-analistas.ps1 -Abrir
#   .\scripts\relatorio-versoes-analistas.ps1 -DiasAlerta 14

param(
    [int]$DiasAlerta = 7,
    [switch]$Abrir
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir

$timeFile = Join-Path $projetoDir "config\time-analistas.json"
$logsDir = Join-Path $projetoDir "logs\analistas"
$relatoriosDir = Join-Path $projetoDir "logs\relatorios"
$versionFile = Join-Path $projetoDir "distribuicao\ultima-versao\config\VERSION.json"

if (-not (Test-Path $timeFile)) {
    Write-Host "ERRO: Cadastro central nao encontrado: $timeFile" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $versionFile)) {
    Write-Host "AVISO: VERSION.json de distribuicao/ultima-versao nao encontrado em $versionFile" -ForegroundColor Yellow
    $versaoAtual = "?"
} else {
    $versaoAtual = (Get-Content $versionFile -Raw -Encoding UTF8 | ConvertFrom-Json).versao
}

New-Item -ItemType Directory -Path $relatoriosDir -Force | Out-Null

Write-Host ""
Write-Host "=== Relatorio de versoes dos analistas ===" -ForegroundColor Cyan
Write-Host "Versao alvo (distribuicao/ultima-versao): v$versaoAtual"
Write-Host "Cadastro: $timeFile"
Write-Host "Logs:     $logsDir"
Write-Host ""

$time = Get-Content $timeFile -Raw -Encoding UTF8 | ConvertFrom-Json
$linhas = [System.Collections.ArrayList]::new()
$dataLimite = (Get-Date).AddDays(-$DiasAlerta)

foreach ($a in $time) {
    $statusFile = Join-Path $logsDir "$($a.pasta_log)\status-ambiente.json"
    $registro = [ordered]@{
        nome             = $a.nome
        email            = $a.email
        codigo_id        = $a.codigo_id
        pasta_log        = $a.pasta_log
        areas            = $a.areas
        versao_instalada = $null
        resultado        = $null
        verificadoEm     = $null
        defasagem_dias   = $null
        atualizado       = $null
        host             = $null
        usuario_windows  = $null
        obrigatoriosOK   = $null
        obrigatoriosTotal = $null
        opcionaisOK      = $null
        opcionaisTotal   = $null
        status           = "NAO_VERIFICADO"
        observacao       = $null
    }
    if (Test-Path $statusFile) {
        try {
            $st = Get-Content $statusFile -Raw -Encoding UTF8 | ConvertFrom-Json
            $registro.versao_instalada = $st.versao
            $registro.resultado        = $st.resultado
            $registro.verificadoEm     = $st.verificadoEm
            $registro.host             = $st.host
            $registro.usuario_windows  = $st.usuario_windows
            $registro.obrigatoriosOK   = $st.obrigatoriosOK
            $registro.obrigatoriosTotal= $st.obrigatoriosTotal
            $registro.opcionaisOK      = $st.opcionaisOK
            $registro.opcionaisTotal   = $st.opcionaisTotal
            try {
                $dt = [datetime]$st.verificadoEm
                $registro.defasagem_dias = [math]::Round(((Get-Date) - $dt).TotalDays, 1)
            } catch {
                $registro.defasagem_dias = $null
            }
            $registro.atualizado = ($st.versao -eq $versaoAtual)
            if ($registro.atualizado -and $registro.resultado -eq "OK" -and $dt -ge $dataLimite) {
                $registro.status = "OK"
            } elseif (-not $registro.atualizado) {
                $registro.status = "DESATUALIZADO"
                $registro.observacao = "Rodar atualizar-projeto.ps1 (atual: v$($st.versao), alvo: v$versaoAtual)"
            } elseif ($dt -lt $dataLimite) {
                $registro.status = "VERIFICACAO_VENCIDA"
                $registro.observacao = "Ultima verificacao ha $([int]$registro.defasagem_dias) dias - rodar verificar-ambiente.ps1"
            } else {
                $registro.status = "ATENCAO"
                $registro.observacao = "Resultado: $($st.resultado) ($($st.obrigatoriosOK)/$($st.obrigatoriosTotal) obrigatorios)"
            }
        } catch {
            $registro.status = "ERRO_LEITURA"
            $registro.observacao = "Falha ao ler status: $($_.Exception.Message)"
        }
    } else {
        $registro.observacao = "Sem status-ambiente.json no OneDrive (analista nunca rodou verificar-ambiente.ps1 apos a v$($versaoAtual))"
    }
    [void]$linhas.Add([PSCustomObject]$registro)
}

# --- Estatisticas agregadas ---
# @(...) forca array para que .Count funcione mesmo com 0 ou 1 elemento.
$total = $linhas.Count
$nao = @($linhas | Where-Object { $_.status -eq "NAO_VERIFICADO" }).Count
$ok = @($linhas | Where-Object { $_.status -eq "OK" }).Count
$desatualizados = @($linhas | Where-Object { $_.status -eq "DESATUALIZADO" }).Count
$vencidos = @($linhas | Where-Object { $_.status -eq "VERIFICACAO_VENCIDA" }).Count
$atencao = @($linhas | Where-Object { $_.status -eq "ATENCAO" }).Count
$erros = @($linhas | Where-Object { $_.status -eq "ERRO_LEITURA" }).Count

Write-Host "Total analistas      : $total"
Write-Host "  OK                 : $ok" -ForegroundColor Green
Write-Host "  Desatualizados     : $desatualizados" -ForegroundColor Yellow
Write-Host "  Verificacao vencida: $vencidos" -ForegroundColor DarkYellow
Write-Host "  Atencao            : $atencao" -ForegroundColor Yellow
Write-Host "  Nunca verificaram  : $nao" -ForegroundColor Red
if ($erros -gt 0) { Write-Host "  Erro de leitura    : $erros" -ForegroundColor Red }
Write-Host ""

# --- Distribuicao de versoes ---
$porVersao = $linhas | Where-Object { $_.versao_instalada } | Group-Object versao_instalada | Sort-Object Name
Write-Host "Distribuicao por versao instalada:"
foreach ($g in $porVersao) {
    $marca = if ($g.Name -eq $versaoAtual) { "<- alvo" } else { "" }
    Write-Host ("  v{0,-12} : {1,3}  {2}" -f $g.Name, $g.Count, $marca)
}
Write-Host ""

# --- Markdown ---
$dataAtualizacao = Get-Date -Format "dd/MM/yyyy HH:mm"
$md = [System.Collections.Generic.List[string]]::new()
$md.Add("# Relatorio de versoes dos analistas")
$md.Add("")
$md.Add("> Atualizado em: $dataAtualizacao")
$md.Add("> Versao alvo (distribuicao/ultima-versao): v$versaoAtual")
$md.Add("> Janela de verificacao recente: $DiasAlerta dias")
$md.Add("")
$md.Add("## Resumo")
$md.Add("")
$md.Add("| Status | Total |")
$md.Add("|---|---|")
$md.Add("| OK | $ok |")
$md.Add("| Desatualizados | $desatualizados |")
$md.Add("| Verificacao vencida (>$DiasAlerta dias) | $vencidos |")
$md.Add("| Atencao | $atencao |")
$md.Add("| Nunca verificaram | $nao |")
if ($erros -gt 0) { $md.Add("| Erro de leitura | $erros |") }
$md.Add("| **Total** | **$total** |")
$md.Add("")

if ($porVersao.Count -gt 0) {
    $md.Add("## Distribuicao por versao instalada")
    $md.Add("")
    $md.Add("| Versao | Analistas |")
    $md.Add("|---|---|")
    foreach ($g in $porVersao) {
        $tag = if ($g.Name -eq $versaoAtual) { " **(alvo)**" } else { "" }
        $md.Add("| v$($g.Name)$tag | $($g.Count) |")
    }
    $md.Add("")
}

# Detalhe agrupado por status
$ordemStatus = @("DESATUALIZADO","NAO_VERIFICADO","VERIFICACAO_VENCIDA","ATENCAO","ERRO_LEITURA","OK")
foreach ($st in $ordemStatus) {
    $grupo = @($linhas | Where-Object { $_.status -eq $st })
    if ($grupo.Count -eq 0) { continue }
    $md.Add("## $st ($($grupo.Count))")
    $md.Add("")
    $md.Add("| Analista | Email | Versao | Resultado | Verificado em | Defasagem (d) | Host | Observacao |")
    $md.Add("|---|---|---|---|---|---|---|---|")
    foreach ($l in $grupo | Sort-Object nome) {
        $v = if ($l.versao_instalada) { "v$($l.versao_instalada)" } else { "-" }
        $r = if ($l.resultado) { $l.resultado } else { "-" }
        $vd = if ($l.verificadoEm) { ($l.verificadoEm -replace 'T',' ') } else { "-" }
        $df = if ($null -ne $l.defasagem_dias) { $l.defasagem_dias } else { "-" }
        $h = if ($l.host) { $l.host } else { "-" }
        $o = if ($l.observacao) { $l.observacao } else { "" }
        $md.Add("| $($l.nome) | $($l.email) | $v | $r | $vd | $df | $h | $o |")
    }
    $md.Add("")
}

$mdFile = Join-Path $relatoriosDir "versoes-analistas.md"
$jsonFile = Join-Path $relatoriosDir "versoes-analistas.json"
Set-Content -Path $mdFile -Value ($md -join "`n") -Encoding UTF8

$dadosJson = [ordered]@{
    geradoEm = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    versaoAlvo = $versaoAtual
    diasAlerta = $DiasAlerta
    resumo = [ordered]@{
        total = $total
        ok = $ok
        desatualizados = $desatualizados
        verificacao_vencida = $vencidos
        atencao = $atencao
        nao_verificaram = $nao
        erros = $erros
    }
    porVersao = ($porVersao | ForEach-Object { @{ versao = $_.Name; analistas = $_.Count } })
    analistas = $linhas
} | ConvertTo-Json -Depth 5
Set-Content -Path $jsonFile -Value $dadosJson -Encoding UTF8

Write-Host "Relatorios gerados:" -ForegroundColor Green
Write-Host "  $mdFile"
Write-Host "  $jsonFile"
Write-Host ""

if ($Abrir) {
    Invoke-Item $mdFile
}
