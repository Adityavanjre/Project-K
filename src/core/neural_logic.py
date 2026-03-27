#!/usr/bin/env python3
"""
KALI NEURAL LOGIC
Phase 9: Neural Core Evolution
Implements synaptic routing and weighted cognitive dynamics.
"""

import json
import os
import logging
import math
from typing import Dict, Any, List

class NeuralLogic:
    """Mimics brain-inspired synaptic weighting for task prioritization."""
    
    def __init__(self, dna_path="data/user_dna.json"):
        self.logger = logging.getLogger(__name__)
        self.dna_path = os.path.abspath(dna_path)
        self.synapses: Dict[str, float] = {}
        self._load_synapses()

    def _load_synapses(self):
        """Initializes synapses based on User DNA expertise and interests."""
        if os.path.exists(self.dna_path):
            with open(self.dna_path, "r") as f:
                dna = json.load(f)
                expertise = dna.get("expertise", {})
                # Weight synapses by expertise levels (0.1 to 1.0)
                for topic, level in expertise.items():
                    self.synapses[topic.lower()] = min(1.0, level / 10.0)
        
        # Default Baseline Synapses
        defaults = ["circuit_design", "cryptography", "logic_gates", "robotics"]
        for d in defaults:
            if d not in self.synapses:
                self.synapses[d] = 0.5

    def calculate_priority(self, task_name: str, base_priority: int = 50) -> float:
        """Calculates synaptic firing weight for a given task."""
        weight = 1.0
        task_norm = task_name.lower()
        
        for topic, strength in self.synapses.items():
            if topic in task_norm:
                weight += strength
        
        # Sigmoid-like squashing for priority (0-100)
        priority = base_priority * weight
        return min(100.0, priority)

    def route_tasks(self, tasks: List[Dict]) -> List[Dict]:
        """Orders tasks by synaptic priority."""
        for task in tasks:
            task["synaptic_priority"] = self.calculate_priority(task.get("name", ""))
            
        return sorted(tasks, key=lambda x: x["synaptic_priority"], reverse=True)

if __name__ == "__main__":
    logic = NeuralLogic()
    test_tasks = [
        {"name": "Simple LED Blink", "base_priority": 10},
        {"name": "Circuit Design for Neural interface", "base_priority": 20},
        {"name": "Cryptography Audit", "base_priority": 30}
    ]
    routed = logic.route_tasks(test_tasks)
    for t in routed:
        print(f"[*] Task: {t['name']} | Synaptic Priority: {t['synaptic_priority']:.2f}")
