#Requires -Version 5.1
# Processa pedidos em consultas-externas/entrada e grava JSON em saida/.
# Tipos: sai | codigo | ler-arquivo | sai-sgd | psai-sgd
param(
    [string]$ProjetoFilho = "",
    [switch]$Uma
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ProjetoFilho) { $ProjetoFilho = Split-Path -Parent $scriptDir }

$ce = Join-Path $ProjetoFilho "consultas-externas"
$entrada = Join-Path $ce "entrada"
$procDir = Join-Path $ce "processando"
$saida = Join-Path $ce "saida"
$erros = Join-Path $ce "erros"
foreach ($d in @($entrada, $procDir, $saida, $erros)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

function Test-TextoSeguro([string]$s, [int]$maxLen) {
    if ([string]::IsNullOrWhiteSpace($s)) { return $false }
    if ($s.Length -gt $maxLen) { return $false }
    if ($s -match '[;&|`$<>]') { return $false }
    return $true
}

function Get-BranchConceito([string]$conceito) {
    $cfgPath = Join-Path $ProjetoFilho "config\codigo-fonte-branches.json"
    $cfg = Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $conceito) { $conceito = "vigente" }
    $no = $cfg.$conceito
    if (-not $no -or -not $no.branch) {
        throw "Conceito de branch '$conceito' sem valor em codigo-fonte-branches.json"
    }
    return [string]$no.branch
}

function Write-Resultado($id, $obj) {
    $path = Join-Path $saida "$id.json"
    $json = $obj | ConvertTo-Json -Depth 8
    Set-Content -Path $path -Value $json -Encoding UTF8
    return $path
}

function Invoke-PedidoSai($pedido) {
    $p = $pedido.parametros
    $buscar = Join-Path $scriptDir "buscar-sai.ps1"
    $tmp = Join-Path $env:TEMP ("sai-" + [guid]::NewGuid().ToString() + ".json")
    $max = 20
    if ($p.max) { $max = [int]$p.max }
    $argList = @("-NoProfile", "-File", $buscar, "-JsonOut", $tmp, "-Max", "$max")
    if ($p.termo) { $argList += @("-Termo", [string]$p.termo) }
    if ($p.sai) { $argList += @("-SAI", [string]$p.sai) }
    if ($p.psai) { $argList += @("-PSAI", [string]$p.psai) }
    if ($p.tipoSai) { $argList += @("-Tipo", [string]$p.tipoSai) }
    if ($p.modulo) { $argList += @("-Modulo", [string]$p.modulo) }
    if ($p.pendentes -eq $true) { $argList += "-Pendentes" }
    if (-not $p.termo -and -not $p.sai -and -not $p.psai) {
        throw "Pedido sai exige parametros.termo, sai ou psai"
    }
    $proc = Start-Process -FilePath "powershell.exe" -ArgumentList $argList -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -ne 0) { throw "buscar-sai.ps1 saiu com codigo $($proc.ExitCode)" }
    if (-not (Test-Path $tmp)) { throw "buscar-sai.ps1 nao gerou JSON" }
    $dados = Get-Content $tmp -Raw -Encoding UTF8 | ConvertFrom-Json
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    return $dados
}

function Invoke-PedidoCodigo($pedido) {
    $p = $pedido.parametros
    $query = [string]$p.query
    if (-not (Test-TextoSeguro $query 180)) {
        throw "parametros.query invalido (vazio, longo ou com caracteres perigosos)"
    }
    $conceito = if ($p.conceitoBranch) { [string]$p.conceitoBranch } else { "vigente" }
    $branch = Get-BranchConceito $conceito
    $q = "$query repo:tr/brtap-dominio_contabil"
    $encoded = [uri]::EscapeDataString($q)
    $raw = & gh api "search/code?q=$encoded&per_page=20"
    if ($LASTEXITCODE -ne 0) { throw "gh api search/code falhou" }
    $parsed = $raw | ConvertFrom-Json
    $itens = @()
    foreach ($i in @($parsed.items | Select-Object -First 20)) {
        $itens += [pscustomobject]@{
            path       = $i.path
            html_url   = $i.html_url
            repository = $i.repository.full_name
        }
    }
    return [pscustomobject]@{
        total_github = $parsed.total_count
        mostrando    = $itens.Count
        branch_usada = $branch
        conceito     = $conceito
        aviso        = "O Code Search do GitHub indexa o default do repo. A branch vigente declarada e $branch. Use tipo ler-arquivo para ler um path nessa branch."
        itens        = $itens
    }
}

function Invoke-LerArquivo($pedido) {
    $p = $pedido.parametros
    $arquivo = ([string]$p.arquivo) -replace '\\', '/'
    if ($arquivo -match '\.\.' -or $arquivo -notmatch '^[A-Za-z0-9_./-]+$') {
        throw "parametros.arquivo invalido"
    }
    if ($arquivo.Length -gt 240) { throw "path muito longo" }
    $conceito = if ($p.conceitoBranch) { [string]$p.conceitoBranch } else { "vigente" }
    $branch = Get-BranchConceito $conceito
    $uri = "repos/tr/brtap-dominio_contabil/contents/${arquivo}?ref=$branch"
    $texto = & gh api $uri -H "Accept: application/vnd.github.raw"
    if ($LASTEXITCODE -ne 0) { throw "gh api contents falhou" }
    $s = [string]$texto
    $truncado = $false
    if ($s.Length -gt 40000) { $s = $s.Substring(0, 40000); $truncado = $true }
    return [pscustomobject]@{
        arquivo  = $arquivo
        branch   = $branch
        conceito = $conceito
        truncado = $truncado
        conteudo = $s
    }
}

function Invoke-Sgd($tipo, $pedido) {
    $n = [int]$pedido.parametros.numero
    if ($n -le 0) { throw "parametros.numero obrigatorio para $tipo" }
    $credPsai = Join-Path $ProjetoFilho "data\sgd-psai-consultas\.sgd-credentials.local"
    $credSai = Join-Path $ProjetoFilho "data\sgd-sai-consultas\.sgd-credentials.local"
    if (-not ((Test-Path $credPsai) -or (Test-Path $credSai))) {
        return [pscustomobject]@{
            status  = "pendente-credencial"
            detalhe = "Configure credenciais SGD no projeto-filho e reenvie o pedido."
        }
    }
    $scriptNome = if ($tipo -eq "sai-sgd") { "Consultar-SAI-SGD.ps1" } else { "Consultar-PSAI-SGD.ps1" }
    $script = Join-Path $scriptDir $scriptNome
    $out = & powershell.exe -NoProfile -File $script $n "--json" "--quiet" 2>&1 | Out-String
    $lim = [Math]::Min(15000, $out.Length)
    return [pscustomobject]@{ saida_script = $out.Substring(0, $lim) }
}

$arquivos = @(Get-ChildItem -Path $entrada -Filter "*.json" -File -ErrorAction SilentlyContinue | Sort-Object Name)
if ($Uma -and $arquivos.Count -gt 0) { $arquivos = @($arquivos[0]) }

if ($arquivos.Count -eq 0) {
    Write-Host "Nenhum pedido em $entrada" -ForegroundColor DarkGray
    exit 0
}

Write-Host "Processando $($arquivos.Count) pedido(s)..." -ForegroundColor Cyan
foreach ($arq in $arquivos) {
    $id = [IO.Path]::GetFileNameWithoutExtension($arq.Name)
    $destProc = Join-Path $procDir $arq.Name
    Move-Item -LiteralPath $arq.FullName -Destination $destProc -Force
    try {
        $pedido = Get-Content $destProc -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($pedido.id) { $id = [string]$pedido.id }
        $tipo = ([string]$pedido.tipo).ToLower()
        $resultado = $null
        switch ($tipo) {
            "sai" { $resultado = Invoke-PedidoSai $pedido }
            "codigo" { $resultado = Invoke-PedidoCodigo $pedido }
            "ler-arquivo" { $resultado = Invoke-LerArquivo $pedido }
            "sai-sgd" { $resultado = Invoke-Sgd $tipo $pedido }
            "psai-sgd" { $resultado = Invoke-Sgd $tipo $pedido }
            default { throw "tipo desconhecido: $tipo (use sai, codigo, ler-arquivo, sai-sgd, psai-sgd)" }
        }
        $outPath = Write-Resultado $id ([pscustomobject]@{
            id            = $id
            origem        = $pedido.origem
            tipo          = $tipo
            status        = "ok"
            processadoEm  = (Get-Date).ToString("o")
            pergunta      = $pedido.pergunta
            resultado     = $resultado
        })
        Remove-Item -LiteralPath $destProc -Force -ErrorAction SilentlyContinue
        Write-Host "OK $id -> $outPath" -ForegroundColor Green
    } catch {
        $errObj = [pscustomobject]@{
            id            = $id
            status        = "erro"
            processadoEm  = (Get-Date).ToString("o")
            erro          = $_.Exception.Message
        }
        Write-Resultado $id $errObj | Out-Null
        Copy-Item -LiteralPath $destProc -Destination (Join-Path $erros $arq.Name) -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $destProc -Force -ErrorAction SilentlyContinue
        Write-Host "ERRO $id : $($_.Exception.Message)" -ForegroundColor Red
    }
}
