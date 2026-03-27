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

    def clear_dataset(self):
        if os.path.exists(self.dataset_file):
            os.remove(self.dataset_file)
