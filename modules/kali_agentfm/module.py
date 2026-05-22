import time
import os
import logging
from modules.base import Module
from modules.registry import SandboxTier

logger = logging.getLogger(__name__)

from src.core.config_manager import config

class AgentFMModule(Module):
    """
    Phase 56: AgentFM P2P Execution Engine.
    Uses AgentFM's peer-to-peer compute grid for decentralized model execution.
    """
    
    def __init__(self, gateway_url: str = None):
        self.name = "agentfm"
        # 🔱 SOVEREIGN REGISTRY: Unified P2P Gateway
        self.gateway_url = gateway_url or f"{config.get('sovereign.internal.base_url')}:{config.get('api.port')}"
        self._client = None
        
    @property
    def metadata(self):
        return {
            "capabilities": ["reasoning", "analysis", "planning", "llm", "p2p_compute"],
            "version": "1.0.0",
            "sandbox_tier": SandboxTier.CONTROLLED.value,
            "latency_class": "distributed",
            "p2p_enabled": True
        }

    def _get_client(self):
        if self._client is None:
            try:
                from agentfm import AgentFMClient
                self._client = AgentFMClient(gateway_url=self.gateway_url)
            except ImportError:
                logger.error("agentfm-sdk not installed.")
                return None
        return self._client

    def is_available(self) -> bool:
        client = self._get_client()
        if client:
            try:
                return client.ping()
            except:
                return False
        return False

    def run(self, task: dict, device: str = "cpu") -> dict:
        start_time = time.time()
        client = self._get_client()
        if not client:
            return {"status": "fail", "output": "AgentFM client not available", "reason": "ImportError"}

        try:
            prompt = task.get("input", "")
            context = task.get("context", {})
            model = context.get("model", "llama3.2")
            
            # Use OpenAI-compatible interface of AgentFM
            # This routes the request to a worker advertising 'model'
            response = client.openai.chat.completions.create(
                model=model,
                messages=[{"role": "user", "content": prompt}]
            )
            
            return {
                "status": "success",
                "output": response.choices[0].message.content,
                "latency": time.time() - start_time,
                "worker_id": response.get("worker_id"), # Custom AgentFM field if available
                "device": "distributed_p2p"
            }
        except Exception as e:
            logger.error(f"AgentFM Dispatch Failure: {e}")
            return {
                "status": "fail",
                "output": str(e),
                "latency": time.time() - start_time,
                "reason": "AgentFM mesh error"
            }
