"""
Basic tests for the Doubt Clearing AI application.
"""

import pytest
from src.core.processor import DoubtProcessor
from src.core.data_structures import DoubtContext
from src.utils.helpers import load_config, create_default_config


def test_doubt_processor_initialization():
    """Test that DoubtProcessor can be initialized."""
    processor = DoubtProcessor()
    assert processor is not None
    assert processor.knowledge_base is not None
    assert processor.explainer is not None


def test_process_simple_question():
    """Test processing a simple question."""
    processor = DoubtProcessor()
    response = processor.process_doubt("What is AI?")
    
    assert isinstance(response, str)
    assert len(response) > 0
    assert "Artificial Intelligence" in response


def test_doubt_context():
    """Test DoubtContext creation and initialization."""
    context = DoubtContext(question="Test question")
    assert context.question == "Test question"
    assert context.user_level == "intermediate"
    assert context.domain is None
    assert context.conversation_history == []


def test_config_creation():
    """Test configuration creation."""
    config = create_default_config()
    
    assert "application" in config
    assert "knowledge" in config
    assert "explainer" in config
    assert "logging" in config
    
    assert config["application"]["name"] == "Doubt Clearing AI"
    assert config["explainer"]["default_user_level"] == "intermediate"


def test_different_question_types():
    """Test processing different types of questions."""
    processor = DoubtProcessor()
    
    # Definition question
    response1 = processor.process_doubt("What is photosynthesis?")
    assert "photosynthesis" in response1.lower()
    
    # Procedure question
    response2 = processor.process_doubt("How does machine learning work?")
    assert "machine learning" in response2.lower()
    
    # Both should be strings with content
    assert isinstance(response1, str) and len(response1) > 50
    assert isinstance(response2, str) and len(response2) > 50


def test_conversation_history():
    """Test that conversation history is maintained."""
    processor = DoubtProcessor()
    
    # Initial state
    assert len(processor.get_history()) == 0
    
    # After first question
    processor.process_doubt("What is AI?")
    history = processor.get_history()
    assert len(history) == 2  # question + response
    
    # After second question
    processor.process_doubt("How does it work?")
    history = processor.get_history()
    assert len(history) == 4  # 2 questions + 2 responses
    
    # Clear history
    processor.clear_history()
    assert len(processor.get_history()) == 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
