import sqlite3
import json
import os
import logging
from datetime import datetime
from typing import Dict, Any, Optional, List

class UserDNA:
    """
    The complete memory profile of a user. Structured long-term profile.
    """
    DEFAULT_PROFILE = {
        "identity": {
            "name": None,
            "spoken_language": "English",
            "timezone": None,
            "education_level": "unknown"
        },
        "expertise": {
            "overall_level": "unknown",
            "domains": {},
            "known_concepts": {}, # Changed to dict for mastery {concept: score}
            "weak_areas": []
        },
        "projects": {
            "active": [],
            "completed": [],
            "wishlist": []
        },
        "hardware": {
            "owned": [],
            "sensors": [],
            "tools": []
        },
        "preferences": {
            "explanation_style": "detailed",
            "code_language": None,
            "prefers_diagrams": True,
            "response_tone": "professional"
        },
        "goals": {
            "short_term": [],
            "long_term": [],
            "aspirations": []
        },
        "emotional_patterns": {
            "gets_frustrated_with": [],
            "gets_excited_by": [],
            "learning_style": "unknown",
            "patience_level": "normal"
        },
        "interaction_stats": {
            "total_conversations": 0,
            "first_seen": None,
            "last_seen": None,
            "favorite_topics": {},
            "questions_asked": 0
        }
    }

    def __init__(self, user_id: str = "default", db_path: str = "data/user_dna.db"):
        self.user_id = user_id
        self.db_path = os.path.abspath(db_path)
        self.logger = logging.getLogger(__name__)
        self._init_db()
        self.profile = self._load()

    def switch_user(self, user_id: str):
        """Switch to a different user identity (Phase 20)."""
        self.user_id = user_id
        self.profile = self._load()
        self.logger.info(f"KALI DNA switched to profile: {user_id}")

    def list_profiles(self) -> List[str]:
        """List all known user profiles."""
        conn = sqlite3.connect(self.db_path)
        rows = conn.execute("SELECT user_id FROM user_dna").fetchall()
        conn.close()
        return [r[0] for r in rows]

    def _init_db(self):
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        conn = sqlite3.connect(self.db_path)
        conn.execute("""
            CREATE TABLE IF NOT EXISTS user_dna (
                user_id   TEXT PRIMARY KEY,
                profile   TEXT NOT NULL,
                updated   DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()
        conn.close()

    def _get_hardware_uid(self) -> str:
        """Fetches a unique hardware ID (CPU + Motherboard) to lock the DNA."""
        try:
            import subprocess
            cpu = subprocess.check_output("wmic cpu get processorid", shell=True).decode().split("\n")[1].strip()
            base = subprocess.check_output("wmic baseboard get serialnumber", shell=True).decode().split("\n")[1].strip()
            return f"{cpu}-{base}"
        except:
            return "UNKNOWN-HW-ID"

    def _load(self) -> dict:
        conn = sqlite3.connect(self.db_path)
        row = conn.execute("SELECT profile FROM user_dna WHERE user_id=?", (self.user_id,)).fetchone()
        conn.close()
        
        hw_id = self._get_hardware_uid()
        
        if row:
            profile = json.loads(row[0])
            # Hardware Lock Verification
            stored_hw = profile.get("security", {}).get("hardware_anchor")
            if stored_hw and stored_hw != hw_id:
                self.logger.critical(f"DNA HW LOCK VIOLATION: Expected {stored_hw}, got {hw_id}. Security Interlock Engaged.")
                # We still load but mark as UNVERIFIED/POTENTIALLY_SPOOFED
                profile["security"]["hw_verified"] = False
            else:
                if "security" not in profile: profile["security"] = {}
                profile["security"]["hardware_anchor"] = hw_id
                profile["security"]["hw_verified"] = True
            return profile
        
        profile = json.loads(json.dumps(self.DEFAULT_PROFILE))
        profile["interaction_stats"]["first_seen"] = datetime.now().isoformat()
        profile["security"] = {"hardware_anchor": hw_id, "hw_verified": True}
        self._save(profile)
        return profile

    def _save(self, profile: Optional[dict] = None):
        p = profile if profile is not None else self.profile
        conn = sqlite3.connect(self.db_path)
        conn.execute("""
            INSERT INTO user_dna (user_id, profile, updated)
            VALUES (?, ?, ?)
            ON CONFLICT(user_id) DO UPDATE SET profile=?, updated=?
        """, (self.user_id, json.dumps(p), datetime.now(), json.dumps(p), datetime.now()))
        conn.commit()
        conn.close()

    def set_name(self, name: str):
        self.profile["identity"]["name"] = name.title()
        self._save()

    def get_name(self) -> Optional[str]:
        return self.profile["identity"]["name"]

    def add_hardware(self, item: str):
        if item not in self.profile["hardware"]["owned"]:
            self.profile["hardware"]["owned"].append(item)
            self._save()

    def add_sensor(self, sensor: str):
        if sensor not in self.profile["hardware"]["sensors"]:
            self.profile["hardware"]["sensors"].append(sensor)
            self._save()

    def add_active_project(self, name: str, description: str, hardware: Optional[List[str]] = None):
        self.profile["projects"]["active"].append({
            "name": name,
            "description": description,
            "hardware": hardware or [],
            "started": datetime.now().isoformat(),
            "status": "in_progress"
        })
        self._save()

    def add_known_concept(self, concept: str, score_delta: int = 20):
        concept = concept.upper()
        current = self.profile["expertise"]["known_concepts"].get(concept, 0)
        self.profile["expertise"]["known_concepts"][concept] = min(100, current + score_delta)
        self._save()

    def add_goal(self, goal: str, term: str = "short_term"):
        if term in self.profile["goals"]:
            self.profile["goals"][term].append(goal)
            self._save()

    def set_preference(self, key: str, value: str):
        if key in self.profile["preferences"]:
            self.profile["preferences"][key] = value
            self._save()

    def record_interaction(self, topic: Optional[str] = None):
        stats = self.profile["interaction_stats"]
        stats["total_conversations"] += 1
        stats["questions_asked"] += 1
        stats["last_seen"] = datetime.now().isoformat()
        if topic:
            stats["favorite_topics"][topic] = stats["favorite_topics"].get(topic, 0) + 1
        self._save()

    def save_dna_fact(self, key: str, value: str):
        """Generalized method to anchor new DNA facts."""
        if "identity_extensions" not in self.profile:
            self.profile["identity_extensions"] = {}
        self.profile["identity_extensions"][key] = value
        self._save()
        self.logger.info(f"DNA Fact Anchored: {key} -> {value[:50]}...")

    def get_dna_context(self) -> str:
        p = self.profile
        lines = ["=== KALI KNOWLEDGE OF USER (DNA EXCERPT) ==="]
        
        name = p["identity"]["name"]
        if name: lines.append(f"NAME: {name}")
        
        domains = p["expertise"]["domains"]
        if domains:
            lines.append(f"EXPERTISE: {', '.join(f'{d} ({l})' for d, l in domains.items())}")
            
        known = p["expertise"].get("known_concepts", {})
        if known:
            keys = list(known.keys())
            lines.append(f"CONCEPTS KNOWN: {', '.join(keys[:10])}")
        
        active = p["projects"]["active"]
        if active:
            proj = active[-1]
            lines.append(f"CURRENT PROJECT: {proj['name']} ({proj['description'][:100]})")
            
        hardware = p["hardware"]["owned"]
        if hardware: lines.append(f"EQUIPMENT: {', '.join(hardware[:6])}")
        
        return "\n".join(lines)
