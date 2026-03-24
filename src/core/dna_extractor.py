import re
import logging
from typing import Optional

class DNAExtractor:
    """
    Silently extracts user facts from conversations and updates the User DNA.
    """
    def __init__(self, user_dna, vector_memory):
        self.dna = user_dna
        self.vm = vector_memory
        self.logger = logging.getLogger(__name__)

    def process(self, user_message: str, ai_response: str):
        q = user_message.lower()
        
        # 1. Identity
        self._extract_identity(q)
        
        # 2. Hardware/Sensors
        self._extract_hardware(q)
        
        # 3. Projects
        self._extract_projects(q, user_message)
        
        # 4. Expertise
        self._extract_expertise(q)
        
        # 5. Goals
        self._extract_goals(q, user_message)
        
        # Identify the core concept using AI (Phase 33 Mastery logic)
        q_clean = str(q)[:150]
        prompt = f"Extract ONE core technical concept from this query: {q_clean}\nReturn ONLY the concept word (e.g. PWM, SQL)."
        
        # Record interaction and detect topic
        topic = self._detect_topic(str(q))
        self.dna.record_interaction(topic=topic)
        
        # Store raw fact in vector memory for fuzzy recall
        self.vm.remember_user_fact(f"User fact: {user_message[:500]}")

    def _extract_identity(self, q: str):
        m = re.search(r"(?:my name is|i am|i'm|call me)\s+([a-zA-Z]{2,20})", q)
        if m and not self.dna.get_name():
            self.dna.set_name(m.group(1))

    def _extract_hardware(self, q: str):
        HARDWARE = ["arduino", "esp32", "raspberry pi", "uno", "mega", "nano", "pico", "stm32"]
        SENSORS = ["dht11", "hc-sr04", "mpu6050", "neopixel", "servo", "motor", "lcd", "led"]
        
        for h in HARDWARE:
            if h in q: self.dna.add_hardware(h.upper())
        for s in SENSORS:
            if s in q: self.dna.add_sensor(s.upper())

    def _extract_projects(self, q: str, raw: str):
        if any(t in q for t in ["building", "working on", "making", "designing"]):
            self.dna.add_active_project(name=raw[:40], description=raw[:150])
            self.vm.remember_project(raw[:250])

    def _extract_expertise(self, q: str):
        CONCEPTS = ["PWM", "I2C", "SPI", "UART", "INTERRUPT", "PID", "MQTT", "REST", "API", "JSON", "SQL"]
        for c in CONCEPTS:
            if c.lower() in q: 
                self.dna.add_known_concept(c, score_delta=20)

    def _extract_goals(self, q: str, raw: str):
        if any(t in q for t in ["i want to", "my goal", "trying to"]):
            self.dna.add_goal(raw[:150])

    def _extract_preferences(self, q: str):
        if "simple" in q or "concise" in q:
            self.dna.set_preference("explanation_style", "concise")
        elif "detail" in q or "deep dive" in q:
            self.dna.set_preference("explanation_style", "detailed")

    def _detect_topic(self, q: str) -> Optional[str]:
        if "arduino" in q: return "Arduino"
        if "esp32" in q: return "ESP32"
        if "python" in q: return "Python"
        if "circuit" in q or "voltage" in q: return "Electronics"
        return "General"
