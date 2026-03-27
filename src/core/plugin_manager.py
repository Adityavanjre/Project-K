import os
import importlib.util
import logging
from typing import Dict, Any

class PluginManager:
    """
    KALI Plugin System (Phase 17).
    Allows KALI to dynamically load and integrate external python modules as tools.
    """
    def __init__(self, plugin_dir: str = "plugins"):
        self.plugin_dir = os.path.abspath(plugin_dir)
        os.makedirs(self.plugin_dir, exist_ok=True)
        self.plugins: Dict[str, Any] = {}
        self.logger = logging.getLogger(__name__)

    def _normalize_name(self, name: str) -> str:
        """Converts any name to snake_case."""
        import re
        s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
        return re.sub('([a-z0-0])([A-Z])', r'\1_\2', s1).lower().replace(" ", "_")

    def load_plugins(self):
        """Discover and load all .py files in the plugins directory."""
        self.logger.info(f"KALI Searching for extensions in {self.plugin_dir}...")
        
        for filename in os.listdir(self.plugin_dir):
            if filename.endswith(".py") and not filename.startswith("__"):
                plugin_name = filename[:-3]
                file_path = os.path.join(self.plugin_dir, filename)
                
                try:
                    spec = importlib.util.spec_from_file_location(plugin_name, file_path)
                    if spec and spec.loader:
                        module = importlib.util.module_from_spec(spec)
                        spec.loader.exec_module(module)
                        
                        # Register plugin if it has an 'initialize' method
                        if hasattr(module, "initialize"):
                            self.plugins[plugin_name] = module.initialize()
                            self.logger.info(f"KALI Extension Loaded: {plugin_name}")
                except Exception as e:
                    self.logger.error(f"Failed to load plugin {plugin_name}: {e}")
        
        self.logger.info(f"KALI Plugins Registry: {list(self.plugins.keys())}")

    def execute_plugin(self, name: str, *args, **kwargs):
        """Safely execute a plugin capability."""
        name = self._normalize_name(name)
        if name in self.plugins:
            try:
                plugin = self.plugins[name]
                if hasattr(plugin, "run"):
                    return plugin.run(*args, **kwargs)
                return f"Plugin '{name}' has no 'run' method."
            except Exception as e:
                self.logger.error(f"Plugin execution error ({name}): {e}")
        return f"Extension '{name}' not found."

    def create_plugin_from_query(self, name: str, code: str) -> bool:
        """Autonomously write and load a new plugin (OpenClaw-style)."""
        name = self._normalize_name(name)
        filename = f"{name}.py"
        file_path = os.path.join(self.plugin_dir, filename)
        
        try:
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(code)
            
            self.logger.info(f"KALI autonomously manifest a new skill: {name}")
            self.load_plugins() # Reload to integrate
            return True
        except Exception as e:
            self.logger.error(f"Failed to manifest autonomous skill: {e}")
            return False
