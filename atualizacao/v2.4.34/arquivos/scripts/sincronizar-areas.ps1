# Sincronizar areas do analista
# Re-le o cadastro central (config/time-analistas.json no OneDrive/General)
# e atualiza config/analista.json local com as areas oficiais.
#
# Quando rodar:
# - Apos o gerente reclassificar as areas no Admin
# - Quando as buscas estiverem retornando areas erradas
# - Apos atualizar para uma versao que ainda nao re-sincroniza automaticamente
#
# Uso:
#   .\scripts\sincronizar-areas.ps1
#   .\scripts\sincronizar-areas.ps1 -Confirmar:$false   # nao pede confirmacao

param(
    [switch]$Confirmar = $true
)

$ErrorActionPreference = "Stop"

function Write-OK    { param($m) Write-Host "  [OK]    $m" -ForegroundColor Green }
function Write-Warn  { param($m) Write-Host "  [AVISO] $m" -ForegroundColor Yellow }
function Write-Fail  { param($m) Write-Host "  [ERRO]  $m" -ForegroundColor Red }
function Write-Info  { param($m) Write-Host "  $m" -ForegroundColor Cyan }

Write-Host ""
Write-Host "=== Sincronizar areas do analista ===" -ForegroundColor Cyan
Write-Host ""

# 1) Caminhos locais
$projetoDir   = Split-Path -Parent $PSScriptRoot
$analistaFile = Join-Path $projetoDir "config\analista.json"
$caminhosFile = Join-Path $projetoDir "config\caminhos.json"

if (-not (Test-Path $analistaFile)) {
    Write-Fail "config/analista.json nao encontrado. Rode primeiro o instalador."
    exit 1
}

# 2) Descobrir caminho do OneDrive (via caminhos.json ou descoberta)
function Find-OneDrivePath {
    if (Test-Path $caminhosFile) {
        try {
            $c = Get-Content $caminhosFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($c.onedrive_base -and (Test-Path (Join-Path $c.onedrive_base "config\time-analistas.json"))) {
                return $c.onedrive_base
            }
        } catch {}
    }
    $candidatos = @(
        "$env:USERPROFILE\Thomson Reuters Incorporated\CursorEscrita - General",
        "$env:USERPROFILE\Thomson Reuters Incorporated\CursorEscrita - Documentos\General",
        "$env:OneDriveCommercial\Thomson Reuters Incorporated\CursorEscrita - General",
        "$env:OneDriveCommercial\Thomson Reuters Incorporated\CursorEscrita - Documentos\General",
        "$env:OneDrive\Thomson Reuters Incorporated\CursorEscrita - General",
        "$env:OneDrive\Thomson Reuters Incorporated\CursorEscrita - Documentos\General"
    )
    foreach ($p in $candidatos) {
        if ($p -and (Test-Path (Join-Path $p "config\time-analistas.json"))) { return $p }
    }
    return $null
}

$onedrive = Find-OneDrivePath
if (-not $onedrive) {
    Write-Fail "Nao localizei o OneDrive (CursorEscrita - General)."
    Write-Info "Verifique se o OneDrive esta rodando e sincronizado."
    exit 1
}
$timeFile = Join-Path $onedrive "config\time-analistas.json"
Write-OK "Cadastro central: $timeFile"

# 3) Ler config local
$analista = Get-Content $analistaFile -Raw -Encoding UTF8 | ConvertFrom-Json
$areasLocais = @()
if ($analista.areas) { $areasLocais = @($analista.areas) }

Write-Host ""
Write-Info "Identidade local: $($analista.nome) <$($analista.email)>"
Write-Info "Areas atuais (locais): $($areasLocais -join ', ')"

# 4) Ler cadastro central
$time = Get-Content $timeFile -Raw -Encoding UTF8 | ConvertFrom-Json
$registro = $time | Where-Object {
    ($_.email -and $_.email -eq $analista.email) -or
    ($_.nome  -and $_.nome  -eq $analista.nome)
} | Select-Object -First 1

if (-not $registro) {
    Write-Warn "Voce nao esta cadastrado no time-analistas.json central."
    Write-Info "Peca ao gerente de produto para incluir seu nome/email/areas."
    exit 0
}
if (-not $registro.areas -or $registro.areas.Count -eq 0) {
    Write-Warn "Voce esta cadastrado, mas sem areas no central. Mantendo areas locais."
    exit 0
}

$areasCentrais = @($registro.areas)
Write-Info "Areas no central:      $($areasCentrais -join ', ')"

# 5) Comparar
$dif = Compare-Object -ReferenceObject $areasLocais -DifferenceObject $areasCentrais
if (-not $dif) {
    Write-Host ""
    Write-OK "Suas areas locais ja estao iguais ao cadastro central. Nada a fazer."
    exit 0
}

Write-Host ""
Write-Warn "Areas locais e centrais estao diferentes:"
foreach ($d in $dif) {
    $marca = if ($d.SideIndicator -eq "=>") { "+ adicionar (esta no central)" } else { "- remover (so esta local)" }
    Write-Host "    $marca : $($d.InputObject)" -ForegroundColor Yellow
}

# 6) Confirmar
if ($Confirmar) {
    Write-Host ""
    $resp = Read-Host "  Atualizar areas locais para refletir o cadastro central? (S/N)"
    if ($resp -notmatch '^(s|sim|y|yes)$') {
        Write-Info "Cancelado pelo usuario."
        exit 0
    }
}

# 7) Backup + salvar
$backupFile = "$analistaFile.bak"
Copy-Item -Path $analistaFile -Destination $backupFile -Force
Write-OK "Backup salvo: $backupFile"

$analista.areas = $areasCentrais
$analista | ConvertTo-Json -Depth 5 | Set-Content -Path $analistaFile -Encoding UTF8 -Force
Write-OK "config/analista.json atualizado."

Write-Host ""
Write-OK "Pronto! Suas areas agora sao: $($areasCentrais -join ', ')"
