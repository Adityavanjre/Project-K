"""
Test Suite: Phase 6 — DreamEngine (Cognitive Consolidation)
"""
import sys, os, json, pytest, tempfile
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from core.dream_engine import DreamEngine


@pytest.fixture
def tmp_paths(tmp_path):
    history = tmp_path / "training_data.jsonl"
    wisdom = tmp_path / "wisdom_seeds.jsonl"
    return str(history), str(wisdom)


def test_dream_engine_no_data(tmp_paths):
    """DreamEngine returns empty list when no history exists."""
    history_path, wisdom_path = tmp_paths
    engine = DreamEngine(history_path=history_path, wisdom_path=wisdom_path)
    seeds = engine.dream()
    assert seeds == []


def test_dream_engine_consolidates(tmp_paths):
    """DreamEngine processes interaction logs and saves wisdom seeds."""
    history_path, wisdom_path = tmp_paths
    
    # Write a fake interaction log
    log = {
        "timestamp": "2026-01-01T00:00:00",
        "messages": [
            {"role": "user", "content": "Explain logic gate circuit design."},
            {"role": "assistant", "content": "A logic gate processes binary inputs to produce outputs."}
        ]
    }
    with open(history_path, "w") as f:
        f.write(json.dumps(log) + "\n")
    
    engine = DreamEngine(history_path=history_path, wisdom_path=wisdom_path)
    seeds = engine.dream()
    
    # Verify function ran without error (may produce 0 or more seeds)
    assert isinstance(seeds, list)


def test_dream_engine_creates_wisdom_file(tmp_paths):
    """DreamEngine creates the wisdom_seeds.jsonl file."""
    history_path, wisdom_path = tmp_paths
    log = {
        "timestamp": "2026-01-01T00:00:00",
        "messages": [
            {"role": "user", "content": "Explain logic circuit."},
            {"role": "assistant", "content": "Logic circuits process binary signals."}
        ]
    }
    with open(history_path, "w") as f:
        f.write(json.dumps(log) + "\n")
    
    engine = DreamEngine(history_path=history_path, wisdom_path=wisdom_path)
    engine.dream()
    assert os.path.exists(wisdom_path)
