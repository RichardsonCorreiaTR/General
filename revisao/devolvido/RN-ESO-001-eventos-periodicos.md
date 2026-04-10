# Regra de Negocio: RN-ESO-001 — Geracao de Eventos Periodicos eSocial

## Metadados

| Campo | Valor |
|---|---|
| **ID** | RN-ESO-001 |
| **Titulo** | Regras de geracao dos eventos periodicos S-1200, S-1210, S-1299 |
| **Modulo** | eSocial |
| **Autor** | Agente IA (semente - precisa validacao) |
| **Data** | 2026-03-04 |
| **Versao** | 0.1 |
| **Status** | Rascunho |
| **Prioridade** | Alta |

## Contexto

Os eventos periodicos sao gerados apos o calculo da folha e transmitidos
ao governo. Erros na geracao causam rejeicoes e multas. NEs frequentes
envolvem divergencia entre valores da folha e do XML.

## Regra

1. O sistema DEVE gerar S-1200 (remuneracao) para cada trabalhador ativo
   na competencia, com todas as rubricas calculadas.
2. O sistema DEVE gerar S-1210 (pagamentos) com a data efetiva de pagamento.
3. O sistema DEVE gerar S-1299 (fechamento) apos transmissao de todos os
   S-1200 e S-1210.
4. Cada rubrica no S-1200 DEVE corresponder a uma rubrica cadastrada na
   tabela S-1010 (rubricas).
5. O sistema DEVE validar o XML contra o esquema XSD vigente antes da
   transmissao.
6. Quando o S-1299 for rejeitado, o sistema DEVE permitir correcao e
   retransmissao sem perda de dados.
7. Na rescisao, o sistema DEVE gerar S-2299 (desligamento) com verbas e
   NAO incluir o trabalhador no S-1200 da competencia seguinte.

## Condicoes de Aplicacao

- [x] Folha mensal calculada e conferida
- [x] Leiaute S-1.3 vigente
- [x] Certificado digital valido

## Excecoes

| Excecao | Motivo |
|---|---|
| Competencia sem movimento | Gerar S-1299 com indicador de sem movimento |
| Empregado afastado o mes inteiro | S-1200 com valor zero (depende da situacao) |

## Areas de Impacto

- [x] eSocial
- [x] Calculo mensal
- [x] Ferias
- [x] Rescisao
- [x] 13o salario

## Base Legal

- Manual de Orientacao do eSocial (MOS) vigente
- Leiautes S-1.3
- Notas Tecnicas periodicas

## Criterios de Aceite

1. [x] XML validado contra XSD sem erros
2. [x] Valores do S-1200 = valores da folha
3. [x] S-1299 aceito pelo governo
4. [x] Rescindido nao aparece na competencia seguinte

## SAIs relacionadas

- NE 94316/PSAI 119012: S-1200 e S-2299 incorretos no desligamento
- NE 93920/PSAI 118788: Aviso de competencia fechada no eSocial incorreto
- NE 96962/PSAI 118706: Valores retornados pelo eSocial nao demonstrados
- SAL 100312/PSAI 128033: Adequacao a Nota Tecnica S-1.3 No 06/2026

---

| Versao | Data | Autor | Alteracao |
|---|---|---|---|
| 0.1 | 2026-03-04 | Agente IA | Criacao inicial (semente) |
