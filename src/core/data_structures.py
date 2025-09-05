"""
Data structures for the Doubt Clearing AI system.
"""

from dataclasses import dataclass
from typing import List, Optional


@dataclass
class DoubtContext:
    """Context information for a doubt."""

    question: str
    user_level: str = "intermediate"  # beginner, intermediate, advanced
    domain: Optional[str] = None
    conversation_history: List[str] = None

    def __post_init__(self):
        if self.conversation_history is None:
            self.conversation_history = []
