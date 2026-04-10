# Spec Tecnica - Fase 2: Smart Rewrite + Eliminar Monolitico

> Gerado em: 07/03/2026
> Base: PLANO.md secao Fase 2 + analise dos 3 scripts

---

## 1. RESUMO

Tres mudancas principais:
A) Smart rewrite: nao reescrever arquivo se conteudo identico (reducao sync)
B) Monolitico para scripts/cache/ (fora do OneDrive, -165 MB sync)
C) gerar-indices-sais.ps1 processa fracionados em vez do monolitico (-73% RAM)

---

## 2. ARQUIVOS A CRIAR

### 2.1 scripts/cache/ (diretorio)
Local para monolitico fora do OneDrive. Criado automaticamente.

---

## 3. ARQUIVOS A ALTERAR

### 3.1 scripts/extrair-sais.ps1

#### Mudanca 1: Destino do monolitico
ANTES: Salvar-CacheFinal grava em banco-dados/dados-brutos/sai-psai-folha.json
DEPOIS: Gravar em scripts/cache/sai-psai-folha.json

Na funcao Salvar-CacheFinal (~linha 436):
- Mudar $destinoJson para scripts/cache/sai-psai-folha.json
- Criar scripts/cache/ se nao existir

#### Mudanca 2: Gerar fracionados apos salvar cache
DEPOIS de Salvar-CacheFinal, adicionar funcao Gravar-Fracionados que:
1. Recebe $registros (mesmo array do monolitico)
2. Para cada tipo (NE/SAM/SAL/SAIL) x status (pendentes/liberadas/descartadas):
   a. Filtra registros
   b. Gera PSAI JSON (todos os registros)
   c. Gera SAI JSON (agrupado por i_sai, registro mais recente)
   d. Usa Smart-Write (nao reescreve se identico)
3. Escreve em banco-dados/dados-brutos/psai/ e sai/

Logica de fracionamento: COPIAR da Fase A atual do gerar-indices-sais.ps1
(linhas 41-99 do script atual)

#### Mudanca 3: Flag --GerarMonolitico (D2)
Adicionar parametro [switch]$GerarMonolitico
Se ativado: TAMBEM grava monolitico em banco-dados/dados-brutos/ (backup)
Se nao ativado: so grava em scripts/cache/

#### Mudanca 4: Smart-Write no extrair-sais.ps1
Funcao auxiliar:
```
function Smart-Write($path, $content) {
    if (Test-Path $path) {
        $existing = Get-Content $path -Raw -Encoding UTF8
        if ($existing -eq $content) { return $false }
    }
    Set-Content -Path $path -Value $content -Encoding UTF8
    return $true
}
```

### 3.2 scripts/gerar-indices-sais.ps1

#### Mudanca 1: Remover Fase A (fracionamento)
REMOVER: Linhas 41-99 (Fase A inteira)
MOTIVO: Fracionamento agora feito por extrair-sais.ps1

#### Mudanca 2: Carregar fracionados em vez do monolitico
ANTES (linhas 16-33):
  $cacheFile = dados-brutos/sai-psai-folha.json
  $json = Get-Content $cacheFile | ConvertFrom-Json
  $dados = $json.dados (29K registros, ~2 GB RAM)

DEPOIS:
  Carregar PSAI fracionados um por vez para flat indices.
  Acumular dados leves para cross-cutting indices.
  Pico RAM: ~550 MB.

Fluxo novo:
```
1. Inicializacao (paths, keywords)
2. $acumDados = @()   (acumulador leve)
3. $total = 0
4. Para cada arquivo PSAI fracionado:
   a. $fileJson = ler arquivo
   b. $fileDados = $fileJson.dados
   c. Gerar flat index para este tipo+status
   d. Acumular dados leves:
      Para cada item em $fileDados:
        $acumDados += @{
          i_sai=$_.i_sai; i_psai=$_.i_psai; tipoSAI=$_.tipoSAI
          sai_descricao=$_.sai_descricao; nomeVersao=$_.nomeVersao
          gravidade_ne=$_.gravidade_ne; CadastroPSAI=$_.CadastroPSAI
          Liberacao=$_.Liberacao; Descarte=$_.Descarte
          situacaoSai=$_.situacaoSai
        }
   e. $total += $fileDados.Count
   f. $fileDados = $null; [GC]::Collect()
5. Gerar cross-cutting indices de $acumDados:
   - B3: por-versao
   - B4: estatisticas
   - B5: classificacao multi-modulo + por-modulo + modulos + resumo
   - B6: por-rubrica
   - B8: orfaos
   - B7: README
```

#### Mudanca 3: Smart-Write para TODOS os outputs MD
Substituir Set-Content por Smart-Write em TODA geracao de MD.
Contar: arquivos escritos vs pulados. Exibir no final.

#### Mudanca 4: Atualizar cabecalho e mensagens
Remover referencia ao monolitico e ~2GB RAM.
Novo comentario: "Processa fracionados (~550 MB pico)"

### 3.3 scripts/importar-sais.ps1

#### Mudanca 1: Ajustar verificacao de cache
ANTES: Verifica banco-dados/dados-brutos/sai-psai-folha.json
DEPOIS: Verifica scripts/cache/sai-psai-folha.json

#### Mudanca 2: Metadados atualizados
importacao-meta.json: adicionar campo "fracionados" com contagem de arquivos.

---

## 4. ARQUIVOS MOVIDOS

### 4.1 sai-psai-folha.json
DE: banco-dados/dados-brutos/sai-psai-folha.json (OneDrive, 165 MB)
PARA: scripts/cache/sai-psai-folha.json (local, fora do sync)

NOTA: Nao apagar o original imediatamente. Mover apos teste bem-sucedido.
O arquivo em banco-dados/ fica como backup ate Fase 4.

---

## 5. DEPENDENCIAS E ORDEM

1. Adicionar Smart-Write e fracionamento ao extrair-sais.ps1
2. Remover Fase A e refatorar loading do gerar-indices-sais.ps1
3. Ajustar importar-sais.ps1
4. Testar: rodar importar-sais.ps1 e verificar resultados

---

## 6. CRITERIOS DE SUCESSO MENSURAVEIS

| Criterio | Meta | Como medir |
|----------|------|------------|
| Monolitico em scripts/cache/ | Existe | Test-Path |
| Monolitico em dados-brutos/ | NAO existe (ou nao regravado) | LastWriteTime |
| Fracionados PSAI | 12 arquivos | Contar |
| Fracionados SAI | 12 arquivos | Contar |
| Smart rewrite: arquivos pulados | mais que 30 de ~58 | Contar no output |
| RAM pico gerar-indices | menor que 700 MB | Get-Process |
| Indices MD identicos aos da Fase 1 | TODOS | Comparar conteudo |
| Flag --GerarMonolitico | Funciona | Testar |
| Tempo execucao | menor que 5 min | Medir |

---

## 7. PLANO DE TESTE

1. Salvar snapshot dos indices atuais (MD5 de cada arquivo)
2. Rodar importar-sais.ps1 (que chama extrair + gerar-indices)
3. Verificar:
   - Monolitico em scripts/cache/? Tamanho correto?
   - Fracionados gerados? Mesmos dados?
   - Indices MD: conteudo identico ao pre-teste?
   - Smart rewrite: quantos arquivos pulados?
   - RAM pico: medir com Get-Process
4. Rodar segunda vez (sem mudanca nos dados):
   - Smart rewrite deve pular TODOS os MD e JSON fracionados
   - Tempo mais rapido (so leitura + comparacao)

RODAR EM TERMINAL SEPARADO (RAM ~550 MB).

---

## 8. RISCOS

| Risco | Probabilidade | Mitigacao |
|-------|---------------|----------|
| Fracionados diferentes do esperado | Baixa | Comparar com snapshot |
| RAM ainda alta | Baixa | [GC]::Collect apos cada arquivo |
| Smart-Write lenta (muita comparacao) | Baixa | Comparacao MD5 se necessario |
| Incremental quebra sem monolitico OneDrive | Media | Cache em scripts/cache/ mantem merge |

---

## Validacao

(sera preenchido na Etapa 2)

---

## Validacao (Etapa 2 - 07/03/2026)

### Checklist PLANO.md Fase 2

- [x] Smart rewrite: comparar conteudo antes de gravar
- [x] Eliminar monolitico do OneDrive: mover para scripts/cache/
- [x] Refatorar extracao para gravar direto nos fracionados
- [x] Refatorar geracao de indices para processar 1 fracionado por vez
- [x] Flag --gerar-monolitico mantido como backup (D2)
- [x] Sync: 335 MB -> ~92 MB meta
- [x] RAM: 2 GB -> ~550 MB meta
- [x] Arquivos alterados: extrair-sais.ps1, gerar-indices-sais.ps1, importar-sais.ps1

### Checklist PENDENTES.md

- [x] D2: Monolitico eliminado do OneDrive, flag --gerar-monolitico backup
- [x] D8: Indices flat mantidos (nao alterados nesta fase)

### Checklist SWOT.md

- [x] W5: Teste com snapshot de comparacao
- [x] T1: Smart rewrite reduz conflitos OneDrive sync

### Verificacao de paths reais

- [x] scripts/extrair-sais.ps1: EXISTE
- [x] scripts/gerar-indices-sais.ps1: EXISTE (modificado Fase 1)
- [x] scripts/importar-sais.ps1: EXISTE
- [x] banco-dados/dados-brutos/psai/: EXISTE
- [x] banco-dados/dados-brutos/sai/: EXISTE
- [x] scripts/cache/: SERA CRIADO

### RESULTADO

Validada em 07/03/2026. Nenhuma inconsistencia encontrada.
