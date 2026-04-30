"""
Sessão autenticada no SGD via Playwright (portado de sgd-extractor).
"""
import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from playwright.async_api import (
    Browser,
    BrowserContext,
    Page,
    Playwright,
    async_playwright,
)

from env import settings

logger = logging.getLogger(__name__)

_LOGIN_SELECTORS = {
    "username": "input[name='usuario'], #usuario, input[type='text']",
    "password": "input[name='senha'], #senha, input[type='password']",
    "submit": "input[type='submit'], button[type='submit'], .btn-login",
    "post_login_indicator": ".menu-principal, #menu, nav, .navbar",
}


class SGDSession:
    def __init__(self, playwright: Playwright) -> None:
        self._playwright = playwright
        self._browser: Browser | None = None
        self._context: BrowserContext | None = None

    async def _iniciar_browser(self) -> None:
        self._browser = await self._playwright.chromium.launch(
            headless=settings.SCRAPER_HEADLESS,
        )
        logger.info(f"Browser iniciado (headless={settings.SCRAPER_HEADLESS})")

    async def _aguardar_pos_login(self, page: Page) -> None:
        timeout = settings.SCRAPER_TIMEOUT_MS * 4
        try:
            await page.wait_for_url(
                lambda url: "login" not in url.lower(),
                timeout=timeout,
            )
            logger.debug("URL pós-login detectada.")
        except Exception:
            logger.debug("wait_for_url não concluiu, tentando indicador visual.")
            await page.wait_for_selector(
                _LOGIN_SELECTORS["post_login_indicator"],
                timeout=timeout,
            )

    async def _carregar_sessao_salva(self) -> bool:
        if not settings.SESSION_FILE.exists():
            return False

        try:
            self._context = await self._browser.new_context(
                storage_state=str(settings.SESSION_FILE)
            )
            page = await self._context.new_page()
            await page.goto(
                f"{settings.SGD_URL}/sgsa/faces/home.html",
                timeout=settings.SCRAPER_TIMEOUT_MS,
            )
            await page.wait_for_load_state(
                "domcontentloaded", timeout=settings.SCRAPER_TIMEOUT_MS
            )

            if "login" not in page.url.lower() and await page.query_selector(
                _LOGIN_SELECTORS["post_login_indicator"]
            ):
                logger.info("Sessão reutilizada com sucesso a partir do estado salvo.")
                await page.close()
                return True

            logger.info("Estado salvo expirado, realizando novo login.")
            await page.close()
            await self._context.close()
            self._context = None
            return False

        except Exception as e:
            logger.warning(f"Falha ao carregar sessão salva: {e}")
            if self._context:
                await self._context.close()
                self._context = None
            return False

    async def _fazer_login(self) -> None:
        settings.validate()

        self._context = await self._browser.new_context()
        page = await self._context.new_page()

        try:
            logger.info(f"Acessando {settings.SGD_URL}/login.html")
            await page.goto(
                f"{settings.SGD_URL}/login.html",
                timeout=settings.SCRAPER_TIMEOUT_MS,
            )
            await page.wait_for_load_state("domcontentloaded")

            campo_usuario = await page.wait_for_selector(
                _LOGIN_SELECTORS["username"],
                timeout=settings.SCRAPER_TIMEOUT_MS,
            )
            await campo_usuario.fill(settings.SGD_USERNAME)

            campo_senha = await page.wait_for_selector(
                _LOGIN_SELECTORS["password"],
                timeout=settings.SCRAPER_TIMEOUT_MS,
            )
            await campo_senha.fill(settings.SGD_PASSWORD)

            botao = await page.wait_for_selector(
                _LOGIN_SELECTORS["submit"],
                timeout=settings.SCRAPER_TIMEOUT_MS,
            )
            await botao.click(no_wait_after=True, timeout=settings.SCRAPER_TIMEOUT_MS)
            await self._aguardar_pos_login(page)

            if "login" in page.url.lower():
                raise RuntimeError(
                    "Login falhou — verifique SGD_USERNAME e SGD_PASSWORD no .env"
                )

            settings.SESSION_FILE.parent.mkdir(parents=True, exist_ok=True)
            await self._context.storage_state(path=str(settings.SESSION_FILE))
            logger.info(f"Login bem-sucedido. Sessão salva em {settings.SESSION_FILE}")

        finally:
            await page.close()

    async def conectar(self) -> None:
        await self._iniciar_browser()

        if not await self._carregar_sessao_salva():
            await self._fazer_login()

    async def nova_pagina(self) -> Page:
        if self._context is None:
            raise RuntimeError("Sessão não iniciada. Chame conectar() primeiro.")
        page = await self._context.new_page()
        page.set_default_timeout(settings.SCRAPER_TIMEOUT_MS)
        return page

    async def fechar(self) -> None:
        if self._context:
            await self._context.close()
        if self._browser:
            await self._browser.close()
        logger.info("Browser encerrado.")

    def invalidar_sessao(self) -> None:
        if settings.SESSION_FILE.exists():
            settings.SESSION_FILE.unlink()
            logger.info("Sessão invalidada. Próxima execução fará novo login.")


@asynccontextmanager
async def sessao_sgd() -> AsyncGenerator[SGDSession, None]:
    async with async_playwright() as pw:
        session = SGDSession(pw)
        try:
            await session.conectar()
            yield session
        except Exception:
            session.invalidar_sessao()
            raise
        finally:
            await session.fechar()
