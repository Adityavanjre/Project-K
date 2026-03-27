import pytest
from src.core.predictive_engine import PredictiveIntentEngine

def test_predictive_engine_initializes():
    """PredictiveIntentEngine should initialize with default knowledge paths."""
    engine = PredictiveIntentEngine()
    assert engine.knowledge_paths["microcontroller"] == ["Circuit Diagram", "Pinouts", "Firmware Upload"]

def test_prediction_logic_arduino():
    """PredictiveIntentEngine should suggest microcontroller topics for Arduino input."""
    engine = PredictiveIntentEngine()
    predictions = engine.predict_next_steps("My Arduino is power cycling.", dna_level=15)
    # Use level 15 to avoid "Foundational:" prefix for simple check
    assert any("Circuit Diagram" in p for p in predictions) or any("Pinouts" in p for p in predictions)
    assert len(predictions) > 0

def test_prediction_dna_scaling():
    """Predictions should be scaled based on DNA level."""
    engine = PredictiveIntentEngine()
    low_dna_preds = engine.predict_next_steps("Arduino", dna_level=5)
    high_dna_preds = engine.predict_next_steps("Arduino", dna_level=45)
    
    assert "Foundational: " in low_dna_preds[0]
    assert "Expert Scale: " in high_dna_preds[0]

def test_anticipation_manifest():
    """Generates a complete manifestation for the UI."""
    engine = PredictiveIntentEngine()
    manifest = engine.generate_anticipation_manifest(["Drone motors"], {"total_dna": 25})
    assert "predicted_queries" in manifest
    assert "suggested_mission" in manifest
    assert manifest["confidence"] > 0.5
