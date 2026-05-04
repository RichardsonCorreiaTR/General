"""
Quando os fracionados em banco-dados/dados-brutos/psai/*.json tiverem
comportamento e/ou definicao (e opcionalmente psai_descricao) vazios,
consulta o SGD e grava esses campos a partir do texto extraido (Playwright).

Uso (credenciais: mesmo fluxo que consultar_psai.py / Consultar-PSAI-SGD.ps1):
  python enriquecer_psai_dados_brutos.py 130475
  python enriquecer_psai_dados_brutos.py 130475 130476 --dry-run

Usa scripts/.update-lock.json (mesmo esquema que lib-lock.ps1).
"""
from __future__ import annotations

import argparse
import asyncio
import json
import logging
import sys
from datetime import datetime
from pathlib import Path

_SCRIPT_DIR = Path(__file__).resolve().parent
_PROJETO_ROOT = _SCRIPT_DIR.parent.parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from consultar_psai import consultar_psai

logger = logging.getLogger(__name__)

_LOCK_REL = Path("scripts") / ".update-lock.json"
_LOCK_MAX_MIN = 30


def _lock_path() -> Path:
    return _PROJETO_ROOT / _LOCK_REL


def _request_lock(operacao: str) -> bool:
    import os

    lock = _lock_path()
    lock.parent.mkdir(parents=True, exist_ok=True)
    if lock.is_file():
        try:
            data = json.loads(lock.read_text(encoding="utf-8"))
            iniciado = datetime.fromisoformat(str(data.get("iniciadoEm", "")))
            age_min = (datetime.now() - iniciado).total_seconds() / 60.0
            if age_min < _LOCK_MAX_MIN:
                print(
                    f"BLOQUEADO: {data.get('usuario')} em {data.get('operacao')} "
                    f"(ha {age_min:.0f} min). Ficheiro: {lock}",
                    file=sys.stderr,
                )
                return False
        except (OSError, ValueError, TypeError):
            pass
        lock.unlink(missing_ok=True)
    payload = {
        "usuario": os.environ.get("USERNAME", ""),
        "computador": os.environ.get("COMPUTERNAME", ""),
        "operacao": operacao,
        "iniciadoEm": datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
    }
    lock.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    return True


def _release_lock() -> None:
    try:
        _lock_path().unlink(missing_ok=True)
    except OSError:
        pass


def _vazio(v: object) -> bool:
    if v is None:
        return True
    s = str(v).strip()
    return not s or s.lower() == "nenhuma"


def _localizar_registro_psai(i_psai: int) -> tuple[Path, dict, int] | None:
    psai_dir = _PROJETO_ROOT / "banco-dados" / "dados-brutos" / "psai"
    if not psai_dir.is_dir():
        logger.error("Pasta nao encontrada: %s", psai_dir)
        return None
    for path in sorted(psai_dir.glob("*.json")):
        try:
            doc = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as e:
            logger.warning("Ignorar %s: %s", path.name, e)
            continue
        dados = doc.get("dados")
        if not isinstance(dados, list):
            continue
        for idx, rec in enumerate(dados):
            if not isinstance(rec, dict):
                continue
            try:
                n = int(rec.get("i_psai") or 0)
            except (TypeError, ValueError):
                continue
            if n == i_psai:
                return path, doc, idx
    return None


def _aplicar_textos_sgd(rec: dict, textos: dict[str, str], *, dry_run: bool) -> list[str]:
    """Preenche apenas campos locais vazios (consultar_psai ja aplicou reconciliacao NE)."""
    alteracoes: list[str] = []
    t = textos or {}

    if _vazio(rec.get("comportamento")) and not _vazio(t.get("comportamento")):
        alteracoes.append("comportamento")
        if not dry_run:
            rec["comportamento"] = (t.get("comportamento") or "").strip()
    if _vazio(rec.get("definicao")) and not _vazio(t.get("definicao")):
        alteracoes.append("definicao")
        if not dry_run:
            rec["definicao"] = (t.get("definicao") or "").strip()
    if _vazio(rec.get("psai_descricao")) and not _vazio(t.get("descricao")):
        alteracoes.append("psai_descricao")
        if not dry_run:
            rec["psai_descricao"] = (t.get("descricao") or "").strip()
    return alteracoes


def _gravar_fracionado(path: Path, doc: dict) -> None:
    # Mesmo estilo compacto que os scripts PowerShell (menor ficheiro).
    txt = json.dumps(doc, ensure_ascii=False, separators=(",", ":"))
    path.write_text(txt, encoding="utf-8")


async def _enriquecer_um(i_psai: int, *, dry_run: bool, arquivo_sgd: bool) -> int:
    loc = _localizar_registro_psai(i_psai)
    if not loc:
        print(f"  [{i_psai}] ERRO: nao encontrado em banco-dados/dados-brutos/psai/*.json", file=sys.stderr)
        return 1
    path, doc, idx = loc
    rec = doc["dados"][idx]
    falta_comp_ou_def = _vazio(rec.get("comportamento")) or _vazio(rec.get("definicao"))
    falta_desc = _vazio(rec.get("psai_descricao"))
    if not falta_comp_ou_def and not falta_desc:
        print(f"  [{i_psai}] OK ja tem comportamento, definicao e psai_descricao — nada a fazer.")
        return 0

    logger.info("SGD: consultar PSAI %s…", i_psai)
    dados = await consultar_psai(str(i_psai), arquivo=arquivo_sgd)
    textos = dados.get("textos") or {}

    chg = _aplicar_textos_sgd(rec, textos, dry_run=dry_run)
    if not chg:
        print(
            f"  [{i_psai}] AVISO: SGD nao devolveu texto para campos vazios "
            f"(ver data/consultas/psai_{i_psai}.json). Ficheiro: {path.name}",
            file=sys.stderr,
        )
        return 2

    print(f"  [{i_psai}] {'[dry-run] ' if dry_run else ''}Atualizar {', '.join(chg)} em {path.name}")
    if not dry_run:
        _gravar_fracionado(path, doc)
    return 0


async def main_async(argv: list[str] | None) -> int:
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    p = argparse.ArgumentParser(description="Enriquece fracionados PSAI a partir do SGD.")
    p.add_argument("numeros", nargs="+", help="Numeros i_psai (ex: 130475)")
    p.add_argument("--dry-run", action="store_true", help="So mostra alteracoes; nao grava")
    p.add_argument(
        "--arquivo-sgd",
        action="store_true",
        help="Grava pacote completo consulta SGD (HTML/screenshots); por defeito so consulta leve.",
    )
    args = p.parse_args(argv)

    numeros: list[int] = []
    for raw in args.numeros:
        try:
            numeros.append(int(str(raw).strip()))
        except ValueError:
            print(f"Numero invalido: {raw}", file=sys.stderr)
            return 1

    if not _request_lock("enriquecer_psai_dados_brutos"):
        return 1
    rc = 0
    try:
        for n in numeros:
            r = await _enriquecer_um(n, dry_run=args.dry_run, arquivo_sgd=args.arquivo_sgd)
            if r > rc:
                rc = r
    finally:
        _release_lock()
    return rc


def main() -> None:
    raise SystemExit(asyncio.run(main_async(sys.argv[1:])))


if __name__ == "__main__":
    main()
