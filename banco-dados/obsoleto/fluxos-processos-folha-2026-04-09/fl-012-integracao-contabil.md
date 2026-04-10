# Fluxo de Processo: FL-012 - Integracao Contabil

## Metadados

| Campo | Valor |
|---|---|
| **ID** | FL-012 |
| **Titulo** | Integracao da Folha com Modulo Contabil |
| **Modulo** | Integracao Contabil |
| **Autor** | Agente IA (base: codigo-fonte + SAIs) |
| **Data** | 2026-03-04 |
| **Versao** | 0.2 (revisado - pendente aprovacao) |

## Objetivo do Fluxo

Descreve o processo de integracao dos lancamentos da folha de pagamento
com o modulo contabil do Dominio, incluindo configuracao e execucao.

## Atores Envolvidos

| Ator | Papel no Fluxo |
|---|---|
| Departamento Pessoal | Confere folha, executa integracao |
| Contabilidade | Confere lancamentos, fecha periodo |
| Sistema Folha | Gera lancamentos, exporta para contabil |

## Fluxo Principal

```
INICIO (Folha calculada e conferida)
  |
  v
[1] Configurar plano de contas (Cadastros > Contabilidade)
  |   (fointeg1 - w_integ_configura.srw)
  |
  v
[2] Mapear rubricas para contas contabeis
  |   Cada rubrica → conta debito + conta credito
  |
  v
[3] Definir centro de custo (se aplicavel)
  |
  v
[4] Executar integracao (Processos > Integracao)
  |   (fointeg2 - w_integracao.srw)
  |
  v
[5] Conferir lancamentos gerados
  |
  v
[Divergencia?] --SIM--> [5A] Ajustar mapeamento e re-integrar
  |
  NAO
  |
  v
[6] Exportar para modulo Contabil/Fiscal
  |   (foexternos - w_integracao_contabil.srw)
  |
  v
[7] Conferir no modulo Contabil
  |
  v
FIM
```

## Descricao dos Passos

### Passo 1 - Plano de contas
- **Ator**: Contabilidade
- **Acao**: Configurar o plano de contas da empresa no modulo Folha, espelhando o plano do Contabil.

### Passo 2 - Mapear rubricas
- **Ator**: Contabilidade / DP
- **Acao**: Para cada rubrica da folha, definir conta de debito (despesa/ativo) e credito (passivo/obrigacao). Exemplos: salarios → despesa pessoal; INSS a recolher → obrigacao.

### Passo 3 - Centro de custo
- **Ator**: Contabilidade
- **Acao**: Se a empresa usa centro de custo, vincular departamentos/empregados aos centros.

### Passo 4 - Executar
- **Ator**: Departamento Pessoal
- **Acao**: Rodar integracao para a competencia. O sistema agrupa lancamentos por rubrica e conta.

### Passo 5 - Conferencia
- **Ator**: Contabilidade
- **Acao**: Comparar total dos lancamentos com resumo da folha. Verificar que debitos = creditos.

### Passo 6 - Exportar
- **Ator**: Sistema Folha
- **Acao**: Gerar arquivo ou transferir direto para o Dominio Contabil.

### Passo 7 - Conferir no Contabil
- **Ator**: Contabilidade
- **Acao**: Validar lancamentos importados no razao contabil.

## Regras de Negocio Relacionadas

Nenhuma regra especifica da base aplica-se diretamente a este fluxo.

## Observacoes

- Sao 4 PBLs de integracao (fointeg1 a fointeg4) + foexternos.
- Provisoes (FL-008) tambem geram lancamentos contabeis.
- SAM 100205: Ajustar consideracoes da Folha para integrar ao Escrita.

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (rascunho) |
| 0.2 | 2026-03-04 | Agente IA | Revisao: cruzamento com regras e mapa |
