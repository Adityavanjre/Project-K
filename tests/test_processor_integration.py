import pytest
import os
import json
from src.core.processor import DoubtProcessor

class TestProcessorIntegration:
    """
    Phase 52: T-5 Integration Tests.
    Verifies that DoubtProcessor can handle a full question cycle.
    """
    
    @pytest.fixture
    def processor(self):
        # Use a temporary directory for data during tests
        config = {"project_root": "tests/test_data"}
        os.makedirs("tests/test_data/data", exist_ok=True)
        return DoubtProcessor(config=config)

    def test_process_doubt_basic(self, processor):
        """Test a simple question through the full pipeline."""
        question = "What is the structural integrity of a titanium frame?"
        result = processor.process_doubt(question)
        
        assert "text" in result
        assert isinstance(result["text"], str)
        assert len(result["text"]) > 0
        
    def test_shadow_eval_logging(self, processor):
        """Verify shadow evaluation logs are generated."""
        eval_path = os.path.join(processor.project_root, "data", "shadow_eval.jsonl")
        if os.path.exists(eval_path): os.remove(eval_path)
        
        # Trigger an evaluation
        processor._log_shadow_eval("test query", "local resp", "external resp")
        
        assert os.path.exists(eval_path)
        with open(eval_path, "r") as f:
            line = f.readline()
            data = json.loads(line)
            assert data["query"] == "test query"
            assert data["length_ratio"] > 0
