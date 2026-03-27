import pytest
from src.core.watchdog_service import WatchdogService

def test_watchdog_monitoring():
    dog = WatchdogService("/tmp")
    status = dog.monitor_health()
    assert status["status"] == "NOMINAL"

def test_repair_logic():
    dog = WatchdogService("/tmp")
    dog.trigger_repair("SyntaxError", "traceback...", "test.py")
    status = dog.get_repair_status()
    assert status["total_repairs"] == 1
    assert status["history"][0]["error"] == "SyntaxError"

def test_repair_history_limit():
    dog = WatchdogService("/tmp")
    for i in range(10):
        dog.trigger_repair(f"Err_{i}", "...", "test.py")
    status = dog.get_repair_status()
    assert len(status["history"]) == 5 # Limit 5
    assert status["total_repairs"] == 10
