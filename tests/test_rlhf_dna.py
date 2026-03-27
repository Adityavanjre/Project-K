import pytest
import os
import json
from src.core.rlhf_service import RLHFService

@pytest.fixture
def temp_rlhf_root(tmp_path):
    root = tmp_path / "app"
    root.mkdir()
    (root / "data").mkdir()
    return str(root)

def test_rlhf_alignment_calculation(temp_rlhf_root):
    service = RLHFService(temp_rlhf_root)
    directives = ["Sovereignty", "Physical Fabrication", "Simplicity"]
    
    # High alignment
    synthesis = "KALI achieves Sovereignty through Physical Fabrication and Simplicity."
    score = service.calculate_alignment(synthesis, directives)
    assert score > 90 # Initial 92.5 + boost
    
    # Low alignment
    synthesis = "Random text without directives."
    score = service.calculate_alignment(synthesis, directives)
    assert score < 95 # Should start decaying

def test_rlhf_weight_adjustment(temp_rlhf_root):
    service = RLHFService(temp_rlhf_root)
    initial_gpt_weight = service.weights["gpt-4"]
    
    # Penalty
    service.adjust_model_authority("gpt-4", "correction")
    assert service.weights["gpt-4"] < initial_gpt_weight
    
    # Boost
    service.adjust_model_authority("claude-3", "approval")
    assert service.weights["claude-3"] > 1.0

def test_rlhf_bias_detection(temp_rlhf_root):
    service = RLHFService(temp_rlhf_root)
    
    text = "This is the only way to achieve singularity. It will always work."
    biases = service.detect_bias(text)
    
    assert len(biases) >= 2
    assert "ABSOLUTISM_DETECTED" in biases[0]

def test_rlhf_telemetry(temp_rlhf_root):
    service = RLHFService(temp_rlhf_root)
    status = service.get_alignment_status()
    
    assert "alignment_score" in status
    assert "bias_count" in status
    assert "status" in status
    assert status["status"] == "ALIGNMENT_OPTIMAL"
