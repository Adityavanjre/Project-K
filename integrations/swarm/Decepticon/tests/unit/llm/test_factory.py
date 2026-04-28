"""Unit tests for decepticon.llm.factory"""

import asyncio

import pytest

from decepticon.llm.factory import LLMFactory
from decepticon.llm.models import GEMINI_FLASH, HAIKU, LLMModelMapping, ProxyConfig


class TestLLMFactory:
    def setup_method(self):
        self.proxy = ProxyConfig(
            url="http://localhost:4000",
            api_key="test-key",
        )
        self.mapping = LLMModelMapping()
        self.factory = LLMFactory(self.proxy, self.mapping)

    def test_factory_initializes(self):
        assert self.factory.proxy_url == "http://localhost:4000"

    def test_get_model_returns_chat_model(self):
        model = self.factory.get_model("recon")
        assert model is not None
        assert model.model_name == HAIKU

    def test_get_model_caches_instances(self):
        model1 = self.factory.get_model("recon")
        model2 = self.factory.get_model("recon")
        assert model1 is model2  # Same instance

    def test_get_model_different_roles(self):
        recon = self.factory.get_model("recon")
        decepticon = self.factory.get_model("decepticon")
        assert recon is not decepticon
        assert recon.model_name != decepticon.model_name

    def test_get_model_unknown_role_raises(self):
        with pytest.raises(KeyError, match="No model assignment"):
            self.factory.get_model("nonexistent")

    def test_router_accessible(self):
        assert self.factory.router is not None

    def test_get_fallback_models_with_fallback(self):
        models = self.factory.get_fallback_models("recon")
        assert len(models) == 1
        assert models[0].model_name == GEMINI_FLASH

    def test_get_fallback_models_without_fallback(self):
        mapping = LLMModelMapping()
        mapping.recon.fallback = None
        factory = LLMFactory(self.proxy, mapping)
        models = factory.get_fallback_models("recon")
        assert len(models) == 0


class TestLLMFactoryHealthCheck:
    def test_health_check_returns_false_when_no_proxy(self):
        proxy = ProxyConfig(url="http://localhost:19999")
        factory = LLMFactory(proxy)
        result = asyncio.run(factory.health_check())
        assert result is False
