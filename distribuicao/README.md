# Distribuicao - Projeto Filho

Esta pasta contem os pacotes de atualizacao do Projeto Filho.

- `ultima-versao/` - Versao mais recente (canal OneDrive para auto-update)
- `projeto-filho-vX.Y.Z.zip` - Pacotes ZIP por versao (canal fallback)
- `CHANGELOG.md` - Historico de mudancas

## Como gerar uma atualizacao

No projeto admin, rode:
`powershell -File scripts\gerar-atualizacao.ps1 -Versao "1.1.0" -Changelog "Descricao"`
