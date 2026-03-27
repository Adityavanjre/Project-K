import pytest
from src.core.predictive_engine import PredictiveIntentEngine

def test_motor_prediction():
    engine = PredictiveIntentEngine()
    preds = engine.predict_next_steps("I want to buy a brushless motor", 0)
    assert "Select ESC" in preds
    assert len(preds) == 3

def test_drone_prediction():
    engine = PredictiveIntentEngine()
    preds = engine.predict_next_steps("help me build a racing drone", 0)
    assert "Flight Controller Setup" in preds

def test_fallback_prediction():
    engine = PredictiveIntentEngine()
    preds = engine.predict_next_steps("Tell me about gravity", 0)
    assert "Component Analysis" in preds
    assert len(preds) == 3

def test_case_insensitivity():
    engine = PredictiveIntentEngine()
    preds = engine.predict_next_steps("MOTOR", 0)
    assert "Select ESC" in preds
