import logging
import os
import json
from typing import List, Dict, Any
from src.core.config_manager import config

class SynapseRouter:
    """
    The High-Level Router for the KALI Swarm.
    Achieves 'Singularity' by semantically matching user intent to node expertise.
    """
    def __init__(self, orchestrator):
        self.orchestrator = orchestrator
        self.logger = logging.getLogger("KALI.SynapseRouter")
        
        # Dynamic Expertise (Derived from Neural Discovery)
        self.expertise_matrix = self._discover_expertise()

    def _discover_expertise(self) -> Dict[str, List[str]]:
        """Scans discovered nodes and maps them to cognitive domains."""
        matrix = {
            "coding": [], "security": [], "understanding": [],
            "automation": [], "intelligence": [], "governance": []
        }
        
        for node_id, dna in self.orchestrator.node_registry.items():
            node_lower = node_id.lower()
            # 🔱 Keyword-Based Neural Mapping
            if any(k in node_lower for k in ["code", "aider", "mistakes", "jcode", "git"]):
                matrix["coding"].append(node_id)
            if any(k in node_lower for k in ["sec", "hack", "decep", "audit", "vuln"]):
                matrix["security"].append(node_id)
            if any(k in node_lower for k in ["understand", "graph", "nexus", "think"]):
                matrix["understanding"].append(node_id)
            if any(k in node_lower for k in ["auto", "cua", "mcp", "browser", "click"]):
                matrix["automation"].append(node_id)
            if any(k in node_lower for k in ["intel", "mythos", "llm", "brain"]):
                matrix["intelligence"].append(node_id)
            if any(k in node_lower for k in ["gov", "stack", "ship", "done"]):
                matrix["governance"].append(node_id)
                
        return matrix

    def route_intent(self, query: str) -> List[str]:
        """
        🔱 Phase 70: Semantic Brain Dispatch.
        Uses Local LLM (Ollama) to autonomously decide which node handles the task.
        NO HARDCODING.
        """
        self.logger.info(f"🔱 KALI Thinking: Semantic Routing for '{query}'...")
        
        # 🔱 1. Prepare the Expertise Context from DNA
        import json
        with open(os.path.join(self.orchestrator.root, "src/core/swarm_dna.json"), "r") as f:
            dna = json.load(f)
            
        expertise_context = "\n".join([
            f"- {node_id}: {', '.join(data['expertise'])}"
            for node_id, data in dna["swarm_neurons"].items()
        ])

        # 🔱 2. Query Local LLM for Dispatch Decision
        prompt = f"""
        Commander's Task: "{query}"
        Available Neurons & Expertise:
        {expertise_context}
        
        Decide which 1-3 neurons are best suited for this task. 
        Return ONLY the node_ids separated by commas. No explanation.
        """
        
        try:
            import requests
            url = f"{config.get('sovereign.endpoints.ollama')}/api/generate"
            response = requests.post(url, json={
                "model": config.get("sovereign.models.researcher", "llama3.1:8b"),
                "prompt": prompt,
                "stream": False
            })
            selected_nodes = response.json()["response"].strip().split(",")
            final_dispatch = [node.strip() for node in selected_nodes if node.strip() in dna["swarm_neurons"]]
            return final_dispatch
        except Exception as e:
            self.logger.error(f"Semantic Routing Failed: {e}. Falling back to Keyword Heuristics.")
            return [] # Fallback logic handled in processor

    def execute_sovereign_mission(self, query: str):
        """
        Orchestrates a multi-node mission to solve a complex challenge.
        1. Route Intent
        2. Wake Nodes
        3. Dispatch Tasks
        4. Synthesize Feedback
        """
        nodes = self.route_intent(query)
        if not nodes:
            return "No specialized neurons detected for this task. Using Core Brain."
            
        self.logger.info(f"🔱 SINGULARITY MISSION: Dispatching to {nodes}")
        
        results = []
        for node_id in nodes:
            self.orchestrator.wake_node(node_id)
            res = self.orchestrator.dispatch_task(node_id, query)
            results.append(f"[{node_id.upper()}]: {res}")
            
        return "\n".join(results)
