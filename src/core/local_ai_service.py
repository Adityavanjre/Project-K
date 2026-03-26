import os
import requests
import logging
import json
import re
import base64
from typing import Dict, Any, Optional, List

class LocalAIService:
    """
    Drop-in replacement for AIService.
    Connects to Ollama running on localhost:11434.
    All method names match AIService exactly for compatibility.
    """
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        self.model = os.getenv("LOCAL_MODEL", "llama3.1:8b")
        self.api_url = "http://localhost:11434/api/chat"
        self.logger = logging.getLogger(__name__)
        self.is_connected = self._check()
        
        if self.is_connected:
            self.logger.info(f"Connected to Local Ollama. Model: {self.model}")
        else:
            self.logger.warning("Local Ollama not detected at http://localhost:11434")

    def _check(self) -> bool:
        try:
            resp = requests.get("http://localhost:11434/api/tags", timeout=3)
            return resp.status_code == 200
        except:
            return False

    def is_available(self) -> bool:
        # Re-check connection occasionally or just return the initial status
        return self.is_connected

    def ask_question(self, question: str, context: str = "", temperature: float = 0.7) -> str:
        messages = []
        if context:
            messages.append({"role": "system", "content": f"You are KALI, an advanced AI Assistant. Context: {context}"})
        messages.append({"role": "user", "content": question})
        return self._call(messages, temperature=temperature)


    def ask_json(self, system_prompt: str, user_prompt: str, temperature: float = 0.2) -> Dict[str, Any]:
        messages = [
            {"role": "system", "content": system_prompt + "\nIMPORTANT: Output valid JSON only."},
            {"role": "user", "content": user_prompt}
        ]
        resp_text = self._call(messages, json_mode=True, temperature=temperature)
        try:
            return self._extract_json(resp_text)
        except Exception as e:
            self.logger.error(f"Failed to parse JSON from local model: {e}")
            return {"error": "JSON parse failure", "raw": resp_text}

    def analyze_image(self, image_file, prompt: str = "Analyze this image.") -> str:
        try:
            image_file.seek(0)
            b64 = base64.b64encode(image_file.read()).decode()
            messages = [{
                "role": "user", 
                "content": prompt, 
                "images": [b64]
            }]
            # Note: llama3.2-vision or llava is needed for this to work
            return self._call(messages)
        except Exception as e:
            return f"Local Image Analysis Failed: {e}"

    def _call(self, messages: List[Dict[str, Any]], json_mode: bool = False, temperature: float = 0.7) -> str:
        try:
            payload = {
                "model": self.model,
                "messages": messages,
                "stream": False,
                "options": {
                    "temperature": temperature
                }
            }
            if json_mode:
                payload["format"] = "json"
                
            resp = requests.post(self.api_url, json=payload, timeout=120)
            if resp.status_code == 200:
                return resp.json()["message"]["content"]
            else:
                return f"Local model error: {resp.status_code} - {resp.text}"
        except Exception as e:
            self.logger.error(f"Local AI call failed: {e}")
            return f"Local connection failed: {e}"

    def _fallback_response(self, question: str) -> str:
        return "Local model unavailable. Please ensure Ollama is running (`ollama serve`)."

    def _extract_json(self, text: str) -> Dict[str, Any]:
        """Extracted from AIService for compatibility."""
        try:
            text = text.strip()
            if "```" in text:
                match = re.search(r"```(?:json)?(.*?)```", text, re.DOTALL)
                if match:
                    text = match.group(1).strip()
            
            start = text.find("{")
            end = text.rfind("}")
            
            if start != -1 and end != -1:
                text = text[start : end + 1]
            
            return json.loads(text)
        except Exception as e:
            raise ValueError(f"Could not extract valid JSON: {e}")
