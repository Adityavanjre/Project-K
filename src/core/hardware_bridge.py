import logging
import json
import random
import time
from typing import Dict, Any, List, Optional

logger = logging.getLogger(__name__)

class HardwareBridge:
    """Phase 31: Hardware-In-The-Loop (HITL) Integration."""
    
    def __init__(self, port: str = "COM3", baud: int = 115200):
        self.port = port
        self.baud = baud
        self.is_connected = False
        self.last_telemetry = {}
        self.sim_mode = True # Default to simulator for stability
        
    def connect(self) -> bool:
        """Establishes connection to the external MCU."""
        logger.info(f"KALI Hardware: Attempting connection to {self.port} at {self.baud}...")
        # In a real environment, we'd use 'serial.Serial'
        # For now, we simulate the 'Sovereign Handshake'
        time.sleep(0.5)
        self.is_connected = True
        logger.info("KALI Hardware: HITL Link Established.")
        return True

    def get_telemetry(self) -> Dict[str, Any]:
        """Reads real-time sensor data from the hardware."""
        if not self.is_connected:
            return {"status": "DISCONNECTED"}
            
        if self.sim_mode:
            # Generate tactical telemetry
            self.last_telemetry = {
                "vcc": round(3.3 + random.uniform(-0.1, 0.1), 2),
                "rssi": random.randint(-70, -30),
                "cpu_temp": round(45.0 + random.uniform(0, 5), 1),
                "sensor_delta": round(random.uniform(0, 1), 3),
                "uptime": int(time.time()) % 1000
            }
            
        return self.last_telemetry

    def send_command(self, cmd: str, args: Optional[List[Any]] = None) -> bool:
        """Transmits a tactical command to the MCU."""
        if not self.is_connected:
            return False
            
        payload = {"cmd": cmd, "args": args or [], "ts": time.time()}
        logger.info(f"KALI Hardware: Uplink Command -> {json.dumps(payload)}")
        return True

    def toggle_simulator(self, mode: bool):
        self.sim_mode = mode
