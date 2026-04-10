# Glossario: Notacao de Definicoes

> Padroes de escrita e formatacao encontrados nas SAIs

---

## Estrutura de uma Definicao

Uma SAI segue este padrao de secoes:

| Secao | Conteudo |
|---|---|
| GERAL | Contexto, objetivo, SAIs relacionadas |
| PROCESSOS | Alteracoes em menus de processo |
| ARQUIVO | Alteracoes em cadastros/telas |
| CONTROLE | Alteracoes em parametros e configuracoes |
| RELATORIOS | Alteracoes em impressos e listagens |

---

## Padroes de Navegacao

| Notacao | Significado | Exemplo |
|---------|-------------|---------|
| SECAO > Menu > Submenu | Caminho no sistema | PROCESSOS > Calculo |
| [x] / [ ] | Checkbox marcado/desmarcado | [x] Gerar eSocial |
| [...] | Botao de reticencias | Botao [...] DIRF |
| Campo: 'valor' | Campo e seu conteudo | Campo: 'Data Admissao' |

---

## Frases-Padrao

| Frase | Significado | Frequencia |
|-------|-------------|------------|
| conforme versao de mercado | Manter comportamento atual | ~1.250 SAIs |
| conforme SAI XXXXX | Referencia a outra definicao | Muito frequente |
| conforme imagem | Referencia a mockup/screenshot | ~1.504 SAIs |
| a partir da competencia XX/YYYY | Regra temporal | Frequente em SALs |
| Nao mencionado = nao alterar | Principio de preservacao | Implicito |

---

## Padrao Incremental

Cada SAI **complementa** SAIs anteriores. Para entender uma regra completa, muitas vezes e preciso seguir uma cadeia de 3-4 SAIs encadeadas.

Exemplo: SAI 93395 (cria emprestimo) > SAI 93653 (cria provisao) > SAI 93760 (altera tela) > SAI 94053 (cria relatorio).

---

## Linguagem

- Predomina linguagem tecnica e direta
- Uso intenso de termos do sistema (nomes de telas, campos, rubricas)
- NEs descrevem "esta calculando incorretamente..." / "nao esta gerando..."
- SAMs descrevem "criar opcao..." / "permitir..." / "implementar..."
- SALs descrevem "alterar conforme Lei..." / "adequar ao leiaute..."
