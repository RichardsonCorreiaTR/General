# Validações de PSAI / SAI (analista)

Cada PSAI com número oficial pode ter **um ficheiro** `psai-<numero>.md` **nesta pasta** — é o **histórico de validações feitas por si** nesta máquina (IA + analista).

## Relação com o projeto Admin

- Em `referencia/banco-dados/sais/validacoes/` pode existir histórico **oficial** vindo do OneDrive (GP). Essa pasta é **só leitura** no projeto-filho — **não edite**.
- **Grave sempre aqui** (`meu-trabalho/validacoes-psai/`) as novas entradas, conforme o **Passo 6** de `.cursor/rules/revisar-psai.mdc`.
- Modelo de secção: `templates/TEMPLATE-validacao-psai.md`.

## Convenção

- Nome do ficheiro: `psai-<i_psai>.md`.
- Nova validação: secção `## AAAA-MM-DD — …` no **topo** (logo abaixo da linha de instrução inicial do ficheiro); **não apague** entradas antigas.
- Na revalidação (ex.: após **Respondida pelo Coordenador** no SGD), compare com a entrada anterior e descreva **melhoras** / **pendências** na secção «Evolução vs validação anterior».

## SGD

Para obter texto quando o export em `referencia/` estiver incompleto:

`.\scripts\Consultar-PSAI-SGD.ps1 <numero> --json`

O agente deve **tentar este comando antes** de pedir colagem manual — ver secção «Fluxo obrigatorio» em `.cursor/rules/revisar-psai.mdc`.
