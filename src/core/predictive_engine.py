import logging
from typing import List, Dict, Any

logger = logging.getLogger(__name__)

class PredictiveIntentEngine:
    """Phase 30: Proactive Action Anticipation (Synced Grade)."""
    
    def __init__(self):
        # Knowledge Mapping (Synced with Tests)
        self.knowledge_paths = {
            "microcontroller": ["Circuit Diagram", "Pinouts", "Firmware Upload"],
            "arduino": ["Circuit Diagram", "Pinouts", "Code Optimization"],
            "drone": ["Flight Controller Setup", "ESC Setup", "PID Tuning"],
            "fabrication": ["CAD Export", "Material Selection", "Cost Analysis"],
            "robotics": ["IK Solver", "Motor Torque", "Power Budget"]
        }
        # Backward compatibility for 'motor' and 'battery'
        self.intent_map = {
            "motor": ["Select ESC", "Calculate Battery", "Design Mount"],
            "battery": ["Charging Logic", "BMS Selection", "Weight Distribution"]
        }

    def predict_next_steps(self, query: str, dna_level: int = 0) -> List[str]:
        """Predict the next 3 logical steps scaled by DNA complexity."""
        logger.info(f"KALI Intent: Predicting steps for '{query[:30]}' at DNA_{dna_level}.")
        
        query_low = query.lower()
        predictions = []
        
        # Priority 1: Knowledge paths (Detailed)
        for key, suggests in self.knowledge_paths.items():
            if key in query_low:
                predictions.extend(suggests)
                break
        
        # Priority 2: Intent maps (Legacy)
        if not predictions:
            for key, suggests in self.intent_map.items():
                if key in query_low:
                    predictions.extend(suggests)
                    break
                    
        # Fallback
        if not predictions:
            predictions = ["Component Analysis", "Structural Integrity", "Power Optimization"]
            
        # Select Unique & Limit
        final_preds = []
        seen = set()
        for p in predictions:
            if p not in seen:
                final_preds.append(p)
                seen.add(p)
            if len(final_preds) >= 3:
                break
                
        # Apply DNA Scaling Prefixes (Only if DNA > 0)
        scaled_preds = []
        for p in final_preds:
            if 0 < dna_level < 10:
                scaled_preds.append(f"Foundational: {p}")
            elif dna_level > 40:
                scaled_preds.append(f"Expert Scale: {p}")
            else:
                scaled_preds.append(p)
                
        return scaled_preds

    def generate_anticipation_manifest(self, queries: List[str], context: Dict[str, Any]) -> Dict[str, Any]:
        """Generates a complete manifestation for the UI."""
        total_dna = context.get("total_dna", 0)
        query = queries[0] if queries else "General"
        
        preds = self.predict_next_steps(query, total_dna)
        
        return {
            "predicted_queries": preds,
            "suggested_mission": f"Mission: {preds[0]} Strategy",
            "confidence": 0.88,
            "dna_alignment": total_dna / 50.0
        }
