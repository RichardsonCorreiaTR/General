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
    "codigo_local": "C:\\CursorEscrita\\codigo-sistema\\versao-atual",
    "onedrive_base": "C:\\Users\\{MEU-USUARIO}\\Thomson Reuters Incorporated\\CursorEscrita - General",
    "onedrive_logs": "C:\\Users\\{MEU-USUARIO}\\Thomson Reuters Incorporated\\CursorEscrita - General\\logs\\analistas\\{meu-nome-kebab}"
  }
  (substitua {MEU-USUARIO} pelo meu usuario Windows e {meu-nome-kebab} pelo meu nome em kebab-case sem acentos)

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

**7. CREDENCIAIS SGD (OBRIGATORIO para consulta PSAI)**
- Me pergunte: "Deseja salvar seu usuario e senha do SGD neste PC para nao precisar digitar a cada consulta? (S/N)"
- Se SIM:
  - Me pergunte meu usuario do SGD
  - Me pergunte minha senha do SGD (avise que ficara salva localmente, nunca vai para o Git)
  - Crie a pasta: C:\CursorEscrita\projeto-filho\data\sgd-psai-consultas\
  - Crie o arquivo C:\CursorEscrita\projeto-filho\data\sgd-psai-consultas\.sgd-credentials.local com o conteudo:
    SGD_USERNAME={meu-usuario-sgd}
    SGD_PASSWORD="{minha-senha-sgd}"
  - Confirme: "Credenciais salvas. A consulta PSAI usara essas credenciais automaticamente."
- Se NAO:
  - Informe: "OK. Na primeira consulta de PSAI o sistema vai pedir seu usuario e senha. Voce pode salvar depois rodando: .\scripts\Consultar-PSAI-SGD.ps1 <numero>"

**8. VERIFICAR AMBIENTE**
- Rode: powershell -File "C:\CursorEscrita\projeto-filho\scripts\verificar-ambiente.ps1"
- Me mostre o resultado.

**9. INSTRUCOES FINAIS**
- Me diga para fechar esta janela do Cursor
- Me diga para abrir o Cursor de novo em: File > Open Folder > C:\CursorEscrita\projeto-filho
- Ao abrir, a IA vai me receber com o wizard de onboarding automaticamente

Comece pelo passo 1. Antes de executar qualquer coisa, me confirme o que vai fazer.
