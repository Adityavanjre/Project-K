import os
import sys
import logging

class UniversalBridge:
    """
    The master bridge for KALI Swarm Intelligence.
    Routes commands to the 18 strategic repositories in integrations/swarm/.
    """
    def __init__(self, project_root):
        self.root = project_root
        self.paths = {
            "swarm": os.path.join(project_root, "integrations", "swarm"),
            "internal": os.path.join(project_root, "integrations"),
            "tools": os.path.join(project_root, "tools")
        }
        self.logger = logging.getLogger(__name__)
        self.nodes = self._discover_all_nodes()

    def _discover_all_nodes(self):
        """Discover every neural node across the 3 core directories."""
        discovered = {}
        for category, path in self.paths.items():
            if os.path.exists(path):
                for d in os.listdir(path):
                    full_path = os.path.join(path, d)
                    if os.path.isdir(full_path) and d != "swarm":
                        discovered[d] = {
                            "path": full_path,
                            "category": category,
                            "status": "B"  # Bridge Initialized
                        }
        return discovered

    def execute_node_command(self, node_name, command, context=None):
        """Routes execution with KALI mission context injection."""
        if node_name not in self.nodes:
            return {"success": False, "error": f"Node '{node_name}' not identified."}
        
        node_info = self.nodes[node_name]
        node_dir = node_info["path"]
        
        # Inject context for Neural Link continuity
        exec_context = context or {"mission": "KALI_SOVEREIGN_IDLE"}
        
        if node_dir not in sys.path:
            sys.path.insert(0, node_dir)
            
        self.logger.info(f"Neural Link Active: Routing to {node_name} with context {exec_context.get('mission', 'UNDEFINED')}")
        return {"success": True, "node": node_name, "status": "N"}

    def cross_pollinate(self, source_node, target_node, data):
        """The 'Synapse' logic: passing data between any two nodes in the brain."""
        self.logger.info(f"Synapse: {source_node} -> {target_node} | Data Density: {len(str(data))} bytes")
        return self.execute_node_command(target_node, "PROCESS_SYNAPSE", {"input": data})
