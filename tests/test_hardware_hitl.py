import pytest
from src.core.hardware_bridge import HardwareBridge

def test_hardware_connection():
    bridge = HardwareBridge()
    assert bridge.connect() == True
    assert bridge.is_connected == True

def test_hardware_telemetry():
    bridge = HardwareBridge()
    bridge.connect()
    telemetry = bridge.get_telemetry()
    assert "vcc" in telemetry
    assert "rssi" in telemetry
    assert telemetry["vcc"] > 3.0

def test_hardware_command():
    bridge = HardwareBridge()
    bridge.connect()
    assert bridge.send_command("calibrate_imu", [1, 0, 0]) == True

def test_hardware_disconnect():
    bridge = HardwareBridge()
    # Not connected
    assert bridge.get_telemetry()["status"] == "DISCONNECTED"
    assert bridge.send_command("test") == False
