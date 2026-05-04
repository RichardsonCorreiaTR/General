# instalar-projeto-filho.ps1
# Instalador Automatizado - Projeto Filho Escrita v1.0.0
#
# USO:
#   Clique direito -> Executar com PowerShell
#   OU abra PowerShell e rode:
#   Set-ExecutionPolicy Bypass -Scope Process; .\instalar-projeto-filho.ps1
#
# Com codigo a partir de ZIP (evita clone Git):
#   .\instalar-projeto-filho.ps1 -Nome "Seu Nome" -Email "seu@thomsonreuters.com" -ZipPath "C:\Users\...\Downloads\brtap-dominio_contabil-VC106A02.zip"
#
# Logs: criados em OneDrive (logs\analistas\{seu-nome}) e sincronizados automaticamente no drive.

param(
    [string]$ProjetoDir = "C:\CursorEscrita\projeto-filho",
    [string]$CodigoDir = "C:\CursorEscrita\codigo-sistema\versao-atual",
    [string]$Branch = "VC106A02",
    [string]$RepoUrl = "https://github.com/tr/brtap-dominio_contabil",
    [switch]$PularCodigo,
    [switch]$PularOneDrive,
    [string]$Nome,
    [string]$Email,
    [string]$ZipPath,
    [switch]$PularSgdCredenciais
)

$ErrorActionPreference = "Stop"
$script:erros = @()
$script:NaoInterativo = ($Nome -and $Email)

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  =============================================" -ForegroundColor Cyan
    Write-Host "  |   Projeto Filho - Escrita Fiscal             |" -ForegroundColor Cyan
    Write-Host "  |   Instalador Automatizado v1.0.0           |" -ForegroundColor Cyan
    Write-Host "  =============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step($num, $total, $msg) {
    Write-Host ""
    Write-Host "[$num/$total] $msg" -ForegroundColor Yellow
    Write-Host ("-" * 50) -ForegroundColor DarkGray
}

function Write-OK($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [!] $msg" -ForegroundColor DarkYellow }
function Write-Fail($msg) { Write-Host "  [X] $msg" -ForegroundColor Red; $script:erros += $msg }

function Test-Prerequisites {
    $ok = $true
    $cursorCmd = Get-Command cursor -ErrorAction SilentlyContinue
    if ($cursorCmd) {
        Write-OK "Cursor encontrado: $($cursorCmd.Source)"
    } else {
        $cursorPaths = @(
            "$env:LOCALAPPDATA\Programs\cursor\resources\app\bin\cursor.cmd",
            "$env:LOCALAPPDATA\cursor\cursor.exe"
        )
        $found = $cursorPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($found) { Write-OK "Cursor encontrado: $found" }
        else { Write-Fail "Cursor nao encontrado. Instale em https://cursor.sh"; $ok = $false }
    }
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) { Write-OK "Git encontrado: $(git --version 2>$null)" }
    else { Write-Warn "Git nao encontrado. Codigo-fonte nao sera baixado." }
    $pyCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pyCmd) {
        $pyVer = (python --version 2>&1) -replace "Python ", ""
        Write-OK "Python encontrado: $pyVer (necessario para consulta PSAI no SGD)"
    } else {
        Write-Warn "Python nao encontrado no PATH. O setup do SGD sera pulado. Instale depois em https://www.python.org/downloads/ (marque 'Add python.exe to PATH') e rode: .\scripts\setup-sgd-python.ps1"
    }
    $onedriveProc = Get-Process OneDrive -ErrorAction SilentlyContinue
    if ($onedriveProc) {
        Write-OK "OneDrive esta rodando"
    } else {
        $onedriveExe = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
        if (Test-Path $onedriveExe) {
            Start-Process $onedriveExe; Start-Sleep -Seconds 3
            Write-OK "OneDrive iniciado"
        } else { Write-Fail "OneDrive nao encontrado."; $ok = $false }
    }
    $odbcDriver = Get-OdbcDriver -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*SQL Anywhere*" } | Select-Object -First 1
    if ($odbcDriver) {
        Write-OK "ODBC driver SQL Anywhere encontrado"
        $odbcDsn = Get-OdbcDsn -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*pbcvs*" } | Select-Object -First 1
        if ($odbcDsn) {
            Write-OK "ODBC DSN pbcvs configurado"
        } else {
            Write-Warn "ODBC DSN pbcvs nao encontrado."
            $setupOdbc = Join-Path $PSScriptRoot "setup-odbc.ps1"
            if (Test-Path $setupOdbc) {
                if (-not $script:NaoInterativo) {
                    $resp = Read-Host "  Deseja configurar o ODBC agora? (S/N)"
                    if ($resp -eq "S" -or $resp -eq "s") { & $setupOdbc }
                } else {
                    Write-Host "  (modo nao interativo: ODBC nao configurado)" -ForegroundColor DarkGray
                }
            } else {
                Write-Host "  Rode setup-odbc.ps1 apos a instalacao." -ForegroundColor DarkYellow
            }
        }
    } else {
        Write-Warn "ODBC driver SQL Anywhere nao encontrado. Consulte o time de infra se precisar de acesso ao banco."
    }
    return $ok
}

function Find-OneDrivePath {
    $possiblePaths = @(
        "$env:USERPROFILE\Thomson Reuters Incorporated\CursorEscrita - General",
        "$env:USERPROFILE\Thomson Reuters Incorporated\CursorEscrita - Documentos\General",
        "$env:OneDriveCommercial\Thomson Reuters Incorporated\CursorEscrita - General",
        "$env:OneDriveCommercial\Thomson Reuters Incorporated\CursorEscrita - Documentos\General",
        "$env:OneDrive\Thomson Reuters Incorporated\CursorEscrita - General",
        "$env:OneDrive\Thomson Reuters Incorporated\CursorEscrita - Documentos\General"
    )
    foreach ($p in $possiblePaths) {
        if ($p -and (Test-Path (Join-Path $p "banco-dados"))) { return $p }
    }
    $bases = @($env:OneDriveCommercial, $env:OneDrive, $env:USERPROFILE) | Where-Object { $_ -and (Test-Path $_) }
    foreach ($base in $bases) {
        foreach ($nome in @("CursorEscrita - General")) {
            $found = Get-ChildItem -Path $base -Filter $nome -Directory -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found -and (Test-Path (Join-Path $found.FullName "banco-dados"))) { return $found.FullName }
        }
        $docGeneral = Join-Path $base "Thomson Reuters Incorporated\CursorEscrita - Documentos\General"
        if (Test-Path (Join-Path $docGeneral "banco-dados")) { return $docGeneral }
    }
    return $null
}

function Invoke-OneDriveSync {
    Write-Host "  Tentando iniciar sincronizacao do OneDrive..." -ForegroundColor Cyan
    $spUrl = "https://trten.sharepoint.com/sites/CursorEscrita/Shared%20Documents/General"
    try {
        Start-Process $spUrl
        Write-Host "  SharePoint aberto no navegador." -ForegroundColor Yellow
        Write-Host "  Clique em 'Sincronizar' para iniciar." -ForegroundColor Yellow
    } catch { Write-Warn "Nao foi possivel abrir o navegador." }
    $maxWait = 180; $waited = 0
    Write-Host ""
    while ($waited -lt $maxWait) {
        $path = Find-OneDrivePath
        if ($path) { Write-OK "OneDrive sincronizado: $path"; return $path }
        $pct = [math]::Round(($waited / $maxWait) * 100)
        Write-Host "`r  Aguardando sincronizacao... $waited/${maxWait}s ($pct%)" -NoNewline
        Start-Sleep -Seconds 5; $waited += 5
    }
    Write-Host ""
    Write-Fail "OneDrive nao sincronizou em ${maxWait}s."
    return $null
}

function Install-ProjectFiles {
    param([string]$OneDrivePath, [string]$Destino)
    $fonteProjetoFilho = Join-Path $OneDrivePath "projeto-filho"
    if (-not (Test-Path $fonteProjetoFilho)) {
        Write-Fail "Pasta projeto-filho nao encontrada em: $fonteProjetoFilho"
        return $false
    }
    New-Item -ItemType Directory -Path $Destino -Force | Out-Null
    $itens = 0
    foreach ($pasta in @(".cursor", "templates", "meu-trabalho")) {
        $src = Join-Path $fonteProjetoFilho $pasta
        $dst = Join-Path $Destino $pasta
        if (Test-Path $src) { Copy-Item -Path $src -Destination $dst -Recurse -Force; $itens++ }
    }
    foreach ($arq in @("PROJETO.md", "SETUP.md", "PILOTO.md", "GUIA-RAPIDO.md", "PROMPT-INSTALACAO.md", ".cursorignore")) {
        $src = Join-Path $fonteProjetoFilho $arq
        if (Test-Path $src) { Copy-Item -Path $src -Destination (Join-Path $Destino $arq) -Force; $itens++ }
    }
    $configDir = Join-Path $Destino "config"
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    $versionSrc = Join-Path $fonteProjetoFilho "config\VERSION.json"
    $versionDst = Join-Path $configDir "VERSION.json"
    if (Test-Path $versionSrc) { Copy-Item -Path $versionSrc -Destination $versionDst -Force }
    # Copiar scripts do projeto-filho (se existirem)
    $scriptsSrc = Join-Path $fonteProjetoFilho "scripts"
    $scriptsDst = Join-Path $Destino "scripts"
    if (Test-Path $scriptsSrc) { Copy-Item -Path $scriptsSrc -Destination $scriptsDst -Recurse -Force; $itens++ }
    New-Item -ItemType Directory -Path (Join-Path $Destino "referencia") -Force | Out-Null
    Write-OK "Projeto instalado: $Destino ($itens itens)"
    return $true
}

function Set-AnalystConfig {
    param([string]$Destino, [string]$OneDrivePath, [string]$NomeParam, [string]$EmailParam)
    Write-Host ""
    Write-Host "  === Configuracao do Analista ===" -ForegroundColor Cyan
    Write-Host ""
    $nome = if ($NomeParam) { $NomeParam } else { Read-Host "  Seu nome completo" }
    $email = if ($EmailParam) { $EmailParam } else { Read-Host "  Seu email (@thomsonreuters.com)" }
    while (-not $nome -or -not $email) {
        Write-Host "  Nome e email sao obrigatorios." -ForegroundColor Red
        if (-not $nome) { $nome = Read-Host "  Seu nome completo" }
        if (-not $email) { $email = Read-Host "  Seu email (@thomsonreuters.com)" }
    }
    $nomeKebab = ($nome -replace '[aàáâãä]','a' -replace '[eèéêë]','e' -replace '[iìíîï]','i' -replace '[oòóôõö]','o' -replace '[uùúûü]','u' -replace '[cç]','c' -replace '\s+','-' -replace '[^a-zA-Z0-9-]','').ToLower()

    # Buscar areas do cadastro central (time-analistas.json no OneDrive)
    $areasAnalista = @("Escrita", "Importação", "Onvio Escrita")
    $timeFile = Join-Path $OneDrivePath "config\time-analistas.json"
    if (Test-Path $timeFile) {
        $timeData = Get-Content $timeFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $registro = $timeData | Where-Object { $_.email -eq $email -or $_.nome -eq $nome } | Select-Object -First 1
        if ($registro -and $registro.areas) {
            $areasAnalista = $registro.areas
            Write-OK "Areas carregadas do cadastro central: $($areasAnalista -join ', ')"
        }
    }

    $analista = @{
        nome = $nome; email = $email
        data_setup = (Get-Date -Format "yyyy-MM-dd")
        versao_instalada = "1.0.0"; onboarding_completo = $false
        areas = $areasAnalista
    } | ConvertTo-Json -Depth 3
    Set-Content -Path (Join-Path $Destino "config\analista.json") -Value $analista -Encoding UTF8
    Write-OK "Identidade salva: $nome (areas: $($areasAnalista -join ', '))"
    $logsPath = Join-Path $OneDrivePath "logs\analistas\$nomeKebab"
    $caminhos = @{
        projeto_local = $Destino; codigo_local = $CodigoDir
        onedrive_base = $OneDrivePath
        onedrive_logs = $logsPath
    } | ConvertTo-Json -Depth 2
    Set-Content -Path (Join-Path $Destino "config\caminhos.json") -Value $caminhos -Encoding UTF8
    Write-OK "Caminhos configurados"
    New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
    Write-OK "Pasta de logs criada no OneDrive (sincroniza automaticamente no drive)"
    $hoje = Get-Date -Format "yyyy-MM-dd"
    $arquivoLogHoje = Join-Path $logsPath "$hoje.md"
    if (-not (Test-Path $arquivoLogHoje)) {
        $conteudoInicial = "# Log do dia $hoje`n`n> Instalacao do projeto filho. Pasta de logs no OneDrive -- sincronizacao automatica com o drive.`n"
        Set-Content -Path $arquivoLogHoje -Value $conteudoInicial -Encoding UTF8
        Write-OK "Arquivo de log inicial criado: $hoje.md (drive sincronizara automaticamente)"
    }
    return $nomeKebab
}

function New-Symlinks {
    param([string]$Destino, [string]$OneDrivePath, [string]$NomeKebab)
    $refDir = Join-Path $Destino "referencia"
    New-Item -ItemType Directory -Path $refDir -Force | Out-Null
    $links = @(
        @{ Name = "banco-dados"; Target = (Join-Path $OneDrivePath "banco-dados") },
        @{ Name = "logs"; Target = (Join-Path $OneDrivePath "logs\analistas\$NomeKebab") },
        @{ Name = "atualizacao"; Target = (Join-Path $OneDrivePath "atualizacao") }
    )
    foreach ($link in $links) {
        $lp = Join-Path $refDir $link.Name
        if (Test-Path $lp) { Write-OK "Link ja existe: $($link.Name)"; continue }
        if (-not (Test-Path $link.Target)) { New-Item -ItemType Directory -Path $link.Target -Force | Out-Null }
        try {
            New-Item -ItemType SymbolicLink -Path $lp -Target $link.Target -ErrorAction Stop | Out-Null
            Write-OK "Symlink criado: $($link.Name)"
        } catch {
            try {
                cmd /c mklink /J "$lp" "$($link.Target)" 2>$null | Out-Null
                Write-OK "Junction criado: $($link.Name)"
            } catch {
                Write-Fail "Nao foi possivel criar link: $($link.Name)"
                Write-Host "  Crie manualmente:" -ForegroundColor Yellow
                Write-Host "  cmd /c mklink /J `"$lp`" `"$($link.Target)`"" -ForegroundColor Gray
            }
        }
    }
}

function Install-FromZip {
    param([string]$ZipFilePath, [string]$DestinoCodigo)
    if (-not (Test-Path $ZipFilePath)) {
        Write-Fail "Arquivo ZIP nao encontrado: $ZipFilePath"
        return $false
    }
    $tempDir = Join-Path $env:TEMP "brtap-extract-$(Get-Random)"
    try {
        Write-Host "  Extraindo ZIP..." -ForegroundColor Cyan
        Expand-Archive -Path $ZipFilePath -DestinationPath $tempDir -Force
        $moduloPath = $null
        foreach ($candidato in @("escrita", "brtap-dominio_contabil\escrita", "brtap-dominio_contabil-VC106A02\escrita")) {
            $p = Join-Path $tempDir $candidato
            if (Test-Path $p) { $moduloPath = $p; break }
        }
        if (-not $moduloPath) {
            $subdirs = Get-ChildItem -Path $tempDir -Directory -Recurse -Depth 2 -ErrorAction SilentlyContinue
            $moduloPath = $subdirs | Where-Object { $_.Name -eq "escrita" } | Select-Object -First 1 -ExpandProperty FullName
        }
        if (-not $moduloPath -or -not (Test-Path $moduloPath)) {
            Write-Fail "Pasta 'escrita' nao encontrada no ZIP. Esperado: brtap-dominio_contabil/escrita (ou equivalente)."
            return $false
        }
        New-Item -ItemType Directory -Path $DestinoCodigo -Force | Out-Null
        Copy-Item -Path "$moduloPath\*" -Destination $DestinoCodigo -Recurse -Force
        $total = (Get-ChildItem -Recurse -File $DestinoCodigo -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-OK "Codigo extraido do ZIP: $total arquivos em $DestinoCodigo"
        $metaDir = Split-Path $DestinoCodigo
        $meta = @{
            branch = $Branch
            origem = "ZIP"
            zipFile = $ZipFilePath
            atualizadoEm = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            arquivos = $total
        } | ConvertTo-Json -Depth 2
        Set-Content -Path (Join-Path $metaDir "META.json") -Value $meta -Encoding UTF8
        return $true
    } finally {
        if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
    }
}

function Install-GitCode {
    if ($PularCodigo) { Write-Warn "Download de codigo pulado (-PularCodigo)"; return }
    if ($ZipPath) {
        $resolvedZip = $ZipPath
        if (-not [System.IO.Path]::IsPathRooted($ZipPath)) {
            $resolvedZip = Join-Path $env:USERPROFILE "Downloads\$ZipPath"
        }
        if (Test-Path $resolvedZip) {
            if (Install-FromZip -ZipFilePath $resolvedZip -DestinoCodigo $CodigoDir) { return }
            Write-Warn "Falha ao usar ZIP; tentando Git se disponivel."
        } else {
            Write-Warn "ZIP nao encontrado: $resolvedZip"
        }
    }
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCmd) { Write-Warn "Git nao disponivel. Pulando codigo-fonte."; return }
    if (Test-Path $CodigoDir) {
        $n = (Get-ChildItem -Path $CodigoDir -File -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
        if ($n -gt 100) {
            Write-OK "Codigo-fonte ja presente ($n arquivos)"
            $metaDir = Split-Path $CodigoDir
            $metaPath = Join-Path $metaDir "META.json"
            if (-not (Test-Path $metaPath)) {
                Write-Warn "META.json ausente. Criando registro de rastreamento..."
                $meta = @{
                    branch = $Branch
                    atualizadoEm = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
                    atualizadoPor = $env:USERNAME
                    arquivos = $n
                    origem = "pre-existente"
                    nota = "Codigo ja existia antes da instalacao; rodar atualizar-codigo.ps1 para sincronizar com o repo."
                } | ConvertTo-Json -Depth 2
                Set-Content -Path $metaPath -Value $meta -Encoding UTF8
                Write-OK "META.json criado em $metaPath"
            }
            return
        }
    }
    New-Item -ItemType Directory -Path $CodigoDir -Force | Out-Null
    $repoLocalDir = $null
    $tempDir = $null
    foreach ($c in @("C:\1 - A\B\Programas\brtap-dominio", "C:\Users\$($env:USERNAME)\brtap-dominio_contabil", "D:\brtap-dominio_contabil")) {
        if (-not (Test-Path $c -ErrorAction SilentlyContinue)) { continue }
        if (-not (Test-Path (Join-Path $c "escrita"))) { continue }
        if ((git -C $c branch --show-current 2>$null) -eq $Branch) {
            $repoLocalDir = $c; break
        }
    }
    if ($repoLocalDir) {
        Write-Host "  Usando repo local: $repoLocalDir" -ForegroundColor Green
        git -C $repoLocalDir pull origin $Branch 2>&1 | Out-Null
        $origemModulo = Join-Path $repoLocalDir "escrita"
        if (-not (Test-Path $origemModulo)) {
            Write-Fail "Pasta 'escrita' nao encontrada em $repoLocalDir"
            return
        }
        $commitSrc = $repoLocalDir
    } else {
        Write-Host "  Clonando do GitHub (shallow clone, pode demorar)..." -ForegroundColor Yellow
        $tempDir = Join-Path $env:TEMP "escrita-sdd-clone-$(Get-Random)"
        git clone --depth 1 --branch $Branch --single-branch $RepoUrl $tempDir 2>&1 | Out-Host
        if ($LASTEXITCODE -ne 0) { Write-Fail "Falha ao clonar repositorio."; return }
        $origemModulo = Join-Path $tempDir "escrita"
        if (-not (Test-Path $origemModulo)) {
            Write-Fail "Clone nao contem a pasta 'escrita'. Verifique branch e repositorio."
            if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
            return
        }
        $commitSrc = $tempDir
    }
    Write-Host "  Copiando modulo Escrita..." -ForegroundColor Cyan
    Copy-Item -Path "$origemModulo\*" -Destination $CodigoDir -Recurse -Force
    $total = (Get-ChildItem -Recurse -File $CodigoDir | Measure-Object).Count
    Write-OK "Codigo copiado: $total arquivos"
    $meta = @{
        branch = $Branch
        commit = (git -C $commitSrc log -1 --format="%H" 2>$null)
        commitDate = (git -C $commitSrc log -1 --format="%ci" 2>$null)
        atualizadoEm = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        arquivos = $total
    } | ConvertTo-Json -Depth 2
    $metaDir = Split-Path $CodigoDir
    Set-Content -Path (Join-Path $metaDir "META.json") -Value $meta -Encoding UTF8
    if ($tempDir -and (Test-Path $tempDir)) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
}

function Invoke-SgdCredentialsStep {
    param([string]$Destino)
    if ($PularSgdCredenciais) {
        Write-Warn "Passo SGD credenciais pulado (-PularSgdCredenciais)."
        return
    }
    if ($script:NaoInterativo) {
        Write-Warn "Modo nao interativo: defina SGD_USERNAME/SGD_PASSWORD no ambiente ou crie data\sgd-psai-consultas\.sgd-credentials.local depois."
        return
    }
    $dataSgd = Join-Path $Destino "data\sgd-psai-consultas"
    New-Item -ItemType Directory -Force -Path $dataSgd | Out-Null
    Write-Host ""
    Write-Host "  === Credenciais SGD (consulta PSAI no browser) ===" -ForegroundColor Cyan
    Write-Host "  Opcional: gravar aqui evita digitar a cada execucao de Consultar-PSAI-SGD.ps1." -ForegroundColor DarkGray
    Write-Host "  O ficheiro fica em data\sgd-psai-consultas\.sgd-credentials.local (nao vai para o Git)." -ForegroundColor DarkGray
    Write-Host ""
    $r = Read-Host "  Gravar utilizador e senha do SGD neste PC? (S/N)"
    if ($r -ne "S" -and $r -ne "s") {
        Write-Warn "Sem gravacao local. Na primeira consulta o script pedira utilizador e senha."
        return
    }
    $u = Read-Host "  Utilizador SGD"
    if ([string]::IsNullOrWhiteSpace($u)) {
        Write-Warn "Utilizador vazio — passo SGD cancelado."
        return
    }
    $sec = Read-Host "  Senha SGD" -AsSecureString
    if ($null -eq $sec -or $sec.Length -eq 0) {
        Write-Warn "Senha vazia — passo SGD cancelado."
        return
    }
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
    try { $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    $passEsc = $plain.Replace('\', '\\').Replace('"', '\"')
    $credPath = Join-Path $dataSgd ".sgd-credentials.local"
    $lines = @(
        "# Credenciais SGD (local). Nao partilhar. Gerado pelo instalador.",
        "SGD_USERNAME=$($u.Trim())",
        "SGD_PASSWORD=`"$passEsc`""
    )
    Set-Content -Path $credPath -Value ($lines -join "`n") -Encoding UTF8
    Write-OK "Credenciais SGD gravadas: data\sgd-psai-consultas\.sgd-credentials.local"
}

function Test-Installation {
    param([string]$Destino)
    $checks = @(
        @{ N = "config/analista.json"; P = (Join-Path $Destino "config\analista.json") },
        @{ N = "config/caminhos.json"; P = (Join-Path $Destino "config\caminhos.json") },
        @{ N = "config/VERSION.json"; P = (Join-Path $Destino "config\VERSION.json") },
        @{ N = ".cursor/rules/projeto.mdc"; P = (Join-Path $Destino ".cursor\rules\projeto.mdc") },
        @{ N = "templates/TEMPLATE-psai.md"; P = (Join-Path $Destino "templates\TEMPLATE-psai.md") },
        @{ N = "PROJETO.md"; P = (Join-Path $Destino "PROJETO.md") },
        @{ N = "referencia/banco-dados"; P = (Join-Path $Destino "referencia\banco-dados") },
        @{ N = "referencia/logs"; P = (Join-Path $Destino "referencia\logs") }
    )
    $ok = 0
    foreach ($c in $checks) {
        if (Test-Path $c.P) { Write-OK $c.N; $ok++ }
        else { Write-Fail "Nao encontrado: $($c.N)" }
    }
    $statusFile = Join-Path $Destino "config\status-ambiente.json"
    $status = @{
        verificadoEm = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        totalChecks = $checks.Count; checksOK = $ok
        resultado = if ($ok -eq $checks.Count) { "OK" } else { "PARCIAL" }
    } | ConvertTo-Json -Depth 2
    Set-Content -Path $statusFile -Value $status -Encoding UTF8
    Write-Host ""
    $cor = if ($ok -eq $checks.Count) { "Green" } else { "Yellow" }
    Write-Host "  Resultado: $ok/$($checks.Count) verificacoes OK" -ForegroundColor $cor
}

# ============================================
# EXECUCAO PRINCIPAL
# ============================================

Write-Banner

Write-Step 1 10 "Verificando pre-requisitos"
if (-not (Test-Prerequisites)) {
    Write-Host ""; Write-Host "  Corrija os pre-requisitos e rode novamente." -ForegroundColor Red
    Read-Host "  Pressione Enter para sair"; exit 1
}

Write-Step 2 10 "Detectando OneDrive"
$onedrivePath = Find-OneDrivePath
if ($onedrivePath) { Write-OK "OneDrive encontrado: $onedrivePath" }
elseif (-not $PularOneDrive) {
    $onedrivePath = Invoke-OneDriveSync
    if (-not $onedrivePath) {
        Write-Host "  Sincronize o OneDrive e rode novamente." -ForegroundColor Red
        Read-Host "  Pressione Enter para sair"; exit 1
    }
}

Write-Step 3 10 "Criando estrutura do projeto"
if (Test-Path $ProjetoDir) {
    Write-Warn "Pasta ja existe: $ProjetoDir"
    if (-not $script:NaoInterativo) {
        $r = Read-Host "  Deseja sobrescrever? (S/N)"
        if ($r -ne "S" -and $r -ne "s") {
            Write-Host "  Cancelado." -ForegroundColor Yellow
            Read-Host "  Pressione Enter para sair"; exit 0
        }
    } else {
        Write-Host "  (modo nao interativo: sobrescrevendo)" -ForegroundColor DarkGray
    }
}
if (-not (Install-ProjectFiles -OneDrivePath $onedrivePath -Destino $ProjetoDir)) {
    Write-Host "  Falha ao instalar." -ForegroundColor Red
    Read-Host "  Pressione Enter para sair"; exit 1
}

Write-Step 4 10 "Configurando identidade do analista"
$nomeKebab = Set-AnalystConfig -Destino $ProjetoDir -OneDrivePath $onedrivePath -NomeParam $Nome -EmailParam $Email

Write-Step 5 10 "Criando links para OneDrive"
New-Symlinks -Destino $ProjetoDir -OneDrivePath $onedrivePath -NomeKebab $nomeKebab

Write-Step 6 10 "Baixando codigo-fonte do sistema"
Install-GitCode

Write-Step 7 10 "Verificando instalacao"
Test-Installation -Destino $ProjetoDir

Write-Step 8 10 "Credenciais SGD (consulta PSAI)"
Invoke-SgdCredentialsStep -Destino $ProjetoDir

Write-Step 9 10 "Setup Python SGD (Playwright para consulta PSAI)"
$setupSgdScript = Join-Path $ProjetoDir "scripts\setup-sgd-python.ps1"
$pyCmd2 = Get-Command python -ErrorAction SilentlyContinue
if (-not $pyCmd2) {
    Write-Warn "Python nao encontrado — passo ignorado. Instale Python 3.10+ e rode .\scripts\setup-sgd-python.ps1 depois."
} elseif (-not (Test-Path $setupSgdScript)) {
    Write-Warn "setup-sgd-python.ps1 nao encontrado em $ProjetoDir\scripts. Sera necessario rodar manualmente apos instalacao."
} else {
    Write-Host "  Criando .venv e instalando Playwright (pode demorar ~2 min)..." -ForegroundColor Cyan
    try {
        & $setupSgdScript
        Write-OK "Ambiente Python SGD configurado com sucesso."
    } catch {
        Write-Warn "Setup Python SGD falhou: $_. Rode .\scripts\setup-sgd-python.ps1 manualmente apos a instalacao."
    }
}

Write-Step 10 10 "Finalizando"
Write-Host ""
if ($script:erros.Count -gt 0) {
    Write-Host "  Instalacao concluida com $($script:erros.Count) aviso(s):" -ForegroundColor Yellow
    $script:erros | ForEach-Object { Write-Host "    - $_" -ForegroundColor DarkYellow }
} else {
    Write-Host "  Instalacao concluida com sucesso!" -ForegroundColor Green
}
Write-Host ""
Write-Host "  Local do projeto: $ProjetoDir" -ForegroundColor White
Write-Host ""
if ($script:NaoInterativo) {
    try { Start-Process "cursor" $ProjetoDir; Write-OK "Cursor aberto!" }
    catch { Write-Warn "Abra manualmente: File -> Open Folder -> $ProjetoDir" }
} else {
    $abrir = Read-Host "  Deseja abrir o Cursor agora? (S/N)"
    if ($abrir -eq "S" -or $abrir -eq "s") {
        try { Start-Process "cursor" $ProjetoDir; Write-OK "Cursor aberto!" }
        catch { Write-Warn "Abra manualmente: File -> Open Folder -> $ProjetoDir" }
    }
}
Write-Host ""
Write-Host "  =============================================" -ForegroundColor Cyan
Write-Host "  |   Instalacao finalizada!                   |" -ForegroundColor Cyan
Write-Host "  |   Bom trabalho!                             |" -ForegroundColor Cyan
Write-Host "  =============================================" -ForegroundColor Cyan
Write-Host ""
if (-not $script:NaoInterativo) { Read-Host "  Pressione Enter para fechar" }

