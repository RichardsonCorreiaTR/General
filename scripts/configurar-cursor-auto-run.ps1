#Requires -Version 5.1
<#
.SYNOPSIS
  Ajuda a reduzir pedidos de "Run" no Cursor Agent (terminal).

.DESCRIPTION
  1) Lembra de definir Cursor Settings > Agents > Auto-Run > "Run in Sandbox" (recomendado) ou "Run Everything".
  2) Se ainda nao existir %USERPROFILE%\.cursor\permissions.json, copia .cursor\permissions.json.example
     da raiz do repositorio aberto (General ou projeto-filho).

  O ficheiro permissions.json e GLOBAL (por utilizador), nao por pasta; a copia e opcional e so na primeira vez.

.EXAMPLE
  .\scripts\configurar-cursor-auto-run.ps1
#>
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path (Join-Path $scriptDir "..")
$example = Join-Path $repoRoot ".cursor\permissions.json.example"
$cursorUser = Join-Path $env:USERPROFILE ".cursor"
$target = Join-Path $cursorUser "permissions.json"

Write-Host ""
Write-Host "=== Cursor Agent: menos confirmacoes no terminal ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "1) No Cursor: Settings (Ctrl+,) > Agents > Auto-Run" -ForegroundColor White
Write-Host "   - Recomendado: Run in Sandbox" -ForegroundColor Green
Write-Host "   - Windows: instale WSL2 para o sandbox funcionar bem (docs Cursor > Terminal)." -ForegroundColor DarkGray
Write-Host "   - Maximo sem perguntas: Run Everything (maior risco; use so se aceitar)." -ForegroundColor Yellow
Write-Host ""
Write-Host "2) Allowlist global (opcional): $target" -ForegroundColor White
Write-Host "   So aplica com Auto-Run Sandbox ou Run Everything (nao em Ask Every Time)." -ForegroundColor DarkGray

if (-not (Test-Path -LiteralPath $example)) {
    Write-Warning "Exemplo nao encontrado: $example"
    exit 0
}

New-Item -ItemType Directory -Force -Path $cursorUser | Out-Null
if (Test-Path -LiteralPath $target) {
    Write-Host "Ja existe: $target - nao alterado (edite manualmente se quiser o exemplo)." -ForegroundColor DarkYellow
} else {
    Copy-Item -LiteralPath $example -Destination $target -Force
    Write-Host "Criado: $target (a partir do exemplo do repo)." -ForegroundColor Green
}
Write-Host ""
Write-Host "Este repo ja inclui .cursor/sandbox.json (rede permitida no sandbox + cache partilhado)." -ForegroundColor DarkGray
Write-Host ""
