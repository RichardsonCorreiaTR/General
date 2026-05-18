# Resolucao da pasta scripts/sgd_consulta (consultas Playwright ao SGD).
# Usado por Consultar-PSAI-SGD.ps1 e Enriquecer-PSAI-DadosBrutos.ps1.

function Get-SgdConsultaPkgDir {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjetoFilhoRoot
    )
    $candidates = [System.Collections.Generic.List[string]]::new()
    $gr = $env:GENERAL_REPO_ROOT
    if ($gr -and -not [string]::IsNullOrWhiteSpace($gr)) {
        $t = $gr.Trim().TrimEnd('\', '/')
        if ($t) { $candidates.Add((Join-Path $t "scripts\sgd_consulta")) }
    }
    # Pacote do filho com modulo Python embutido (ultima-versao / monorepo)
    $candidates.Add((Join-Path $ProjetoFilhoRoot "scripts\sgd_consulta"))
    $parent = Split-Path -Parent $ProjetoFilhoRoot
    # Monorepo: General/projeto-filho -> General/scripts/sgd_consulta
    $candidates.Add((Join-Path $parent "scripts\sgd_consulta"))
    # Instalacao: CursorEscrita/General + CursorEscrita/projeto-filho
    $candidates.Add((Join-Path $parent "General\scripts\sgd_consulta"))
    foreach ($dir in $candidates) {
        if ([string]::IsNullOrWhiteSpace($dir)) { continue }
        $py = Join-Path $dir "consultar_psai.py"
        if (Test-Path -LiteralPath $py) {
            return (Resolve-Path -LiteralPath $dir).Path
        }
    }
    return $null
}

function Test-SgdCredentialsLocalFile {
    <#
    .SYNOPSIS
      True se existir .sgd-credentials.local com linha SGD_USERNAME= (nao so comentarios).
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$DataRootSgd
    )
    $p = Join-Path $DataRootSgd ".sgd-credentials.local"
    if (-not (Test-Path -LiteralPath $p)) { return $false }
    foreach ($line in Get-Content -LiteralPath $p -ErrorAction SilentlyContinue) {
        $t = $line.Trim()
        if ($t.Length -eq 0 -or $t.StartsWith("#")) { continue }
        if ($t -match '^\s*SGD_USERNAME\s*=') { return $true }
    }
    return $false
}

function Save-SgdCredentialsLocalFile {
    <#
    .SYNOPSIS
      Grava SGD_USERNAME / SGD_PASSWORD no formato esperado por env.py (igual ao instalador).
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$DataRootSgd,
        [Parameter(Mandatory = $true)]
        [string]$UserName,
        [Parameter(Mandatory = $true)]
        [string]$PlainPassword
    )
    New-Item -ItemType Directory -Force -Path $DataRootSgd | Out-Null
    $passEsc = $PlainPassword.Replace('\', '\\').Replace('"', '\"')
    $credPath = Join-Path $DataRootSgd ".sgd-credentials.local"
    $lines = @(
        "# Credenciais SGD (local). Nao partilhar.",
        "SGD_USERNAME=$($UserName.Trim())",
        "SGD_PASSWORD=`"$passEsc`""
    )
    Set-Content -Path $credPath -Value ($lines -join "`n") -Encoding UTF8
}
