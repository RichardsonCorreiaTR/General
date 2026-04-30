"""
Consulta o conteúdo completo de uma PSAI no SGD (Playwright).

Uso (a partir da raiz do General ou desta pasta):
    python scripts/sgd_consulta/consultar_psai.py <numero> [--json] [--quiet]

Credenciais: ver README (scripts PowerShell ou variáveis de ambiente; não vêm do .env).

Por defeito grava pacote completo em data/consultas/arquivo/psai_<n>/ (HTML, texto, imagens,
manifest, log JSONL). Use --no-arquivo para só extrair sem gravar o pacote pesado.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import logging
import re
import sys
from pathlib import Path

_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from env import settings
from psai_arquivo import salvar_pacote_consulta
from session import sessao_sgd

logger = logging.getLogger(__name__)

_URL_DETALHE = "{base}/sgsa/faces/psai.html?psai={numero}"

_CAMPOS_TEXTO = [
    "Descrição",
    "Descricao",
    "Definição",
    "Definicao",
    "Comportamento",
    "Observação",
    "Observações",
    "Observacoes",
    "Anotações",
    "Anotacoes",
    "Anexo",
    "Anexos",
    "Justificativa",
    "Alternativa",
    "Embasamento Legal",
    "Embasamento",
    "Revisões",
    "Revisoes",
]

_LABELS_CABECALHO = {
    "numero": ["número", "numero", "nº", "n°"],
    "data": ["data", "entrada"],
    "pre_sai": ["pré-sai", "pre-sai", "psai"],
    "sai": ["sai"],
    "situacao": ["situação", "situacao", "status"],
    "produto": ["produto"],
    "sistema": ["sistema"],
    "modulo": ["módulo", "modulo"],
    "submodulo": ["submódulo", "submodulo", "submódulos", "submodulos"],
    "versao": ["versão", "versao"],
    "cliente": ["cliente"],
    "usuario": ["usuário", "usuario"],
    "responsavel": ["responsável", "responsavel"],
    "assunto": ["assunto", "descrição resumida", "descricao resumida"],
    "tipo": ["tipo"],
    "classificacao": ["classificação", "classificacao", "motivo"],
    "ultimo_tramite": ["últ. trâmite", "ultimo tramite", "último trâmite"],
}

_ORDEM_CONFERENCIA = [
    "descricao",
    "definicao",
    "comportamento",
    "embasamento_legal",
    "observacoes",
    "revisoes",
    "anotacoes",
    "anexos",
    "justificativa",
    "alternativa",
]


def _normalizar(texto: str) -> str:
    return texto.strip().lower().rstrip(":").strip()


def _sem_acento(texto: str) -> str:
    return (
        texto.replace("ã", "a")
        .replace("ç", "c")
        .replace("ê", "e")
        .replace("õ", "o")
        .replace("é", "e")
        .replace("ó", "o")
        .replace("á", "a")
        .replace("ú", "u")
        .replace("í", "i")
        .replace("â", "a")
        .replace("ô", "o")
        .replace("à", "a")
    )


def _chave_campo(nome: str) -> str:
    chave = _sem_acento(nome.lower().strip())
    if chave.startswith("descri"):
        return "descricao"
    if chave.startswith("defini"):
        return "definicao"
    if chave.startswith("comporta"):
        return "comportamento"
    if "embasamento legal" in chave:
        return "embasamento_legal"
    if chave.startswith("embasa"):
        return "embasamento_legal"
    if chave.startswith("anota"):
        return "anotacoes"
    if chave.startswith("justifi"):
        return "justificativa"
    if chave.startswith("alterna"):
        return "alternativa"
    if chave.startswith("revis"):
        return "revisoes"
    if chave.startswith("observa"):
        return "observacoes"
    if chave.startswith("anexo"):
        return "anexos"
    return chave.replace(" ", "_")


def _extrair_campos_texto(corpo: str) -> dict[str, str]:
    campos: dict[str, str] = {}

    delimitadores_re = "|".join(re.escape(c) for c in _CAMPOS_TEXTO)
    delimitadores_re += (
        "|Anexo:|Anexos:|SS:|SSC:|SSCs:|SSs:|Tópico:|Nível:|TRÂMITES"
        "|GERAR TRÂMITE|PROCURAR PRÉ-SAI|PROCURAR SAI|Legenda"
    )

    padrao = re.compile(
        r"(?P<campo>" + "|".join(re.escape(c) for c in _CAMPOS_TEXTO) + r")"
        r":\s*\t?\s*\n"
        r"(?P<conteudo>.*?)"
        r"(?=\n\s*(?:" + delimitadores_re + r")|\Z)",
        re.IGNORECASE | re.DOTALL,
    )

    for m in padrao.finditer(corpo):
        nome = m.group("campo").strip()
        conteudo = m.group("conteudo").strip()
        chave = _chave_campo(nome)
        if chave not in campos and conteudo:
            campos[chave] = conteudo

    return campos


def _reconciliar_definicao_comportamento_ne(textos: dict[str, str], tipo: str) -> None:
    """
    No SGD, com 'Definição:' vazio, o inner_text pode fazer o regex de _extrair_campos_texto
    capturar o bloco inteiro (incluindo o rótulo 'Comportamento:') em `definicao` e deixar
    `comportamento` vazio — dispara falso CAMPO_ESPERADO_VAZIO na NE.
    Move o texto para `comportamento` e limpa `definicao` quando o padrão é inequívoco.
    """
    if tipo != "NE":
        return
    comp = (textos.get("comportamento") or "").strip()
    if comp:
        return
    defin = (textos.get("definicao") or "").strip()
    if not defin:
        return
    m = re.match(r"^Comportamento\s*:\s*", defin, flags=re.IGNORECASE | re.DOTALL)
    if not m:
        return
    rest = defin[m.end() :].strip()
    if not rest:
        textos["definicao"] = ""
        return
    textos["comportamento"] = rest
    textos["definicao"] = ""


def _extrair_cabecalho(corpo: str) -> dict[str, str]:
    campos: dict[str, str] = {}
    trecho = corpo
    for marcador in ["Descrição:", "Descricao:", "Definição:", "Comportamento:"]:
        if marcador in trecho:
            trecho = trecho.split(marcador)[0]
            break
    trecho = trecho[:3000]

    for linha in trecho.splitlines():
        partes = re.split(r"\t|  {2,}", linha)
        for parte in partes:
            if ":" in parte:
                label, _, valor = parte.partition(":")
                label_norm = _normalizar(label)
                valor = valor.strip()
                for chave, sinonimos in _LABELS_CABECALHO.items():
                    if label_norm in sinonimos and valor:
                        campos[chave] = valor
                        break
    return campos


def _extrair_tipo(corpo: str) -> str:
    mapa = {
        "NOTIFICAÇÃO DE ERRO": "NE",
        "NOTIFICACAO DE ERRO": "NE",
        "SOLICITAÇÃO DE MELHORIA": "SAM",
        "SOLICITACAO DE MELHORIA": "SAM",
        "SOLICITAÇÃO DE ALTERAÇÃO LEGAL": "SAL",
        "SOLICITACAO DE ALTERACAO LEGAL": "SAL",
        "SOLICITAÇÃO DE IMPLEMENTAÇÃO LEGAL": "SAIL",
        "SOLICITACAO DE IMPLEMENTACAO LEGAL": "SAIL",
    }
    corpo_upper = corpo.upper()
    for texto, sigla in mapa.items():
        if texto in corpo_upper:
            return sigla
    m = re.search(r"Tipo:\s*(NE|SAM|SAL|SAIL|SA)\b", corpo, re.IGNORECASE)
    if m:
        return m.group(1).upper()
    return "SA"


def _cortar_rodape_acoes(corpo: str) -> str:
    """
    Remove texto dos botões de rodapé. Só corta em GERAR TRÂMITE / PROCURAR PRÉ-SAI
    quando o marcador vem depois da secção TRÂMITES, ou (sem TRÂMITES) só no fim
    da página — evita cortar a Definição quando o DOM repete o texto do menu.
    """
    pos_tram = -1
    for label in ("TRÂMITES", "TRAMITES"):
        pos_tram = corpo.find(label)
        if pos_tram != -1:
            break
    n = len(corpo)
    limite_fim = max(int(n * 0.88), n - 8000)

    for marcador in ("GERAR TRÂMITE", "GERAR TRAMITE", "PROCURAR PRÉ-SAI"):
        pos = corpo.find(marcador)
        if pos == -1:
            continue
        if pos_tram != -1 and pos > pos_tram:
            return corpo[:pos].rstrip()
        if pos_tram == -1 and pos >= limite_fim:
            return corpo[:pos].rstrip()
    return corpo


def _extrair_tramites(corpo: str) -> tuple[list[dict], list[str]]:
    tramites_completos: list[dict] = []
    historico: list[str] = []
    bloco = re.split(r"TRÂMITES|TRAMITES", corpo, maxsplit=1)
    if len(bloco) < 2:
        return tramites_completos, historico
    bloco_tram = bloco[1]
    tramites = re.findall(
        r"Número:\s*(\d+)\s*Usuário:\s*(.+?)\s*Data:\s*(\d{2}/\d{2}/\d{2}\s*\d{2}:\d{2})"
        r"(?:.*?Descrição:\s*\t?\s*\n(.*?))?(?=\nNúmero:|\Z)",
        bloco_tram,
        re.DOTALL | re.IGNORECASE,
    )
    for t in tramites:
        num, usuario, data = t[0], t[1], t[2]
        desc = (t[3] if len(t) > 3 and t[3] is not None else "") or ""
        desc = desc.strip() if desc else ""
        usuario = usuario.strip()
        tramites_completos.append(
            {"numero": num, "usuario": usuario, "data": data.strip(), "descricao": desc}
        )
        if desc and desc.lower() != "nenhuma":
            historico.append(f"[{num:>02}] {data} | {usuario} | {desc[:300]}")
    return tramites_completos, historico


async def consultar_psai(numero: str, *, arquivo: bool = True) -> dict:
    url = _URL_DETALHE.format(base=settings.SGD_URL, numero=numero)
    resultado: dict = {"numero": numero, "url": url}

    async with sessao_sgd() as session:
        page = await session.nova_pagina()
        logger.info(f"Acessando: {url}")
        await page.goto(url, wait_until="domcontentloaded")
        await page.wait_for_load_state("domcontentloaded")

        if "login" in page.url.lower():
            raise RuntimeError("Sessao expirada — refaca o login.")

        corpo = await page.inner_text("body")
        html = await page.content()
        corpo_principal = _cortar_rodape_acoes(corpo)

        resultado["tipo"] = _extrair_tipo(corpo_principal)
        resultado["cabecalho"] = _extrair_cabecalho(corpo_principal)
        resultado["textos"] = _extrair_campos_texto(corpo_principal)
        _reconciliar_definicao_comportamento_ne(resultado["textos"], resultado["tipo"])
        tr_completos, tr_hist = _extrair_tramites(corpo_principal)
        resultado["tramites"] = tr_completos
        resultado["historico"] = tr_hist

        out_dir = settings.CONSULTAS_DIR
        out_dir.mkdir(parents=True, exist_ok=True)

        if arquivo:
            await salvar_pacote_consulta(
                numero=numero,
                consultas_dir=out_dir,
                usuario_sgd=settings.SGD_USERNAME,
                corpo_raw=corpo,
                corpo_principal=corpo_principal,
                html=html,
                resultado=resultado,
                page=page,
            )
            logger.info("Pacote de arquivo local: %s", resultado.get("arquivo_local"))
            for av in (resultado.get("manifest") or {}).get("avisos_extracao") or []:
                logger.warning("Extracao PSAI %s: [%s] %s", numero, av.get("codigo"), av.get("detalhe"))
        else:
            screenshot_path = out_dir / f"psai_{numero}.png"
            await page.screenshot(path=str(screenshot_path), full_page=True)
            resultado["screenshot"] = str(screenshot_path)
            logger.info(f"Screenshot: {screenshot_path}")

        await page.close()

    return resultado


def _imprimir(dados: dict) -> None:
    sep = "=" * 70
    tipo = dados.get("tipo", "SA")
    cab = dados.get("cabecalho", {})
    numero = cab.get("numero", dados["numero"])

    print(f"\n{sep}")
    print(f"  PSAI #{numero}  [{tipo}]")
    print(f"  URL: {dados['url']}")
    print(sep)

    ordem_cab = [
        "assunto",
        "data",
        "ultimo_tramite",
        "situacao",
        "sistema",
        "modulo",
        "submodulo",
        "versao",
        "cliente",
        "usuario",
        "responsavel",
        "tipo",
        "classificacao",
    ]
    if cab:
        print("\n[CABECALHO]")
        for chave in ordem_cab:
            if chave in cab and cab[chave]:
                label = chave.replace("_", " ").upper()
                print(f"  {label:<22} {cab[chave]}")

    textos = dados.get("textos", {})
    campos_exibidos: set[str] = set()

    print("\n[ORDEM DE CONFERENCIA — texto da PSAI]")
    print("-" * 70)
    print("  1) Definicao  2) Comportamento  3) Observacoes  4) Anexos  5) Tramites (abaixo)")

    for chave in _ORDEM_CONFERENCIA:
        if chave in textos and textos[chave]:
            valor = textos[chave]
            if valor.strip().lower() in ("nenhuma", ""):
                continue
            label = chave.replace("_", " ").upper()
            print(f"\n[{label}]")
            print("-" * 70)
            for linha in valor.splitlines():
                print(f"  {linha}")
            campos_exibidos.add(chave)

    for chave, valor in textos.items():
        if chave not in campos_exibidos and valor and valor.strip().lower() not in ("nenhuma", ""):
            label = chave.replace("_", " ").upper()
            print(f"\n[{label}]")
            print("-" * 70)
            for linha in valor.splitlines():
                print(f"  {linha}")

    trs = dados.get("tramites") or []
    if trs:
        print(f"\n[TRAMITES — lista completa] ({len(trs)} registros)")
        print("-" * 70)
        for tr in trs:
            num = tr.get("numero", "?")
            u = tr.get("usuario", "?")
            d = tr.get("data", "?")
            desc = tr.get("descricao") or "(sem descricao)"
            linha = f"  #{num} | {d} | {u} | {desc[:400]}"
            print(linha)
            if len(desc) > 400:
                print(f"      ... (+{len(desc) - 400} caracteres)")

    hist = dados.get("historico", [])
    if hist:
        print(f"\n[TRAMITES — somente com descricao util] ({len(hist)} registros)")
        print("-" * 70)
        for item in hist:
            print(f"  {item}")

    sc = dados.get("screenshot")
    if sc:
        print(f"\nScreenshot: {sc}")
    if dados.get("arquivo_local"):
        print(f"Arquivo local (HTML + texto + grids + manifest): {dados['arquivo_local']}")
        man = dados.get("manifest") or {}
        avs = man.get("avisos_extracao") or []
        if avs:
            print("\n[Avisos para revisao das regras de extracao]")
            for av in avs:
                print(f"  - [{av.get('severidade')}] {av.get('codigo')}: {av.get('detalhe')}")
    print(f"\n{sep}\n")


def _salvar_json(dados: dict, dest: Path) -> Path:
    dest = dest.resolve()
    dest.parent.mkdir(parents=True, exist_ok=True)
    with dest.open("w", encoding="utf-8") as f:
        json.dump(dict(dados), f, ensure_ascii=False, indent=2)
    return dest


async def main() -> None:
    parser = argparse.ArgumentParser(
        description="Consulta PSAI no SGD (Playwright) e extrai campos de texto e trâmites.",
    )
    parser.add_argument("numero", help="Numero da PSAI (ex: 130298)")
    parser.add_argument(
        "--json",
        action="store_true",
        help="Grava JSON em scripts/sgd_consulta/data/consultas/psai_<numero>.json",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="Com --json: nao imprime relatorio humano; so grava JSON e imprime o caminho",
    )
    parser.add_argument(
        "--no-arquivo",
        action="store_true",
        help="Nao grava pasta arquivo/ (HTML, grids, manifest, log JSONL); so screenshot simples",
    )
    args = parser.parse_args()
    if args.quiet and not args.json:
        parser.error("--quiet exige --json")

    numero = args.numero.strip()
    logger.info(f"Consultando PSAI #{numero}...")
    dados = await consultar_psai(numero, arquivo=not args.no_arquivo)

    json_path: Path | None = None
    if args.json:
        json_path = settings.CONSULTAS_DIR / f"psai_{numero}.json"
        json_path = _salvar_json(dados, json_path)
        if args.quiet:
            print(str(json_path))
        else:
            print(f"\nJSON salvo em: {json_path}")

    if not (args.json and args.quiet):
        _imprimir(dados)


if __name__ == "__main__":
    asyncio.run(main())
