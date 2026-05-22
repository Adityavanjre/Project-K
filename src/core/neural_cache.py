import os
import json
import hashlib
import logging

class NeuralCache:
    """
    Hash-based response caching for Project-K.
    Reduces latency and CPU usage by storing frequent query results.
    """
    def __init__(self, cache_dir="data/cache/neural"):
        self.root = cache_dir
        os.makedirs(self.root, exist_ok=True)
        self.logger = logging.getLogger("NeuralCache")
        # 🔱 Neural Blacklist: Patterns that should NEVER be cached
        self.blacklist = [
            "System is under extreme load",
            "Gateway Timeout",
            "Neural Error",
            "Tunnel Collapse",
            "Sovereignty maintaining",
            "re-synchronization"
        ]

    def _get_hash(self, query: str, context: str = "") -> str:
        content = f"{query.strip()}|{context.strip()}"
        return hashlib.sha256(content.encode()).hexdigest()

    def get(self, query: str, context: str = ""):
        """Retrieve cached response if exists."""
        q_hash = self._get_hash(query, context)
        path = os.path.join(self.root, f"{q_hash}.json")
        
        if os.path.exists(path):
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                return data.get("response")
            except:
                return None
        return None

    def store(self, query: str, response: str, context: str = ""):
        """Store response in cache."""
        q_hash = self._get_hash(query, context)
        path = os.path.join(self.root, f"{q_hash}.json")
        
        # 🔱 QUALITY CHECK: Do not cache blacklisted or error responses
        if any(pattern.lower() in response.lower() for pattern in self.blacklist):
            self.logger.warning(f"Cache Filter: Refusing to store degraded/fallback response.")
            return

        try:
            with open(path, 'w', encoding='utf-8') as f:
                json.dump({
                    "query": query,
                    "response": response,
                    "context": context,
                    "timestamp": os.path.getmtime(path) if os.path.exists(path) else 0
                }, f, indent=4)
        except Exception as e:
            self.logger.error(f"Cache Store Failure: {e}")
