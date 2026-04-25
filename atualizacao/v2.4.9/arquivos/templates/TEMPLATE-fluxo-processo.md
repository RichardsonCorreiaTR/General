# Fluxo de Processo: [FL-XXX] — [Título do Fluxo]

## Metadados

| Campo | Valor |
|---|---|
| **ID** | FL-XXX |
| **Título** | [Nome do fluxo] |
| **Módulo** | [Módulo principal] |
| **Autor** | [Nome] |
| **Data** | AAAA-MM-DD |
| **Versão** | 1.0 |

## Objetivo do Fluxo

> O que este fluxo descreve? Qual processo de negócio ele mapeia?

[Escreva aqui]

## Atores Envolvidos

| Ator | Papel no Fluxo |
|---|---|
| [Ex: Departamento Pessoal] | [O que faz neste fluxo] |
| [Ex: Escrita Fiscal / dominio contabil] | [O que processa neste fluxo] |

## Fluxo Principal (Caminho Feliz)

```
INÍCIO
  │
  ▼
[Passo 1] — [Descrição]
  │
  ▼
[Passo 2] — [Descrição]
  │
  ▼
[Decisão?] ──SIM──→ [Passo 3A]
  │                      │
  NÃO                    ▼
  │                  [Passo 4]
  ▼                      │
[Passo 3B]               │
  │                      │
  ▼                      ▼
  └──────────────→ [Passo Final]
                      │
                      ▼
                    FIM
```

## Descrição dos Passos

### Passo 1 — [Nome]
- **Ator**: [quem executa]
- **Entrada**: [dados/documentos necessários]
- **Ação**: [o que acontece]
- **Saída**: [resultado do passo]
- **Regras aplicáveis**: RN-XXX, RN-YYY

### Passo 2 — [Nome]
- **Ator**: [quem executa]
- **Entrada**: [dados/documentos necessários]
- **Ação**: [o que acontece]
- **Saída**: [resultado do passo]
- **Regras aplicáveis**: RN-XXX

## Fluxos Alternativos

### Alternativa A — [Descrição]
> Quando [condição], o fluxo segue por aqui.

[Descreva os passos alternativos]

### Alternativa B — [Tratamento de Erro]
> Quando [erro/exceção], o sistema deve:

[Descreva o tratamento]

## Regras de Negócio Relacionadas

| Regra | Onde se aplica no fluxo |
|---|---|
| RN-XXX | Passo 2 |
| RN-YYY | Decisão entre Passo 3A e 3B |

## Observações

[Informações adicionais ou "Nenhuma"]

---

| Versão | Data | Autor | Alteração |
|---|---|---|---|
| 1.0 | AAAA-MM-DD | [Nome] | Criação inicial |
