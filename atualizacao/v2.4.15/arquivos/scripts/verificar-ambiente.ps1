# verificar-ambiente.ps1 (Projeto Filho)
# Valida todos os componentes do ambiente do analista.
# Gera relatorio colorido + config/status-ambiente.json

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir

Write-Host ""
Write-Host "  =============================================" -ForegroundColor Cyan
Write-Host "  |   Verificacao de Ambiente - Escrita         |" -ForegroundColor Cyan
Write-Host "  =============================================" -ForegroundColor Cyan
Write-Host ""

$checks = @()

function Add-Check($nome, $ok, $detalhe, $nivel) {
    if (-not $nivel) { $nivel = "obrigatorio" }
    $script:checks += @{ nome = $nome; ok = $ok; detalhe = $detalhe; nivel = $nivel }
    if ($ok) { Write-Host "  [OK] $nome" -ForegroundColor Green }
    elseif ($nivel -eq "opcional") { Write-Host "  [!]  $nome - $detalhe" -ForegroundColor DarkYellow }
    else { Write-Host "  [X]  $nome - $detalhe" -ForegroundColor Red }
}

# 1. Cursor
$cursorCmd = Get-Command cursor -ErrorAction SilentlyContinue
if ($cursorCmd) {
    Add-Check "Cursor instalado" $true $cursorCmd.Source
} else {
    $cursorAlt = @(
        "$env:LOCALAPPDATA\Programs\cursor\resources\app\bin\cursor.cmd",
        "$env:LOCALAPPDATA\cursor\cursor.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    Add-Check "Cursor instalado" ([bool]$cursorAlt) "Nao encontrado em PATH"
}

# 2. Git
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
Add-Check "Git instalado" ([bool]$gitCmd) $(if ($gitCmd) { (git --version 2>$null).Trim() } else { "Instale em https://git-scm.com" })

# 3. OneDrive rodando
$odProc = Get-Process OneDrive -ErrorAction SilentlyContinue
Add-Check "OneDrive rodando" ([bool]$odProc) $(if ($odProc) { "Processo OneDrive ativo" } else { "Inicie o OneDrive" })

# 4. Config analista.json
$analistaFile = Join-Path $projetoDir "config\analista.json"
$analistaOK = $false
if (Test-Path $analistaFile) {
    $analista = Get-Content $analistaFile -Raw | ConvertFrom-Json
    $analistaOK = [bool]$analista.nome -and [bool]$analista.email
}
Add-Check "config/analista.json preenchido" $analistaOK "Preencha nome e email"

# 5. Config caminhos.json
$caminhosFile = Join-Path $projetoDir "config\caminhos.json"
$caminhosOK = $false
if (Test-Path $caminhosFile) {
    $caminhos = Get-Content $caminhosFile -Raw | ConvertFrom-Json
    $caminhosOK = [bool]$caminhos.onedrive_base
}
Add-Check "config/caminhos.json configurado" $caminhosOK $(if ($caminhosOK) { $caminhos.onedrive_base } else { "Rode o instalador" })

# 6. VERSION.json
$versionFile = Join-Path $projetoDir "config\VERSION.json"
$versionOK = Test-Path $versionFile
$versaoAtual = ""
if ($versionOK) { $versaoAtual = (Get-Content $versionFile -Raw | ConvertFrom-Json).versao }
Add-Check "config/VERSION.json (v$versaoAtual)" $versionOK $(if ($versionOK) { "Presente em config/" } else { "Arquivo ausente" })

# 7. OneDrive sincronizado
$onedriveOK = $false
$onedrivePath = ""
if ($caminhosOK) {
    $onedrivePath = $caminhos.onedrive_base
    $onedriveOK = (Test-Path $onedrivePath) -and (Test-Path (Join-Path $onedrivePath "banco-dados"))
}
Add-Check "OneDrive sincronizado" $onedriveOK $(if ($onedriveOK) { $onedrivePath } else { "Pasta nao encontrada ou sem banco-dados: $onedrivePath" })

# 8. Symlink banco-dados
$refBD = Join-Path $projetoDir "referencia\banco-dados"
$symlinkBDOK = Test-Path $refBD
Add-Check "referencia/banco-dados (symlink)" $symlinkBDOK $(if ($symlinkBDOK) { "Acessivel em $refBD" } else { "Crie o symlink para o OneDrive (scripts\corrigir-symlinks.ps1)" })

# 9. Symlink logs
$refLogs = Join-Path $projetoDir "referencia\logs"
$symlinkLogsOK = Test-Path $refLogs
Add-Check "referencia/logs (symlink)" $symlinkLogsOK $(if ($symlinkLogsOK) { "Acessivel em $refLogs" } else { "Crie o symlink para logs no OneDrive" })

# 10. Templates presentes
$templatesDir = Join-Path $projetoDir "templates"
$templatesOK = $false
$nTemplates = 0
if (Test-Path $templatesDir) {
    $nTemplates = (Get-ChildItem $templatesDir -Filter "TEMPLATE-*.md" | Measure-Object).Count
    $templatesOK = $nTemplates -ge 4
}
Add-Check "Templates presentes ($nTemplates TEMPLATE-*.md, minimo 4)" $templatesOK $(if ($templatesOK) { "Criterio atendido" } else { "Faltam templates TEMPLATE-*.md em templates/" })

# 11. Regras .cursor/rules
$rulesDir = Join-Path $projetoDir ".cursor\rules"
$rulesOK = $false
$nRules = 0
if (Test-Path $rulesDir) {
    $nRules = (Get-ChildItem $rulesDir -Filter "*.mdc" | Measure-Object).Count
    $rulesOK = $nRules -ge 3
}
Add-Check "Regras IA ($nRules .mdc)" $rulesOK $(if ($rulesOK) { ".cursor/rules com regras suficientes" } else { "Regras ausentes ou insuficientes em .cursor/rules" })

# 12. Codigo-fonte local (com fallback legado)
$codigoOK = $false
$codigoPath = ""
if ($caminhosOK) {
    $codigoPath = $caminhos.codigo_local
    if (-not (Test-Path $codigoPath)) {
        foreach ($legado in @(
            (Join-Path $env:USERPROFILE "EscritaSDD-dados-pesados\versao-atual")
        )) {
            if (Test-Path $legado) {
                $codigoPath = $legado
                Write-Host "  [i]  Codigo encontrado no caminho legado: $legado" -ForegroundColor DarkYellow
                break
            }
        }
    }
    if (Test-Path $codigoPath) {
        $nArqs = (Get-ChildItem $codigoPath -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
        $codigoOK = $nArqs -gt 100
    }
}
Add-Check "Codigo-fonte local ($codigoPath)" $codigoOK $(if ($codigoOK) { "Arquivos suficientes em codigo_local" } else { "Rode: .\scripts\atualizar-codigo.ps1" })

# 12b. Indice de arquivos
$indiceArquivosOK = $false
$indiceArquivosPath = Join-Path $projetoDir "referencia\banco-dados\mapa-sistema\indice-arquivos.md"
if (Test-Path $indiceArquivosPath) { $indiceArquivosOK = $true }
Add-Check "Indice de arquivos (mapa-sistema)" $indiceArquivosOK $(if ($indiceArquivosOK) { $indiceArquivosPath } else { "O gerente precisa rodar: scripts\gerar-indice-codigo.ps1" }) "opcional"

# 13. ODBC - Driver SQL Anywhere
$odbcDriverOK = $false
$odbcDriver = Get-OdbcDriver -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*SQL Anywhere*" } | Select-Object -First 1
if ($odbcDriver) { $odbcDriverOK = $true }
Add-Check "ODBC driver SQL Anywhere" $odbcDriverOK $(if ($odbcDriverOK) { $odbcDriver.Name } else { "Instale o driver SQL Anywhere 9.0 (peca ao time de infra)" }) "opcional"

# 14. ODBC - DSN pbcvs9
$odbcDsnOK = $false
$odbcDsn = Get-OdbcDsn -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*pbcvs*" } | Select-Object -First 1
if ($odbcDsn) { $odbcDsnOK = $true }
Add-Check "ODBC DSN pbcvs9" $odbcDsnOK $(if ($odbcDsnOK) { $odbcDsn.Name } else { "Rode: .\scripts\setup-odbc.ps1 -Verificar (ou configure manualmente)" }) "opcional"

# 15. Versao atualizada (vs pacote em distribuicao/ultima-versao, se existir)
$versaoAtualizadaOK = $true
$versaoAtualizadaDetalhe = "Pacote distribuicao/ultima-versao nao encontrado em onedrive_base (comparacao ignorada)"
if ($caminhosOK -and $onedrivePath) {
    $ultimaVDir = Join-Path $onedrivePath "distribuicao\ultima-versao\config\VERSION.json"
    if (Test-Path $ultimaVDir) {
        $ultimaVersao = (Get-Content $ultimaVDir -Raw | ConvertFrom-Json).versao
        $versaoAtualizadaOK = $versaoAtual -eq $ultimaVersao
        if ($versaoAtualizadaOK) {
            $versaoAtualizadaDetalhe = "Igual ao pacote ultima-versao (v$ultimaVersao)"
        } else {
            $versaoAtualizadaDetalhe = "Rode: .\scripts\atualizar-projeto.ps1 (disponivel v$ultimaVersao, local v$versaoAtual)"
            Write-Host "  [!] Versao disponivel: v$ultimaVersao (atual: v$versaoAtual)" -ForegroundColor DarkYellow
        }
    }
}
Add-Check "Versao atualizada" $versaoAtualizadaOK $versaoAtualizadaDetalhe

# 16. analista.json versao_instalada vs VERSION (opcional)
$versaoInstaladaOK = $true
$versaoInstaladaMsg = "Campo vazio ou igual a VERSION.json"
if (Test-Path $analistaFile) {
    $anJson = Get-Content $analistaFile -Raw | ConvertFrom-Json
    if ($anJson.versao_instalada -and $versaoAtual -and ($anJson.versao_instalada -ne $versaoAtual)) {
        $versaoInstaladaOK = $false
        $versaoInstaladaMsg = "versao_instalada=$($anJson.versao_instalada) mas VERSION.json=$versaoAtual - atualize apos atualizar-projeto.ps1"
    }
}
Add-Check "analista.json versao_instalada alinhada" $versaoInstaladaOK $versaoInstaladaMsg "opcional"

# Resumo
Write-Host ""
Write-Host ("-" * 50) -ForegroundColor DarkGray
$obrigatorios = $checks | Where-Object { $_.nivel -ne "opcional" }
$opcionais = $checks | Where-Object { $_.nivel -eq "opcional" }
$obrigOK = ($obrigatorios | Where-Object { $_.ok }).Count
$opcOK = ($opcionais | Where-Object { $_.ok }).Count
$totalOK = ($checks | Where-Object { $_.ok }).Count
$total = $checks.Count

$cor = if ($obrigOK -eq $obrigatorios.Count) { "Green" } elseif ($obrigOK -ge ($obrigatorios.Count - 2)) { "Yellow" } else { "Red" }
Write-Host "  Obrigatorios: $obrigOK/$($obrigatorios.Count) OK" -ForegroundColor $cor
Write-Host "  Opcionais:    $opcOK/$($opcionais.Count) OK" -ForegroundColor $(if ($opcOK -eq $opcionais.Count) { "Green" } else { "DarkYellow" })
Write-Host "  Total:        $totalOK/$total" -ForegroundColor $cor

if ($totalOK -lt $total) {
    $falhasObrig = $obrigatorios | Where-Object { -not $_.ok }
    $falhasOpc = $opcionais | Where-Object { -not $_.ok }
    if ($falhasObrig.Count -gt 0) {
        Write-Host ""
        Write-Host "  Itens pendentes (obrigatorios):" -ForegroundColor Red
        $falhasObrig | ForEach-Object { Write-Host "    - $($_.nome): $($_.detalhe)" -ForegroundColor Red }
    }
    if ($falhasOpc.Count -gt 0) {
        Write-Host ""
        Write-Host "  Itens pendentes (opcionais):" -ForegroundColor DarkYellow
        $falhasOpc | ForEach-Object { Write-Host "    - $($_.nome): $($_.detalhe)" -ForegroundColor DarkYellow }
    }
}

# Salvar status
$statusFile = Join-Path $projetoDir "config\status-ambiente.json"
$nomeAnalista = if (Test-Path $analistaFile) { (Get-Content $analistaFile -Raw | ConvertFrom-Json).nome } else { "" }
$emailAnalista = if (Test-Path $analistaFile) { (Get-Content $analistaFile -Raw | ConvertFrom-Json).email } else { "" }
$statusObj = [ordered]@{
    verificadoEm = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    analista = $nomeAnalista
    email = $emailAnalista
    host = $env:COMPUTERNAME
    usuario_windows = $env:USERNAME
    versao = $versaoAtual
    totalChecks = $total
    checksOK = $totalOK
    obrigatoriosOK = $obrigOK
    obrigatoriosTotal = $obrigatorios.Count
    opcionaisOK = $opcOK
    opcionaisTotal = $opcionais.Count
    resultado = if ($obrigOK -eq $obrigatorios.Count) { "OK" } elseif ($obrigOK -ge ($obrigatorios.Count - 2)) { "PARCIAL" } else { "FALHA" }
    detalhes = $checks | ForEach-Object { @{ nome = $_.nome; ok = $_.ok; detalhe = $_.detalhe; nivel = $_.nivel } }
}
$status = $statusObj | ConvertTo-Json -Depth 3
Set-Content -Path $statusFile -Value $status -Encoding UTF8

Write-Host ""
Write-Host "  Status salvo em: config/status-ambiente.json" -ForegroundColor Gray

# Publicar status no OneDrive (logs/analistas/{pasta_log}/status-ambiente.json)
# para o relatorio centralizado de versoes (scripts/relatorio-versoes-analistas.ps1).
if ($caminhosOK -and $caminhos.onedrive_logs -and (Test-Path $caminhos.onedrive_logs)) {
    try {
        $statusOneDrive = Join-Path $caminhos.onedrive_logs "status-ambiente.json"
        Set-Content -Path $statusOneDrive -Value $status -Encoding UTF8 -ErrorAction Stop
        Write-Host "  Status publicado no OneDrive: $statusOneDrive" -ForegroundColor Gray
    } catch {
        Write-Host "  [!] Nao foi possivel publicar status no OneDrive: $($_.Exception.Message)" -ForegroundColor DarkYellow
    }
}
Write-Host ""
