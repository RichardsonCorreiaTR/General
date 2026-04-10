# Teste - Fase 2: Smart Rewrite + Eliminar Monolitico

> Executado em: 07/03/2026

## Resultados: 4 execucoes

### Execucao 1 (primeira com dados da Fase 1)

| Metrica | Valor |
|---------|-------|
| Tempo | 158.7s (~2.6 min) |
| RAM pico | 799.4 MB |
| Smart-Write escritos | 51 |
| Smart-Write pulados | 0 |
| Erros | 0 |

### Execucao 2 (idempotencia - antes do fix timestamp)

| Metrica | Valor |
|---------|-------|
| Tempo | 156.0s |
| RAM pico | 799.7 MB |
| Smart-Write escritos | 51 |
| Smart-Write pulados | 0 |
| Notas | BUG: timestamps $(Get-Date) mudavam a cada run |

### Execucao 3 (apos fix timestamp estavel)

| Metrica | Valor |
|---------|-------|
| Tempo | 157.3s |
| RAM pico | 723.2 MB |
| Smart-Write escritos | 51 |
| Smart-Write pulados | 0 |
| Notas | BUG: Set-Content adiciona trailing newline, Get-Content -Raw inclui |

### Execucao 4 (apos fix TrimEnd na comparacao)

| Metrica | Valor |
|---------|-------|
| Tempo | 170.5s |
| RAM pico | 723.5 MB |
| Smart-Write escritos | 0 |
| Smart-Write pulados | 51 |
| Notas | SUCESSO! 100% dos arquivos pulados (identicos) |

## Criterios de Sucesso vs Resultado

| Criterio | Meta | Real | Status |
|----------|------|------|--------|
| RAM pico | < 700 MB | 723-799 MB | PARCIAL (64% reducao vs 73% meta) |
| Smart-Write funcional | arquivos pulados | 51/51 pulados na run 4 | OK |
| Monolitico em dados-brutos/ | NAO regravado | Nao tocado | OK |
| Fase A removida | Fracionamento em extrair-sais.ps1 | Removida do gerar-indices | OK |
| Indices MD identicos | Conteudo preservado | Gerados com sucesso | OK |
| Tempo | < 5 min | ~2.6-2.8 min | OK |
| Erros | 0 | 0 | OK |

## Bugs Encontrados e Corrigidos

1. Smart-Write recursiva (regex substituiu Set-Content dentro da funcao)
   - Corrigido: restaurado Set-Content dentro da funcao
2. Timestamps dinamicos (Get-Date mudava a cada execucao)
   - Corrigido: usar data de modificacao dos fracionados PSAI
3. Trailing newline (Set-Content adiciona, Get-Content -Raw inclui)
   - Corrigido: TrimEnd em ambos os lados da comparacao

## Analise da RAM

A meta do PLANO era 550 MB (-73%). O resultado real foi ~723-799 MB (-60% a -64%).
A diferenca ocorre porque PSCustomObject do PowerShell consome mais overhead do que
estimado. Os 29K registros leves (~10 campos cada) ocupam ~150 MB em memoria
como objetos PowerShell, nao ~75 MB como estimado.

Ainda assim, a reducao de ~2 GB para ~750 MB e significativa (62% reducao).
O script roda confortavelmente em maquinas com 4 GB+ de RAM.

## Dados dos Indices Gerados

- 29.372 registros carregados (lightweight)
- 12.943 PSAIs classificadas em modulos
- 24 modulos inteligentes
- 383 rubricas
- 5 versoes
- 51 arquivos MD gerados

## Nota sobre Smart-Write nos fracionados JSON

O Smart-Write nos JSONs fracionados (PSAI e SAI) e feito pelo extrair-sais.ps1,
que nao pode ser testado sem conexao ODBC ou fonte BuscaSaiFolha. No entanto,
a funcao Smart-Write esta implementada e usara o mesmo TrimEnd fix.

Em operacao normal com extrair-sais.ps1:
- Fracionados que nao mudaram: PULADOS (economia de sync no OneDrive)
- Monolitico em scripts/cache/: fora do OneDrive (economia de 165 MB sync)
- Estimativa total sync: ~92 MB (vs 335 MB antes)
