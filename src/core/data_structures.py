from dataclasses import dataclass
from typing import List, Dict, Optional, Any

@dataclass
class PresentationStep:
    id: int
    text: str          # Text shown on screen
    audio_text: str    # Text spoken by TTS
    visual_code: str   # Code to render visual (HTML/Three.js)

@dataclass
class ProjectPlan:
    title: str
    difficulty: str
    bom: List[Dict[str, str]]  # {name, specs, cost}
    tech_stack: List[str]
    prerequisites: List[str]
    steps: List[str]
    calibration: List[str]

@dataclass
class DoubtContext:
    """Context for understanding user's doubt."""
    question: str
    conversation_history: list = None
    current_step: Optional[int] = None
    current_topic: Optional[str] = None
    image_url: Optional[str] = None
