# Mapa do Sistema — Area Contabil

> Area PBCVS: `Contabil` | nomeArea exato: `Contabil`
> Atualizado em: 2026-04-23

## Modulos

| Modulo | Slug | Descricao |
|--------|------|-----------|
| Contabilidade | `contabilidade` | Lancamentos, plano de contas, balancete, DRE, fechamento contabil |
| Patrimônio | `patrimonio` | Ativo imobilizado, depreciacao, amortizacao, baixa de bens |
| Atualização Monetária | `atualizacao-monetaria` | Correcao monetaria, variacao cambial, indices (IPCA, IGP-M) |
| LALUR | `lalur` | Livro de Apuracao do Lucro Real, LACS, ECF, adicoes, exclusoes |
| Registros Contábeis | `registros-contabeis` | ECD, SPED Contabil, livros fiscais, autenticacao |
| Conteúdo Contábil Tributário | `conteudo-contabil-tributario` | Regimes tributarios, ECF, DIPJ, apuracao IRPJ/CSLL/PIS/COFINS |

## Fonte de dados

- **nomeArea no PBCVS**: `Contabil` (23.103 registros em 2026-04-23)
- **Extrator**: `scripts/extrair-sais.ps1` com `extracao.areas = ["Contabil"]`
- **Indices**: `banco-dados/sais/indices/modulos/contabilidade.md`, `patrimonio.md`, etc.

## Como pesquisar

```powershell
# Busca na area Contabil
.\scripts\buscar-sai.ps1 -Termo "LALUR" -Areas "Contabil"

# Busca em modulo especifico
.\scripts\buscar-sai.ps1 -Termo "depreciacao" -Modulo "patrimonio"
```

## Relacao com outras areas

- **Escrita Fiscal**: integracao contabil das notas fiscais (mapa-escrita.md)
- **ONVIO CONTABIL**: versao cloud do modulo Contabil (23.103 registros acima ja incluem)
