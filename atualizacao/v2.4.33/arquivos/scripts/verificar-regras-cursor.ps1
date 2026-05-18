#Requires -Version 5.1
<#
.SYNOPSIS
  Verifica se as regras Cursor (.cursor/rules) e ficheiros .cursor do projeto-filho estao completos face ao manifesto oficial.

.DESCRIPTION
  Compara a pasta local com config/cursor-rules-manifest.json (regras obrigatorias + opcionais).
  Util para analistas com copias defasadas ou merges manuais incompletos.

  Saida: texto no terminal; codigo de saida 0 = tudo OK, 1 = falha (falta regra obrigatoria).

.PARAMETER GerarPrompt
  Imprime um prompt pronto para colar no chat do Cursor e pedir a IA uma revisao semantica das regras.

.PARAMETER Json
  Emite resumo em JSON (stdout) para automatizacao.

.EXAMPLE
  .\scripts\verificar-regras-cursor.ps1
  .\scripts\verificar-regras-cursor.ps1 -GerarPrompt
  .\scripts\verificar-ambiente.ps1 -IncluirRegrasCursor
#>
param(
    [switch]$GerarPrompt,
    [switch]$Json,
    [switch]$Severo
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projetoDir = Split-Path -Parent $scriptDir
$manifestPath = Join-Path $projetoDir "config\cursor-rules-manifest.json"
$rulesDir = Join-Path $projetoDir ".cursor\rules"

function Get-ManifestData {
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        return $null
    }
    return (Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json)
}

$manifest = Get-ManifestData
if (-not $manifest) {
    Write-Error "Manifesto nao encontrado: $manifestPath"
}

$obrigatorias = @($manifest.regrasObrigatorias)
$opcionaisRel = @($manifest.arquivosCursorOpcionais)

$faltando = [System.Collections.Generic.List[string]]::new()
$okRegras = [System.Collections.Generic.List[string]]::new()
$opcOk = [System.Collections.Generic.List[string]]::new()
$opcFalta = [System.Collections.Generic.List[string]]::new()

foreach ($nome in $obrigatorias) {
    $p = Join-Path $rulesDir $nome
    if (Test-Path -LiteralPath $p) {
        $bytes = (Get-Item -LiteralPath $p).Length
        if ($bytes -lt 50) {
            $faltando.Add("$nome (ficheiro quase vazio: $bytes bytes)")
        }
        else { $okRegras.Add($nome) }
    }
    else { $faltando.Add($nome) }
}

$noDisco = @()
if (Test-Path -LiteralPath $rulesDir) {
    $noDisco = @(Get-ChildItem -LiteralPath $rulesDir -Filter "*.mdc" -File | ForEach-Object { $_.Name })
}
$extras = @($noDisco | Where-Object { $_ -notin $obrigatorias })

foreach ($rel in $opcionaisRel) {
    $p = Join-Path $projetoDir ($rel -replace "/", "\")
    if (Test-Path -LiteralPath $p) { $opcOk.Add($rel) }
    else { $opcFalta.Add($rel) }
}

$tudoObrigatorioOk = ($faltando.Count -eq 0)
$sucesso = $tudoObrigatorioOk -and ((-not $Severo) -or ($extras.Count -eq 0))

if ($GerarPrompt) {
    $lista = ($obrigatorias -join ", ")
    $prompt = @"
Tarefa: auditoria das regras Cursor deste workspace (projeto-filho Escrita).

1) Leia config/cursor-rules-manifest.json e confirme que existe cada ficheiro em .cursor/rules/ ($lista).
2) Para cada .mdc: verifique frontmatter (description, alwaysApply, globs se existir) e se o conteudo parece truncado ou placeholder.
3) Liste ficheiros .mdc em .cursor/rules/ que NAO estao no manifesto (extras).
4) Se faltar regra ou houver suspeita de copia antiga: diga explicitamente para o analista correr na raiz do projeto: .\scripts\atualizar-projeto.ps1 (pacote distribuicao/ultima-versao ou ZIP do gerente).

Responda em lista: OK / problemas / proximos passos.
"@
    Write-Host $prompt
    exit 0
}

if ($Json) {
    $obj = [ordered]@{
        projetoDir     = $projetoDir
        versaoManifesto = $manifest.versaoManifesto
        obrigatoriasOK = $tudoObrigatorioOk
        faltando       = @($faltando)
        regrasOK       = @($okRegras)
        extrasRules    = @($extras)
        opcionaisOK    = @($opcOk)
        opcionaisFalta = @($opcFalta)
        severoExtras   = $Severo
    }
    Write-Output (($obj | ConvertTo-Json -Depth 4 -Compress))
    exit $(if ($sucesso) { 0 } else { 1 })
}

Write-Host ""
Write-Host "  === Verificacao regras Cursor (.cursor/rules) ===" -ForegroundColor Cyan
Write-Host "  Manifesto: config/cursor-rules-manifest.json (v$($manifest.versaoManifesto))" -ForegroundColor DarkGray
Write-Host ""

foreach ($n in $okRegras) {
    Write-Host "  [OK] .cursor/rules/$n" -ForegroundColor Green
}
foreach ($n in $faltando) {
    Write-Host "  [X]  FALTA ou invalido: $n" -ForegroundColor Red
}
if ($opcOk.Count -gt 0) {
    Write-Host ""
    Write-Host "  Opcionais presentes:" -ForegroundColor DarkGray
    foreach ($n in $opcOk) { Write-Host "    [OK] $n" -ForegroundColor Green }
}
if ($opcFalta.Count -gt 0) {
    Write-Host ""
    Write-Host "  Opcionais em falta (recomendado alinhar ao pacote):" -ForegroundColor DarkYellow
    foreach ($n in $opcFalta) { Write-Host "    [!] $n" -ForegroundColor DarkYellow }
}
if ($extras.Count -gt 0) {
    Write-Host ""
    Write-Host "  Ficheiros .mdc EXTRA (nao estao no manifesto oficial):" -ForegroundColor DarkYellow
    foreach ($n in $extras) { Write-Host "    ? $n" -ForegroundColor DarkYellow }
    if ($Severo) {
        Write-Host "  Modo -Severo: extras contam como falha." -ForegroundColor Red
    }
}

Write-Host ""
if ($sucesso) {
    Write-Host "  Resultado: regras obrigatorias OK." -ForegroundColor Green
    Write-Host "  Dica: para revisao pela IA do conteudo, rode: .\scripts\verificar-regras-cursor.ps1 -GerarPrompt" -ForegroundColor DarkGray
}
else {
    Write-Host "  Resultado: CORRIJA antes de continuar (atualize o projeto-filho)." -ForegroundColor Red
    Write-Host "  Comando: .\scripts\atualizar-projeto.ps1" -ForegroundColor White
}
Write-Host ""

exit $(if ($sucesso) { 0 } else { 1 })
