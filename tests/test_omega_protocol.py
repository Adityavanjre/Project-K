import pytest
import os
import json
from src.core.omega_protocol import OmegaProtocol

@pytest.fixture
def temp_omega_root(tmp_path):
    root = tmp_path / "app"
    root.mkdir()
    (root / "data").mkdir()
    return str(root)

def test_omega_manifest_generation(temp_omega_root):
    protocol = OmegaProtocol(temp_omega_root)
    
    # Trigger handover
    result = protocol.initiate_handover()
    assert result["status"] == "OMEGA_COMPLETE"
    assert "manifest_hash" in result
    
    # Check physical file
    assert os.path.exists(protocol.manifest_path)
    with open(protocol.manifest_path, "r") as f:
        manifest = json.load(f)
        assert manifest["state"]["evolution_phases"] == 40
        assert manifest["state"]["sovereignty"] == "ABSOLUTE"

def test_omega_telemetry(temp_omega_root):
    protocol = OmegaProtocol(temp_omega_root)
    
    # Before activation
    status = protocol.get_protocol_status()
    assert status["active"] is False
    assert status["state"] == "OMEGA_IDLE"
    
    # After activation
    protocol.initiate_handover()
    status = protocol.get_protocol_status()
    assert status["active"] is True
    assert status["state"] == "SINGULARITY_REACHED"
    assert status["timestamp"] is not None

def test_omega_manifest_integrity(temp_omega_root):
    protocol = OmegaProtocol(temp_omega_root)
    protocol.initiate_handover()
    
    with open(protocol.manifest_path, "r") as f:
        manifest = json.load(f)
        
    expected_sig = f"KALI-SIG-{manifest['hash'][:8]}"
    assert manifest["signature"] == expected_sig
