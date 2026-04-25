# PROMPT BLUEPRINT: Simplificacao da Arquitetura de Atualizacao do Projeto Escria

## 1. CONTEXTO DO PROBLEMA

**O que acontece:** O projeto possui 3 copias dos mesmos agentes (.mdc), 4 copias do mesmo script (buscar-sai.ps1), 2 canais de atualizacao sobrepostos, e uma pasta (atualizacao/) que mistura dados operacionais (status de importacao de SAIs) com pacotes de versao (v1.1.0/) e documentos de trabalho (agentes/, testes/, revisao/).

**O que deveria acontecer:** Uma unica fonte da verdade para cada artefato, com caminhos claros de publicacao e proposito inequivoco para cada pasta. Quatro conceitos bem definidos:

1. **Projeto Mae** -- Gerenciamento do projeto (admin). Onde o gerente edita, revisa e orquestra.
2. **Projeto Filho** -- O que o analista usa no dia a dia para criar PSAIs e SAIs.
3. **Planejamento Atualizacao** -- Tudo que planejamos e preparamos para uma atualizacao (specs, testes, revisoes, SWOT).
4. **Atualizacao Final** -- Planejamento anterior executado, testado, garantido e com arquivos prontos para ser passados aos analistas atualizarem dando input no seu Cursor.

**Exemplo concreto:**
- buscar-sai.ps1 existe em 4 lugares: scripts/, projeto-filho/scripts/, distribuicao/ultima-versao/scripts/, atualizacao/v1.1.0/arquivos/scripts/
- Os agentes .mdc existem em 3 lugares: projeto-filho/.cursor/rules/, distribuicao/ultima-versao/.cursor/rules/, atualizacao/v1.1.0/arquivos/.cursor/rules/
- O script gerar-atualizacao.ps1 so publica em distribuicao/ mas nao em atualizacao/v{X.Y.Z}/, criando risco de dessincronizacao

**Impacto:** O gerente nao sabe com confianca se uma alteracao nos agentes ja chegou a todos os canais.

## 2. DORES DO SOLICITANTE

1.  Estou com a sensacao que o projeto esta muito perdido -- excesso de pastas com propositos sobrepostos
2. Achei que ele ia buscar direto da pasta da atualizacao -- confusao sobre qual pasta o script usa
3. To meio assim com a quantidade de pasta perdida -- documentos de trabalho misturados com producao
4. Pode ser configurado de uma maneira mais clara -- desejo de simplificacao estrutural

## 3. FASES

### FASE 0: Diagnostico -- em execucao
### FASE 1: Definir arquitetura-alvo
### FASE 2: Unificar canal de publicacao
### FASE 3: Limpar e reorganizar pastas
### FASE FINAL: Documentacao e propagacao

(Detalhes completos de cada fase no chat original.)
