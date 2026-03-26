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
from .ai_service import AIService
from .explainer import Explainer
from .reflection_engine import ReflectionEngine
from .proactive_research import ProactiveResearchEngine
from .code_executor import CodeExecutor
from .report_generator import ReportGenerator
from .planner import TaskPlanner
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
            
        self.explainer = Explainer(self.ai_service)

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
        self.planner = TaskPlanner(self.ai_service, self.vector_memory)
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
        self.current_phase = 0
        
        # Phase 28: Sovereignty Status
        self.checker = SovereignCheck()
        self.is_sovereign, self.sovereign_msg = self.checker.check_origin()
        
        if not self.is_sovereign:
            self.power_mode = "ECO"
            print(f"[!] WARNING: {self.sovereign_msg}. Entering Restricted Mode.")
            
        # Do not start proactive research immediately in __init__
        # It will be triggered by web_app.py or manually
        self.message_count = 0
        self.conversation_history = []
        self.current_session_id: Optional[str] = None
        
        # Initialize directory logic relative to project root
        self.project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
        user_home = os.path.expanduser("~")
        self.doc_dir = os.path.join(user_home, "Documents", "KALI_RESOURCES")
        if not os.path.exists(self.doc_dir):
            os.makedirs(self.doc_dir)

        self._load_last_session()
        self.logger.info(f"DoubtProcessor initialized on: {os.name} ({self.power_mode})")


        self._ensure_sovereign_hooks()
        self._seed_universal_knowledge()

    def _seed_universal_knowledge(self):
        """Phase 12/21/22: Index spiritual and tactical seeds."""
        try:
            import json
            for file in ["spiritual_archive.json", "tactical_defense.json"]:
                path = os.path.join(self.project_root, "data", file)
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

    def _load_last_session(self):
        """Restore the most recent session state."""
        sessions = self.memory.get_sessions()
        if sessions:
            self.current_session_id = sessions[0]["session_id"]
            self.logger.info(f"KALI Session Restored: {self.current_session_id}")
        else:
            self.current_session_id = str(uuid.uuid4())

    def run_sync_cycle(self):
        """
        Phase 15: The Sync Cycle.
        Reconsolidate state from KALI_MASTER_PLAN.md and MEMORY_ANCHOR.md.
        """
        try:
            self.logger.info("INITIATING SYNC CYCLE...")
            state = self.memory.sync_anchor("MEMORY_ANCHOR.md")
            
            if state:
                self.logger.info(f"Context Restored. Last Action: {state.get('last_action')}")
                
            # Cross-reference with Master Plan
            plan_path = "KALI_MASTER_PLAN.md"
            if os.path.exists(plan_path):
                with open(plan_path, "r", encoding="utf-8") as f:
                    plan_content = f.read()
                
                # Identify current phase
                import re
                phase_match = re.search(r"Current Phase: (\d+)", plan_content)
                if phase_match:
                    self.current_phase = int(phase_match.group(1))
                    self.logger.info(f"Synchronized with Master Plan: Phase {self.current_phase}")
            
            return True
        except Exception as e:
            self.logger.error(f"Sync Cycle Failed: {e}")
            return False

    def process_doubt(self, query: str, context: Optional[DoubtContext] = None) -> Any:
        try:
            # Automatic Sync if state is cold
            if not hasattr(self, 'current_phase') or self.current_phase == 0:
                self.run_sync_cycle()

            self.logger.info(f"KALI Research Loop: {query.splitlines()[0]}...")
            
            # Cache check
            cached = self.vector_memory.get_cached_answer(query)
            if cached:
                self.memory.update_anchor(f"Handled via Cache: {query.splitlines()[0]}")
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
            # 4. Generate structured explanation via Explainer
            user_level = (context.user_level if context else "intermediate")
            response = self.explainer.generate_explanation(
                query, 
                context=full_context, 
                style=user_level
            )
            
            # 5. Persist to History
            self.memory.save_interaction(self.current_session_id, query, response)
            self.vector_memory.cache_answer(query, response)
            
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
                proj_name = f"manifest_{pred}_{str(uuid.uuid4().hex)[0:4]}"
                manifest_res = self.manifestor.manifest_project(proj_name, {"README.md": f"# {proj_name}\nManifested via Atemporal Intent."})
                response = f"{response}\n\n✅ **MANIFESTED**: Project path: {manifest_res.get('path')}"

            # Final Response Assembly
            res = {
                "text": response,
                "can_build": "build" in query.lower() or "manifest" in query.lower(),
                "power_mode": self.power_mode,
                "report_ready": len(response) > 500,
                "msg_id": str(uuid.uuid4()),
                "source": "council"
            }
            
            # Phase 15: Post-Action Anchor Update
            self.memory.update_anchor(f"RESOLVED: {query.splitlines()[0]}")

            return res
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
        
        self.logger.info(f"KALI Project Mentor: Analyzing {idea}")
        # Phase 5 Integration: Execute research mission for costs and sources
        goal = f"Identify materials, exact costs, trusted sources, and purchase links for: {idea}"
        research = self.planner.execute(goal)
        
        return {
            "response": research.get("answer", "I could not finalize the analysis, Sir."),
            "can_build": True,
            "research_steps": research.get("steps", [])
        }

    def process_presentation_mode(self, question: str, context: Optional[dict] = None) -> dict:
        """
        Generates a 3D-enhanced, multi-step explanation.
        """
        self.logger.info(f"Generating 3D Presentation for: {question}")
        
        prompt = f"""
        You are KALI, the Ultimate Fabrication Mentor.
        Create a 3-5 step instructional sequence to answer: "{question}"
        
        Each step MUST be a JSON object with:
        - "text": A clear, professional explanation (strictly no emojis).
        - "visual_code": JavaScript using 'parts' library:
            - parts.addBreadboard(x, y, z)
            - parts.addMicrocontroller(x, y, z)
            - parts.addServo(x, y, z)
            - parts.animateTo(mesh, newPos, duration)
        
        Return ONLY a JSON array of steps.
        """
        
        raw_res = self.ai_service.ask_question(prompt)
        try:
            # Clean up potential markdown formatting from AI
            cleaned = raw_res.strip("```json").strip("```").strip()
            steps = json.loads(cleaned)
            
            # Phase 15: Post-Action Anchor Update
            self.memory.update_anchor(f"3D MISSION: {question[:50]}")
            
            return {"steps": steps}
        except Exception as e:
            self.logger.error(f"Failed to parse 3D steps: {e}")
            return {"steps": [{"text": "Visual decomposition failed, Sir. I will explain in text instead.", "visual_code": ""}]}

    def handle_feedback(self, q, r, c):
        self.vector_memory.remember(f"CORRECTION: {c}", collection_name="knowledge", meta={"is_correction": True})
        return {"success": True}

    def re_tune(self):
        self.logger.info("KALI Evolution: Success-driven re-tuning complete.")

    def perform_mission(self, goal: str) -> dict:
        """KALI autonomously executes a mission via the research engine."""
        self.logger.info(f"KALI Mission initiated: {goal}")
        report = self.proactive_research.research_topic(goal)
        return {"success": True, "report": report}
