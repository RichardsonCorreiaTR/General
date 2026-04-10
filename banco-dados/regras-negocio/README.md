# Regras de negocio - Escrita Fiscal (taxonomia atual)

Subpastas = **dominios de produto** alinhados a `mapa-sistema/mapa-escrita.md` e ao
mapeamento PBL (`pbl-area-escrita.json`), nao a modulos da Folha (calculo, ferias, etc.).

| Pasta | Uso |
|-------|-----|
| `apuracao-impostos` | Apuracao, DRCST, Simples Nacional |
| `escrituracao-movimento-fiscal` | Nucleo esc*, movimento esf/esm |
| `sped-documentos-eletronicos` | DIPJ, layouts fixos, NF-e/CT-e, XML |
| `integracoes-canais-digitais` | Externos, APIs, Portal Federal, analytics |
| `obrigacoes-relatorios-estaduais` | Sefaz, relatorios esr*, declaracoes |
| `parcelamento-planejamento` | Parcelamento, planejamento tributario, e-CAC |
| `onvio-importacao-dados` | Onvio, rotinas de importacao, dominio atendimento |
| `utilitarios-rotinas` | Utilitarios, alteracoes em lote |

**Legado Folha:** `../obsoleto/regras-negocio-taxonomia-folha-2026-04-09/` (historico).

Novas RN: use `templates/`, revisao do gerente, depois publique na subpasta do dominio acima.
