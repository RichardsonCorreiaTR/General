# Templates de auditoria de PSAI/SAI

Conjunto opcional para **validação aprofundada** (além do agente `revisar-psai.mdc` e dos guias `GUIA-padroes-psai.md` / `GUIA-validacao-ne.md`).

## Ordem sugerida

1. Obter texto fiel do SGD quando o JSON ODBC estiver incompleto: use **`Consultar-PSAI-SGD.ps1`** (`scripts/` no General ou `projeto-filho/scripts/`) — pede **sempre** utilizador e senha SGD; o `.env` não fornece credenciais. Alternativa: `python scripts/sgd_consulta/consultar_psai.py` (terminal interativo pede credenciais se necessário). Saída **`--json`**: `scripts/sgd_consulta/data/consultas/psai_<n>.json`. Ver `banco-dados/sais/cache/REFERENCIA.md`.
2. Ler `PROMPT-auditoria-psai.md` (secção *Ordem obrigatória de leitura* + *Próximos passos*) e escolher o nível de detalhe.
3. Anexar ao chat (ou `@`) os checklists que se aplicam ao escopo da PSAI.
4. Manter os **PDFs oficiais** acessíveis (sincronizados localmente ou anexados); os nomes abaixo são os que a equipa forneceu para alinhamento.

## Ficheiros

| Ficheiro | Uso |
|----------|-----|
| `PROMPT-auditoria-psai.md` | Instruções do agente: níveis, citações, trâmites, saída, Processos (quando houver `.md` de apoio). |
| `CHECKLIST-auditoria-manual-geral-1.3.9.md` | Manual **Pré-SAI e SAI** Escrita/Geral **v1.3.9** (16/10/2024). |
| `CHECKLIST-auditoria-importacao-1.5.md` | Manual **Pré-SAI e SAI de Importação Padrão** **v1.5**. |
| `CHECKLIST-auditoria-reflexos.md` | Manual **Análise de reflexos** na Pré-SAI/SAI (extra do kit 1.3.9). |
| `CHECKLIST-auditoria-janelas-1.1.md` | **Interface Desktop** **v1.1**. |

## PDFs de referência (nomes sugeridos na máquina do analista)

Coloque cópias read-only numa pasta local (ex.: `referencia/manuais-gerencia/`) **sem** substituir o SharePoint como fonte normativa.

| Documento oficial | Exemplo de ficheiro recebido |
|---------------------|----------------------------|
| Manual de Padrão de Pré-SAI e SAI v1.3.9 | `Manual de PSAI 1.3.9 (1).pdf` |
| Manual de Padrão de Pré-SAI e SAI de Importação v1.5 | `Manual de PSAI da Importação Padrão 1.5 NOVO (1).pdf` |
| Manual de reflexos (Pré-SAI/SAI) | `Manual de PSAI - Reflexos.pdf` |
| Manual de padrões (versão resumida / conferir rodapé) | `Manual de PSAI - Padrões.pdf` *(PDF extraído: v1.3.8 — validar com a biblioteca se ainda vigente)* |
| Manual de interface Desktop v1.1 | `Manual de Janelas 1.1 (1).pdf` |

## Módulo Processos

Quando existir `manual processos.md` (ou equivalente) com colunas **Menu**, **Submenu**, **Opção**, **UF**, **Código da Atividade**, siga o bloco **Processos** em `PROMPT-auditoria-psai.md`.
