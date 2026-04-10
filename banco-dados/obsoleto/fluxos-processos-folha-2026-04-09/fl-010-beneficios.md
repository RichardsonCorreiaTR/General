# Fluxo de Processo: FL-010 - Beneficios

## Metadados

| Campo | Valor |
|---|---|
| **ID** | FL-010 |
| **Titulo** | Cadastro e Calculo de Beneficios (VT, VA, Plano Saude) |
| **Modulo** | Beneficios |
| **Autor** | Agente IA (base: codigo-fonte + SAIs) |
| **Data** | 2026-03-04 |
| **Versao** | 0.2 (revisado - pendente aprovacao) |

## Objetivo do Fluxo

Descreve o processo de cadastro, calculo e desconto de beneficios na
folha de pagamento.

## Atores Envolvidos

| Ator | Papel no Fluxo |
|---|---|
| Departamento Pessoal | Cadastra beneficios, configura descontos |
| Sistema Folha | Calcula descontos automaticos, gera relatorios |

## Fluxo Principal

```
INICIO
  |
  v
[1] Cadastrar beneficios disponiveis na empresa
  |
  v
[2] Vincular empregado aos beneficios (na admissao ou apos)
  |
  v
[3] Configurar valores e percentuais de desconto
  |
  v
[4] Calculo automatico na folha mensal
  |
  v
[5] Conferir descontos no recibo
  |
  v
[Afastamento?] --SIM--> [5A] Verificar regras de suspensao do beneficio
  |
  NAO
  |
  v
[6] Gerar relatorios de beneficios (controle, custos)
  |
  v
FIM
```

## Descricao dos Passos

### Passo 1 - Cadastrar beneficios
- **Ator**: Departamento Pessoal
- **Acao**: Definir tipos: vale-transporte, vale-alimentacao/refeicao, plano de saude, plano odontologico, seguro de vida, auxilio creche.

### Passo 2 - Vincular empregado
- **Ator**: Departamento Pessoal
- **Acao**: Na admissao (FL-005) ou posteriormente, associar empregado aos beneficios que utilizara.

### Passo 3 - Valores e descontos
- **Ator**: Departamento Pessoal
- **Acao**: Configurar:
  - VT: desconto ate 6% do salario base (Lei 7.418/85)
  - VA/VR: desconto conforme politica (max 20% do valor, se PAT)
  - Plano saude: valor fixo ou percentual, coparticipacao
  - Auxilio creche: sem desconto (beneficio integral)

### Passo 4 - Calculo automatico
- **Ator**: Sistema Folha
- **Acao**: Na folha mensal, incluir rubricas de desconto. Proporcionalizar se admissao/rescisao no meio do mes.

### Passo 5 - Conferir descontos
- **Ator**: Departamento Pessoal
- **Acao**: Verificar no recibo que descontos estao corretos. Em caso de afastamento, verificar se o beneficio se mantem ou suspende.

### Passo 6 - Relatorios
- **Ator**: Departamento Pessoal
- **Acao**: Emitir relatorios de controle: custo por empregado, custo total, VT por linha/empresa.

## Regras de Negocio Relacionadas

Nenhuma regra especifica da base aplica-se diretamente a este fluxo.

## Base Legal

- Lei 7.418/85 - Vale-transporte (desconto 6%)
- Dec. 95.247/87 - Regulamento VT
- Lei 6.321/76 - PAT (alimentacao)
- CLT Art. 458 - Utilidades que nao integram salario

## Observacoes

- Beneficios NAO integram salario para fins de encargos (INSS, FGTS) se concedidos conforme legislacao.
- Rascunho - precisa validacao.

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (rascunho) |
| 0.2 | 2026-03-04 | Agente IA | Revisao: cruzamento com regras e mapa |
