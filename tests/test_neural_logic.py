"""
Test Suite: Phase 9 — NeuralLogic (Synaptic Routing)
"""
import sys, os, pytest
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from core.neural_logic import NeuralLogic


def test_neural_logic_initializes():
    """NeuralLogic initializes with default synapses."""
    logic = NeuralLogic(dna_path="__nonexistent__.json")
    assert isinstance(logic.synapses, dict)
    assert len(logic.synapses) > 0


def test_synaptic_priority_baseline():
    """Tasks with no matching synapses get baseline priority."""
    logic = NeuralLogic(dna_path="__nonexistent__.json")
    priority = logic.calculate_priority("random unrelated task", base_priority=50)
    assert priority == 50.0


def test_synaptic_priority_amplified():
    """Tasks matching a synapse topic are amplified above baseline."""
    logic = NeuralLogic(dna_path="__nonexistent__.json")
    logic.synapses["circuit_design"] = 1.0
    # 'circuit_design' matches -> weight=2.0, priority = 50*2 = 100
    amplified = logic.calculate_priority("circuit design for bridge", base_priority=50)
    # no match -> weight=1.0, priority = 50*1 = 50
    baseline = logic.calculate_priority("random unmatched task xyz", base_priority=50)
    assert amplified >= baseline


def test_route_tasks_sorts_by_priority():
    """route_tasks returns tasks sorted highest priority first."""
    logic = NeuralLogic(dna_path="__nonexistent__.json")
    logic.synapses["cryptography"] = 1.0
    tasks = [
        {"name": "Simple LED Blink"},
        {"name": "Cryptography Audit for Sovereign Node"}
    ]
    routed = logic.route_tasks(tasks)
    assert routed[0]["name"] == "Cryptography Audit for Sovereign Node"


def test_priority_capped_at_100():
    """Synaptic priority cannot exceed 100."""
    logic = NeuralLogic(dna_path="__nonexistent__.json")
    for key in logic.synapses:
        logic.synapses[key] = 1.0
    priority = logic.calculate_priority(
        " ".join(logic.synapses.keys()), base_priority=100
    )
    assert priority <= 100.0
