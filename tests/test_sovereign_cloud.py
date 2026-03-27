import pytest
import os
import json
import shutil
from src.core.sovereign_cloud import SovereignCloudService

@pytest.fixture
def temp_cloud_root(tmp_path):
    root = tmp_path / "app"
    root.mkdir()
    return str(root)

def test_cloud_encryption(temp_cloud_root):
    service = SovereignCloudService(temp_cloud_root)
    test_data = {"memory": "kali_sentience_01", "dna": 42}
    
    encrypted_str = service.encrypt_payload(test_data)
    encrypted_json = json.loads(encrypted_str)
    
    assert "payload" in encrypted_json
    assert "sig" in encrypted_json
    assert "ts" in encrypted_json
    
    # Verify payload is the original data
    assert json.loads(encrypted_json["payload"]) == test_data

def test_cloud_memory_anchoring(temp_cloud_root):
    service = SovereignCloudService(temp_cloud_root)
    test_data = {"goal": "Phase 38 Complete", "status": "NOMINAL"}
    
    success = service.anchor_memory_segment("test_segment", test_data)
    assert success is True
    
    # Check physical file existence
    anchor_file = os.path.join(service.cloud_root, "test_segment.kanchor")
    assert os.path.exists(anchor_file)
    
    with open(anchor_file, "r") as f:
        stored = json.load(f)
        assert json.loads(stored["payload"]) == test_data

def test_cloud_telemetry(temp_cloud_root):
    service = SovereignCloudService(temp_cloud_root)
    
    # Before sync
    status = service.get_cloud_status()
    assert status["status"] == "SYNC_NOMINAL"
    assert status["total_anchors"] == 0
    
    # Anchor something
    service.anchor_memory_segment("node_alpha", {"ping": "pong"})
    
    # After sync
    status = service.get_cloud_status()
    assert status["total_anchors"] == 1
    assert status["network_integrity"] == 100
