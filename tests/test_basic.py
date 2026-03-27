"""
Basic tests for the Doubt Clearing AI application.
"""

import pytest
from core.processor import DoubtProcessor
from core.data_structures import DoubtContext
from utils.helpers import load_config, create_default_config


def test_doubt_processor_initialization():
    """Test that DoubtProcessor can be initialized."""
    processor = DoubtProcessor()
    assert processor is not None
    assert processor.vector_memory is not None
    assert processor.explainer is not None


def test_process_simple_question():
    """Test processing a simple question."""
    processor = DoubtProcessor()
    response = processor.process_doubt("What is AI?")
    
    assert isinstance(response, dict)
    assert "text" in response
    assert len(response["text"]) > 0
    assert "Artificial Intelligence" in response["text"]


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
    
    assert config["application"]["name"] == "KALI"
    assert config["explainer"]["default_user_level"] == "intermediate"


def test_different_question_types():
    """Test processing different types of questions."""
    processor = DoubtProcessor()
    
    # Definition question
    response1 = processor.process_doubt("What is photosynthesis?")
    assert "photosynthesis" in response1["text"].lower()
    
    # Procedure question
    response2 = processor.process_doubt("How does machine learning work?")
    assert "machine learning" in response2["text"].lower()
    
    # Both should be strings with content
    assert isinstance(response1["text"], str) and len(response1["text"]) > 50
    assert isinstance(response2["text"], str) and len(response2["text"]) > 50


def test_conversation_history():
    """Test that conversation history is maintained."""
    processor = DoubtProcessor()
    
    # Initial state
    processor.clear_history()
    assert len(processor.get_history()) == 0
    
    # After first question
    processor.process_doubt("What is AI?")
    history = processor.get_history()
    assert len(history) >= 2  # question + response (might be more if proactive)
    
    # After second question
    processor.process_doubt("How does it work?")
    history = processor.get_history()
    assert len(history) >= 4  
    
    # Clear history
    processor.clear_history()
    assert len(processor.get_history()) == 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
