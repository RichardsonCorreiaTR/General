"""
Arquivo local de cada consulta PSAI: HTML, texto completo, imagens, manifesto
e linha de log para melhoria de regras de extração no General.
"""
from __future__ import annotations

import hashlib
import json
import logging
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)


def _utc_run_id() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def _hash_user(user: str) -> str:
    u = (user or "").strip()
    if not u:
        return "none"
    return hashlib.sha256(u.encode("utf-8")).hexdigest()[:16]


def diagnosticar_extracao(
    *,
    numero: str,
    tipo: str,
    textos: dict[str, str],
    tramites: list[dict],
    corpo_raw: str,
    corpo_principal: str,
    html_len: int,
) -> list[dict[str, Any]]:
    """Sinais para o General afinar regex / fluxos (sem dados sensíveis longos)."""
    avisos: list[dict[str, Any]] = []

    if not corpo_raw or len(corpo_raw) < 200:
        avisos.append(
            {
                "codigo": "CORPO_MUITO_CURTO",
                "severidade": "alta",
                "detalhe": f"inner_text body tem {len(corpo_raw)} caracteres",
            }
        )

    if "TRÂMITES" not in corpo_raw and "TRAMITES" not in corpo_raw.upper():
        avisos.append(
            {
                "codigo": "SEM_MARCADOR_TRAMITES_TEXTO",
                "severidade": "media",
                "detalhe": "Texto plano não contém secção TRÂMITES; regex de trâmites pode falhar",
            }
        )

    if not tramites:
        avisos.append(
            {
                "codigo": "TRAMITES_VAZIO",
                "severidade": "media",
                "detalhe": "Nenhum trâmite capturado pelo padrão atual",
            }
        )

    esperados_por_tipo: dict[str, list[str]] = {
        # NE: definição costuma vazia; o reprodutível está em comportamento (revisar-psai.mdc).
        "NE": ["descricao", "comportamento"],
        "SAM": ["descricao", "definicao"],
        "SAL": ["descricao", "definicao"],
        "SAIL": ["descricao", "definicao"],
        "SA": ["descricao", "definicao"],
    }
    esp = esperados_por_tipo.get(tipo, esperados_por_tipo["SA"])
    for ch in esp:
        v = (textos.get(ch) or "").strip()
        if not v or v.lower() == "nenhuma":
            avisos.append(
                {
                    "codigo": "CAMPO_ESPERADO_VAZIO",
                    "severidade": "alta",
                    "detalhe": f"Campo '{ch}' vazio ou 'nenhuma' para tipo {tipo}",
                }
            )

    definicao = (textos.get("definicao") or "").strip()
    if definicao and len(definicao) < 80 and "REGISTRO" in definicao.upper():
        avisos.append(
            {
                "codigo": "DEFINICAO_POSSIVELMENTE_TRUNCADA",
                "severidade": "media",
                "detalhe": "Definição curta mas menciona REGISTRO — verificar corte de rodapé / DOM",
            }
        )

    if html_len < 5000:
        avisos.append(
            {
                "codigo": "HTML_PEQUENO",
                "severidade": "baixa",
                "detalhe": f"HTML com {html_len} bytes — página pode estar incompleta ou login",
            }
        )

    return avisos


def extrair_links_html(html: str, max_links: int = 80) -> list[str]:
    hrefs = re.findall(r'href\s*=\s*"([^"]+)"', html, re.IGNORECASE)
    out: list[str] = []
    for h in hrefs:
        h = h.strip()
        if not h or h.startswith("#") or h.startswith("javascript:"):
            continue
        out.append(h)
        if len(out) >= max_links:
            break
    return out


async def salvar_pacote_consulta(
    *,
    numero: str,
    consultas_dir: Path,
    usuario_sgd: str,
    corpo_raw: str,
    corpo_principal: str,
    html: str,
    resultado: dict[str, Any],
    page: Any,
) -> dict[str, Any]:
    """
    Grava pasta timestamped em consultas/arquivo/psai_<n>/<run_id>/ e atualiza resultado com caminhos.
    Retorna manifest (também escrito em manifest.json).
    """
    run_id = _utc_run_id()
    base_arquivo = consultas_dir / "arquivo" / f"psai_{numero}"
    run_dir = base_arquivo / run_id
    run_dir.mkdir(parents=True, exist_ok=True)

    (run_dir / "body_inner_text_bruto.txt").write_text(corpo_raw, encoding="utf-8", errors="replace")
    (run_dir / "body_inner_text_principal.txt").write_text(
        corpo_principal, encoding="utf-8", errors="replace"
    )
    (run_dir / "page.html").write_text(html, encoding="utf-8", errors="replace")

    shot_full = run_dir / "screenshot_pagina_completa.png"
    await page.screenshot(path=str(shot_full), full_page=True)
    shot_vp = run_dir / "screenshot_viewport.png"
    await page.screenshot(path=str(shot_vp), full_page=False)

    tabelas_gravadas = 0
    try:
        loc = page.locator("table")
        n = await loc.count()
        for i in range(min(n, 40)):
            try:
                await loc.nth(i).screenshot(path=str(run_dir / f"grid_tabela_{i:03d}.png"))
                tabelas_gravadas += 1
            except Exception as e:
                logger.debug("Screenshot tabela %s: %s", i, e)
    except Exception as e:
        logger.warning("Iteração de tabelas: %s", e)

    links = extrair_links_html(html)
    avisos = diagnosticar_extracao(
        numero=numero,
        tipo=str(resultado.get("tipo") or ""),
        textos=resultado.get("textos") or {},
        tramites=resultado.get("tramites") or [],
        corpo_raw=corpo_raw,
        corpo_principal=corpo_principal,
        html_len=len(html.encode("utf-8")),
    )

    manifest: dict[str, Any] = {
        "numero_psai": numero,
        "run_id": run_id,
        "utc": datetime.now(timezone.utc).isoformat(),
        "sgd_user_hash": _hash_user(usuario_sgd),
        "corpo_bruto_chars": len(corpo_raw),
        "corpo_principal_chars": len(corpo_principal),
        "html_bytes_utf8": len(html.encode("utf-8")),
        "campos_texto": list((resultado.get("textos") or {}).keys()),
        "tramites_count": len(resultado.get("tramites") or []),
        "tabelas_screenshots": tabelas_gravadas,
        "links_amostra": links,
        "avisos_extracao": avisos,
        "paths": {
            "pasta_execucao": str(run_dir.resolve()),
            "screenshot_full": str(shot_full.resolve()),
            "screenshot_viewport": str(shot_vp.resolve()),
            "html": str((run_dir / "page.html").resolve()),
        },
    }
    (run_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    resultado["arquivo_local"] = str(run_dir.resolve())
    resultado["manifest"] = manifest
    resultado["screenshot"] = str(shot_full.resolve())

    # JSON estruturado (campos extraídos + manifest; textos longos também em .txt / .html)
    (run_dir / "consulta.json").write_text(
        json.dumps(dict(resultado), ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    # Ponteiro "última execução" para esta PSAI
    ultima = {
        "run_id": run_id,
        "pasta": str(run_dir.resolve()),
        "utc": manifest["utc"],
        "avisos_codigos": [a.get("codigo") for a in avisos],
    }
    (base_arquivo / "ultima_execucao.json").write_text(
        json.dumps(ultima, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    _append_log_extracao(consultas_dir, manifest, usuario_sgd)
    return manifest


def _append_log_extracao(consultas_dir: Path, manifest: dict[str, Any], usuario_sgd: str) -> None:
    logs_dir = consultas_dir / "logs"
    logs_dir.mkdir(parents=True, exist_ok=True)
    log_line = {
        "utc": manifest.get("utc"),
        "numero_psai": manifest.get("numero_psai"),
        "run_id": manifest.get("run_id"),
        "sgd_user_hash": _hash_user(usuario_sgd),
        "tramites_count": manifest.get("tramites_count"),
        "campos": manifest.get("campos_texto"),
        "avisos": [a.get("codigo") for a in (manifest.get("avisos_extracao") or [])],
        "corpo_bruto_chars": manifest.get("corpo_bruto_chars"),
        "html_bytes_utf8": manifest.get("html_bytes_utf8"),
        "pasta": manifest.get("paths", {}).get("pasta_execucao"),
    }
    path = logs_dir / "psai-extracao.jsonl"
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(log_line, ensure_ascii=False) + "\n")
