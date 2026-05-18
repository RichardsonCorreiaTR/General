"""
Analisa legislacao (lei, decreto, portaria, IN, resolucao) via Claude AI.

Uso (a partir da raiz do projeto-filho ou General):
    python scripts/sgd_consulta/consultar_legislacao.py --url "https://..."
    python scripts/sgd_consulta/consultar_legislacao.py --arquivo "lei.pdf"
    python scripts/sgd_consulta/consultar_legislacao.py --url "..." --pergunta "Qual o prazo?"
    python scripts/sgd_consulta/consultar_legislacao.py --url "..." --json

Requer: ANTHROPIC_API_KEY no arquivo scripts/sgd_consulta/.env ou no ambiente.
"""
from __future__ import annotations

import argparse
import json
import logging
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

logger = logging.getLogger(__name__)

_MODELO_PADRAO = "claude-sonnet-4-6"

_PROMPT_RESUMO = """
Voce e um assistente especializado em legislacao fiscal e tributaria brasileira,
atuando como suporte a analistas de produto do modulo Escrita Fiscal.

Analise o texto da legislacao abaixo e forneca um resumo estruturado com:

1. **Identificacao**: Nome/numero do ato normativo, orgao emissor, data de publicacao
2. **Objetivo**: O que a legislacao regula ou determina
3. **Principais obrigacoes e determinacoes**: Pontos mais importantes (lista)
4. **Prazos e vigencias**: Datas e prazos relevantes
5. **A quem se aplica**: Contribuintes, empresas ou situacoes afetadas
6. **Pontos de atencao**: Aspectos criticos para implementacao ou cumprimento fiscal

Use linguagem tecnica clara. Cite artigos e paragrafos relevantes quando possivel.

LEGISLACAO:
{texto}
""".strip()

_PROMPT_PERGUNTA = """
Voce e um assistente especializado em legislacao fiscal e tributaria brasileira,
atuando como suporte a analistas de produto do modulo Escrita Fiscal.

Com base na legislacao abaixo, responda a pergunta do analista de forma precisa.
Cite os artigos, paragrafos e incisos relevantes quando possivel.

LEGISLACAO:
{texto}

PERGUNTA DO ANALISTA:
{pergunta}
""".strip()


def _carregar_env() -> None:
    """Carrega variaveis do arquivo .env (se existir)."""
    env_candidates = [
        _SCRIPT_DIR / ".env",
        _SCRIPT_DIR.parent.parent / "scripts" / "sgd_consulta" / ".env",
    ]
    try:
        from dotenv import load_dotenv
        for env_path in env_candidates:
            if env_path.exists():
                load_dotenv(env_path, override=False)
                break
    except ImportError:
        pass


def _get_api_key() -> str:
    key = os.environ.get("ANTHROPIC_API_KEY", "").strip()
    if not key:
        raise RuntimeError(
            "ANTHROPIC_API_KEY nao encontrada.\n"
            "Configure em scripts\\sgd_consulta\\.env:\n"
            "  ANTHROPIC_API_KEY=sk-ant-...\n"
            "Ou exporte no terminal:\n"
            "  $env:ANTHROPIC_API_KEY = 'sk-ant-...'"
        )
    return key


def buscar_url(url: str, timeout: int = 30) -> str:
    """Busca conteudo de uma URL e retorna texto extraido."""
    try:
        import httpx
        from bs4 import BeautifulSoup
    except ImportError:
        raise RuntimeError(
            "Dependencias faltando. Execute:\n  pip install httpx beautifulsoup4"
        )

    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/124.0.0.0 Safari/537.36"
        )
    }

    with httpx.Client(follow_redirects=True, timeout=timeout) as client:
        resp = client.get(url, headers=headers)
        resp.raise_for_status()
        content_type = resp.headers.get("content-type", "")

        if "pdf" in content_type:
            import tempfile
            with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as f:
                f.write(resp.content)
                tmp = Path(f.name)
            texto = ler_arquivo(tmp)
            tmp.unlink(missing_ok=True)
            return texto

        soup = BeautifulSoup(resp.text, "html.parser")
        for tag in soup(["script", "style", "nav", "footer", "header", "aside"]):
            tag.decompose()
        texto = soup.get_text(separator="\n", strip=True)
        texto = re.sub(r"\n{3,}", "\n\n", texto)
        return texto.strip()


def ler_arquivo(path: Path) -> str:
    """Le conteudo de um arquivo (txt, md, pdf, docx)."""
    sufixo = path.suffix.lower()

    if sufixo == ".pdf":
        try:
            import pdfplumber
        except ImportError:
            raise RuntimeError(
                "pdfplumber nao instalado. Execute:\n  pip install pdfplumber"
            )
        paginas: list[str] = []
        with pdfplumber.open(path) as pdf:
            for pagina in pdf.pages:
                texto = pagina.extract_text()
                if texto:
                    paginas.append(texto)
        return "\n\n".join(paginas)

    if sufixo == ".docx":
        try:
            import docx
        except ImportError:
            raise RuntimeError(
                "python-docx nao instalado. Execute:\n  pip install python-docx"
            )
        doc = docx.Document(str(path))
        return "\n".join(p.text for p in doc.paragraphs if p.text.strip())

    return path.read_text(encoding="utf-8", errors="replace")


def analisar_com_claude(
    texto: str,
    pergunta: Optional[str],
    modelo: str,
    max_tokens: int = 4096,
) -> str:
    """Envia texto para Claude e retorna a analise."""
    try:
        import anthropic
    except ImportError:
        raise RuntimeError(
            "anthropic nao instalado. Execute:\n  pip install anthropic"
        )

    api_key = _get_api_key()
    client = anthropic.Anthropic(api_key=api_key)

    # Truncar texto muito longo (limite seguro ~600k chars)
    max_chars = 600_000
    if len(texto) > max_chars:
        texto = texto[:max_chars] + "\n\n[...texto truncado por limite de tamanho...]"
        logger.warning("Texto truncado para %d caracteres.", max_chars)

    if pergunta:
        prompt = _PROMPT_PERGUNTA.format(texto=texto, pergunta=pergunta)
    else:
        prompt = _PROMPT_RESUMO.format(texto=texto)

    msg = client.messages.create(
        model=modelo,
        max_tokens=max_tokens,
        messages=[{"role": "user", "content": prompt}],
    )
    return msg.content[0].text


def salvar_resultado(resultado: dict, saida_dir: Path) -> Path:
    """Salva resultado em JSON na pasta de saida."""
    saida_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    fonte_slug = re.sub(r"[^\w-]", "_", resultado.get("fonte", "legislacao")[:40])
    arquivo = saida_dir / f"{fonte_slug}_{ts}.json"
    arquivo.write_text(
        json.dumps(resultado, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return arquivo


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Analisa legislacao via Claude AI",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Exemplos:\n"
            "  python consultar_legislacao.py --url https://www.planalto.gov.br/...\n"
            "  python consultar_legislacao.py --arquivo lei.pdf\n"
            "  python consultar_legislacao.py --url https://... --pergunta 'Qual o prazo?'\n"
        ),
    )
    parser.add_argument("--url", help="URL da legislacao a analisar")
    parser.add_argument("--arquivo", help="Caminho para arquivo local (PDF, TXT, DOCX, MD)")
    parser.add_argument("--pergunta", help="Pergunta especifica (padrao: gera resumo completo)")
    parser.add_argument(
        "--modelo",
        default=_MODELO_PADRAO,
        help=f"Modelo Claude a usar (padrao: {_MODELO_PADRAO})",
    )
    parser.add_argument("--saida", default=None, help="Pasta de saida para o JSON")
    parser.add_argument("--json", action="store_true", dest="json_out", help="Imprime saida JSON")
    args = parser.parse_args()

    if not args.url and not args.arquivo:
        parser.error("Informe --url ou --arquivo")

    _carregar_env()

    # Resolver pasta de saida
    if args.saida:
        saida_dir = Path(args.saida)
    else:
        # Sobe 3 niveis: sgd_consulta/ -> scripts/ -> raiz do projeto
        root = _SCRIPT_DIR.parent.parent
        saida_dir = root / "data" / "legislacao"

    # Obter texto da fonte
    fonte = args.url or args.arquivo
    if args.url:
        print(f"[legislacao] Buscando URL: {args.url}", file=sys.stderr)
        texto = buscar_url(args.url)
        print(f"[legislacao] {len(texto)} caracteres obtidos.", file=sys.stderr)
    else:
        caminho = Path(args.arquivo)
        if not caminho.exists():
            print(f"[legislacao] Erro: arquivo nao encontrado: {caminho}", file=sys.stderr)
            sys.exit(1)
        print(f"[legislacao] Lendo arquivo: {caminho}", file=sys.stderr)
        texto = ler_arquivo(caminho)
        print(f"[legislacao] {len(texto)} caracteres extraidos.", file=sys.stderr)

    print(f"[legislacao] Analisando com {args.modelo}...", file=sys.stderr)
    resposta = analisar_com_claude(texto, args.pergunta, args.modelo)

    resultado = {
        "fonte": fonte,
        "tipo": "url" if args.url else "arquivo",
        "pergunta": args.pergunta or "resumo",
        "modelo": args.modelo,
        "data": datetime.now().isoformat(),
        "resposta": resposta,
        "chars_texto": len(texto),
    }

    arquivo_json = salvar_resultado(resultado, saida_dir)
    print(f"[legislacao] Resultado salvo: {arquivo_json}", file=sys.stderr)

    if args.json_out:
        print(json.dumps(resultado, ensure_ascii=False, indent=2))
    else:
        print()
        print("=" * 70)
        print(resposta)
        print("=" * 70)


if __name__ == "__main__":
    logging.basicConfig(level=logging.WARNING)
    main()
