# Configurar outro projeto para usar o projeto-filho

O outro workspace **nao precisa** ter a base de SAIs nem o clone do BR Contabil. Ele so escreve pedidos e le respostas.

## 1. Caminho do projeto-filho nesta maquina

Padrao no PC do analista: `C:\CursorEscrita\projeto-filho`

No repositorio Admin (General), a copia de desenvolvimento fica em `projeto-filho\` na raiz do General.

Copie `caminhos-filho.json.example` para o **outro** projeto, por exemplo:

`config/caminhos-filho.json`

Ajuste o caminho se a instalacao for diferente.

## 2. Copiar a regra da IA

Copie `consultar-projeto-filho.mdc` para:

`{outro-projeto}/.cursor/rules/consultar-projeto-filho.mdc`

## 3. Copiar os scripts (opcional, mas recomendado)

Copie `solicitar-consulta.ps1` e `ler-resultado.ps1` para uma pasta de scripts do outro projeto.

## 4. Enviar um pedido

No PowerShell do outro projeto:

```
powershell -File .\scripts\solicitar-consulta.ps1 -FilhoRoot "C:\CursorEscrita\projeto-filho" -Tipo sai -Termo "ICMS ST" -Origem "meu-projeto"
```

Pesquisa de codigo:

```
powershell -File .\scripts\solicitar-consulta.ps1 -FilhoRoot "C:\CursorEscrita\projeto-filho" -Tipo codigo -Query "of_calcular_icms" -Origem "meu-projeto"
```

Ler um arquivo na branch vigente:

```
powershell -File .\scripts\solicitar-consulta.ps1 -FilhoRoot "C:\CursorEscrita\projeto-filho" -Tipo ler-arquivo -Arquivo "escrita/caminho/arquivo.sru" -Origem "meu-projeto"
```

## 5. Processar (lado do filho)

No projeto-filho (terminal ou chat da IA):

```
powershell -File .\scripts\processar-consultas-externas.ps1
```

Quem processa precisa de: OneDrive com `referencia\banco-dados` (SAI) e `gh` autenticado (codigo).

## 6. Ler o resultado

```
powershell -File .\scripts\ler-resultado.ps1 -FilhoRoot "C:\CursorEscrita\projeto-filho" -Id ID-RETORNADO
```

O JSON fica em `projeto-filho\consultas-externas\saida\{id}.json`.

## Atalho na mesma maquina (sem fila)

O agente do outro projeto pode chamar direto (sem esperar o filho):

```
powershell -File "C:\CursorEscrita\projeto-filho\scripts\buscar-sai.ps1" -Termo "INSS" -JsonOut ".\sai-resultado.json" -Max 20
```

Codigo: usar `gh api` com a branch de `C:\CursorEscrita\projeto-filho\config\codigo-fonte-branches.json`.
