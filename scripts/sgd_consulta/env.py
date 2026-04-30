"""Configuração local da consulta SGD (sem dependência do repositório SGD).

Credenciais SGD (SGD_USERNAME / SGD_PASSWORD) **não** vêm dos `.env` gerais do projeto.

Ordem de preenchimento: (1) variáveis de ambiente já definidas; (2) ficheiros locais
(ver `_merge_local_sgd_credentials_file`); (3) terminal interativo pede utilizador e senha.

**Projeto-filho (analista):** defina `SGD_SGD_DATA_ROOT` para a pasta `data/sgd-psai-consultas`
do projeto-filho antes de invocar o Python — consultas, arquivo, logs e sessão Playwright
ficam todas nesse diretório (dados por analista na cópia local do projeto-filho).
"""
from __future__ import annotations

import getpass
import hashlib
import logging
import os
import sys
from pathlib import Path

from dotenv import dotenv_values

PACKAGE_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = PACKAGE_DIR.parent.parent

_CRED_KEYS = frozenset({"SGD_USERNAME", "SGD_PASSWORD"})


def _sgd_data_root() -> Path | None:
    """Raiz opcional para consultas + sessão (ex.: projeto-filho/data/sgd-psai-consultas)."""
    raw = os.getenv("SGD_SGD_DATA_ROOT", "").strip()
    if not raw:
        return None
    return Path(raw).resolve()


def _consultas_dir() -> Path:
    root = _sgd_data_root()
    if root is not None:
        return (root / "consultas").resolve()
    return (PACKAGE_DIR / "data" / "consultas").resolve()


def _merge_dotenv_no_sgd_creds(path: Path) -> None:
    """Carrega .env sem propagar utilizador/senha SGD (evita reutilizar credenciais de outra pessoa)."""
    if not path.is_file():
        return
    for k, v in dotenv_values(path).items():
        if k in _CRED_KEYS:
            continue
        if v is None:
            continue
        if k not in os.environ:
            os.environ[k] = str(v)


_merge_dotenv_no_sgd_creds(PACKAGE_DIR / ".env")
_merge_dotenv_no_sgd_creds(PROJECT_ROOT / ".env")


def _credential_file_candidates() -> list[Path]:
    """Ordem: ficheiro explícito → projeto-filho (analista) → pasta do script General."""
    paths: list[Path] = []
    explicit = os.getenv("SGD_CREDENTIALS_FILE", "").strip()
    if explicit:
        paths.append(Path(explicit))
    paths.append(
        PROJECT_ROOT
        / "projeto-filho"
        / "data"
        / "sgd-psai-consultas"
        / ".sgd-credentials.local"
    )
    paths.append(PACKAGE_DIR / ".sgd-credentials.local")
    return paths


def _merge_local_sgd_credentials_file() -> None:
    """Carrega SGD_USERNAME / SGD_PASSWORD a partir do primeiro ficheiro dotenv candidato."""
    for path in _credential_file_candidates():
        if not path.is_file():
            continue
        for k, v in dotenv_values(path).items():
            if k not in _CRED_KEYS or v is None:
                continue
            val = str(v).strip()
            if not val:
                continue
            if os.getenv(k, "").strip():
                continue
            os.environ[k] = val


_merge_local_sgd_credentials_file()


def _ensure_sgd_credentials() -> None:
    """Garante SGD_USERNAME e SGD_PASSWORD no ambiente; pede no terminal se faltar."""
    if os.getenv("SGD_USERNAME", "").strip() and os.getenv("SGD_PASSWORD", ""):
        return
    if not sys.stdin.isatty():
        raise ValueError(
            "Credenciais SGD em falta. Corra a partir de um terminal interativo "
            "(scripts\\Consultar-PSAI-SGD.ps1 ou projeto-filho\\scripts\\Consultar-PSAI-SGD.ps1), "
            "ou defina SGD_USERNAME e SGD_PASSWORD no ambiente antes de invocar o Python."
        )
    print(
        "SGD: indique o seu utilizador e senha (ou crie .sgd-credentials.local em "
        "projeto-filho/data/sgd-psai-consultas/ ou em scripts/sgd_consulta/).",
        file=sys.stderr,
    )
    u = input("Utilizador SGD: ").strip()
    if not u:
        raise ValueError("Utilizador SGD vazio.")
    p = getpass.getpass("Senha SGD: ")
    if not p:
        raise ValueError("Senha SGD vazia.")
    os.environ["SGD_USERNAME"] = u
    os.environ["SGD_PASSWORD"] = p


_ensure_sgd_credentials()


def _session_file_path() -> Path:
    override = os.getenv("SCRAPER_SESSION_FILE", "").strip()
    if override:
        return Path(override)
    u = os.getenv("SGD_USERNAME", "").strip()
    h = hashlib.sha256(u.encode("utf-8")).hexdigest()[:16] if u else "none"
    root = _sgd_data_root()
    if root is not None:
        root.mkdir(parents=True, exist_ok=True)
        return (root / f"session_state_{h}.json").resolve()
    return (PACKAGE_DIR / "data" / f"session_state_{h}.json").resolve()


_CONSULTAS_DIR = _consultas_dir()


class Settings:
    SGD_URL: str = os.getenv("SGD_URL", "https://sgd.dominiosistemas.com.br")
    SGD_USERNAME: str = os.getenv("SGD_USERNAME", "")
    SGD_PASSWORD: str = os.getenv("SGD_PASSWORD", "")

    SCRAPER_HEADLESS: bool = os.getenv("SCRAPER_HEADLESS", "true").lower() == "true"
    SCRAPER_TIMEOUT_MS: int = int(os.getenv("SCRAPER_TIMEOUT_MS", "15000"))
    SESSION_FILE: Path = _session_file_path()
    CONSULTAS_DIR: Path = _CONSULTAS_DIR

    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")

    def validate(self) -> None:
        if not self.SGD_USERNAME or not self.SGD_PASSWORD:
            raise ValueError(
                "SGD_USERNAME e SGD_PASSWORD são obrigatórios (terminal interativo ou variáveis de ambiente)."
            )


settings = Settings()

logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL, logging.INFO),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
_logger = logging.getLogger(__name__)
_logger.info(
    "SGD: consulta como utilizador '%s' (sessão: %s; consultas: %s)",
    settings.SGD_USERNAME,
    settings.SESSION_FILE.name,
    settings.CONSULTAS_DIR,
)
