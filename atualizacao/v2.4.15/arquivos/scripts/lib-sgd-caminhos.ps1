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
