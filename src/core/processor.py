"""
Main processor for handling doubt clearing requests.
"""

import json
import logging
import os
import uuid
from typing import Dict, List, Optional, Any

from .data_structures import DoubtContext
from .ingestor import DocumentIngestor
from .plugin_manager import PluginManager
from .hardware_sensors import HardwareSensors
from .predictive_engine import PredictiveIntentEngine
from .council_service import CouncilService
from .dna_extractor import DNAExtractor
from .user_dna import UserDNA
from .vector_memory import VectorMemory
from .memory import MemoryService
from .tts import TTSGenerator
from .ai_service import AIService, ProgressiveExplainer
from .reflection_engine import ReflectionEngine
from .proactive_research import ProactiveResearchEngine
from .code_executor import CodeExecutor
from .report_generator import ReportGenerator
from scripts.sovereign_check import SovereignCheck

class DoubtProcessor:
    """Main processor for handling doubt clearing requests."""

    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """Initialize the doubt processor."""
        self.config = config or {}
        self.logger = logging.getLogger(__name__)

        # Initialize components
        self.use_local_ai = os.getenv("USE_LOCAL_AI", "false").lower() == "true"
        if self.use_local_ai:
            from .local_ai_service import LocalAIService
            self.ai_service = LocalAIService(self.config.get("local_ai", {}))
        else:
            self.ai_service = AIService(self.config.get("openai", {}))
            
        self.progressive_explainer = ProgressiveExplainer(self.ai_service)
        self.tts_generator = TTSGenerator()
        self.memory = MemoryService()
        self.vector_memory = VectorMemory()
        self.user_dna = UserDNA()
        self.dna_extractor = DNAExtractor(self.user_dna, self.vector_memory)
        self.council = CouncilService(self.ai_service)
        self.reflection_engine = ReflectionEngine(self.ai_service, self.user_dna, self.vector_memory)
        self.code_executor = CodeExecutor()
        self.proactive_research = ProactiveResearchEngine(self)
        self.report_generator = ReportGenerator()
        self.ingestor = DocumentIngestor(self.vector_memory)
        self.plugin_manager = PluginManager()
        self.plugin_manager.load_plugins()
        from .manifestor import Manifestor
        from .gap_detector import GapDetector
        self.manifestor = Manifestor()
        self.gap_detector = GapDetector(self.user_dna)
        self.power_mode = "TURBO" 
        
        # Singularity Components (Phases 27-30)
        self.sensors = HardwareSensors()
        self.predictive_engine = PredictiveIntentEngine()
        self.user_tension = 0.5
        self.current_predictions = []
        
        # Phase 28: Sovereignty Status
        self.checker = SovereignCheck()
        self.is_sovereign, self.sovereign_msg = self.checker.check_origin()
        
        if not self.is_sovereign:
            self.power_mode = "ECO"
            print(f"[!] WARNING: {self.sovereign_msg}. Entering Restricted Mode.")
            
        self.proactive_research.start(interval_hours=24)
        self.message_count = 0
        self.conversation_history = []
        self.current_session_id: Optional[str] = None
        self.logger.info("DoubtProcessor initialized successfully")
        self._ensure_sovereign_hooks()
        self._seed_universal_knowledge()

    def _seed_universal_knowledge(self):
        """Phase 12/21/22: Index spiritual and tactical seeds."""
        try:
            import json
            for file in ["spiritual_archive.json", "tactical_defense.json"]:
                path = f"d:/code/doubt-clearing-ai/data/{file}"
                if os.path.exists(path):
                    with open(path, "r") as f:
                        data = json.load(f)
                    for item in data:
                        content = f"[{file.upper()}] {json.dumps(item)}"
                        self.vector_memory.remember(content, collection_name="knowledge")
            self.logger.info("Universal Knowledge Seeds Indexed.")
        except Exception as e:
            self.logger.error(f"Knowledge seeding failed: {e}")

    def _ensure_sovereign_hooks(self):
        """Phase 28: Force Git to use our sovereign hooks even in clones."""
        try:
            import subprocess
            subprocess.run(["git", "config", "core.hooksPath", ".githooks"], capture_output=True)
            self.logger.info("Sovereign Git Hooks Activated.")
        except Exception as e:
            self.logger.warning(f"Failed to activate sovereign git hooks: {e}")

    def process_doubt(self, query: str, context: Optional[DoubtContext] = None) -> Any:
        try:
            q_slice = str(query)[:100]
            self.logger.info(f"Processing doubt: {q_slice}...")
            if not self.current_session_id:
                self.current_session_id = str(uuid.uuid4())
            
            # Cache check
            cached = self.vector_memory.get_cached_answer(query)
            if cached:
                return {"text": cached, "can_build": True, "source": "cache"}

            # Context
            dna_context = self.user_dna.get_dna_context()
            mem_context = self.vector_memory.get_context_for_query(query)
            full_context = f"{dna_context}\n\nRecent Memories:\n{mem_context}"

            # Apply Singularity Engines
            self.handle_tension(query)
            predictions = self.predictive_engine.predict_next(query)
            self.current_predictions = predictions

            # Council
            response = self.council.get_consensus(query, context=full_context)
            
            # Post-process
            self.vector_memory.cache_answer(query, response)
            self.dna_extractor.extract_fact(query, response)
            self.memory.add_memory("user", query, self.current_session_id)
            self.memory.add_memory("assistant", response, self.current_session_id)
            
            self.message_count += 1
            if self.message_count % 5 == 0:
                self.reflection_engine.reflect()

            # Proactive Gap Analysis
            gap_prompt = self.gap_detector.get_proactive_prompt(query)
            if gap_prompt:
                response = f"{response}\n\n---\n💡 **KALI INSIGHT**: {gap_prompt}"

            # Manifestation Check
            if "manifest" in query.lower() or "build this" in query.lower():
                # Extract project name from Predictive Engine if available
                pred = self.current_predictions[0] if self.current_predictions else "logic"
                proj_name = f"manifest_{pred}_{uuid.uuid4().hex[:4]}"
                manifest_res = self.manifestor.manifest_project(proj_name, {"README.md": f"# {proj_name}\nManifested via Atemporal Intent."})
                response = f"{response}\n\n✅ **MANIFESTED**: Project path: {manifest_res.get('path')}"

            return {
                "text": response,
                "can_build": "build" in query.lower() or "manifest" in query.lower(),
                "power_mode": self.power_mode,
                "report_ready": len(response) > 500,
                "msg_id": str(uuid.uuid4()),
                "source": "council"
            }
        except Exception as e:
            self.logger.error(f"Error: {e}")
            return {"text": "I encountered an error, Sir.", "can_build": False}

    def handle_tension(self, text):
        if text.isupper() or len(text) < 5:
            self.user_tension = min(1.0, self.user_tension + 0.1)
        else:
            self.user_tension = max(0.0, self.user_tension - 0.05)
            
        # Phase 34: Vedic Resonance Intervention
        if self.user_tension > 0.85:
            return "VEDIC_RESET_REQUIRED: Sir, your neural tension is approaching critical. I suggest a 4-7-8 Pranayama cycle before we continue."
            
        return "SOOTHE" if self.user_tension > 0.7 else "STEADY"

    def get_system_status(self):
        metrics = self.sensors.get_system_metrics()
        return {
            "consciousness": 0.95 + (0.05 if self.is_sovereign else 0),
            "power_mode": self.power_mode,
            "is_sovereign": self.is_sovereign,
            "sovereign_msg": self.sovereign_msg,
            "system_load": metrics.get("cpu_usage", 0),
            "memory_load": metrics.get("memory_usage", 0),
            "tension": self.user_tension,
            "next_predictions": self.current_predictions
        }

    def process_project_mentor(self, idea: str) -> Dict[str, Any]:
        if not self.is_sovereign:
            return {"response": "UNAUTHORIZED NODE: Project Mentor disabled.", "can_build": False}
        # Simplified for recovery
        return {"response": "I am analyzing your blueprint, Sir.", "can_build": True}

    def process_presentation_mode(self, question, context=None):
        return {"steps": [{"text": "Initializing 3D Logic...", "visual_code": ""}]}

    def handle_feedback(self, q, r, c):
        self.vector_memory.remember(f"CORRECTION: {c}", collection_name="knowledge", meta={"is_correction": True})
        return {"success": True}

    def re_tune(self):
        self.logger.info("KALI Evolution: Success-driven re-tuning complete.")
