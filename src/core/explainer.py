"""
Explanation generation for the Doubt Clearing AI.
"""

import logging
from typing import Dict, List, Optional, Any
from .knowledge import KnowledgeItem
from .data_structures import DoubtContext


class Explainer:
    """Generates clear, structured explanations for doubts."""

    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """Initialize the explainer."""
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
        context: DoubtContext,
        knowledge: List[KnowledgeItem],
        analysis: Dict[str, Any],
    ) -> str:
        """
        Generate a clear explanation for the given question.

        Args:
            question: The original question
            context: Context information
            knowledge: Relevant knowledge items
            analysis: Question analysis results

        Returns:
            A well-structured explanation
        """
        try:
            self.logger.debug(
                f"Generating explanation for question type: {analysis.get('type')}"
            )

            # Determine explanation style based on user level
            style = self.explanation_styles.get(
                context.user_level, self.explanation_styles["intermediate"]
            )

            # If we have relevant knowledge, use it
            if knowledge:
                explanation = self._create_knowledge_based_explanation(
                    question, context, knowledge, analysis, style
                )
            else:
                # Generate a general explanation
                explanation = self._create_general_explanation(
                    question, context, analysis, style
                )

            # Add formatting and structure
            explanation = self._format_explanation(explanation, analysis, style)

            self.logger.debug("Explanation generated successfully")
            return explanation

        except Exception as e:
            self.logger.error(f"Error generating explanation: {e}")
            return self._create_fallback_explanation(question)

    def _create_knowledge_based_explanation(
        self,
        question: str,
        context: DoubtContext,
        knowledge: List[KnowledgeItem],
        analysis: Dict[str, Any],
        style: Dict[str, Any],
    ) -> str:
        """Create explanation based on knowledge base items."""
        # Use the most relevant knowledge item
        primary_knowledge = knowledge[0]

        explanation_parts = []

        # Start with a direct answer based on the question type
        if analysis["type"] == "definition":
            explanation_parts.append(
                f"**{primary_knowledge.title.replace('What is ', '')}**"
            )
            explanation_parts.append(primary_knowledge.content)

        elif analysis["type"] == "procedure":
            explanation_parts.append(f"**How it works:**")
            explanation_parts.append(primary_knowledge.content)

        elif analysis["type"] == "explanation":
            explanation_parts.append(f"**The reason behind this is:**")
            explanation_parts.append(primary_knowledge.content)

        else:
            explanation_parts.append(primary_knowledge.content)

        # Add examples if style requires it
        if style["include_examples"]:
            example = self._generate_example(primary_knowledge, analysis)
            if example:
                explanation_parts.append(f"\\n**Example:** {example}")

        # Add analogies for beginners
        if style["use_analogies"]:
            analogy = self._generate_analogy(primary_knowledge, analysis)
            if analogy:
                explanation_parts.append(f"\\n**Think of it like:** {analogy}")

        # Add related information if we have multiple knowledge items
        if len(knowledge) > 1:
            related_info = self._create_related_info(knowledge[1:])
            if related_info:
                explanation_parts.append(
                    f"\\n**Related information:**\\n{related_info}"
                )

        return "\\n\\n".join(explanation_parts)

    def _create_general_explanation(
        self,
        question: str,
        context: DoubtContext,
        analysis: Dict[str, Any],
        style: Dict[str, Any],
    ) -> str:
        """Create a general explanation when no specific knowledge is available."""

        # Template responses based on question type
        templates = {
            "definition": f"I understand you're asking about the definition or meaning of something in your question: '{question}'. While I don't have specific information about this topic in my current knowledge base, I can suggest breaking down the key terms and looking for authoritative sources in the {analysis.get('domain', 'relevant')} field.",
            "procedure": f"You're asking about how to do something or how something works. For procedural questions like '{question}', I recommend looking for step-by-step guides or tutorials from reliable sources. The key is to break down the process into manageable steps.",
            "explanation": f"This appears to be a 'why' question about '{question}'. To find a good explanation, consider looking at the underlying principles, causes, or reasons behind the phenomenon you're asking about.",
            "general": f"I see you're asking about '{question}'. While I don't have specific information about this in my knowledge base, I'd be happy to help you think through this systematically.",
        }

        base_explanation = templates.get(analysis["type"], templates["general"])

        # Add helpful suggestions
        suggestions = [
            "\\n**Helpful approaches:**",
            "• Try breaking down complex terms into simpler parts",
            "• Look for reliable sources in the relevant field",
            "• Consider asking follow-up questions to clarify specific aspects",
        ]

        if analysis["domain"] != "general":
            suggestions.append(
                f"• Focus on {analysis['domain']} resources for domain-specific information"
            )

        return base_explanation + "\\n" + "\\n".join(suggestions)

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

    def _generate_example(
        self, knowledge: KnowledgeItem, analysis: Dict[str, Any]
    ) -> Optional[str]:
        """Generate a relevant example based on the knowledge and question type."""
        examples = {
            "technology": {
                "AI": "Like how your smartphone's camera automatically focuses on faces, or how streaming services recommend movies you might like.",
                "machine learning": "Similar to how you get better at a skill through practice, machines get better at tasks by processing lots of examples.",
            },
            "science": {
                "photosynthesis": "When you see green plants growing towards sunlight, they're actually using that light to make their own food through photosynthesis.",
            },
            "mathematics": {
                "pythagorean theorem": "If you have a rectangular screen that's 3 feet wide and 4 feet tall, the diagonal would be 5 feet (since 3² + 4² = 5²)."
            },
        }

        domain_examples = examples.get(knowledge.domain, {})
        for keyword in knowledge.keywords:
            if keyword.lower() in domain_examples:
                return domain_examples[keyword.lower()]

        return None

    def _generate_analogy(
        self, knowledge: KnowledgeItem, analysis: Dict[str, Any]
    ) -> Optional[str]:
        """Generate a helpful analogy for beginners."""
        analogies = {
            "AI": "a very smart assistant that learns from experience",
            "machine learning": "teaching a child to recognize patterns by showing them many examples",
            "photosynthesis": "a solar panel that converts sunlight into energy, but for plants",
            "democracy": "a group of friends voting on what movie to watch together",
        }

        for keyword in knowledge.keywords:
            if keyword.lower() in analogies:
                return analogies[keyword.lower()]

        return None

    def _create_related_info(self, related_knowledge: List[KnowledgeItem]) -> str:
        """Create related information section."""
        info_parts = []
        for item in related_knowledge[:2]:  # Limit to 2 related items
            info_parts.append(f"• **{item.title}**: {item.content[:100]}...")

        return "\\n".join(info_parts)

    def _format_explanation(
        self, explanation: str, analysis: Dict[str, Any], style: Dict[str, Any]
    ) -> str:
        """Apply final formatting to the explanation."""

        # Truncate if too long
        max_length = style["max_length"]
        if len(explanation) > max_length:
            explanation = explanation[:max_length] + "..."

        # Add a summary for complex explanations
        if style["complexity"] == "detailed" and len(explanation) > 300:
            summary = self._create_summary(analysis)
            if summary:
                explanation = f"**Summary:** {summary}\\n\\n" + explanation

        return explanation

    def _create_summary(self, analysis: Dict[str, Any]) -> str:
        """Create a brief summary for complex explanations."""
        question_type = analysis.get("type", "general")
        domain = analysis.get("domain", "general")

        if question_type == "definition":
            return f"This is a {domain} concept that can be understood by examining its key characteristics and applications."
        elif question_type == "procedure":
            return f"This {domain} process involves several steps that work together to achieve a specific outcome."
        elif question_type == "explanation":
            return f"The underlying principles in {domain} help explain why this phenomenon occurs."
        else:
            return f"This {domain} topic involves multiple interconnected concepts."
