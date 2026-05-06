"""
Consulta o conteúdo completo de uma SAI no portal SGSAI (Playwright).

Uso (a partir da raiz do General):
    python scripts/sgd_consulta/consultar_sai.py <numero> [--json] [--quiet] [--no-arquivo]

Credenciais: mesmas do SGD (SGD_USERNAME / SGD_PASSWORD).
O SGSAI usa domínio separado (sgsai.dominiosistemas.com.br) com login próprio.
A sessão é salva em data/sai_session_state_<hash>.json para reutilização.
"""
from __future__ import annotations

import argparse
import asyncio
import hashlib
import json
import logging
import re
import sys
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import AsyncGenerator

_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from env import settings
from playwright.async_api import Browser, BrowserContext, Page, Playwright, async_playwright

logger = logging.getLogger(__name__)

_URL_BASE_SAI   = "https://sgsai.dominiosistemas.com.br"
_URL_LOGIN_SAI  = f"{_URL_BASE_SAI}/login.html"
_URL_DETALHE    = f"{_URL_BASE_SAI}/sgsai/faces/sai.html?sai={{numero}}"

_CAMPOS_TEXTO = [
    "Descrição", "Descricao",
    "Definição", "Definicao",
    "Comportamento",
    "Observação", "Observações", "Observacoes",
    "Anotações", "Anotacoes",
    "Anexo", "Anexos",
    "Justificativa",
    "Alternativa",
    "Embasamento Legal", "Embasamento",
    "Revisões", "Revisoes",
]

_LABELS_CABECALHO = {
    "numero":       ["número", "numero", "nº", "n°", "sai"],
    "data":         ["data", "entrada"],
    "psai":         ["pré-sai", "pre-sai", "psai"],
    "situacao":     ["situação", "situacao", "status"],
    "produto":      ["produto"],
    "sistema":      ["sistema"],
    "modulo":       ["módulo", "modulo"],
    "submodulo":    ["submódulo", "submodulo"],
    "versao":       ["versão", "versao"],
    "usuario":      ["usuário", "usuario"],
    "responsavel":  ["responsável", "responsavel"],
    "tipo":         ["tipo", "classificação", "classificacao"],
    "gravidade":    ["gravidade"],
    "area":         ["área", "area"],
}

_ORDEM_CONFERENCIA = [
    "descricao", "definicao", "comportamento",
    "embasamento_legal", "observacoes", "revisoes", "anotacoes", "anexos",
    "justificativa", "alternativa",
]

_LOGIN_SELECTORS = {
    "username": "input[name='usuario'], #usuario, input[type='text']",
    "password": "input[name='senha'], #senha, input[type='password']",
    "submit":   "input[type='submit'], button[type='submit'], .btn-login",
}


def _sai_session_file() -> Path:
    u = settings.SGD_USERNAME or ""
    h = hashlib.sha256(u.encode()).hexdigest()[:16] if u else "none"
    base = settings.SESSION_FILE.parent
    return base / f"sai_session_state_{h}.json"


def _normalizar(texto: str) -> str:
    return texto.strip().lower().rstrip(":").strip()


def _sem_acento(texto: str) -> str:
    return (
        texto.replace("ã", "a").replace("ç", "c").replace("ê", "e")
             .replace("õ", "o").replace("é", "e").replace("ó", "o")
             .replace("á", "a").replace("ú", "u").replace("í", "i")
             .replace("â", "a").replace("ô", "o").replace("à", "a")
    )


def _chave_campo(nome: str) -> str:
    chave = _sem_acento(nome.lower().strip())
    if chave.startswith("descri"):   return "descricao"
    if chave.startswith("defini"):   return "definicao"
    if chave.startswith("comporta"): return "comportamento"
    if "embasamento legal" in chave: return "embasamento_legal"
    if chave.startswith("embasa"):   return "embasamento_legal"
    if chave.startswith("anota"):    return "anotacoes"
    if chave.startswith("justifi"):  return "justificativa"
    if chave.startswith("alterna"):  return "alternativa"
    if chave.startswith("revis"):    return "revisoes"
    if chave.startswith("observa"):  return "observacoes"
    if chave.startswith("anexo"):    return "anexos"
    return chave.replace(" ", "_")


def _extrair_campos_texto(corpo: str) -> dict[str, str]:
    campos: dict[str, str] = {}
    delimitadores_re = "|".join(re.escape(c) for c in _CAMPOS_TEXTO)
    delimitadores_re += (
        "|Anexo:|Anexos:|SS:|SSC:|Tópico:|Nível:|TRÂMITES"
        "|GERAR TRÂMITE|PROCURAR SAI|PROCURAR PRÉ-SAI|Legenda"
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
        "NOTIFICAÇÃO DE ERRO": "NE", "NOTIFICACAO DE ERRO": "NE",
        "SOLICITAÇÃO DE MELHORIA": "SAM", "SOLICITACAO DE MELHORIA": "SAM",
        "SOLICITAÇÃO DE ALTERAÇÃO LEGAL": "SAL", "SOLICITACAO DE ALTERACAO LEGAL": "SAL",
        "SOLICITAÇÃO DE IMPLEMENTAÇÃO LEGAL": "SAIL", "SOLICITACAO DE IMPLEMENTACAO LEGAL": "SAIL",
    }
    corpo_upper = corpo.upper()
    for texto, sigla in mapa.items():
        if texto in corpo_upper:
            return sigla
    m = re.search(r"Tipo[:\s]+(NE|SAM|SAL|SAIL|SA)\b", corpo, re.IGNORECASE)
    if m:
        return m.group(1).upper()
    return "SA"


def _cortar_rodape(corpo: str) -> str:
    pos_tram = max(corpo.find("TRÂMITES"), corpo.find("TRAMITES"))
    n = len(corpo)
    limite_fim = max(int(n * 0.88), n - 8000)
    for marcador in ("GERAR TRÂMITE", "GERAR TRAMITE", "PROCURAR SAI", "PROCURAR PRÉ-SAI"):
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
        desc = desc.strip()
        tramites_completos.append({"numero": num, "usuario": usuario.strip(), "data": data.strip(), "descricao": desc})
        if desc and desc.lower() != "nenhuma":
            historico.append(f"[{num:>02}] {data} | {usuario.strip()} | {desc[:300]}")
    return tramites_completos, historico


# ─── Sessão SGSAI ────────────────────────────────────────────────────────────

class SAISession:
    def __init__(self, playwright: Playwright) -> None:
        self._playwright = playwright
        self._browser: Browser | None = None
        self._context: BrowserContext | None = None
        self._session_file = _sai_session_file()

    async def _iniciar_browser(self) -> None:
        self._browser = await self._playwright.chromium.launch(headless=settings.SCRAPER_HEADLESS)
        logger.info(f"Browser SAI iniciado (headless={settings.SCRAPER_HEADLESS})")

    async def _carregar_sessao(self) -> bool:
        if not self._session_file.exists():
            return False
        try:
            self._context = await self._browser.new_context(storage_state=str(self._session_file))
            page = await self._context.new_page()
            await page.goto(f"{_URL_BASE_SAI}/sgsai/faces/sais.html", timeout=settings.SCRAPER_TIMEOUT_MS)
            await page.wait_for_load_state("domcontentloaded", timeout=settings.SCRAPER_TIMEOUT_MS)
            if "login" not in page.url.lower():
                logger.info("Sessão SAI reutilizada.")
                await page.close()
                return True
            logger.info("Sessão SAI expirada — novo login necessário.")
            await page.close()
            await self._context.close()
            self._context = None
            return False
        except Exception as e:
            logger.warning(f"Falha ao carregar sessão SAI: {e}")
            if self._context:
                await self._context.close()
                self._context = None
            return False

    async def _fazer_login(self) -> None:
        settings.validate()
        self._context = await self._browser.new_context()
        page = await self._context.new_page()
        try:
            logger.info(f"Acessando login SGSAI: {_URL_LOGIN_SAI}")
            await page.goto(_URL_LOGIN_SAI, wait_until="domcontentloaded", timeout=settings.SCRAPER_TIMEOUT_MS)
            campo_user = await page.wait_for_selector(_LOGIN_SELECTORS["username"], timeout=settings.SCRAPER_TIMEOUT_MS)
            await campo_user.fill(settings.SGD_USERNAME)
            campo_senha = await page.wait_for_selector(_LOGIN_SELECTORS["password"], timeout=settings.SCRAPER_TIMEOUT_MS)
            await campo_senha.fill(settings.SGD_PASSWORD)
            botao = await page.wait_for_selector(_LOGIN_SELECTORS["submit"], timeout=settings.SCRAPER_TIMEOUT_MS)
            await botao.click(no_wait_after=True, timeout=settings.SCRAPER_TIMEOUT_MS)
            timeout_login = settings.SCRAPER_TIMEOUT_MS * 4
            try:
                await page.wait_for_url(lambda url: "login" not in url.lower(), timeout=timeout_login)
            except Exception:
                await page.wait_for_selector(".menu-principal, #menu, nav, .navbar", timeout=timeout_login)
            if "login" in page.url.lower():
                raise RuntimeError("Login SGSAI falhou — verifique SGD_USERNAME e SGD_PASSWORD.")
            self._session_file.parent.mkdir(parents=True, exist_ok=True)
            await self._context.storage_state(path=str(self._session_file))
            logger.info(f"Login SGSAI bem-sucedido. Sessão salva em {self._session_file}")
        finally:
            await page.close()

    async def conectar(self) -> None:
        await self._iniciar_browser()
        if not await self._carregar_sessao():
            await self._fazer_login()

    async def nova_pagina(self) -> Page:
        if self._context is None:
            raise RuntimeError("Sessão SAI não iniciada.")
        page = await self._context.new_page()
        page.set_default_timeout(settings.SCRAPER_TIMEOUT_MS)
        return page

    async def fechar(self) -> None:
        if self._context:
            await self._context.close()
        if self._browser:
            await self._browser.close()
        logger.info("Browser SAI encerrado.")


@asynccontextmanager
async def sessao_sai() -> AsyncGenerator[SAISession, None]:
    async with async_playwright() as pw:
        session = SAISession(pw)
        try:
            await session.conectar()
            yield session
        finally:
            await session.fechar()


# ─── Consulta principal ───────────────────────────────────────────────────────

async def consultar_sai(numero: str, *, arquivo: bool = True) -> dict:
    url = _URL_DETALHE.format(numero=numero)
    resultado: dict = {"numero": numero, "url": url}

    async with sessao_sai() as session:
        page = await session.nova_pagina()
        logger.info(f"Acessando: {url}")
        await page.goto(url, wait_until="domcontentloaded")
        await page.wait_for_load_state("domcontentloaded")

        if "login" in page.url.lower():
            raise RuntimeError("Sessão SGSAI expirada — refaça o login.")

        corpo = await page.inner_text("body")
        html  = await page.content()
        corpo_principal = _cortar_rodape(corpo)

        resultado["tipo"]      = _extrair_tipo(corpo_principal)
        resultado["cabecalho"] = _extrair_cabecalho(corpo_principal)
        resultado["textos"]    = _extrair_campos_texto(corpo_principal)
        tr_completos, tr_hist  = _extrair_tramites(corpo_principal)
        resultado["tramites"]  = tr_completos
        resultado["historico"] = tr_hist

        out_dir = settings.CONSULTAS_DIR
        out_dir.mkdir(parents=True, exist_ok=True)

        if arquivo:
            run_id   = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
            base_arq = out_dir / "arquivo" / f"sai_{numero}"
            run_dir  = base_arq / run_id
            run_dir.mkdir(parents=True, exist_ok=True)
            (run_dir / "body_inner_text.txt").write_text(corpo_principal, encoding="utf-8", errors="replace")
            (run_dir / "page.html").write_text(html, encoding="utf-8", errors="replace")
            shot = run_dir / "screenshot.png"
            await page.screenshot(path=str(shot), full_page=True)
            resultado["arquivo_local"] = str(run_dir)
            resultado["screenshot"]    = str(shot)
            (run_dir / "consulta.json").write_text(
                json.dumps(resultado, ensure_ascii=False, indent=2, default=str),
                encoding="utf-8",
            )
            logger.info(f"Arquivo local: {run_dir}")
        else:
            shot = out_dir / f"sai_{numero}.png"
            await page.screenshot(path=str(shot), full_page=True)
            resultado["screenshot"] = str(shot)

        await page.close()

    return resultado


# ─── Impressão ────────────────────────────────────────────────────────────────

def _imprimir(dados: dict) -> None:
    sep = "=" * 70
    tipo = dados.get("tipo", "SA")
    cab  = dados.get("cabecalho", {})
    numero = cab.get("numero", dados["numero"])

    print(f"\n{sep}")
    print(f"  SAI #{numero}  [{tipo}]")
    print(f"  URL: {dados['url']}")
    print(sep)

    ordem_cab = ["data", "situacao", "sistema", "modulo", "submodulo", "versao",
                 "usuario", "responsavel", "tipo", "gravidade", "area", "psai"]
    if cab:
        print("\n[CABECALHO]")
        for chave in ordem_cab:
            if chave in cab and cab[chave]:
                print(f"  {chave.replace('_', ' ').upper():<22} {cab[chave]}")

    textos = dados.get("textos", {})
    exibidos: set[str] = set()

    print("\n[ORDEM DE CONFERENCIA — texto da SAI]")
    print("-" * 70)
    print("  1) Definicao  2) Comportamento  3) Observacoes  4) Anexos  5) Tramites")

    for chave in _ORDEM_CONFERENCIA:
        if chave in textos and textos[chave]:
            valor = textos[chave]
            if valor.strip().lower() in ("nenhuma", ""):
                continue
            print(f"\n[{chave.replace('_', ' ').upper()}]")
            print("-" * 70)
            for linha in valor.splitlines():
                print(f"  {linha}")
            exibidos.add(chave)

    for chave, valor in textos.items():
        if chave not in exibidos and valor and valor.strip().lower() not in ("nenhuma", ""):
            print(f"\n[{chave.replace('_', ' ').upper()}]")
            print("-" * 70)
            for linha in valor.splitlines():
                print(f"  {linha}")

    trs = dados.get("tramites") or []
    if trs:
        print(f"\n[TRAMITES] ({len(trs)} registros)")
        print("-" * 70)
        for tr in trs:
            desc = tr.get("descricao") or "(sem descricao)"
            print(f"  #{tr.get('numero','?')} | {tr.get('data','?')} | {tr.get('usuario','?')} | {desc[:400]}")

    if dados.get("arquivo_local"):
        print(f"\nArquivo local: {dados['arquivo_local']}")
    if dados.get("screenshot"):
        print(f"Screenshot: {dados['screenshot']}")
    print(f"\n{sep}\n")


def _salvar_json(dados: dict, dest: Path) -> Path:
    dest = dest.resolve()
    dest.parent.mkdir(parents=True, exist_ok=True)
    with dest.open("w", encoding="utf-8") as f:
        json.dump(dados, f, ensure_ascii=False, indent=2, default=str)
    return dest


async def main() -> None:
    parser = argparse.ArgumentParser(
        description="Consulta SAI no SGSAI (Playwright) e extrai campos de texto e trâmites.",
    )
    parser.add_argument("numero", help="Numero da SAI (ex: 101293)")
    parser.add_argument("--json", action="store_true",
                        help="Grava JSON em scripts/sgd_consulta/data/consultas/sai_<numero>.json")
    parser.add_argument("--quiet", action="store_true",
                        help="Com --json: nao imprime relatorio; so grava e imprime caminho")
    parser.add_argument("--no-arquivo", action="store_true",
                        help="Nao grava pasta arquivo/; so screenshot simples")
    args = parser.parse_args()
    if args.quiet and not args.json:
        parser.error("--quiet exige --json")

    numero = args.numero.strip()
    logger.info(f"Consultando SAI #{numero}...")
    dados = await consultar_sai(numero, arquivo=not args.no_arquivo)

    json_path: Path | None = None
    if args.json:
        json_path = settings.CONSULTAS_DIR / f"sai_{numero}.json"
        json_path = _salvar_json(dados, json_path)
        if args.quiet:
            print(str(json_path))
        else:
            print(f"\nJSON salvo em: {json_path}")

    if not (args.json and args.quiet):
        _imprimir(dados)


if __name__ == "__main__":
    asyncio.run(main())
