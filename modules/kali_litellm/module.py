import sys
import os
import time
from modules.base import Module

class LiteLLMModule(Module):
    def __init__(self):
        self.name = "litellm"

    @property
    def metadata(self):
        return {
            "capabilities": ["reasoning", "analysis", "planning", "llm"],
            "cost": 0.1,
            "latency_class": "fast",
            "risk": "SAFE"
        }

    def is_available(self) -> bool:
        try:
            import litellm
            return True
        except ImportError:
            return False

    def run(self, task: dict, device: str = "cpu") -> dict:
        start_time = time.time()
        try:
            import litellm
            
            prompt = task["input"]
            context = task.get("context", {})
            model = context.get("model", "ollama/llama3")
            
            # LiteLLM call
            # We can pass custom configurations if the provider supports device mapping
            response = litellm.completion(
                model=model,
                messages=[{"role": "user", "content": prompt}],
                timeout=30.0
            )
            
            return {
                "status": "success",
                "output": response.choices[0].message.content,
                "latency": time.time() - start_time,
                "device": device
            }
        except Exception as e:
            return {
                "status": "fail", 
                "output": str(e), 
                "latency": time.time() - start_time, 
                "device": device,
                "reason": "LiteLLM failure"
            }
