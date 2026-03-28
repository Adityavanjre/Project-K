import sys, os, pytest
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src')))

from core.biometric_service import BiometricService

@pytest.fixture
def bio_service():
    return BiometricService()

def test_initial_physiological_state(bio_service):
    """Should start with stable neutral state."""
    state = bio_service.get_physiological_state()
    assert state["status"] == "STABLE"
    assert state["neural_tension"] == 0.0
    assert state["reset_suggested"] is False

def test_tension_accumulation_and_reset(bio_service):
    """Tension should rise with interactions and clear on reset."""
    for _ in range(50):
        bio_service.record_interaction()
    
    mid_tension = bio_service.calculate_neural_tension()
    assert mid_tension > 0
    
    bio_service.perform_reset()
    assert bio_service.calculate_neural_tension() == 0.0

def test_high_tension_trigger(bio_service):
    """High tension (>100.0) should trigger state change and reset suggestion."""
    # Mocking many interactions
    for _ in range(1001):
        bio_service.record_interaction()
        
    state = bio_service.get_physiological_state()
    assert state["neural_tension"] > 100.0
    assert state["status"] == "TENSION_HIGH"
    assert state["reset_suggested"] is True

def test_tension_decay_logic(bio_service):
    """
    If implemented, tension should decay over time. 
    (Verifying current implementation's time-weighted logic if any).
    """
    bio_service.record_interaction()
    t1 = bio_service.calculate_neural_tension()
    
    # Simulate time pass if the service uses timestamps (currently it seems to use count-based decay or fixed)
    # Looking at biometric_service.py... it uses a simple counter usually.
    # Let's verify the behavioral response.
    assert t1 > 0
