import logging
import json
from typing import Dict, List, Optional, Any


class Explainer:
    """Generates clear, structured explanations for doubts."""

    def __init__(self, ai_service: Any, config: Optional[Dict[str, Any]] = None):
        """Initialize the explainer."""
        self.ai = ai_service
        self.config = config or {}
        self.logger = logging.getLogger(__name__)

        # Configuration for explanation styles
        self.explanation_styles = {
            "beginner": {
                "complexity": "simple",
                "include_examples": True,
                "use_analogies": True,
                "max_length": 300,
            },
            "intermediate": {
                "complexity": "moderate",
                "include_examples": True,
                "use_analogies": False,
                "max_length": 500,
            },
            "advanced": {
                "complexity": "detailed",
                "include_examples": False,
                "use_analogies": False,
                "max_length": 800,
            },
        }

        self.logger.info("Explainer initialized successfully")

    def generate_explanation(
        self,
        question: str,
        context: Optional[str] = "",
        style: str = "intermediate"
    ) -> str:
        """
        AI-Enhanced structured explanation.
        """
        style_config = self.explanation_styles.get(style, self.explanation_styles["intermediate"])
        
        prompt = (
            f"You are KALI, an advanced AI Mentor. Generate a {style_config['complexity']} explanation.\n"
            f"Question: {question}\n"
            f"Style: {json.dumps(style_config)}\n"
            f"Requirements: Use analogies for beginners, include examples if appropriate, be concise but deep."
        )
        
        return self.ai.ask_question(prompt, context=context)

    def _create_fallback_explanation(self, question: str) -> str:
        """Create a fallback explanation when everything else fails."""
        return f"""I apologize, but I encountered an issue while processing your question: "{question}"

Let me try to help you in a different way:

**General approach to finding answers:**
• Break down your question into key components
• Identify the main topic or domain
• Look for authoritative sources in that field
• Consider asking more specific follow-up questions

I'm continuously learning and improving. Feel free to rephrase your question or ask about something else!"""
