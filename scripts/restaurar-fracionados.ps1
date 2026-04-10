# restaurar-fracionados.ps1
# Gera banco-dados/dados-brutos/psai e sai a partir do monolitico sai-psai-escrita.json
#
# Uso:
#   .\restaurar-fracionados.ps1
#       Busca sai-psai-*.json no BuscaSAI, mescla no cache local e fraciona.
#   .\restaurar-fracionados.ps1 -UsarMonolitico "C:\...\sai-psai-escrita.json" -PularIndices
#       So fraciona (importar-sais.ps1 chama assim e gera indices depois).

param(
    [string]$UsarMonolitico = "",
    [switch]$PularIndices
)

$ErrorActionPreference = "Stop"
$projetoDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$cacheDir = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "cache"
$cacheFile = Join-Path $cacheDir "sai-psai-escrita.json"
$dadosBrutosDir = Join-Path $projetoDir "banco-dados\dados-brutos"
$psaiOutDir = Join-Path $dadosBrutosDir "psai"
$saiOutDir = Join-Path $dadosBrutosDir "sai"

New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
New-Item -ItemType Directory -Path $psaiOutDir -Force | Out-Null
New-Item -ItemType Directory -Path $saiOutDir -Force | Out-Null

if ($UsarMonolitico -ne "" -and (Test-Path $UsarMonolitico)) {
    $cacheFile = $UsarMonolitico
    Write-Host "[1/4] Usando monolitico ja mesclado: $cacheFile" -ForegroundColor Cyan
} else {
    $candidatosBase = @(
        "C:\1 - A\B\Programas\BuscaSAI",
        (Join-Path $env:USERPROFILE "OneDrive - Thomson Reuters Incorporated\Aplicacoes Cursor\BuscaSAI")
    )
    $dirCache = $null
    foreach ($b in $candidatosBase) {
        if (-not $b) { continue }
        $dc = Join-Path $b "data\cache"
        if (-not (Test-Path $dc)) { continue }
        if ((Get-ChildItem $dc -Filter "sai-psai-*.json" -ErrorAction SilentlyContinue).Count -gt 0) {
            $dirCache = $dc
            break
        }
    }
    if (-not $dirCache) {
        Write-Host "ERRO: BuscaSAI sem data/cache/sai-psai-*.json. Clone em C:\1 - A\B\Programas\BuscaSAI" -ForegroundColor Red
        exit 1
    }

    $arquivos = @(Get-ChildItem -Path $dirCache -Filter "sai-psai-*.json" -File | Sort-Object Name)
    if ($arquivos.Count -eq 1) {
        Write-Host "[1/4] Copiando $($arquivos[0].Name) para cache local..."
        Copy-Item $arquivos[0].FullName $cacheFile -Force
    } else {
        Write-Host "[1/4] Mesclando $($arquivos.Count) arquivos sai-psai-*.json -> $cacheFile"
        $porPsai = @{}
        foreach ($f in $arquivos) {
            $j = Get-Content $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            if (-not $j.dados) { continue }
            foreach ($item in $j.dados) {
                $k = [string]$item.i_psai
                if ($k) { $porPsai[$k] = $item }
            }
        }
        $lista = [System.Collections.ArrayList]::new()
        foreach ($v in $porPsai.Values) { [void]$lista.Add($v) }
        $wrapper = [ordered]@{
            geradoEm = (Get-Date -Format o)
            totalRegistros = $lista.Count
            dados = $lista.ToArray()
            fontesMescladas = @($arquivos | ForEach-Object { $_.Name })
        }
        $wrapper | ConvertTo-Json -Depth 5 -Compress | Set-Content -Path $cacheFile -Encoding UTF8
    }
    $size = [math]::Round((Get-Item $cacheFile).Length / 1MB, 1)
    Write-Host "  Cache local: $size MB"
}

Write-Host "[2/4] Carregando cache JSON (pode demorar ~30s)..."
$data = Get-Content $cacheFile -Raw -Encoding UTF8 | ConvertFrom-Json
$registros = $data.dados
Write-Host "  $($registros.Count) registros carregados"

Write-Host "[3/4] Gerando fracionados..."
$tiposTodos = @("NE","SAM","SAL","SAIL")
$escritos = 0

foreach ($tp in $tiposTodos) {
    $porTipo = @($registros | Where-Object { $_.tipoSAI -eq $tp })
    $pendentes = @($porTipo | Where-Object { -not $_.Liberacao -and -not $_.Descarte })
    $liberadas = @($porTipo | Where-Object { $_.Liberacao })
    $descartadas = @($porTipo | Where-Object { $_.Descarte })
    $tpLower = $tp.ToLower()

    $splits = @(
        @{ nome="pendentes"; itens=$pendentes },
        @{ nome="liberadas"; itens=$liberadas },
        @{ nome="descartadas"; itens=$descartadas }
    )

    foreach ($s in $splits) {
        $arquivo = "$tpLower-$($s.nome).json"
        $regs = $s.itens

        $psaiObj = @{ tipo=$tp; status=$s.nome; total=$regs.Count; dados=$regs }
        $psaiObj | ConvertTo-Json -Depth 5 -Compress | Set-Content (Join-Path $psaiOutDir $arquivo) -Encoding UTF8

        $grupos = $regs | Group-Object -Property i_sai
        $saiRegistros = @()
        foreach ($g in $grupos) {
            $maisRecente = $g.Group | Sort-Object {
                if ($_.CadastroPSAI) { try { [datetime]$_.CadastroPSAI } catch { [datetime]::MinValue } } else { [datetime]::MinValue }
            } -Descending | Select-Object -First 1
            $saiRegistros += [PSCustomObject]@{
                i_sai = $maisRecente.i_sai; tipoSAI = $maisRecente.tipoSAI
                sai_descricao = $maisRecente.sai_descricao; nomeVersao = $maisRecente.nomeVersao
                gravidade_ne = $maisRecente.gravidade_ne; situacaoSai = $maisRecente.situacaoSai
                ultimaPsai = $maisRecente.i_psai; ultimoCadastro = $maisRecente.CadastroPSAI
                totalPsais = $g.Count
            }
        }
        $saiObj = @{ tipo=$tp; status=$s.nome; totalSais=$saiRegistros.Count; dados=$saiRegistros }
        $saiObj | ConvertTo-Json -Depth 5 -Compress | Set-Content (Join-Path $saiOutDir $arquivo) -Encoding UTF8
        $escritos += 2
        Write-Host "  ${arquivo}: $($regs.Count) PSAIs, $($saiRegistros.Count) SAIs"
    }
}
Write-Host "  Total: $escritos arquivos JSON gerados"

if (-not $PularIndices) {
    Write-Host "[4/4] Gerando indices..."
    $indicesScript = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "gerar-indices-sais.ps1"
    & $indicesScript
    Write-Host ""
    Write-Host "=== RESTAURACAO CONCLUIDA ==="
} else {
    Write-Host "[4/4] Indices omitidos (-PularIndices)"
}

Write-Host "  Registros: $($registros.Count)"
Write-Host "  Fracionados: $escritos arquivos"
