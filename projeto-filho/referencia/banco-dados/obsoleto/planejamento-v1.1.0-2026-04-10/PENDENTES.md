# Pontos Pendentes de Discussao

> Atualizado em: 07/03/2026
> Status: TODAS AS DECISOES FECHADAS (rodada 3 - pos-SWOT)

## Decisoes - Rodada 1 (Arquitetura)

### D1. Cache local vs Smart sync
DECISAO: Smart sync (sem cache local).
JSONs bloqueados por .cursorignore, IA nao le. Cache local = complexidade sem ganho.

### D2. Monolitico
DECISAO: Eliminar. Extracao grava direto nos fracionados.
Manter flag --gerar-monolitico como backup.

### D3. Divisao de indices
DECISAO: Modulos inteligentes (20 arquivos de 5-35 KB).
Formato estruturado: pendentes + recentes + temas + descartadas.

### D4. Frequencia
DECISAO: Ao logar + cada 3h (8h, 11h, 14h, 17h). Seg-sex.

### D5. Como analista recebe
DECISAO: Guardiao automatico (verifica status.json) + mecanismo via Cursor/IA.
Fase 4 cria input.md estruturado que a IA do analista executa.

### D6. Indices orfaos
DECISAO: Corrigir na Fase 1 (junto com modulos inteligentes).

### D7. Ordem de execucao
DECISAO: Fase 1 -> 2 -> 3 -> 4. Validar cada antes da proxima.

## Decisoes - Rodada 2 (Detalhamento)

### D8. Indices flat existentes
DECISAO: MANTER. Arquivos como pendentes-ne-recentes.md e liberadas-ne-antigas.md
continuam existindo. Modulos inteligentes sao ADICAO, nao substituicao.

### D9. Classificacao "Nao Classificado" (REVISADA apos SWOT)
DECISAO: MELHORAR em 3 niveis (integrado na Fase 1):
  Nivel 1 - Resolver i_modulos via JOIN no SGD (REQUER investigacao - ver D12)
  Nivel 2 - Expandir keywords (3 modulos faltantes + termos extras por modulo)
            Keywords externalizadas em banco-dados/config/modulos-keywords.json
  Nivel 3 - Permitir multi-modulo (SAI aparece em todos os modulos relevantes)
ACHADO (07/03/2026): modulo_caminho VAZIO em 100% dos 14.917 registros.
  Causa: extrair-sais.ps1 nao faz JOIN com tabela de modulos.
Meta com Nivel 1: Nao Classificado < 500.
Meta sem Nivel 1 (so N2+N3): Nao Classificado ~1500-2500.

### D10. Mecanismo de atualizacao do projeto-filho
DECISAO: Via Cursor/IA. Analista cola 1 frase no Cursor, IA executa tudo.
Estrutura: atualizacao/v{X.Y.Z}/input.md + arquivos/ + manifesto.json
Novo symlink: referencia/atualizacao/ -> OneDrive atualizacao/
Scripts de setup/correcao atualizados para criar o symlink.
atualizar-projeto.ps1 mantido como fallback.

### D11. Comunicacao com analistas
DECISAO: Mensagem padrao no Teams com a frase para colar no Cursor.
Guardiao.mdc detecta automaticamente versao nova e sugere atualizacao.
Analista so precisa dizer "sim" e a IA faz o resto.

## Decisoes - Rodada 3 (Pos-SWOT)

### D12. Viabilidade do Nivel 1 de classificacao (i_modulos)
STATUS: FECHADO - Nivel 1 INVIAVEL. Verificado via ODBC em 07/03/2026.
RESULTADO:
  - i_modulos = 19 (Folha) em 100% dos 35.307 registros. Zero variacao.
  - bethadba.modulos existe mas so tem "Folha" para nosso i_sistemas/i_modulos.
  - SGD NAO tem sub-classificacao dentro de Folha. Nao existe tabela ou campo
    que diga "esta SAI e de Ferias" ou "esta SAI e de FGTS".
  - BuscaSaiFolha (projeto Node.js) ja tinha descoberto isso e usava
    DICIONARIO_TAGS com 87 tags por keyword matching (mesma abordagem).
DECISAO: Eliminar Nivel 1. Fortalecer Niveis 2+3 absorvendo o dicionario
  de 87 tags do BuscaSaiFolha como base para nossas keywords expandidas.
  87 tags agrupadas em ~22 modulos = cobertura muito mais ampla.
  Nenhuma mudanca necessaria na extracao SQL.

### D13. Melhorias adicionais identificadas no SWOT
DECISAO: Incorporar na implementacao (nao bloqueantes):
  - AC2: Backup para meu-trabalho/.backup/ em vez de %TEMP%
  - AC3: Feedback de atualizacao no log do analista (OneDrive)
  - AC4: Keywords em arquivo externo (modulos-keywords.json)

## Proximos Passos

D12 verificado e fechado. Nenhum ponto bloqueante.
Iniciar implementacao pela Fase 1 (Niveis 2+3 com dicionario BuscaSaiFolha).
