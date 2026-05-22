import os
import json
import threading

class ConfigManager:
    """
    Sovereign Config Manager (Thread-Safe Singleton)
    Provides unified access to KALI configuration and Sovereign Registry.
    """
    _instance = None
    _lock = threading.Lock()

    def __new__(cls):
        with cls._lock:
            if cls._instance is None:
                cls._instance = super(ConfigManager, cls).__new__(cls)
                cls._instance._load_config()
        return cls._instance

    def _load_config(self):
        project_root = os.getcwd()
        config_path = os.path.join(project_root, "config", "config.json")
        try:
            with open(config_path, "r") as f:
                self._config = json.load(f)
        except Exception as e:
            print(f"[CONFIG_ERROR] Failed to load config: {e}")
            self._config = {}

    def get(self, key_path: str, default=None):
        """Get config value using dot notation (e.g., 'sovereign.endpoints.ollama')."""
        keys = key_path.split('.')
        val = self._config
        try:
            for k in keys:
                val = val[k]
            return val
        except (KeyError, TypeError):
            return default

# Global instance
config = ConfigManager()
