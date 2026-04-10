# lib-lock.ps1
# Mecanismo de lock para evitar atualizacoes simultaneas via OneDrive

function Get-LockPath {
    param([string]$ProjetoDir)
    return Join-Path $ProjetoDir "scripts\.update-lock.json"
}

function Request-Lock {
    param([string]$ProjetoDir, [string]$Operacao)
    $lockFile = Get-LockPath $ProjetoDir
    
    if (Test-Path $lockFile) {
        $lock = Get-Content $lockFile -Raw | ConvertFrom-Json
        $lockAge = (Get-Date) - [datetime]$lock.iniciadoEm
        
        # Lock expira em 30 minutos (protecao contra crash)
        if ($lockAge.TotalMinutes -lt 30) {
            Write-Host "BLOQUEADO: $($lock.usuario) esta atualizando ($($lock.operacao))" -ForegroundColor Red
            Write-Host "  Iniciado em: $($lock.iniciadoEm)"
            Write-Host "  Ha $([math]::Round($lockAge.TotalMinutes, 0)) minutos"
            Write-Host ""
            Write-Host "Se voce tem certeza que ninguem esta atualizando, delete:"
            Write-Host "  $lockFile"
            return $false
        }
        Write-Host "Lock antigo encontrado (expirado). Removendo..." -ForegroundColor DarkYellow
    }
    
    $lockData = @{
        usuario = $env:USERNAME
        computador = $env:COMPUTERNAME
        operacao = $Operacao
        iniciadoEm = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    } | ConvertTo-Json
    Set-Content -Path $lockFile -Value $lockData -Encoding UTF8
    return $true
}

function Release-Lock {
    param([string]$ProjetoDir)
    $lockFile = Get-LockPath $ProjetoDir
    if (Test-Path $lockFile) {
        Remove-Item $lockFile -Force
    }
}
