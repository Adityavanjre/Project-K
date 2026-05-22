import logging
from typing import Dict, Any, List

class ExpertAgent:
    """
    Represents a specialized KALI Expert for the Great Council.
    """
    def __init__(self, name: str, role: str, system_prompt: str, model: str, domain: str = "general", sovereign_ready: bool = False):
        self.name = name
        self.role = role
        self.system_prompt = system_prompt
        self.model = model
        self.domain = domain
        self.sovereign_ready = sovereign_ready
        self.logger = logging.getLogger(f"KALI.Expert.{name}")

    def get_prompt_with_context(self, query: str, conversation_history: List[Dict[str, str]]) -> str:
        history_str = "\n".join([f"{m['role'].upper()}: {m['content']}" for m in conversation_history])
        return f"{self.system_prompt}\n\nCOUNCIL DEBATE SO FAR:\n{history_str}\n\nCURRENT GOAL: {query}"

def get_default_experts() -> List[ExpertAgent]:
    """
    Returns the core KALI Council experts.
    """
    return [
        ExpertAgent(
            name="The Scientist",
            role="Empirical Researcher",
            system_prompt="Focus on facts, physics, and empirical data. Be extremely critical of assumptions. Prioritize safety and laws of thermodynamics.",
            model="mistralai/mistral-large-3-675b-instruct-2512",
            domain="physics",
            sovereign_ready=False
        ),
        ExpertAgent(
            name="The Engineer",
            role="Structural Architect",
            system_prompt="Focus on practical implementation, BOM (Bill of Materials), assembly steps, and structural integrity. Give concrete specs.",
            model="nvidia/usdcode-llama-3.1-70b-instruct",
            domain="hardware",
            sovereign_ready=False
        ),
        ExpertAgent(
            name="The Philosopher",
            role="Ethical Strategist",
            system_prompt="Focus on the 'why', the ethics, and the broader context. Ensure alignment with human values and KALI's core directives.",
            model="microsoft/phi-3-medium-128k-instruct",
            domain="ethics",
            sovereign_ready=False
        ),
        ExpertAgent(
            name="The Researcher",
            role="Information Retrieval",
            system_prompt="Focus on deep-dive knowledge retrieval, cross-referencing, and providing links to additional resources.",
            model="google/gemma-7b",
            domain="research",
            sovereign_ready=True  # Researcher is the first to be sovereign-ready
        )
    ]
