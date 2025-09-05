"""
Knowledge base management for the Doubt Clearing AI.
"""

import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass


@dataclass
class KnowledgeItem:
    """Represents a piece of knowledge."""

    title: str
    content: str
    domain: str
    keywords: List[str]
    source: Optional[str] = None
    confidence: float = 1.0


class KnowledgeBase:
    """Manages the knowledge base for the AI system."""

    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """Initialize the knowledge base."""
        self.config = config or {}
        self.logger = logging.getLogger(__name__)

        # Storage for knowledge items
        self.knowledge_items: List[KnowledgeItem] = []
        self.domain_index: Dict[str, List[KnowledgeItem]] = {}

        # Initialize with basic knowledge
        self._load_basic_knowledge()

        self.logger.info("KnowledgeBase initialized successfully")

    def _load_basic_knowledge(self) -> None:
        """Load basic knowledge items to get started."""
        basic_knowledge = [
            KnowledgeItem(
                title="What is Artificial Intelligence?",
                content="Artificial Intelligence (AI) is a branch of computer science that aims to create machines capable of performing tasks that typically require human intelligence. This includes learning, reasoning, problem-solving, perception, and language understanding. AI systems can be narrow (designed for specific tasks) or general (capable of performing any intellectual task). Modern AI relies on machine learning, neural networks, and deep learning to process data and make decisions.",
                domain="technology",
                keywords=[
                    "AI",
                    "artificial",
                    "intelligence",
                    "machine",
                    "learning",
                    "computer",
                    "science",
                ],
            ),
            KnowledgeItem(
                title="How does Machine Learning work?",
                content="Machine Learning is a subset of AI that enables computers to learn and improve from experience without being explicitly programmed. It works by feeding algorithms large amounts of data, allowing them to identify patterns and make predictions. There are three main types: supervised learning (using labeled data), unsupervised learning (finding patterns in unlabeled data), and reinforcement learning (learning through trial and error with rewards).",
                domain="technology",
                keywords=[
                    "machine",
                    "learning",
                    "algorithms",
                    "data",
                    "patterns",
                    "supervised",
                    "unsupervised",
                ],
            ),
            KnowledgeItem(
                title="What is Photosynthesis?",
                content="Photosynthesis is the process by which plants, algae, and some bacteria convert light energy (usually from the sun) into chemical energy stored in glucose. The process occurs in two main stages: light-dependent reactions (in the thylakoids) and light-independent reactions (Calvin cycle in the stroma). The overall equation is: 6CO2 + 6H2O + light energy → C6H12O6 + 6O2. This process is crucial for life on Earth as it produces oxygen and forms the base of most food chains.",
                domain="science",
                keywords=[
                    "photosynthesis",
                    "plants",
                    "light",
                    "energy",
                    "glucose",
                    "oxygen",
                    "chloroplast",
                ],
            ),
            KnowledgeItem(
                title="What is the Pythagorean Theorem?",
                content="The Pythagorean Theorem is a fundamental principle in geometry that states: in a right triangle, the square of the hypotenuse (the side opposite the right angle) is equal to the sum of squares of the other two sides. Mathematically: a² + b² = c², where c is the hypotenuse and a and b are the other two sides. This theorem is used to calculate distances, in construction, navigation, and many engineering applications.",
                domain="mathematics",
                keywords=[
                    "pythagorean",
                    "theorem",
                    "triangle",
                    "right",
                    "hypotenuse",
                    "geometry",
                    "square",
                ],
            ),
            KnowledgeItem(
                title="What is Democracy?",
                content="Democracy is a system of government where power is vested in the people, who rule either directly or through freely elected representatives. Key principles include: rule of law, individual rights and freedoms, equality before the law, and majority rule with minority rights protection. There are different forms like direct democracy (citizens vote on issues directly) and representative democracy (citizens elect representatives to make decisions).",
                domain="history",
                keywords=[
                    "democracy",
                    "government",
                    "people",
                    "elected",
                    "representatives",
                    "voting",
                    "rights",
                ],
            ),
        ]

        for item in basic_knowledge:
            self.add_knowledge(item)

    def add_knowledge(self, item: KnowledgeItem) -> None:
        """Add a knowledge item to the base."""
        self.knowledge_items.append(item)

        # Update domain index
        if item.domain not in self.domain_index:
            self.domain_index[item.domain] = []
        self.domain_index[item.domain].append(item)

        self.logger.debug(f"Added knowledge item: {item.title}")

    def search(self, query: str, domain: Optional[str] = None) -> List[KnowledgeItem]:
        """
        Search for relevant knowledge items.

        Args:
            query: Search query
            domain: Optional domain to filter by

        Returns:
            List of relevant knowledge items
        """
        query_lower = query.lower()
        query_words = set(query_lower.split())

        # Get items to search
        if domain and domain in self.domain_index:
            search_items = self.domain_index[domain]
        else:
            search_items = self.knowledge_items

        # Score and rank items
        scored_items = []
        for item in search_items:
            score = self._calculate_relevance_score(query_words, item)
            if score > 0:
                scored_items.append((item, score))

        # Sort by score (descending) and return top results
        scored_items.sort(key=lambda x: x[1], reverse=True)
        return [item for item, score in scored_items[:5]]  # Return top 5

    def _calculate_relevance_score(
        self, query_words: set, item: KnowledgeItem
    ) -> float:
        """Calculate relevance score for a knowledge item."""
        score = 0.0

        # Check title matches (higher weight)
        title_words = set(item.title.lower().split())
        title_matches = len(query_words & title_words)
        score += title_matches * 3.0

        # Check keyword matches (medium weight)
        item_keywords = set(keyword.lower() for keyword in item.keywords)
        keyword_matches = len(query_words & item_keywords)
        score += keyword_matches * 2.0

        # Check content matches (lower weight)
        content_words = set(item.content.lower().split())
        content_matches = len(query_words & content_words)
        score += content_matches * 1.0

        # Apply confidence multiplier
        score *= item.confidence

        return score

    def get_by_domain(self, domain: str) -> List[KnowledgeItem]:
        """Get all knowledge items for a specific domain."""
        return self.domain_index.get(domain, [])

    def get_domains(self) -> List[str]:
        """Get list of all available domains."""
        return list(self.domain_index.keys())

    def get_stats(self) -> Dict[str, Any]:
        """Get knowledge base statistics."""
        return {
            "total_items": len(self.knowledge_items),
            "domains": len(self.domain_index),
            "domain_breakdown": {
                domain: len(items) for domain, items in self.domain_index.items()
            },
        }
