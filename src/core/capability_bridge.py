import importlib.util
import os
import sys
import json
import logging

class CapabilityBridge:
    """
    The 'Mirror of Powers' for KALI.
    Allows KALI to dynamically inherit and execute functions from integrated clones.
    """
    def __init__(self, root_dir: str):
        self.root = root_dir
        self.logger = logging.getLogger("KALI.CapabilityBridge")
        self.inherited_powers = {}
        self.dna_path = os.path.join(self.root, "src", "core", "swarm_dna.json")
        
        # 🔱 Phase 70: Universal Power Ingestion
        self._ingest_all_swarm_powers()

    def _ingest_all_swarm_powers(self):
        """Recursively possesses the functions of every node in the DNA map."""
        if not os.path.exists(self.dna_path):
            self.logger.error("DNA Map not found. Possession limited.")
            return
            
        with open(self.dna_path, "r") as f:
            dna = json.load(f)
            
        for node_id, data in dna.get("swarm_neurons", {}).items():
            # Heuristic: Look for primary entry points to ingest
            for entry_file in ["actions.py", "main.py", "module.py", "server.py"]:
                self.ingest_node_powers(node_id, entry_file)

    def ingest_node_powers(self, node_id: str, entry_file: str):
        """Introspects a node and maps its functions to KALI's capability matrix."""
        node_path = os.path.join(self.root, "integrations", node_id, entry_file)
        if not os.path.exists(node_path):
            self.logger.warning(f"Power Source Not Found: {node_id}")
            return
            
        try:
            # Dynamic Import of the Node's Logic
            spec = importlib.util.spec_from_file_location(f"power_{node_id}", node_path)
            module = importlib.util.module_from_spec(spec)
            sys.path.append(os.path.join(self.root, "integrations", node_id))
            spec.loader.exec_module(module)
            
            # Map all public functions to KALI's inherited powers
            for attr_name in dir(module):
                attr = getattr(module, attr_name)
                if callable(attr) and not attr_name.startswith("_"):
                    power_name = f"{node_id}_{attr_name}"
                    self.inherited_powers[power_name] = attr
                    self.logger.info(f"🔱 KALI Inherited Power: {power_name}")
                    
        except Exception as e:
            self.logger.error(f"Failed to ingest powers from {node_id}: {e}")

    def execute_inherited_power(self, power_name: str, *args, **kwargs):
        """Executes a borrowed power from a specialized neuron."""
        if power_name not in self.inherited_powers:
            self.logger.error(f"Power {power_name} not found in KALI matrix.")
            return None
            
        self.logger.info(f"🔱 KALI Dispatch: Executing {power_name}...")
        return self.inherited_powers[power_name](*args, **kwargs)

if __name__ == "__main__":
    bridge = CapabilityBridge(os.getcwd())
    print(f"KALI Matrix: {len(bridge.inherited_powers)} powers inherited.")
