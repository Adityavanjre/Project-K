"""
GAP DETECTOR
KALI Phase 33.2: Proactive Mentorship
Analyzes user DNA against prerequisite trees to find knowledge gaps.
"""

import logging
from typing import List, Dict, Optional

class GapDetector:
    """Detects missing foundational knowledge."""
    
    PREREQUISITES = {
        "I2C": ["VOLTAGE", "PULLUP", "ADDRESSING"],
        "PWM": ["DUTY_CYCLE", "FREQUENCY", "ANALOG"],
        "MQTT": ["CLIENT_ID", "BROKER", "PUB_SUB"],
        "REST": ["HTTP", "JSON", "ENDPOINTS"],
        "PID": ["FEEDBACK", "ERROR_CALCULATION", "DERIVATIVE"],
        "SQL": ["TABLES", "RELATIONSHIPS", "QUERIES"]
    }
    
    def __init__(self, user_dna):
        self.dna = user_dna
        self.logger = logging.getLogger(__name__)

    def find_gaps(self, current_topic: str) -> List[str]:
        """Returns a list of prerequisite concepts the user has low mastery in."""
        current_topic = current_topic.upper()
        if current_topic not in self.PREREQUISITES:
            return []
            
        prereqs = self.PREREQUISITES[current_topic]
        user_mastery = self.dna.profile["expertise"]["known_concepts"]
        
        gaps = []
        for p in prereqs:
            score = user_mastery.get(p, 0)
            if score < 40: # Threshold for 'Gap'
                gaps.append(p)
                
        return gaps

    def get_proactive_prompt(self, current_topic: str) -> Optional[str]:
        """Generates a soft prompt if gaps are detected."""
        gaps = self.find_gaps(current_topic)
        if not gaps:
            return None
            
        gap_str = ", ".join(gaps)
        return f"Sir, I notice you are exploring {current_topic}. However, your current DNA profile suggests we haven't yet mastered the foundations of {gap_str}. Shall we bridge these gaps first to ensure absolute mastery?"
