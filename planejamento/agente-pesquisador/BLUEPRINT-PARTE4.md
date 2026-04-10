### FASE 7: Gerar Pacote de Distribuicao v1.1.0

**Objetivo:** Preparar pacote para os 17 analistas atualizarem seus projetos-filho.

**Delegacao:** [IA-CURSOR]

**Pre-requisito:** FASE 6 aprovada

**O que fazer:**

1. Incrementar versao em 'projeto-filho/package.json' (se existir) ou 'projeto-filho/versao.txt':
   - De: 1.0.0
   - Para: 1.1.0

2. Criar pasta 'distribuicao/projeto-filho-v1.1.0/'

3. Copiar projeto-filho completo para a pasta de distribuicao

4. Criar 'distribuicao/projeto-filho-v1.1.0/INSTRUCOES-ATUALIZACAO.md':

```markdown
# Instrucoes de Atualizacao v1.1.0

**Data:** 10/03/2026
**Versao anterior:** 1.0.0
**Versao nova:** 1.1.0

## O que ha de novo

- Agente Pesquisador de SAIs (busca descricoes completas)
- Maior confiabilidade nas respostas da IA
- Checkpoint anti-inferencia

## Atualizacao Automatica (Recomendado)

1. Abrir terminal no seu projeto-filho
2. Rodar: 'scripts\atualizar-projeto.ps1'
3. Aguardar conclusao (~2 min)
4. Verificar: 'cat versao.txt' deve mostrar 1.1.0

## Atualizacao Manual

1. Fazer backup da sua pasta 'meu-trabalho/'
2. Deletar projeto-filho atual
3. Descompactar 'projeto-filho-v1.1.0.zip'
4. Restaurar sua pasta 'meu-trabalho/' do backup

## Verificacao

Apos atualizar, verificar:
- [ ] Arquivo '.cursor/rules/agente-pesquisador.mdc' existe
- [ ] Arquivo '.cursor/rules/checkpoint-dados.mdc' existe
- [ ] GUIA-RAPIDO.md menciona "Agente Pesquisador"
- [ ] 'versao.txt' mostra 1.1.0

## Compatibilidade

- Trabalhos em andamento ('meu-trabalho/') NAO sao afetados
- Fluxo de trabalho continua identico
- Nenhuma acao adicional necessaria

## Suporte

Duvidas ou problemas: contatar Gerente de Produto
```

5. Compactar 'distribuicao/projeto-filho-v1.1.0/' -> 'projeto-filho-v1.1.0.zip'

6. Atualizar 'distribuicao/ultima-versao/' (link simbolico ou copia)

**Testes obrigatorios:**

- [ ] Versao incrementada para 1.1.0
- [ ] Pasta de distribuicao criada
- [ ] INSTRUCOES-ATUALIZACAO.md criado
- [ ] Arquivo .zip gerado
- [ ] Tamanho do .zip < 5 MB
- [ ] ultima-versao/ aponta para v1.1.0

**Arquivos criados:**
- distribuicao/projeto-filho-v1.1.0/ (pasta completa)
- distribuicao/projeto-filho-v1.1.0.zip
- distribuicao/projeto-filho-v1.1.0/INSTRUCOES-ATUALIZACAO.md

**Rollback:** Deletar pasta v1.1.0, reverter ultima-versao/ para v1.0.0

**Budget de contexto:** ~10K tokens

**Gate:** Validar pacote. Descompactar em pasta teste e verificar integridade.

---

### FASE FINAL: Monitoramento e Metricas

**Objetivo:** Estabelecer metricas para avaliar sucesso da mudanca.

**Delegacao:** [HUMANO-VALIDA] (monitoramento continuo)

**Pre-requisito:** Analistas atualizaram para v1.1.0

**O que fazer:**

1. Criar 'logs/agente-pesquisador-metricas.json':

```json
{
  "versao": "1.1.0",
  "dataLancamento": "2026-03-10",
  "metricas": {
    "buscasRealizadas": 0,
    "latenciaMedia": 0,
    "tokenMedio": 0,
    "casosComInferencia": 0,
    "satisfacaoAnalistas": null
  },
  "proximaRevisao": "2026-04-10"
}
```

2. Definir metricas de sucesso (30 dias apos lancamento):

- [ ] Latencia media < 10s
- [ ] Nenhum caso de inferencia inadequada reportado
- [ ] 80%+ analistas adotaram v1.1.0
- [ ] Custo adicional < 20% do custo atual
- [ ] Feedback positivo de 70%+ analistas

3. Agendar revisao em 30 dias:
   - Coletar feedback dos analistas
   - Analisar logs de uso
   - Identificar pontos de otimizacao
   - Decidir: manter, otimizar ou reverter

4. Estabelecer criterios de rollback:
   - Se latencia > 20s em 50%+ dos casos
   - Se custo > 2x o custo anterior
   - Se 50%+ analistas reportam problemas

**Testes obrigatorios:**

- [ ] Arquivo de metricas criado
- [ ] Criterios de sucesso definidos
- [ ] Revisao agendada
- [ ] Criterios de rollback claros

**Arquivos criados:**
- logs/agente-pesquisador-metricas.json

**Rollback:** N/A (monitoramento continuo)

**Budget de contexto:** ~5K tokens

**Gate:** Aprovar plano de monitoramento. Revisao em 30 dias.

---

## 6. REGRAS DE EXECUCAO

### Restricoes inviolaveis

1. **NUNCA** alterar projeto-filho antes de testar no Projeto Admin
2. **NUNCA** carregar JSONs grandes (> 50 MB) diretamente no Cursor
3. **NUNCA** pular gates -- sempre obter aprovacao antes da proxima fase
4. **NUNCA** distribuir v1.1.0 sem validacao completa (FASE 5)

### Ordem de dependencia

```
FASE 0 (diagnostico) 
  -> FASE 1 (criar agente)
    -> FASE 2 (testar isoladamente)
      -> FASE 3 (integrar com agente-produto)
        -> FASE 4 (copiar para projeto-filho)
          -> FASE 5 (teste end-to-end)
            -> FASE 6 (documentacao)
              -> FASE 7 (distribuicao)
                -> FASE FINAL (monitoramento)
```

Se qualquer fase falhar, corrigir antes de avancar.

### Quem executa vs quem valida

- **Fases 0-2:** IA-CURSOR executa, HUMANO-VALIDA revisa
- **Fase 3:** IA-CURSOR executa, HUMANO-VALIDA aprova integracao
- **Fases 4-7:** IA-CURSOR executa, HUMANO-VALIDA valida pacote
- **Fase FINAL:** HUMANO-VALIDA monitora continuamente

---

## 7. CRITERIO DE SUCESSO

Checklist final (verificar apos todas as fases):

**Funcionalidade:**
- [ ] Agente Pesquisador funciona isoladamente
- [ ] Integracao com Agente de Produto transparente
- [ ] Caso SAI 40798 resolvido (nenhuma inferencia)
- [ ] Nenhum crash de OOM em testes

**Performance:**
- [ ] Latencia media < 10s
- [ ] Token medio por busca < 30K
- [ ] Custo adicional < 20% do custo atual

**Distribuicao:**
- [ ] Pacote v1.1.0 gerado e validado
- [ ] Instrucoes de atualizacao claras
- [ ] Comunicacao para analistas preparada

**Documentacao:**
- [ ] agente-pesquisador.md completo
- [ ] CHANGELOG.md detalhado
- [ ] GUIA-RAPIDO.md atualizado
- [ ] PROJETO.md reflete nova arquitetura

**Dores enderecadas:**
1. [ ] Atualizacao no projeto-filho: SIM, mas transparente
2. [ ] Risco de crash/token: MITIGADO via protecoes
3. [ ] Exemplos de funcionamento: DOCUMENTADOS em FASE 5
4. [ ] Agentes atualizados: SIM, funciona bem
5. [ ] Dados de token/custo: MEDIDOS em FASE 0

---

## 8. ROLLBACK

### Por fase

**FASE 0:** N/A (read-only)
**FASE 1:** Deletar .cursor/rules/agente-pesquisador.mdc e checkpoint-dados.mdc
**FASE 2:** N/A (read-only)
**FASE 3:** 'git checkout projeto-filho/.cursor/rules/agente-produto.mdc'
**FASE 4:** Deletar arquivos copiados, reverter GUIA-RAPIDO.md
**FASE 5:** N/A (read-only)
**FASE 6:** Deletar agente-pesquisador.md e CHANGELOG.md, reverter PROJETO.md
**FASE 7:** Deletar pasta v1.1.0, reverter ultima-versao/ para v1.0.0

### Rollback completo

Se precisar reverter tudo apos distribuicao:

1. Comunicar analistas: "Reverter para v1.0.0"
2. Disponibilizar pacote v1.0.0 novamente
3. Deletar todos os arquivos criados:
   - .cursor/rules/agente-pesquisador.mdc
   - .cursor/rules/checkpoint-dados.mdc
   - agentes/agente-pesquisador.md
   - atualizacao/v1.1.0/*
4. Reverter mudancas:
   - projeto-filho/.cursor/rules/agente-produto.mdc
   - projeto-filho/GUIA-RAPIDO.md
   - PROJETO.md

Estado anterior: Projeto Admin e Filho v1.0.0 (09/03/2026)

---

## 9. BUDGET DE CONTEXTO

### Estimativa por fase

| Fase | Arquivos Lidos | Arquivos Alterados | Tokens Estimados |
|------|----------------|-------------------|------------------|
| FASE 0 | 4 | 0 | 25.000 |
| FASE 1 | 2 | 2 | 15.000 |
| FASE 2 | 1 | 0 | 35.000 |
| FASE 3 | 1 | 1 | 20.000 |
| FASE 4 | 3 | 3 | 10.000 |
| FASE 5 | 5 | 0 | 40.000 |
| FASE 6 | 2 | 4 | 15.000 |
| FASE 7 | 1 | 5 | 10.000 |
| FINAL | 0 | 1 | 5.000 |
| **TOTAL** | | | **175.000** |

### Gestao de contexto

- Total cabe em 1 janela (< 200K tokens)
- Mas recomenda-se gates frequentes para manter contexto limpo
- Se contexto > 60% cheio apos FASE 5, criar novo chat para FASES 6-7

### Protecao OOM

- Nenhuma fase carrega JSONs grandes diretamente
- buscar-sai.ps1 roda em processo separado
- Subagentes tem limite de -Max 20 resultados
- Sempre usar -Resumido quando possivel

---

## 10. DELEGACAO DETALHADA

### IA-CURSOR (executa com escrita)

- FASE 1: Criar regras .mdc
- FASE 3: Modificar agente-produto.mdc
- FASE 4: Copiar arquivos para projeto-filho
- FASE 6: Criar documentacao
- FASE 7: Gerar pacote distribuicao

### IA-REVIEW (analisa sem alterar)

- FASE 2: Testar agente isoladamente
- FASE 5: Teste end-to-end

### HUMANO-VALIDA (revisa e aprova)

- Todos os gates entre fases
- Aprovacao final antes de distribuir v1.1.0

### HUMANO-TERMINAL (executa fora do Cursor)

- Nenhuma fase neste blueprint
- Mas analistas rodarao atualizar-projeto.ps1 posteriormente

---
