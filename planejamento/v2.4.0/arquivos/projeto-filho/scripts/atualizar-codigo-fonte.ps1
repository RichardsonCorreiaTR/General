# atualizar-codigo-fonte.ps1
# Atualiza o codigo-fonte do sistema no projeto-filho do analista.
# Metodo primario: git clone. Fallback: ZIP do OneDrive.
# Inclui: verificacao de disco, backup, integridade, rastreabilidade.
#
# USO:
#   .\atualizar-codigo-fonte.ps1 -UrlGit "https://github.com/tr/brtap-dominio_contabil"
#   .\atualizar-codigo-fonte.ps1   (sem parametro usa fallback ZIP do OneDrive)
#
# IMPORTANTE: Rodar em terminal SEPARADO (fora do Cursor)

param(
    [string]$UrlGit = ""
)

# ============================================
# CONFIGURACAO
# ============================================

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir
$configFile = Join-Path $projetoDir "config\codigo-fonte.json"
$versionFile = Join-Path $projetoDir "config\codigo-fonte-version.json"
$timestampAtual = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$usuario = $env:USERNAME

# Espaco minimo em disco (500 MB)
$ESPACO_MINIMO_MB = 500

# Timeout do git clone (5 minutos)
$GIT_TIMEOUT_SEGUNDOS = 300

# ============================================
# FUNCOES AUXILIARES
# ============================================

function Write-Info($msg)    { Write-Host "  [INFO] $msg" -ForegroundColor Cyan }
function Write-OK($msg)      { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Aviso($msg)   { Write-Host "  [!] $msg" -ForegroundColor DarkYellow }
function Write-Erro($msg)    { Write-Host "  [ERRO] $msg" -ForegroundColor Red }

function Write-Etapa($num, $total, $msg) {
    Write-Host ""
    Write-Host "[$num/$total] $msg" -ForegroundColor Yellow
    Write-Host ("-" * 60) -ForegroundColor DarkGray
}

function Write-MensagemEscalacao {
    param([string]$Motivo)
    Write-Host ""
    Write-Host "  =====================================================" -ForegroundColor Red
    Write-Host "  |  FALHA COMPLETA NA ATUALIZACAO DO CODIGO-FONTE    |" -ForegroundColor Red
    Write-Host "  =====================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Copie a mensagem abaixo e envie para Vitor Justino via Teams:" -ForegroundColor Yellow
    Write-Host ""

    $mensagem = @"
---
ESCALACAO - Falha na atualizacao do codigo-fonte

Analista: $usuario
Data/Hora: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
Maquina: $env:COMPUTERNAME
Motivo: $Motivo

Tentativas realizadas:
1. Git clone - FALHOU
2. ZIP do OneDrive - FALHOU

Acao necessaria: verificar disponibilidade do repositorio e/ou pasta ZIP no OneDrive.
---
"@
    Write-Host $mensagem -ForegroundColor White
    Write-Host ""
    Write-Host "  =====================================================" -ForegroundColor Red
}

function Registrar-Log {
    param(
        [string]$Resultado,
        [string]$Metodo,
        [string]$Detalhes
    )

    # Log individual do analista em atualizacoes-codigo/logs/
    $logsDir = Join-Path $projetoDir "atualizacoes-codigo\logs"
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null

    $logFile = Join-Path $logsDir "$usuario-$timestampAtual.json"
    $logObj = @{
        analista       = $usuario
        maquina        = $env:COMPUTERNAME
        data_hora      = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        resultado      = $Resultado
        metodo         = $Metodo
        detalhes       = $Detalhes
        url_git        = $UrlGit
        versao_script  = "2.4.0"
    }
    $logObj | ConvertTo-Json -Depth 3 | Set-Content -Path $logFile -Encoding UTF8
    Write-Info "Log registrado: $logFile"
}

function Verificar-SincronizacaoOneDrive {
    param([string]$Pasta)

    if (-not (Test-Path $Pasta)) { return $true }

    # Verificar arquivos temporarios do OneDrive (.tmp, ~*)
    $tmpFiles = Get-ChildItem -Path $Pasta -Filter "*.tmp" -Recurse -ErrorAction SilentlyContinue
    $tildeFiles = Get-ChildItem -Path $Pasta -Filter "~*" -Recurse -ErrorAction SilentlyContinue

    if ($tmpFiles -and $tmpFiles.Count -gt 0) {
        Write-Aviso "Encontrados $($tmpFiles.Count) arquivo(s) .tmp na area de destino. OneDrive pode estar sincronizando."
        Write-Aviso "Arquivos: $($tmpFiles | Select-Object -First 3 -ExpandProperty Name)"
        return $false
    }

    if ($tildeFiles -and $tildeFiles.Count -gt 0) {
        Write-Aviso "Encontrados $($tildeFiles.Count) arquivo(s) com prefixo ~ na area de destino. OneDrive pode estar sincronizando."
        Write-Aviso "Arquivos: $($tildeFiles | Select-Object -First 3 -ExpandProperty Name)"
        return $false
    }

    # Verificar se VERSION.json e legivel (nao esta travado pelo OneDrive)
    $versionJson = Join-Path $Pasta "VERSION.json"
    if (Test-Path $versionJson) {
        try {
            $null = Get-Content $versionJson -Raw -Encoding UTF8 -ErrorAction Stop
            Write-OK "VERSION.json legivel na pasta de destino"
        } catch {
            Write-Aviso "VERSION.json existe mas nao pode ser lido (possivelmente travado pelo OneDrive)"
            return $false
        }
    }

    return $true
}

function Verificar-EspacoDisco {
    param([string]$Caminho)

    $drive = (Split-Path -Qualifier $Caminho)
    if (-not $drive) { $drive = "C:" }

    $disco = Get-PSDrive -Name $drive.TrimEnd(':') -ErrorAction SilentlyContinue
    if ($disco) {
        $livreMB = [math]::Round($disco.Free / 1MB, 0)
        Write-Info "Espaco livre em ${drive}: $livreMB MB"

        if ($livreMB -lt $ESPACO_MINIMO_MB) {
            Write-Erro "Espaco insuficiente! Minimo necessario: $ESPACO_MINIMO_MB MB. Disponivel: $livreMB MB."
            return $false
        }

        Write-OK "Espaco em disco suficiente ($livreMB MB >= $ESPACO_MINIMO_MB MB)"
        return $true
    }

    # Fallback: usar WMI se PSDrive nao funcionou
    try {
        $wmiDisco = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$drive'" -ErrorAction Stop
        $livreMB = [math]::Round($wmiDisco.FreeSpace / 1MB, 0)
        Write-Info "Espaco livre em ${drive}: $livreMB MB (via WMI)"

        if ($livreMB -lt $ESPACO_MINIMO_MB) {
            Write-Erro "Espaco insuficiente! Minimo: $ESPACO_MINIMO_MB MB. Disponivel: $livreMB MB."
            return $false
        }

        Write-OK "Espaco em disco suficiente ($livreMB MB >= $ESPACO_MINIMO_MB MB)"
        return $true
    } catch {
        Write-Aviso "Nao foi possivel verificar espaco em disco. Continuando mesmo assim."
        return $true
    }
}

function Obter-ProxyDoSistema {
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
        $proxyEnabled = (Get-ItemProperty -Path $regPath -Name ProxyEnable -ErrorAction SilentlyContinue).ProxyEnable
        if ($proxyEnabled -eq 1) {
            $proxyServer = (Get-ItemProperty -Path $regPath -Name ProxyServer -ErrorAction SilentlyContinue).ProxyServer
            if ($proxyServer) {
                Write-Info "Proxy do sistema detectado: $proxyServer"
                $env:HTTP_PROXY = "http://$proxyServer"
                $env:HTTPS_PROXY = "http://$proxyServer"
                return $proxyServer
            }
        }
    } catch {
        Write-Aviso "Nao foi possivel detectar configuracoes de proxy do sistema."
    }
    return $null
}

function Criar-Backup {
    param([string]$PastaOrigem)

    if (-not (Test-Path $PastaOrigem)) {
        Write-Info "Pasta de codigo anterior nao encontrada. Backup nao necessario."
        return $null
    }

    $arquivosExistentes = Get-ChildItem -Path $PastaOrigem -Recurse -File -ErrorAction SilentlyContinue
    if (-not $arquivosExistentes -or $arquivosExistentes.Count -eq 0) {
        Write-Info "Pasta de destino vazia. Backup nao necessario."
        return $null
    }

    $backupDir = Join-Path $projetoDir "meu-trabalho\backup-codigo\$timestampAtual"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

    Write-Info "Criando backup de $($arquivosExistentes.Count) arquivo(s)..."
    Copy-Item -Path "$PastaOrigem\*" -Destination $backupDir -Recurse -Force
    $totalBackup = (Get-ChildItem -Path $backupDir -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-OK "Backup criado: $backupDir ($totalBackup arquivos)"

    return $backupDir
}

function Restaurar-Backup {
    param(
        [string]$BackupDir,
        [string]$PastaDestino
    )

    if (-not $BackupDir -or -not (Test-Path $BackupDir)) {
        Write-Erro "Backup nao disponivel para restauracao!"
        return $false
    }

    Write-Aviso "Restaurando backup de: $BackupDir"

    # Limpar pasta de destino
    if (Test-Path $PastaDestino) {
        Get-ChildItem -Path $PastaDestino -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $PastaDestino -Force | Out-Null

    Copy-Item -Path "$BackupDir\*" -Destination $PastaDestino -Recurse -Force
    $totalRestaurado = (Get-ChildItem -Path $PastaDestino -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-OK "Backup restaurado: $totalRestaurado arquivos em $PastaDestino"
    return $true
}

function Verificar-Integridade {
    param(
        [string]$PastaDestino,
        [array]$ArquivosEssenciais
    )

    Write-Info "Verificando integridade dos arquivos essenciais..."
    $todosPresentes = $true

    foreach ($item in $ArquivosEssenciais) {
        $caminhoCompleto = Join-Path $PastaDestino $item

        if ($item.EndsWith("/") -or $item.EndsWith("\")) {
            # Eh um diretorio
            if (Test-Path $caminhoCompleto -PathType Container) {
                $conteudo = Get-ChildItem -Path $caminhoCompleto -Recurse -File -ErrorAction SilentlyContinue
                if ($conteudo -and $conteudo.Count -gt 0) {
                    Write-OK "Diretorio encontrado: $item ($($conteudo.Count) arquivos)"
                } else {
                    Write-Erro "Diretorio encontrado mas vazio: $item"
                    $todosPresentes = $false
                }
            } else {
                Write-Erro "Diretorio essencial ausente: $item"
                $todosPresentes = $false
            }
        } else {
            # Eh um arquivo
            if (Test-Path $caminhoCompleto -PathType Leaf) {
                $tamanho = (Get-Item $caminhoCompleto).Length
                if ($tamanho -gt 0) {
                    Write-OK "Arquivo encontrado: $item ($tamanho bytes)"
                } else {
                    Write-Erro "Arquivo encontrado mas vazio: $item"
                    $todosPresentes = $false
                }
            } else {
                Write-Erro "Arquivo essencial ausente: $item"
                $todosPresentes = $false
            }
        }
    }

    return $todosPresentes
}

function Tentar-GitClone {
    param(
        [string]$Url,
        [string]$PastaDestino
    )

    # Verificar se git esta instalado
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCmd) {
        Write-Aviso "Git nao esta instalado ou nao esta no PATH."
        return $false
    }

    Write-Info "Git encontrado: $(git --version 2>$null)"

    if (-not $Url) {
        Write-Aviso "URL do Git nao fornecida (parametro -UrlGit). Pulando clone."
        return $false
    }

    # Configurar proxy se disponivel
    $null = Obter-ProxyDoSistema

    # Limpar pasta de destino antes do clone
    if (Test-Path $PastaDestino) {
        Get-ChildItem -Path $PastaDestino -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $PastaDestino -Force | Out-Null

    # Usar diretorio temporario para clone
    $tempCloneDir = Join-Path $env:TEMP "codigo-fonte-clone-$(Get-Random)"

    Write-Info "Clonando repositorio (timeout: ${GIT_TIMEOUT_SEGUNDOS}s)..."
    Write-Info "URL: $Url"
    Write-Info "Temp: $tempCloneDir"

    try {
        # Executar git clone com timeout
        $processo = Start-Process -FilePath "git" `
            -ArgumentList "clone", "--depth", "1", "--single-branch", $Url, $tempCloneDir `
            -NoNewWindow -PassThru -RedirectStandardOutput "$env:TEMP\git-clone-stdout.log" `
            -RedirectStandardError "$env:TEMP\git-clone-stderr.log"

        $concluiu = $processo.WaitForExit($GIT_TIMEOUT_SEGUNDOS * 1000)

        if (-not $concluiu) {
            Write-Erro "Git clone excedeu o timeout de $GIT_TIMEOUT_SEGUNDOS segundos."
            try { $processo.Kill() } catch {}
            if (Test-Path $tempCloneDir) { Remove-Item -Recurse -Force $tempCloneDir -ErrorAction SilentlyContinue }
            return $false
        }

        if ($processo.ExitCode -ne 0) {
            $stderr = ""
            if (Test-Path "$env:TEMP\git-clone-stderr.log") {
                $stderr = Get-Content "$env:TEMP\git-clone-stderr.log" -Raw -ErrorAction SilentlyContinue
            }
            Write-Erro "Git clone falhou (codigo de saida: $($processo.ExitCode))."
            if ($stderr) { Write-Erro "Detalhes: $stderr" }
            if (Test-Path $tempCloneDir) { Remove-Item -Recurse -Force $tempCloneDir -ErrorAction SilentlyContinue }
            return $false
        }

        # Copiar conteudo do clone para pasta de destino
        Write-Info "Copiando arquivos clonados para destino..."
        Copy-Item -Path "$tempCloneDir\*" -Destination $PastaDestino -Recurse -Force -Exclude ".git"

        # Remover pasta .git do destino (nao precisamos do historico)
        $gitDir = Join-Path $PastaDestino ".git"
        if (Test-Path $gitDir) { Remove-Item -Recurse -Force $gitDir -ErrorAction SilentlyContinue }

        $totalArquivos = (Get-ChildItem -Path $PastaDestino -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-OK "Clone concluido: $totalArquivos arquivos copiados"

        return $true

    } catch {
        Write-Erro "Erro inesperado durante git clone: $($_.Exception.Message)"
        return $false
    } finally {
        # Limpar temporarios
        if (Test-Path $tempCloneDir) { Remove-Item -Recurse -Force $tempCloneDir -ErrorAction SilentlyContinue }
        Remove-Item -Path "$env:TEMP\git-clone-stdout.log" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:TEMP\git-clone-stderr.log" -Force -ErrorAction SilentlyContinue
    }
}

function Tentar-FallbackZip {
    param(
        [string]$PastaZip,
        [string]$PastaDestino
    )

    if (-not (Test-Path $PastaZip)) {
        Write-Erro "Pasta de ZIP do OneDrive nao encontrada: $PastaZip"
        return $false
    }

    # Buscar o ZIP mais recente na pasta
    $zips = Get-ChildItem -Path $PastaZip -Filter "*.zip" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if (-not $zips -or $zips.Count -eq 0) {
        Write-Erro "Nenhum arquivo .zip encontrado em: $PastaZip"
        return $false
    }

    $zipEscolhido = $zips[0]
    Write-Info "ZIP encontrado: $($zipEscolhido.Name) ($([math]::Round($zipEscolhido.Length / 1MB, 1)) MB)"
    Write-Info "Data do arquivo: $($zipEscolhido.LastWriteTime.ToString('dd/MM/yyyy HH:mm'))"

    # Limpar pasta de destino
    if (Test-Path $PastaDestino) {
        Get-ChildItem -Path $PastaDestino -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $PastaDestino -Force | Out-Null

    # Extrair ZIP
    $tempExtract = Join-Path $env:TEMP "codigo-fonte-zip-$(Get-Random)"
    try {
        Write-Info "Extraindo ZIP..."
        Expand-Archive -Path $zipEscolhido.FullName -DestinationPath $tempExtract -Force

        # Procurar a pasta raiz do codigo dentro do ZIP
        $conteudoRaiz = Get-ChildItem -Path $tempExtract -ErrorAction SilentlyContinue
        $pastaOrigem = $tempExtract

        # Se o ZIP contem uma unica pasta raiz, usar ela como origem
        if ($conteudoRaiz.Count -eq 1 -and $conteudoRaiz[0].PSIsContainer) {
            $pastaOrigem = $conteudoRaiz[0].FullName
        }

        Copy-Item -Path "$pastaOrigem\*" -Destination $PastaDestino -Recurse -Force
        $totalArquivos = (Get-ChildItem -Path $PastaDestino -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-OK "ZIP extraido: $totalArquivos arquivos"

        return $true

    } catch {
        Write-Erro "Falha ao extrair ZIP: $($_.Exception.Message)"
        return $false
    } finally {
        if (Test-Path $tempExtract) { Remove-Item -Recurse -Force $tempExtract -ErrorAction SilentlyContinue }
    }
}

function Gravar-Versao {
    param(
        [string]$Metodo,
        [string]$Referencia,
        [int]$TotalArquivos
    )

    $versaoObj = @{
        versao          = "2.4.0"
        data_atualizacao = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        metodo          = $Metodo
        referencia      = $Referencia
        analista        = $usuario
        maquina         = $env:COMPUTERNAME
        total_arquivos  = $TotalArquivos
    }
    $versaoObj | ConvertTo-Json -Depth 3 | Set-Content -Path $versionFile -Encoding UTF8
    Write-OK "Versao registrada em: $versionFile"
}

# ============================================
# EXECUCAO PRINCIPAL
# ============================================

Write-Host ""
Write-Host "  =============================================" -ForegroundColor Cyan
Write-Host "  |  Atualizador de Codigo-Fonte v2.4.0       |" -ForegroundColor Cyan
Write-Host "  |  Projeto Filho - Folha                     |" -ForegroundColor Cyan
Write-Host "  =============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Usuario: $usuario"
Write-Host "  Data/Hora: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
Write-Host "  Projeto: $projetoDir"
Write-Host ""

# ---- ETAPA 1: Validar configuracao ----
Write-Etapa 1 7 "Validando configuracao"

if (-not (Test-Path $configFile)) {
    Write-Erro "Arquivo de configuracao nao encontrado: $configFile"
    Write-Erro "Certifique-se de que config/codigo-fonte.json existe no projeto."
    Registrar-Log -Resultado "FALHA" -Metodo "N/A" -Detalhes "Arquivo de configuracao ausente: $configFile"
    exit 1
}

Write-OK "Configuracao encontrada: $configFile"
$config = Get-Content $configFile -Raw -Encoding UTF8 | ConvertFrom-Json

$pastaDestino = Join-Path $projetoDir $config.pasta_destino
$pastaZipOneDrive = Join-Path $projetoDir $config.pasta_zip_onedrive
$arquivosEssenciais = @($config.arquivos_essenciais)

Write-Info "Pasta destino: $pastaDestino"
Write-Info "Pasta ZIP OneDrive: $pastaZipOneDrive"
Write-Info "Arquivos essenciais: $($arquivosEssenciais -join ', ')"

# ---- ETAPA 2: Verificar espaco em disco ----
Write-Etapa 2 7 "Verificando espaco em disco"

if (-not (Verificar-EspacoDisco -Caminho $pastaDestino)) {
    Registrar-Log -Resultado "FALHA" -Metodo "N/A" -Detalhes "Espaco em disco insuficiente"
    exit 1
}

# ---- ETAPA 3: Verificar sincronizacao do OneDrive ----
Write-Etapa 3 7 "Verificando sincronizacao do OneDrive"

if (-not (Verificar-SincronizacaoOneDrive -Pasta $pastaDestino)) {
    Write-Aviso "OneDrive pode estar sincronizando. Aguardando 15 segundos..."
    Start-Sleep -Seconds 15

    if (-not (Verificar-SincronizacaoOneDrive -Pasta $pastaDestino)) {
        Write-Erro "OneDrive ainda esta sincronizando. Tente novamente em alguns minutos."
        Registrar-Log -Resultado "FALHA" -Metodo "N/A" -Detalhes "OneDrive em sincronizacao - arquivos temporarios detectados"
        exit 1
    }
}

Write-OK "Nenhum conflito de sincronizacao do OneDrive detectado"

# ---- ETAPA 4: Criar backup ----
Write-Etapa 4 7 "Criando backup do codigo atual"

$backupDir = Criar-Backup -PastaOrigem $pastaDestino

# ---- ETAPA 5: Atualizar codigo-fonte ----
Write-Etapa 5 7 "Atualizando codigo-fonte"

$metodoUsado = ""
$referenciaUsada = ""
$atualizouOk = $false

# Tentativa 1: Git Clone
Write-Info "Tentativa 1: Git Clone..."
$gitOk = Tentar-GitClone -Url $UrlGit -PastaDestino $pastaDestino

if ($gitOk) {
    $metodoUsado = "git-clone"
    $referenciaUsada = $UrlGit
    $atualizouOk = $true
    Write-OK "Codigo atualizado via Git Clone"
} else {
    Write-Aviso "Git Clone falhou. Tentando fallback via ZIP..."

    # Tentativa 2: ZIP do OneDrive
    Write-Info "Tentativa 2: ZIP do OneDrive..."
    $zipOk = Tentar-FallbackZip -PastaZip $pastaZipOneDrive -PastaDestino $pastaDestino

    if ($zipOk) {
        $metodoUsado = "zip-onedrive"
        $referenciaUsada = $pastaZipOneDrive
        $atualizouOk = $true
        Write-OK "Codigo atualizado via ZIP do OneDrive"
    }
}

# Se ambos falharam
if (-not $atualizouOk) {
    Write-Erro "Ambos os metodos de atualizacao falharam!"

    # Restaurar backup se existente
    if ($backupDir) {
        Write-Aviso "Restaurando backup..."
        $null = Restaurar-Backup -BackupDir $backupDir -PastaDestino $pastaDestino
    }

    Registrar-Log -Resultado "FALHA_TOTAL" -Metodo "git+zip" -Detalhes "Ambos os metodos falharam. Git URL: $UrlGit | ZIP: $pastaZipOneDrive"
    Write-MensagemEscalacao -Motivo "Git clone e extracao ZIP falharam. URL: $UrlGit | ZIP: $pastaZipOneDrive"
    exit 1
}

# ---- ETAPA 6: Verificar integridade ----
Write-Etapa 6 7 "Verificando integridade"

$integridadeOk = Verificar-Integridade -PastaDestino $pastaDestino -ArquivosEssenciais $arquivosEssenciais

if (-not $integridadeOk) {
    Write-Erro "Verificacao de integridade falhou! Arquivos essenciais ausentes."

    # Restaurar backup automaticamente
    if ($backupDir) {
        Write-Aviso "Restaurando backup automaticamente..."
        $restaurou = Restaurar-Backup -BackupDir $backupDir -PastaDestino $pastaDestino

        if ($restaurou) {
            Write-OK "Backup restaurado com sucesso. Codigo anterior mantido."
        } else {
            Write-Erro "Falha ao restaurar backup!"
        }
    }

    Registrar-Log -Resultado "FALHA_INTEGRIDADE" -Metodo $metodoUsado -Detalhes "Arquivos essenciais ausentes apos atualizacao via $metodoUsado. Backup restaurado."
    Write-MensagemEscalacao -Motivo "Verificacao de integridade falhou apos $metodoUsado. Arquivos essenciais ausentes."
    exit 1
}

Write-OK "Integridade verificada com sucesso"

# ---- ETAPA 7: Registrar versao e finalizar ----
Write-Etapa 7 7 "Registrando versao e finalizando"

$totalArquivos = (Get-ChildItem -Path $pastaDestino -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
Gravar-Versao -Metodo $metodoUsado -Referencia $referenciaUsada -TotalArquivos $totalArquivos

# Atualizar campo ultima_verificacao no config
try {
    $config.ultima_verificacao = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    $config | ConvertTo-Json -Depth 3 | Set-Content -Path $configFile -Encoding UTF8
    Write-OK "Configuracao atualizada com data da verificacao"
} catch {
    Write-Aviso "Nao foi possivel atualizar a data de verificacao no config: $($_.Exception.Message)"
}

# Registrar log de sucesso
Registrar-Log -Resultado "SUCESSO" -Metodo $metodoUsado -Detalhes "Atualizado com $totalArquivos arquivos via $metodoUsado"

# Resumo final
Write-Host ""
Write-Host "  =============================================" -ForegroundColor Green
Write-Host "  |  ATUALIZACAO CONCLUIDA COM SUCESSO!       |" -ForegroundColor Green
Write-Host "  =============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Metodo utilizado: $metodoUsado" -ForegroundColor White
Write-Host "  Total de arquivos: $totalArquivos" -ForegroundColor White
Write-Host "  Destino: $pastaDestino" -ForegroundColor White
if ($backupDir) {
    Write-Host "  Backup: $backupDir" -ForegroundColor White
}
Write-Host "  Versao: $versionFile" -ForegroundColor White
Write-Host ""
