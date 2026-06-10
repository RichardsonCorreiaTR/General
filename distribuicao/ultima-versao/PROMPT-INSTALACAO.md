# Prompt de Instalacao - Projeto Filho Escrita SDD

> Copie todo o texto abaixo e cole num chat novo do Cursor Agent (em qualquer pasta).
> O agente executara todos os passos e instalara o projeto para voce.

---

Preciso que voce instale o Projeto Filho da Escrita SDD na minha maquina.
Eu ja tenho o OneDrive sincronizado com o SharePoint do CursorEscrita.

Siga estes passos na ordem:

**1. LOCALIZAR O ONEDRIVE**
- Descubra meu usuario Windows (rode: $env:USERNAME)
- O OneDrive deve estar em: C:\Users\{meu-usuario}\Thomson Reuters Incorporated\CursorEscrita - CursorEscrita\General
- Confirme que a pasta existe. Se nao existir, me avise para sincronizar o SharePoint primeiro.
- Confirme que existe a pasta: distribuicao\ultima-versao\ dentro dela.

**2. CRIAR ESTRUTURA LOCAL**
- Crie a pasta C:\CursorEscrita\projeto-filho\
- Copie TODO o conteudo de "distribuicao\ultima-versao\" do OneDrive para C:\CursorEscrita\projeto-filho\
- Crie a pasta C:\CursorEscrita\projeto-filho\referencia\

**3. CONFIGURAR MINHA IDENTIDADE**
- Me pergunte meu nome completo e email (@thomsonreuters.com)
- Edite config\analista.json com meus dados:
  {
    "nome": "MEU NOME",
    "email": "meu.email@thomsonreuters.com",
    "data_setup": "DATA DE HOJE",
    "versao_instalada": "1.1.0",
    "onboarding_completo": false
  }

**4. CONFIGURAR CAMINHOS**
- Crie o arquivo config\caminhos.json com:
  {
    "projeto_local": "C:\\CursorEscrita\\projeto-filho",
    "onedrive_base": "C:\\Users\\{MEU-USUARIO}\\Thomson Reuters Incorporated\\CursorEscrita - General",
    "onedrive_logs": "C:\\Users\\{MEU-USUARIO}\\Thomson Reuters Incorporated\\CursorEscrita - General\\logs\\analistas\\{meu-nome-kebab}"
  }
  (substitua {MEU-USUARIO} pelo meu usuario Windows e {meu-nome-kebab} pelo meu nome em kebab-case sem acentos)
  NOTA v2.4.39: NAO inclua "codigo_local" - a IA consulta o codigo direto no GitHub via gh CLI (passo 8b).

**5. CRIAR LINKS SIMBOLICOS**
- Rode estes comandos:
  cmd /c mklink /J "C:\CursorEscrita\projeto-filho\referencia\banco-dados" "C:\Users\{MEU-USUARIO}\Thomson Reuters Incorporated\CursorEscrita - General\banco-dados"
  cmd /c mklink /J "C:\CursorEscrita\projeto-filho\referencia\logs" "C:\Users\{MEU-USUARIO}\Thomson Reuters Incorporated\CursorEscrita - General\logs\analistas\{meu-nome-kebab}"
  cmd /c mklink /J "C:\CursorEscrita\projeto-filho\referencia\atualizacao" "C:\Users\{MEU-USUARIO}\Thomson Reuters Incorporated\CursorEscrita - General\atualizacao"
- Se o link de logs falhar porque a pasta nao existe no OneDrive, crie a pasta antes.

**6. SETUP PYTHON SGD (OBRIGATORIO para consulta PSAI)**
- Verifique se Python esta disponivel: python --version
- Se Python estiver disponivel (3.10+), rode:
  powershell -File "C:\CursorEscrita\projeto-filho\scripts\setup-sgd-python.ps1"
- Se Python NAO estiver instalado:
  - Me avise: "Python nao encontrado. Instale em https://www.python.org/downloads/ marcando 'Add python.exe to PATH', depois rode: .\scripts\setup-sgd-python.ps1"
  - Continue para o proximo passo mesmo assim.

**7. CREDENCIAIS SGD (OBRIGATORIO - sem isso a consulta de PSAI nao funciona)**
- Informe claramente: "Para consultar PSAIs no SGD e necessario configurar suas credenciais de acesso agora."
- Me pergunte: "Qual e o seu usuario de acesso ao SGD?"
- Aguarde minha resposta com o usuario.
- Me pergunte: "Qual e a sua senha do SGD? (sera salva localmente apenas neste PC, nunca enviada para nenhum servidor)"
- Aguarde minha resposta com a senha.
- Crie a pasta: C:\CursorEscrita\projeto-filho\data\sgd-psai-consultas\
- Crie o arquivo C:\CursorEscrita\projeto-filho\data\sgd-psai-consultas\.sgd-credentials.local com exatamente este conteudo (sem espacos extras):
  SGD_USERNAME={usuario-informado}
  SGD_PASSWORD="{senha-informada}"
- Confirme: "Credenciais SGD salvas. A consulta de PSAI usara essas credenciais automaticamente."
- IMPORTANTE: se eu nao souber minha senha agora, crie o arquivo apenas com o usuario e deixe a senha em branco. Oriente a preencher depois editando o arquivo diretamente.

**8. VERIFICAR AMBIENTE**
- Rode: powershell -File "C:\CursorEscrita\projeto-filho\scripts\verificar-ambiente.ps1"
- Me mostre o resultado.

**8b. ACESSO AO GITHUB (BR Contabil / codigo-fonte)**
- Verifique se o `gh CLI` esta instalado: gh --version
- Se nao estiver: oriente `winget install --id GitHub.cli` e reabrir o PowerShell.
- Verifique autenticacao: gh auth status
- Se nao autenticado, oriente: gh auth login --web --hostname github.com (com conta TR corporativa).
- Teste o acesso ao repo: gh repo view tr/brtap-dominio_contabil --json name
- Se voltar 404, informe que falta liberacao no Team `fiscont-gp-codigo-leitura` (Fernando Pizetti).
- NUNCA pedir token/PAT no chat. Setup completo em: C:\CursorEscrita\projeto-filho\SETUP-GITHUB.md

**9. INSTRUCOES FINAIS**
- Me diga para fechar esta janela do Cursor
- Me diga para abrir o Cursor de novo em: File > Open Folder > C:\CursorEscrita\projeto-filho
- Ao abrir, a IA vai me receber com o wizard de onboarding automaticamente

Comece pelo passo 1. Antes de executar qualquer coisa, me confirme o que vai fazer.
