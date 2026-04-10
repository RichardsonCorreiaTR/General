@echo off
echo ============================================
echo   Atualizador Escrita SDD - SAIs + Codigo
echo ============================================
echo.
echo   ATENCAO: Rode em terminal SEPARADO
echo   (PowerShell ou CMD fora do Cursor).
echo.
echo   O que ele faz:
echo   - Extrai SAIs/PSAIs do banco via ODBC
echo     (fallback: BuscaSAI em Programas\BuscaSAI se ODBC indisponivel)
echo   - Gera indices navegaveis em banco-dados/sais/indices/
echo   - Atualiza codigo-fonte PB (local, nao OneDrive)
echo   - Tudo sincroniza via OneDrive para os analistas
echo ============================================
echo.
pause

echo [1/2] Importando SAIs/PSAIs (ODBC direto)...
powershell -ExecutionPolicy Bypass -File "%~dp0importar-sais.ps1" -Incremental
echo.
echo [2/2] Atualizando codigo-fonte (local)...
powershell -ExecutionPolicy Bypass -File "%~dp0atualizar-codigo.ps1"
echo.
echo === Tudo atualizado! ===
echo SAIs e indices no OneDrive (sincroniza para todos).
pause
