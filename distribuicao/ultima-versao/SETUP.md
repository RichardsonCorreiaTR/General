# Guia de Configuracao Inicial -- Projeto Filho

## Antes de comecar

Voce precisa de:
- **Cursor** instalado (https://cursor.sh)
- **OneDrive** instalado e logado na conta corporativa
- **Acesso ao SharePoint** do CursorEscrita (o gerente vai te adicionar)
- **Git** instalado (https://git-scm.com) -- opcional, para baixar o codigo-fonte

## Instalacao Automatica (Recomendado)

### Passo 1 -- Sincronizar o OneDrive

O gerente vai te dar acesso ao SharePoint. Depois:

1. Abra no navegador: https://trten.sharepoint.com/sites/CursorEscrita
2. Clique em **Documentos** > **General**
3. Clique em **Sincronizar** (botao no topo)
4. Aguarde o OneDrive sincronizar a pasta
5. Ela vai aparecer em: `C:\Users\{seu-usuario}\Thomson Reuters Incorporated\CursorEscrita - General`

### Passo 2 -- Rodar o instalador

Abra o **PowerShell** e rode os comandos abaixo:

```
cd "C:\Users\{seu-usuario}\Thomson Reuters Incorporated\CursorEscrita - General"
Set-ExecutionPolicy Bypass -Scope Process
.\scripts\instalar-projeto-filho.ps1
```

O instalador vai:
1. Verificar pre-requisitos (Cursor, OneDrive, Git, Python)
2. Criar a estrutura em `C:\CursorEscrita\projeto-filho\`
3. Pedir seu nome e email
4. Criar links para a base de dados no OneDrive
5. Baixar o codigo-fonte do sistema (se Git disponivel)
6. Verificar se tudo esta OK
7. Salvar credenciais SGD (opcional)
8. Configurar ambiente Python/Playwright para consulta PSAI (se Python encontrado)
9. Abrir o Cursor

> **Python obrigatorio para consulta PSAI no SGD.** Instale Python 3.10+ antes de rodar o instalador:
> https://www.python.org/downloads/ — marque **"Add python.exe to PATH"** durante a instalacao.

### Passo 3 -- Primeiro uso

1. O Cursor abre em `C:\CursorEscrita\projeto-filho\`
2. A IA inicia o **wizard de onboarding** automaticamente
3. Siga as orientacoes -- ela vai te apresentar o projeto e os comandos

### Consulta PSAI no SGD (`Consultar-PSAI-SGD.ps1`)

O modulo Python fica em **`projeto-filho\scripts\sgd_consulta\`** (incluido no pacote).

O instalador configura o ambiente Python automaticamente. Se precisar refazer (ou o instalador pulou por Python ausente), rode:

```
cd C:\CursorEscrita\projeto-filho
.\scripts\setup-sgd-python.ps1
```

O script cria o `.venv`, instala dependencias e faz `playwright install chromium`.

Depois: `.\scripts\Consultar-PSAI-SGD.ps1 <numero-psai>`

## Instalacao Manual (se o instalador falhar)

### Pre-requisitos

- [ ] Cursor instalado (https://cursor.sh)
- [ ] OneDrive configurado e sincronizando
- [ ] Acesso ao SharePoint do CursorEscrita
- [ ] Git instalado (https://git-scm.com) -- opcional

### Passo 1 -- Copiar o projeto

Copie toda a pasta `projeto-filho/` para `C:\CursorEscrita\projeto-filho\`.

### Passo 2 -- Configurar sua identificacao

Edite `config/analista.json`:

```json
{
  "nome": "Seu Nome Completo",
  "email": "seu.email@thomsonreuters.com",
  "data_setup": "2026-03-04",
  "versao_instalada": "1.0.0",
  "onboarding_completo": false
}
```

### Passo 3 -- Configurar caminhos

Edite `config/caminhos.json` com seus paths:

```json
{
  "projeto_local": "C:\\CursorEscrita\\projeto-filho",
  "codigo_local": "C:\\CursorEscrita\\codigo-sistema\\versao-atual",
  "onedrive_base": "C:\\Users\\SEU-USUARIO\\Thomson Reuters Incorporated\\CursorEscrita - General",
  "onedrive_logs": "C:\\Users\\SEU-USUARIO\\Thomson Reuters Incorporated\\CursorEscrita - General\\logs\\analistas\\seu-nome"
}
```

### Passo 4 -- Sincronizar OneDrive

1. Abra o SharePoint: https://trten.sharepoint.com/sites/CursorEscrita
2. Sincronize a pasta `General`
3. Ela aparecera em: `C:\Users\{seu-usuario}\Thomson Reuters Incorporated\CursorEscrita - General`

### Passo 5 -- Criar links simbolicos

Abra PowerShell e rode:

```
cd "C:\CursorEscrita\projeto-filho\referencia"
cmd /c mklink /J "banco-dados" "C:\Users\{seu-usuario}\Thomson Reuters Incorporated\CursorEscrita - General\banco-dados"
cmd /c mklink /J "logs" "C:\Users\{seu-usuario}\Thomson Reuters Incorporated\CursorEscrita - General\logs\analistas\{seu-nome-kebab}"
```

### Passo 6 -- Abrir no Cursor

1. Abra o Cursor
2. File -> Open Folder -> selecione `C:\CursorEscrita\projeto-filho\`
3. As regras da IA carregam automaticamente
4. A IA iniciara o wizard de onboarding

## Verificacao

Rode para confirmar que tudo esta OK:

```
.\scripts\verificar-ambiente.ps1
```

## Atualizacao

Para atualizar o projeto quando o gerente publicar nova versao:

```
.\scripts\atualizar-projeto.ps1
```

## Buscar SAIs

Em terminal separado (fora do Cursor):

```
cd "C:\CursorEscrita\projeto-filho"
powershell -File scripts\buscar-sai.ps1 -Termo "INSS"
```

## Problemas comuns

| Problema | Solucao |
|----------|---------|
| "Cursor nao encontrado" | Instale em https://cursor.sh e reinicie o terminal |
| "OneDrive nao sincronizou" | Abra o SharePoint e clique em Sincronizar novamente |
| "Falha ao criar symlink" | Rode o PowerShell como Administrador |
| "Git nao encontrado" | Instale git-scm.com ou use `-PularCodigo` no instalador |
| "ODBC nao encontrado" | Normal se voce nao precisa de acesso direto ao banco |
