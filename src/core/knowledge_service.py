import logging
import json
import os
from typing import List, Dict, Any, Optional

logger = logging.getLogger(__name__)

class KnowledgeService:
    """Phase 29: Autonomous Interaction Curation & Dataset Synthesis."""
    
    def __init__(self, project_root: str):
        self.project_root = project_root
        self.training_dir = os.path.join(project_root, "data", "training")
        self.dataset_file = os.path.join(self.training_dir, "dataset.jsonl")
        self._ensure_paths()

    def _ensure_paths(self):
        os.makedirs(self.training_dir, exist_ok=True)

    def curate_interaction(self, query: str, response: str, is_successful: bool = True) -> bool:
        """Adds a high-fidelity interaction to the training dataset."""
        if not is_successful:
            return False
            
        logger.info("KALI DNA: Curating high-fidelity interaction.")
        
        # Format for Alpaca-style instruction tuning (compatible with Unsloth)
        sample = {
            "instruction": "You are KALI, the Ultimate Fabrication Mentor. Answer the following engineering doubt precisely.",
            "input": query,
            "output": response
        }
        
        try:
            with open(self.dataset_file, "a", encoding="utf-8") as f:
                f.write(json.dumps(sample) + "\n")
            return True
        except Exception as e:
            logger.error(f"Failed to curated DNA: {e}")
            return False

    def get_dna_count(self) -> int:
        """Returns the number of curated training samples."""
        if not os.path.exists(self.dataset_file):
            return 0
        try:
            with open(self.dataset_file, "r", encoding="utf-8") as f:
                return sum(1 for _ in f)
        except Exception:
            return 0

    def get_graph_data(self) -> Dict[str, List[Dict]]:
        """Generates dynamic graph nodes and edges from real knowledge atoms."""
        nodes = [
            {"id": "ROOT", "label": "SOVEREIGN_CORE", "type": "origin"},
            {"id": "N1", "label": "VEDIC_LOGIC", "type": "pillar"},
            {"id": "N2", "label": "EXPLOIT_SYNTH", "type": "pillar"},
            {"id": "N3", "label": "SWARM_INTEL", "type": "pillar"},
            {"id": "N4", "label": "ECON_AUTO", "type": "pillar"}
        ]
        edges = [
            {"from": "ROOT", "to": "N1"},
            {"from": "ROOT", "to": "N2"},
            {"from": "ROOT", "to": "N3"},
            {"from": "ROOT", "to": "N4"}
        ]

        # Add nodes from knowledge atoms
        atom_path = os.path.join(self.project_root, "data", "knowledge_atoms.jsonl")
        if os.path.exists(atom_path):
            try:
                with open(atom_path, "r", encoding="utf-8") as f:
                    for i, line in enumerate(f):
                        atom = json.loads(line)
                        atom_id = f"A{i}"
                        nodes.append({
                            "id": atom_id, 
                            "label": atom.get("topic", f"ATOM_{i}"), 
                            "type": "neuron"
                        })
                        # Connect to a pillar based on keywords or random if none
                        pillar = "N1"
                        topic = atom.get("topic", "").lower()
                        if "exploit" in topic or "hack" in topic: pillar = "N2"
                        elif "swarm" in topic or "agent" in topic: pillar = "N3"
                        elif "wealth" in topic or "bounty" in topic: pillar = "N4"
                        
                        edges.append({"from": pillar, "to": atom_id})
                        if i > 20: break # Limit for UI performance
            except Exception: pass
            
        return {"nodes": nodes, "edges": edges}
