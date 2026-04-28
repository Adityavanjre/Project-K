"""Unit tests for decepticon.llm.router"""

import pytest

from decepticon.llm.models import (
    GEMINI_FLASH,
    GPT_5,
    HAIKU,
    OPUS,
    SONNET,
    LLMModelMapping,
    ModelAssignment,
)
from decepticon.llm.router import ModelRouter


class TestModelRouter:
    def setup_method(self):
        self.mapping = LLMModelMapping()
        self.router = ModelRouter(self.mapping)

    def test_resolve_returns_primary_model(self):
        model = self.router.resolve("recon")
        assert model == HAIKU

    def test_resolve_decepticon(self):
        model = self.router.resolve("decepticon")
        assert model == OPUS

    def test_resolve_with_fallback_returns_chain(self):
        chain = self.router.resolve_with_fallback("recon")
        assert len(chain) == 2
        assert chain[0] == HAIKU
        assert chain[1] == GEMINI_FLASH

    def test_resolve_with_fallback_strategic(self):
        chain = self.router.resolve_with_fallback("decepticon")
        assert len(chain) == 2
        assert chain[0] == OPUS
        assert chain[1] == GPT_5

    def test_resolve_unknown_role_raises(self):
        with pytest.raises(KeyError, match="No model assignment"):
            self.router.resolve("nonexistent_role")

    def test_get_assignment_returns_full_config(self):
        assignment = self.router.get_assignment("recon")
        assert isinstance(assignment, ModelAssignment)
        assert assignment.primary == HAIKU
        assert assignment.temperature == 0.3

    def test_resolve_analyst_role(self):
        chain = self.router.resolve_with_fallback("analyst")
        assert chain[0] == SONNET
        assert chain[1] == OPUS
