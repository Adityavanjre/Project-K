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

    def execute_plugin(self, name: str, *args, **kwargs):
        """Safely execute a plugin capability."""
        if name in self.plugins:
            try:
                return self.plugins[name].run(*args, **kwargs)
            except Exception as e:
                self.logger.error(f"Plugin execution error ({name}): {e}")
        return f"Extension '{name}' not found."
