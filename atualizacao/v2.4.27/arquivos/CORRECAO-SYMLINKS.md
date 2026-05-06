# Correcao de Symlinks -- Guia para o Agente

> Este arquivo e consultado pelo agente IA quando o analista reporta
> problemas de acesso a base de SAIs ou indices indisponiveis.
> Localizado em: projeto-filho/CORRECAO-SYMLINKS.md (OneDrive sincroniza)

## Diagnostico rapido

Rode estes testes no terminal para identificar o problema:

```powershell
# 1. Symlink do banco-dados existe?
Test-Path "referencia\banco-dados"

# 2. Indices de SAIs acessiveis?
Test-Path "referencia\banco-dados\sais\indices\README.md"

# 3. caminhos.json tem onedrive_base preenchido?
(Get-Content "config\caminhos.json" -Raw | ConvertFrom-Json).onedrive_base

# 4. OneDrive esta sincronizado?
Test-Path "$env:USERPROFILE\Thomson Reuters Incorporated\CursorEscrita - General\banco-dados"
```

## Resultados possiveis e acoes

### Cenario A: Symlink nao existe (Test-Path referencia\banco-dados = False)

Causa: Instalacao nao criou os links, ou falhou silenciosamente.

Solucao: Rodar o script de reparo.

```powershell
Set-ExecutionPolicy Bypass -Scope Process
.\scripts\corrigir-symlinks.ps1
```

Se o script corrigir-symlinks.ps1 nao existir, siga os passos manuais
da secao "Correcao manual" abaixo.

### Cenario B: OneDrive nao sincronizado (Test-Path retorna False)

Causa: O analista nao sincronizou o SharePoint com o OneDrive.

Solucao: Orientar o analista a:
1. Abrir no navegador: https://trten.sharepoint.com/sites/CursorEscrita
2. Clicar em Documentos > General > Sincronizar
3. Aguardar o OneDrive sincronizar
4. Rodar o corrigir-symlinks.ps1 novamente

### Cenario C: caminhos.json vazio (onedrive_base = "")

Causa: Instalacao parcial ou copia manual sem rodar instalador.

Solucao: O corrigir-symlinks.ps1 tambem corrige isso automaticamente.
Se nao existir, preencher manualmente:

```json
{
  "projeto_local": "C:\\CursorEscrita\\projeto-filho",
  "codigo_local": "C:\\CursorEscrita\\codigo-sistema\\versao-atual",
  "onedrive_base": "C:\\Users\\{USUARIO}\\Thomson Reuters Incorporated\\CursorEscrita - General",
  "onedrive_logs": "C:\\Users\\{USUARIO}\\Thomson Reuters Incorporated\\CursorEscrita - General\\logs\\analistas\\{nome-kebab}"
}
```

Substituir {USUARIO} pelo usuario do Windows e {nome-kebab} pelo nome
do analista em kebab-case sem acentos (ex: ana-ligia-silva).

### Cenario D: Erro de permissao ao criar symlink

Causa: Windows exige admin para criar links simbolicos em alguns ambientes corporativos.

Solucao: O analista deve abrir PowerShell como Administrador e rodar:

```powershell
cd "C:\CursorEscrita\projeto-filho\referencia"
cmd /c mklink /J "banco-dados" "C:\Users\{USUARIO}\Thomson Reuters Incorporated\CursorEscrita - General\banco-dados"
cmd /c mklink /J "logs" "C:\Users\{USUARIO}\Thomson Reuters Incorporated\CursorEscrita - General\logs\analistas\{nome-kebab}"
```

## Correcao manual (passo a passo)

Se o script corrigir-symlinks.ps1 nao existir na maquina do analista:

### Passo 1: Descobrir o caminho do OneDrive

```powershell
$paths = @(
    "$env:USERPROFILE\Thomson Reuters Incorporated\CursorEscrita - General",
    "$env:OneDriveCommercial\Thomson Reuters Incorporated\CursorEscrita - General",
    "$env:OneDrive\Thomson Reuters Incorporated\CursorEscrita - General"
)
$found = $paths | Where-Object { $_ -and (Test-Path (Join-Path $_ "banco-dados")) } | Select-Object -First 1
Write-Host "OneDrive: $found"
```

Se nenhum caminho for encontrado, o OneDrive nao esta sincronizado (cenario B).

### Passo 2: Criar pasta referencia

```powershell
New-Item -ItemType Directory -Path "C:\CursorEscrita\projeto-filho\referencia" -Force
```

### Passo 3: Criar junction para banco-dados

```powershell
cmd /c mklink /J "C:\CursorEscrita\projeto-filho\referencia\banco-dados" "{CAMINHO-DO-ONEDRIVE}\banco-dados"
```

### Passo 4: Criar junction para logs

```powershell
$analista = (Get-Content "C:\CursorEscrita\projeto-filho\config\analista.json" -Raw | ConvertFrom-Json).nome
$nomeKebab = ($analista -replace '[aàáâãä]','a' -replace '[eèéêë]','e' -replace '[iìíîï]','i' -replace '[oòóôõö]','o' -replace '[uùúûü]','u' -replace '[cç]','c' -replace '\s+','-' -replace '[^a-zA-Z0-9-]','').ToLower()
$logsPath = "{CAMINHO-DO-ONEDRIVE}\logs\analistas\$nomeKebab"
New-Item -ItemType Directory -Path $logsPath -Force
cmd /c mklink /J "C:\CursorEscrita\projeto-filho\referencia\logs" "$logsPath"
```

### Passo 5: Atualizar caminhos.json

```powershell
$caminhos = Get-Content "C:\CursorEscrita\projeto-filho\config\caminhos.json" -Raw | ConvertFrom-Json
$caminhos.onedrive_base = "{CAMINHO-DO-ONEDRIVE}"
$caminhos.onedrive_logs = "$logsPath"
$caminhos | ConvertTo-Json -Depth 2 | Set-Content "C:\CursorEscrita\projeto-filho\config\caminhos.json" -Encoding UTF8
```

### Passo 6: Verificar

```powershell
.\scripts\verificar-ambiente.ps1
```

Os itens "referencia/banco-dados (symlink)" e "referencia/logs (symlink)"
devem aparecer como [OK].

## Verificacao pos-correcao

Apos corrigir, confirme que os indices estao acessiveis:

```powershell
Test-Path "referencia\banco-dados\sais\indices\README.md"
Get-ChildItem "referencia\banco-dados\sais\indices\*.md" | Measure-Object | Select-Object -ExpandProperty Count
```

Esperado: True e pelo menos 12 arquivos .md.

## Se nada funcionar

Orientar o analista a procurar o gerente de projeto (Ana Ligia) informando:
- Resultado do .\scripts\verificar-ambiente.ps1
- Usuario do Windows ($env:USERNAME)
- Se OneDrive esta sincronizado ou nao
