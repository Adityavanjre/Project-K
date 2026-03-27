import pytest
import os
import json
import shutil
from src.core.integrity import IntegrityService
from src.core.secure_boot import BootGuardian

@pytest.fixture
def temp_root(tmp_path):
    root = tmp_path / "app"
    root.mkdir()
    core = root / "src" / "core"
    core.mkdir(parents=True)
    
    # Create mock core files
    (core / "logic.py").write_text("print('core')", encoding="utf-8")
    (core / "auth.py").write_text("print('auth')", encoding="utf-8")
    
    return root

def test_integrity_generation(temp_root):
    service = IntegrityService(root_dir=str(temp_root))
    service.CHECKSUM_FILE = str(temp_root / "data" / "checksums.kali")
    
    success = service.generate_signatures()
    assert success is True
    assert os.path.exists(service.CHECKSUM_FILE)
    
    with open(service.CHECKSUM_FILE, "r") as f:
        sigs = json.load(f)
        assert "src/core/logic.py" in sigs
        assert "src/core/auth.py" in sigs

def test_integrity_verification_success(temp_root):
    service = IntegrityService(root_dir=str(temp_root))
    service.CHECKSUM_FILE = str(temp_root / "data" / "checksums.kali")
    service.generate_signatures()
    
    is_intact, violations = service.verify_integrity()
    assert is_intact is True
    assert len(violations) == 0

def test_integrity_tamper_detection(temp_root):
    service = IntegrityService(root_dir=str(temp_root))
    service.CHECKSUM_FILE = str(temp_root / "data" / "checksums.kali")
    service.generate_signatures()
    
    # Tamper with a file
    (temp_root / "src" / "core" / "logic.py").write_text("print('hacked')", encoding="utf-8")
    
    is_intact, violations = service.verify_integrity()
    assert is_intact is False
    assert violations[0]["path"] == "src/core/logic.py"
    assert violations[0]["error"] == "MODIFIED"

def test_secure_boot_gating(temp_root, monkeypatch):
    # Mock IntegrityService to fail
    monkeypatch.setattr("src.core.secure_boot.IntegrityService", lambda: type('obj', (object,), {
        'verify_integrity': lambda self: (False, [{"path": "core.py", "error": "BREACH"}])
    })())
    
    guardian = BootGuardian()
    success = guardian.perform_secure_boot()
    assert success is False
    assert guardian.is_secure_ready is False
    assert guardian.get_bios_status()["status"] == "BREACHED"
