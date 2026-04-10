# Teste - Fase 4: Atualizar Projeto-Filho

> Executado em: 07/03/2026

## Resultados da Simulacao

| # | Verificacao | Resultado |
|---|------------|-----------|
| 1 | input.md legivel (6 secoes, tabela, 57 linhas) | OK |
| 2 | manifesto.json valido (4 arquivos, 3 preservar) | OK |
| 3 | Pacote v1.1.0: 4 arquivos presentes | OK |
| 4 | VERSION.json = 1.1.0 (3 locais) | OK |
| 5 | Symlink atualizacao/ nos 2 scripts | OK |
| 6 | distribuicao/ atualizada (CHANGELOG + MANIFESTO) | OK |

## Criterios de Sucesso

| Criterio | Meta | Real | Status |
|----------|------|------|--------|
| input.md legivel | 5+ secoes | 6 secoes | OK |
| Arquivos copiados | 4 arquivos | 4 arquivos | OK |
| VERSION.json | 1.1.0 | 1.1.0 em 3 locais | OK |
| Symlink atualizacao/ | Nos 2 scripts | Presente em ambos | OK |
| distribuicao/ atualizada | Changelog + manifesto | v1.1.0 em ambos | OK |

## Observacao

O teste real da atualizacao pelo analista requer um projeto-filho instalado
em C:\CursorFolha\projeto-filho com symlinks configurados. O teste aqui
valida que todos os artefatos estao corretos e prontos para uso.

O fluxo do analista sera:
1. Guardiao detecta versao 1.0.0 < 1.1.0 disponivel
2. Pergunta: "Ha uma atualizacao (v1.1.0). Posso atualizar?"
3. Analista aceita
4. IA le referencia/atualizacao/v1.1.0/input.md
5. IA copia 4 arquivos, preserva analista.json + caminhos.json + meu-trabalho
6. IA roda corrigir-symlinks.ps1 para criar link atualizacao/
7. Confirma: "Atualizacao v1.1.0 concluida"
