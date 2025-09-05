"""
Main processor for handling doubt clearing requests.
"""

import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass

from .knowledge import KnowledgeBase
from .explainer import Explainer


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


class DoubtProcessor:
    """Main processor for handling doubt clearing requests."""
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """Initialize the doubt processor."""
        self.config = config or {}
        self.logger = logging.getLogger(__name__)
        
        # Initialize components
        self.knowledge_base = KnowledgeBase(self.config.get("knowledge", {}))
        self.explainer = Explainer(self.config.get("explainer", {}))
        
        # Conversation state
        self.conversation_history = []
        self.current_context = None
        
        self.logger.info("DoubtProcessor initialized successfully")
    
    def process_doubt(self, question: str, context: Optional[DoubtContext] = None) -> str:
        """
        Process a doubt and return a clear explanation.
        
        Args:
            question: The question or doubt to be processed
            context: Additional context for the question
            
        Returns:
            A clear, well-structured explanation
        """
        try:
            self.logger.info(f"Processing doubt: {question[:100]}...")
            
            # Create or update context
            if context is None:
                context = DoubtContext(question=question)
            
            # Update conversation history
            self.conversation_history.append(question)
            context.conversation_history = self.conversation_history.copy()
            
            # Analyze the question
            analysis = self._analyze_question(question, context)
            
            # Retrieve relevant knowledge
            knowledge = self.knowledge_base.search(question, analysis.get("domain"))
            
            # Generate explanation
            explanation = self.explainer.generate_explanation(
                question=question,
                context=context,
                knowledge=knowledge,
                analysis=analysis
            )
            
            # Update conversation history with response
            self.conversation_history.append(explanation)
            
            self.logger.info("Doubt processed successfully")
            return explanation
            
        except Exception as e:
            self.logger.error(f"Error processing doubt: {e}")
            return f"I apologize, but I encountered an error while processing your question: {str(e)}"
    
    def _analyze_question(self, question: str, context: DoubtContext) -> Dict[str, Any]:
        """Analyze the question to understand its nature and requirements."""
        analysis = {
            "type": self._classify_question_type(question),
            "domain": self._identify_domain(question),
            "complexity": self._assess_complexity(question),
            "keywords": self._extract_keywords(question),
            "intent": self._identify_intent(question)
        }
        
        self.logger.debug(f"Question analysis: {analysis}")
        return analysis
    
    def _classify_question_type(self, question: str) -> str:
        """Classify the type of question (what, how, why, etc.)."""
        question_lower = question.lower().strip()
        
        if question_lower.startswith(("what", "what's", "what is")):
            return "definition"
        elif question_lower.startswith(("how", "how to", "how do", "how does")):
            return "procedure"
        elif question_lower.startswith(("why", "why is", "why do", "why does")):
            return "explanation"
        elif question_lower.startswith(("when", "when is", "when do", "when does")):
            return "temporal"
        elif question_lower.startswith(("where", "where is", "where do", "where does")):
            return "location"
        elif question_lower.startswith(("which", "who", "whom")):
            return "identification"
        elif "?" not in question:
            return "statement"
        else:
            return "general"
    
    def _identify_domain(self, question: str) -> Optional[str]:
        """Identify the domain/subject area of the question."""
        # Simple keyword-based domain identification
        # In a real implementation, you'd use more sophisticated NLP
        
        domains = {
            "mathematics": ["math", "equation", "calculate", "algebra", "geometry", "calculus"],
            "science": ["physics", "chemistry", "biology", "experiment", "molecule", "atom"],
            "technology": ["computer", "programming", "software", "code", "algorithm", "AI"],
            "history": ["historical", "ancient", "war", "civilization", "century"],
            "language": ["grammar", "vocabulary", "pronunciation", "meaning", "word"],
            "general": []
        }
        
        question_lower = question.lower()
        for domain, keywords in domains.items():
            if any(keyword in question_lower for keyword in keywords):
                return domain
        
        return "general"
    
    def _assess_complexity(self, question: str) -> str:
        """Assess the complexity level of the question."""
        # Simple heuristic based on question length and certain indicators
        if len(question) > 200 or "complex" in question.lower():
            return "high"
        elif len(question) > 100 or any(word in question.lower() for word in ["advanced", "detailed", "comprehensive"]):
            return "medium"
        else:
            return "low"
    
    def _extract_keywords(self, question: str) -> List[str]:
        """Extract key terms from the question."""
        # Simple keyword extraction (in practice, use NLP libraries)
        import re
        
        # Remove common stop words and extract meaningful terms
        stop_words = {"the", "is", "are", "what", "how", "why", "when", "where", "do", "does", "can", "will", "would", "could", "should"}
        
        words = re.findall(r'\b\w+\b', question.lower())
        keywords = [word for word in words if len(word) > 3 and word not in stop_words]
        
        return keywords[:10]  # Return top 10 keywords
    
    def _identify_intent(self, question: str) -> str:
        """Identify the user's intent behind the question."""
        question_lower = question.lower()
        
        if any(phrase in question_lower for phrase in ["explain", "help me understand", "clarify"]):
            return "understanding"
        elif any(phrase in question_lower for phrase in ["how to", "steps", "guide", "tutorial"]):
            return "instruction"
        elif any(phrase in question_lower for phrase in ["example", "instance", "demonstrate"]):
            return "example"
        elif any(phrase in question_lower for phrase in ["compare", "difference", "versus", "vs"]):
            return "comparison"
        elif "?" in question:
            return "inquiry"
        else:
            return "general"
    
    def clear_history(self) -> None:
        """Clear the conversation history."""
        self.conversation_history = []
        self.current_context = None
        self.logger.info("Conversation history cleared")
    
    def get_history(self) -> List[str]:
        """Get the current conversation history."""
        return self.conversation_history.copy()
