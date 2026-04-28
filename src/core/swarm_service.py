import logging
import time
from typing import Dict, Any, List, Optional

logger = logging.getLogger(__name__)

from .universal_bridge import UniversalBridge

logger = logging.getLogger(__name__)

class SwarmService:
    """Phase 32: The Neural Brain - Interconnected 30-Node Swarm."""
    
    def __init__(self, root_dir):
        self.bridge = UniversalBridge(root_dir)
        self.blackboard = {
            "mission": "SOVEREIGN_IDLE",
            "tension": 0.5,
            "neural_load": 0.0,
            "synapse_log": []
        }
        self.nodes = self.bridge.nodes

    def activate_synapse(self, source_node, target_node, context_data):
        """Triggers a brain-like communication event between two nodes."""
        logger.info(f"KALI Synapse: {source_node} <-> {target_node}")
        self.blackboard["synapse_log"].append({
            "source": source_node,
            "target": target_node,
            "timestamp": time.time()
        })
        return self.bridge.cross_pollinate(source_node, target_node, context_data)

    def update_blackboard(self, key, value):
        """Updates the shared global context available to all 30 nodes."""
        self.blackboard[key] = value
        logger.info(f"KALI Blackboard: {key} updated. All 30 nodes synchronized.")

    def get_neural_health(self):
        """Returns the [B][N][U][S] status of every node for the dashboard."""
        health = {}
        for name, info in self.nodes.items():
            health[name] = {
                "bridge": "x",
                "neural": "x" if name in [s["source"] for s in self.blackboard["synapse_log"]] else "-",
                "ui": "x",
                "secure": "x" if "sanitized" in info else "-"
            }
        return health
