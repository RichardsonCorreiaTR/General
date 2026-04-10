# Fluxo Admin <-> Filho — Mapeamento entre Projetos

> Como os artefatos fluem entre o Projeto Admin (gerente) e o Projeto Filho (analista).

---

## Visao geral do fluxo

```
Demanda (NE/SAM/SAL/SAIL)
       |
       v
  Projeto Filho (analista)
  - Analise via rotas NE/SA/SS
  - Gera PSAI e SAIs
  - Move para meu-trabalho/concluido/
       |
       v
  Revisao (Admin)
  - revisao/pendente/ -> revisao/aprovado/ ou revisao/rejeitado/
  - Gerente usa revisar-definicao.ps1
       |
       v
  Banco de Dados (Admin)
  - RNs publicadas em banco-dados/
  - Indices regenerados
  - Pacote de atualizacao redistribuido
```

---

## Mapeamento de artefatos

| Artefato no Filho        | Fluxo                        | Artefato no Admin           |
|--------------------------|------------------------------|-----------------------------|
| PSAI (pre-SAI)           | Enviado para revisao         | Torna-se base para RN       |
| SAI (definicao completa) | Enviado para revisao         | Publicado como RN aprovada  |
| Task JSON                | Rastreamento local           | Nao flui para Admin          |
| Log diario               | Permanece no filho           | Consolidado pelo gerente     |

---

## Rotas do Filho e relacao com o Admin

| Rota  | Origem          | Resultado no Filho     | Implicacao no Admin                    |
|-------|-----------------|------------------------|----------------------------------------|
| NE    | Nota de Erro    | PSAI + SAI de correcao | RN de correcao apos revisao            |
| SA    | SAM/SAL/SAIL    | PSAI + SAI funcional   | RN de funcionalidade/legal apos revisao|
| SS    | Chamado suporte | Analise N3 (parecer)   | Pode gerar RN se identificar defeito   |

---

## Arquivos compartilhados vs. independentes

### Compartilhados (originam no Admin, distribuidos para o Filho)

- `.cursor/rules/*.mdc` — regras de IA (gerente edita no Admin, distribui via pacote)
- `templates/*.md` e `templates/*.json` — modelos padrao
- `config/VERSION.json` — versao do projeto
- `referencia/banco-dados/` — base de conhecimento (via symlink no filho)
- `scripts/*.ps1` — scripts de manutencao do filho

### Independentes (existem apenas em um projeto)

| Apenas no Admin                          | Apenas no Filho                    |
|------------------------------------------|------------------------------------|
| `scripts/gerar-atualizacao.ps1`          | `meu-trabalho/` (todo o conteudo)  |
| `scripts/extrair-sais.ps1`              | `config/analista.json`             |
| `scripts/importar-sais.ps1`             | `referencia/logs/` (logs locais)   |
| `distribuicao/`                          | `meu-trabalho/tasks/`              |
| `atualizacao/`                           |                                    |
| `revisao/`                               |                                    |
| `banco-dados/dados-brutos/` (dados reais)|                                   |

---

## Mecanismo de atualizacao

### Do Admin para o Filho

```
1. Gerente edita arquivos no Admin (projeto-filho/, templates/, etc.)

2. Gerente executa: gerar-atualizacao.ps1
   - Empacota regras, templates, config, scripts
   - Gera VERSION.json com versao incrementada
   - Salva pacote em: atualizacao/vX.Y.Z/ e distribuicao/ultima-versao/

3. OneDrive sincroniza o pacote para os analistas

4. Analista executa: atualizar-projeto.ps1
   - Detecta nova versao disponivel
   - Verifica sync do OneDrive (v2.4.0, R7)
   - Aplica o pacote: sobrescreve regras, templates, scripts
   - Grava VERSION.json local somente ao final (protecao R3)
   - Regenera cache offline (v2.4.0, R1)
```

### Do Filho para o Admin (fluxo de revisao)

```
1. Analista conclui PSAI/SAI e move para meu-trabalho/concluido/

2. Definicao e copiada para revisao/pendente/ (via symlink ou manualmente)

3. Gerente executa: revisar-definicao.ps1 -Acao listar
   - Ve pendentes com data de envio (v2.4.0, M5)

4. Gerente revisa e executa:
   - revisar-definicao.ps1 -Acao aprovar -Arquivo <caminho>
   - ou: revisar-definicao.ps1 -Acao rejeitar -Arquivo <caminho>

5. Se aprovada: publicada como RN no banco de dados
```

---

## Sincronizacao de versao

O `VERSION.json` e o contrato de versao entre Admin e Filho:

```json
{
  "versao": "1.3.0",
  "data_geracao": "2026-03-25",
  "hash_validacao": "abc123..."
}
```

- **Admin**: gera o VERSION.json ao empacotar
- **Filho**: compara versao local com a do pacote
- **hash_validacao** (v2.4.0, R3): hash do guardiao.mdc para detectar atualizacao incompleta
- **Guardiao do filho**: compara hash real do arquivo com o declarado no VERSION.json

---

## Quando uma PSAI gera uma RN nova

Se durante a analise no Filho o analista identifica que nao existe RN correspondente:

1. Analista documenta na PSAI: "RN inexistente — proposta de nova regra"
2. PSAI segue para revisao normalmente
3. Gerente no Admin avalia e decide:
   - Criar nova RN no banco de dados
   - Ou vincular a RN existente
4. Retorno ao analista via revisao/aprovado/ ou revisao/rejeitado/
