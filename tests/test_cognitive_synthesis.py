import pytest
import os
import json
from src.core.rlhf_service import RLHFService

@pytest.fixture
def temp_synth_root(tmp_path):
    root = tmp_path / "app"
    root.mkdir()
    (root / "data").mkdir()
    
    # Create mock training data
    log_path = root / "data" / "training_data.jsonl"
    with open(log_path, "w") as f:
        for i in range(5):
            record = {"messages": [], "timestamp": "2026-03-26", "source": "kali_live"}
            f.write(json.dumps(record) + "\n")
            
    return str(root)

def test_cognitive_synthesis_logic(temp_synth_root):
    service = RLHFService(temp_synth_root)
    initial_weights = service.weights.copy()
    initial_alignment = service.alignment_score
    
    # Run synthesis
    result = service.run_cognitive_synthesis()
    
    assert result["status"] == "SYNTHESIS_COMPLETE"
    assert result["interactions_processed"] == 5
    assert result["new_alignment"] > initial_alignment
    
    # Check weight boost
    for mid in service.weights:
        assert service.weights[mid] > initial_weights[mid]

def test_synthesis_no_data(tmp_path):
    root = tmp_path / "app_no_data"
    root.mkdir()
    (root / "data").mkdir()
    service = RLHFService(str(root))
    
    result = service.run_cognitive_synthesis()
    assert result["status"] == "NO_DATA_TO_SYNTHESIZE"
