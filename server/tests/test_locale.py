"""Tests du choix de langue de réponse côté proxy."""
import os

os.environ.setdefault("OPENAI_API_KEY", "test-key")
os.environ.setdefault("APP_API_KEY", "test-app-key")

import pytest  # noqa: E402

from main import (  # noqa: E402
    SUPPORTED_LOCALES,
    ChatRequest,
    _build_messages,
    _system_prompt_for,
)


class TestSystemPrompt:
    def test_fr_inclut_consigne_francais(self):
        prompt = _system_prompt_for("fr")
        assert "français" in prompt.lower()

    def test_dioula_inclut_consigne_dioula(self):
        prompt = _system_prompt_for("dioula")
        assert "dioula" in prompt.lower() or "jula" in prompt.lower()

    def test_nouchi_inclut_consigne_nouchi(self):
        prompt = _system_prompt_for("nouchi")
        assert "nouchi" in prompt.lower()

    def test_baoule_inclut_consigne_baoule(self):
        prompt = _system_prompt_for("baoule")
        assert "baoul" in prompt.lower()

    def test_locale_inconnue_fallback_francais(self):
        prompt = _system_prompt_for("klingon")
        # Fallback : on retombe sur l'instruction française.
        assert "français" in prompt.lower()

    def test_base_inchangee_quel_que_soit_locale(self):
        # Le rappel de sécurité doit rester présent.
        for locale in SUPPORTED_LOCALES:
            prompt = _system_prompt_for(locale)
            assert "règles de sécurité" in prompt.lower()


class TestBuildMessages:
    def test_locale_invalide_remplacee_par_fr(self):
        messages = _build_messages("salut", [], "klingon")
        assert "français" in messages[0]["content"].lower()

    def test_locale_dioula_modifie_system_prompt(self):
        fr_messages = _build_messages("salut", [], "fr")
        dioula_messages = _build_messages("salut", [], "dioula")
        assert fr_messages[0]["content"] != dioula_messages[0]["content"]

    def test_question_utilisateur_toujours_encadree(self):
        for locale in ("fr", "dioula", "nouchi", "baoule"):
            messages = _build_messages("test", [], locale)
            # La question utilisateur doit être encadrée (défense prompt injection).
            content = messages[-1]["content"]
            if isinstance(content, str):
                assert "<user_question>" in content


class TestChatRequestLocale:
    def test_locale_par_defaut_fr(self):
        req = ChatRequest()
        assert req.locale == "fr"

    def test_locale_personnalisee(self):
        req = ChatRequest(message="test", locale="nouchi")
        assert req.locale == "nouchi"

    def test_locale_trop_longue_rejetee(self):
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            ChatRequest(locale="x" * 17)
