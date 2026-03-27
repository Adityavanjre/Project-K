"""
Test Suite: Phase 21 — BiometricService (Vedic Integration)
"""
import sys, os, time, pytest
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from core.biometric_service import BiometricService


def test_biometric_initializes():
    """BiometricService initializes with stable defaults."""
    service = BiometricService()
    state = service.get_physiological_state()
    assert state["neural_tension"] >= 0
    assert state["status"] == "STABLE"


def test_neural_tension_increases():
    """Neural tension increases with interaction frequency."""
    service = BiometricService()
    initial_tension = service.calculate_neural_tension()
    
    for _ in range(50):
        service.record_interaction()
        
    higher_tension = service.calculate_neural_tension()
    assert higher_tension > initial_tension


def test_neural_reset_logic():
    """Performing a reset clears the tension state."""
    service = BiometricService()
    for _ in range(100):
        service.record_interaction()
    
    assert service.calculate_neural_tension() > 10
    service.perform_reset()
    assert service.calculate_neural_tension() < 5


def test_trigger_tension_alert():
    """High tension correctly triggers a Neural Reset suggestion."""
    # Set threshold very low for testing
    service = BiometricService(threshold_tension=5.0)
    for _ in range(20):
        service.record_interaction()
    
    state = service.get_physiological_state()
    assert state["reset_suggested"] is True
    assert state["status"] == "TENSION_HIGH"
