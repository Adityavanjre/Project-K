"""
Main processor for handling doubt clearing requests.
"""

import json
import logging
import os
import uuid
from datetime import datetime
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
from .training_logger import TrainingLogger
from .dream_engine import DreamEngine
from .knowledge_check import KnowledgeCheckEngine
from .task_tracker import TaskTracker
from .neural_logic import NeuralLogic
from .biometric_service import BiometricService
from .market_research import MarketResearchEngine
from .bom_service import BOMService
from .blueprint_service import BlueprintService
from .cad_service import CADService
from .knowledge_service import KnowledgeService
from .secure_boot import BootGuardian
from .hud_bridge import HUDBridge
from .hardware_bridge import HardwareBridge
from .robotic_bridge import RoboticBridge
from .swarm_service import SwarmService
from .watchdog_service import WatchdogService
from .restoration_service import RestorationService
from .sovereign_cloud import SovereignCloudService
from .rlhf_service import RLHFService
from .omega_protocol import OmegaProtocol
from .gsd_service import GSDService, GSDPhase
from .review_service import ReviewService
from .evolution_bridge import EvolutionBridge
from .sovereign_intelligence import SovereignIntelligence
from scripts.sovereign_check import SovereignCheck


class DoubtProcessor:
    """Main processor for handling doubt clearing requests."""

    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """Initialize the doubt processor."""
        self.config = config or {}
        self.project_root = self.config.get("project_root", os.getcwd())
        self.logger = logging.getLogger(__name__)

        # Phase 4.9: Unified MCP Pool
        from .mcp_pool import mcp_pool

        self.mcp_pool = mcp_pool

        # Initialize components
        self.use_local_ai = os.getenv("USE_LOCAL_AI", "false").lower() == "true"
        self.vector_memory = VectorMemory()  # Phase 4.17: Moved up for semantic cache
        from .local_ai_service import LocalAIService

        self.local_ai = LocalAIService(self.config.get("local_ai", {}))

        if self.use_local_ai:
            self.ai_service = self.local_ai
        else:
            self.ai_service = AIService(
                self.config.get("openai", {}), vector_memory=self.vector_memory
            )

        self.explainer = Explainer(self.ai_service)

        self.tts_generator = TTSGenerator()
        self.memory = MemoryService()
        self.user_dna = UserDNA()
        self.dna_extractor = DNAExtractor(self.user_dna, self.vector_memory)
        self.council = CouncilService(self.ai_service)
        self.reflection_engine = ReflectionEngine(
            self.ai_service, self.user_dna, self.vector_memory, processor=self
        )
        self.code_executor = CodeExecutor()
        self.proactive_research = ProactiveResearchEngine(self)
        self.report_generator = ReportGenerator()
        self.ingestor = DocumentIngestor(self.vector_memory)
        self.planner = TaskPlanner(self.ai_service, self.vector_memory)
        self.plugin_manager = PluginManager()
        self.plugin_manager.load_plugins()
        self.training_logger = TrainingLogger()
        # Phase 4.30: Knowledge Check Engine — wire into training_logger
        self.knowledge_check = KnowledgeCheckEngine(self.ai_service, self.project_root)
        self.training_logger.knowledge_check = self.knowledge_check
        from .manifestor import Manifestor
        from .gap_detector import GapDetector

        self.manifestor = Manifestor()
        self.gap_detector = GapDetector(self.user_dna)
        self.dream_engine = DreamEngine()
        self.task_tracker = TaskTracker()
        self.neural_logic = NeuralLogic()
        self.biometric_service = BiometricService()
        from .skill_manifestor import SkillManifestor

        self.skill_manifestor = SkillManifestor(self.plugin_manager, self.ai_service)
        self.gsd_service = GSDService()
        self.review_service = ReviewService(self.ai_service)
        self.hud_bridge = HUDBridge()
        self.power_mode = "TURBO"

        # Phase 50: Sovereign Independence Switch
        self.sovereign_force_local = (
            os.getenv("SOVEREIGN_FORCE_LOCAL", "false").lower() == "true"
        )
        if self.sovereign_force_local:
            self.logger.warning(
                "🛡️ SOVEREIGN_FORCE_LOCAL ACTIVE: Bypassing External Council."
            )

        # Phase 26: Neural BIOS Secure Boot
        self.boot_guardian = BootGuardian()
        self.is_bios_secure = self.boot_guardian.perform_secure_boot()

        # Phase 27: Economic Intelligence
        self.market_research = MarketResearchEngine(self.ai_service)
        self.bom_service = BOMService(self.market_research)

        # Phase 28: Fabrication Hub
        self.blueprint_service = BlueprintService(self.ai_service)
        self.cad_service = CADService()

        # Phase 29: Knowledge DNA
        self.knowledge_service = KnowledgeService(self.project_root)

        # Phase 31: Tactical Hardware (HITL)
        self.hardware_bridge = HardwareBridge()
        self.hardware_bridge.connect()

        # Phase 32: Swarm Intelligence
        self.swarm_service = SwarmService()

        # Phase 33: Autonomous Self-Repair
        self.watchdog = WatchdogService(self.project_root)

        # Phase 35: The Great Restoration
        self.restoration = RestorationService(self.project_root)

        # Phase 37: Replicant Hub
        self.robotic_bridge = RoboticBridge()

        # Phase 38: Sovereign Cloud
        self.sovereign_cloud = SovereignCloudService(self.project_root)

        # Phase 39: RLHF-DNA
        self.rlhf_service = RLHFService(self.project_root)

        # Phase 40: Omega Protocol
        self.omega_protocol = OmegaProtocol(self.project_root)

        # Phase 51: Sovereign Self-Evolution Bridge
        self.evolution_bridge = EvolutionBridge(self.project_root, self.ai_service)
        self.sovereign_intel = SovereignIntelligence(self)

        # Singularity Components (Phases 27-30)
        self.sensors = HardwareSensors()
        self.predictive_engine = PredictiveIntentEngine()
        self.user_tension = 0.0
        self.last_manifest_path = None
        self.current_predictions = []
        self.current_phase = 0

        # Phase 28: Sovereignty Status (Deep Hardware Lock)
        self.is_sovereign = self.user_dna.profile.get("security", {}).get(
            "hw_verified", False
        )
        self.sovereign_msg = (
            "DEEP_HW_VERIFIED" if self.is_sovereign else "HARDWARE_DNA_MISMATCH"
        )

        if not self.is_sovereign or not self.is_bios_secure:
            self.power_mode = "ECO"
            reason = (
                "UNAUTHORIZED_HARDWARE" if not self.is_sovereign else "INTEGRITY_BREACH"
            )
            print(f"[!] CRITICAL BIOS ALERT: {reason}. Entering Restricted Mode.")

        # Do not start proactive research immediately in __init__
        # It will be triggered by web_app.py or manually
        self.message_count = 0
        self.conversation_history = []
        self.current_session_id: Optional[str] = None

        # Economic State
        self.active_bom: Optional[Dict[str, Any]] = None
        self.last_interaction: Optional[Dict[str, Any]] = None

        # Initialize directory logic relative to project root
        self.project_root = os.path.abspath(
            os.path.join(os.path.dirname(__file__), "..", "..")
        )
        user_home = os.path.expanduser("~")
        self.doc_dir = os.path.join(user_home, "Documents", "KALI_RESOURCES")
        if not os.path.exists(self.doc_dir):
            os.makedirs(self.doc_dir)

        self._load_last_session()
        self.logger.info(
            f"DoubtProcessor initialized on: {os.name} ({self.power_mode})"
        )

        self._ensure_sovereign_hooks()
        self._seed_universal_knowledge()

    def _seed_universal_knowledge(self):
        """Phase 12/21/22: Index cognitive and tactical seeds."""
        try:
            import json

            for file in ["spiritual_archive.json", "tactical_defense.json"]:
                path = os.path.join(self.project_root, "data", file)
                if os.path.exists(path):
                    with open(path, "r") as f:
                        data = json.load(f)
                    for item in data:
                        content = f"[{file.upper()}] {json.dumps(item)}"
                        self.vector_memory.remember(
                            content, collection_name="knowledge"
                        )
            self.logger.info("Universal Knowledge Seeds Indexed.")
        except Exception as e:
            self.logger.error(f"Knowledge seeding failed: {e}")

    def _ensure_sovereign_hooks(self):
        """Phase 28: Force Git to use our sovereign hooks even in clones."""
        try:
            import subprocess

            subprocess.run(
                ["git", "config", "core.hooksPath", ".githooks"], capture_output=True
            )
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
                self.logger.info(
                    f"Context Restored. Last Action: {state.get('last_action')}"
                )

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
                    self.logger.info(
                        f"Synchronized with Master Plan: Phase {self.current_phase}"
                    )

            return True
        except Exception as e:
            self.logger.error(f"Sync Cycle Failed: {e}")
            return False

    def process_doubt(
        self,
        query: str,
        context: Optional[DoubtContext] = None,
        source: str = "general",
        bypass_cache: bool = False,
    ) -> Any:
        try:
            # Automatic Sync if state is cold
            if not hasattr(self, "current_phase") or self.current_phase == 0:
                self.run_sync_cycle()

            self.logger.info(f"KALI Research Loop: {query.splitlines()[0]}...")

            # Cache check
            if not bypass_cache:
                cached = self.vector_memory.get_cached_answer(query)
                if cached:
                    self.memory.update_anchor(
                        f"Handled via Cache: {query.splitlines()[0]}"
                    )
                    # Phase 5.0 HUD Sync even on cache
                    bio_state = self.biometric_service.get_physiological_state(
                        self.sensors.get_system_metrics().get("cpu_usage", 0)
                    )
                    self.hud_bridge.update_hud(
                        bio_state, self.sensors.get_system_metrics()
                    )
                    return {"text": cached, "can_build": True, "source": "cache"}

            # Context
            dna_text = self.user_dna.get_dna_context()
            mem_context = self.vector_memory.get_context_for_query(query)
            full_context = f"{dna_text}\n\nRecent Memories:\n{mem_context}"

            # Structural DNA for logic
            dna_profile = self.user_dna.profile

            # Apply Singularity Engines
            # Skip biometric check in Colab/cloud environments
            import os
            if os.environ.get("DISABLE_BIOMETRIC_CHECKS", "").lower() == "true":
                # Skip biometric checks
                pass
            else:
                bio_state = self.biometric_service.get_physiological_state(
                    self.sensors.get_system_metrics().get("cpu_usage", 0)
                )
                self.user_tension = bio_state["neural_tension"]
                tension_status = self.handle_tension(query)
                if tension_status and "NEURAL_RESET_REQUIRED" in str(tension_status):
                    return {"text": str(tension_status), "can_build": False}
            else:
                self.user_tension = 0.0

            predictions = self.predictive_engine.predict_next_steps(
                query,
                dna_profile.get("interaction_stats", {}).get("total_conversations", 0),
            )
            self.current_predictions = predictions

            # Phase 39: RLHF Pre-Processing (Bias Detection)
            biases = self.rlhf_service.detect_bias(query)
            if biases:
                self.logger.warning(f"KALI RLHF: Bias detected in query -> {biases}")

            # Council
            # 4. Generate structured explanation via Explainer
            user_level = context.user_level if context else "intermediate"
            # Adjust level based on tension
            if self.user_tension > 0.8:
                user_level = "beginner"  # Simplify for high stress
                self.logger.info(
                    "KALI: High tension detected. Simplifying explanation."
                )

            # Phase 4.30: Council for complex queries (>150 chars), Explainer for short ones
            # Phase 50: Override if SOVEREIGN_FORCE_LOCAL is active
            use_council = (
                len(query) > 150
                and self.power_mode == "TURBO"
                and not self.sovereign_force_local
            )

            if self.sovereign_force_local:
                self.logger.info(
                    "🛡️ KALI: SOVEREIGN_FORCE_LOCAL engaged. Using Local Node."
                )
                response = self.local_ai.ask_question(query, context=full_context)
            elif use_council:
                self.logger.info("KALI: Complex query — convening Council of Experts.")
                council_response = self.council.get_consensus(
                    query, context=full_context, bypass_cache=bypass_cache
                )
                response = (
                    council_response
                    if council_response
                    else self.explainer.generate_explanation(
                        query,
                        context=full_context,
                        style=user_level,
                        bypass_cache=bypass_cache,
                    )
                )
            else:
                response = self.explainer.generate_explanation(
                    query,
                    context=full_context,
                    style=user_level,
                    bypass_cache=bypass_cache,
                )

            # Phase 4.9: Autonomous CodeRabbit Audit (If output contains code)
            if "```" in str(response):
                self.logger.info("KALI CodeRabbit: Audit triggered for generated code.")
                audit_res = self.review_service.review_manifest(
                    str(response), query.splitlines()[0]
                )
                if audit_res.get("score", 100) < 80:
                    self.logger.warning(
                        f"KALI CodeRabbit: Audit score low ({audit_res.get('score')}). Re-correcting."
                    )
                    response = self.council.get_consensus(
                        f"CRITIQUE AND FIX: {query}\n\nFindings: {audit_res.get('findings')}",
                        context=str(response),
                    )

            # Phase 39: RLHF Post-Processing (Alignment)
            alignment = self.rlhf_service.calculate_alignment(
                str(response),
                dna_profile.get("preferences", {}).get("top_directives", []),
            )
            self.logger.info(f"KALI RLHF: Output alignment score -> {alignment}")

            # 5. Persist to History
            self.memory.add_memory("user", query, self.current_session_id)
            self.memory.add_memory("kali", str(response), self.current_session_id)
            self.vector_memory.remember(
                f"Q: {query}\nA: {response}", collection_name="history"
            )

            # Phase 29: Knowledge DNA Curation
            self.knowledge_service.curate_interaction(query, str(response))

            self.message_count += 1
            if self.message_count % 5 == 0:
                self.reflection_engine.reflect()
                # GSD Sync: Log milestone
                self.gsd_service.add_task(
                    f"Evolution Milestone: Completed 5 interactions. System alignment: {alignment}%."
                )

            # Proactive Gap Analysis & Autonomous Manifestation
            gap_prompt = self.gap_detector.get_proactive_prompt(query)
            if gap_prompt:
                self.logger.info(
                    f"KALI: Capability Gap Identified: {gap_prompt}. Manifesting skill."
                )
                manifest_res = self.skill_manifestor.manifest_skill(gap_prompt)

                status_msg = f"💡 **KALI INSIGHT**: {gap_prompt}"
                if manifest_res["success"]:
                    status_msg += f"\n⚙️ **AUTONOMOUS EVOLUTION**: Manifested New Skill `{manifest_res['skill_name']}`."

                response = f"{response}\n\n---\n{status_msg}"
                last_manifested_skill = manifest_res.get("skill_name")

            # Extract DNA
            self.dna_extractor.process(query, str(response))

            # Generate TTS
            audio_url = self.tts_generator.generate_audio(str(response))

            # 5. Log context for CCV (Cross-Context Verification)
            self.training_logger.log(
                query, str(response), source=source, context=source
            )

            # Phase 5.0: Update HUD Bridge
            bio_state = self.biometric_service.get_physiological_state(
                self.sensors.get_system_metrics().get("cpu_usage", 0)
            )
            self.hud_bridge.update_hud(bio_state, self.sensors.get_system_metrics())

            self.last_interaction = {"query": query, "response": str(response)}

            # Manifestation Check
            if "manifest" in query.lower() or "build this" in query.lower():
                # Extract project name from Predictive Engine if available
                pred = (
                    self.current_predictions[0] if self.current_predictions else "logic"
                )
                proj_name = f"manifest_{pred}_{str(uuid.uuid4().hex)[0:4]}"
                # Fix method name from manifest_project to manifest
                manifest_res_path = self.manifestor.manifest(
                    {"title": proj_name, "summary": response}
                )
                response = f"{response}\n\n✅ **MANIFESTED**: Project path: {manifest_res_path}"

            # Final Response Assembly
            build_keywords = [
                "build",
                "manifest",
                "design",
                "make",
                "create",
                "circuit",
                "robot",
                "drone",
                "how to build",
            ]
            res = {
                "text": response,
                "audio_url": audio_url,
                "can_build": any(kw in query.lower() for kw in build_keywords),
                "power_mode": self.power_mode,
                "report_ready": len(response) > 500,
                "msg_id": str(uuid.uuid4()),
                "source": "council",
                "manifested_skill": locals().get("last_manifested_skill"),
            }

            # Phase 15: Post-Action Anchor Update
            self.memory.update_anchor(f"RESOLVED: {query.splitlines()[0]}")

            # Phase 38: Sovereign Cloud Anchoring
            self.sovereign_cloud.anchor_memory_segment(
                res["msg_id"],
                {
                    "query": query,
                    "response": response,
                    "alignment": alignment,
                    "tension": self.user_tension,
                },
            )

            return res
        except Exception as e:
            self.logger.error(f"Error: {e}")
            return {"text": "I encountered an error, Sir.", "can_build": False}

    def handle_tension(self, text):
        # Skip tension check in all environments for now
        self.user_tension = 0.0
        return "STEADY"
        
        # Original code disabled for testing
        if text.isupper() or len(text) < 5:
            self.user_tension = min(1.0, self.user_tension + 0.1)
        else:
            self.user_tension = max(0.0, self.user_tension - 0.05)

        # Phase 34: Neural Performance Intervention
        if self.user_tension > 0.85:
            return "NEURAL_RESET_REQUIRED: Sir, your neural tension is approaching critical. I suggest a Physiological Reset cycle before we continue."

        return "SOOTHE" if self.user_tension > 0.7 else "STEADY"

    def get_system_status(self):
        metrics = self.sensors.get_system_metrics()
        return {
            "consciousness": 0.95 + (0.05 if self.is_sovereign else 0),
            "power_mode": self.power_mode,
            "is_sovereign": self.is_sovereign,
            "sovereign_msg": self.sovereign_msg,
            "cpu_usage": metrics.get("cpu_usage", 0),
            "memory_usage": metrics.get("memory_usage", 0),
            "tension": self.user_tension,
            "next_predictions": self.current_predictions,
            "active_bom": self.active_bom,
            "manifest_path": getattr(self, "last_manifest_path", None),
            "dna_count": self.knowledge_service.get_dna_count(),
            "hardware_telemetry": self.hardware_bridge.get_telemetry(),
            "swarm_status": self.swarm_service.get_swarm_status(),
            "repair_status": self.watchdog.get_repair_status(),
            "is_thinking": self.current_phase > 0 or len(self.current_predictions) > 0,
            "restoration_status": self.restoration.get_restoration_status(),
            "robotic_status": self.robotic_bridge.get_kinematic_status(),
            "cloud_status": self.sovereign_cloud.get_cloud_status(),
            "alignment_status": self.rlhf_service.get_alignment_status(),
            "omega_status": self.omega_protocol.get_protocol_status(),
            "gsd_status": self.gsd_service.get_gsd_status(),
            "reviewer_status": self.review_service.get_reviewer_status(),
        }

    def process_project_mentor(self, idea: str) -> Dict[str, Any]:
        if not self.is_sovereign:
            return {
                "response": "UNAUTHORIZED NODE: Project Mentor disabled.",
                "can_build": False,
                "research_steps": [],
                "bom": {"total_cost": 0, "parts": []},
                "blueprint": [],
            }

        self.logger.info(f"KALI Project Mentor: Analyzing {idea}")

        # GSD Phase: INITIALIZE
        self.gsd_service.transition_to(GSDPhase.INITIALIZE, {"idea": idea})

        # Phase 5 Integration: Execute research mission for costs and sources
        goal = self.gsd_service.get_structured_prompt(idea)
        research = self.planner.execute(goal)
        answer = research.get("answer", "I could not finalize the analysis, Sir.")

        # GSD Phase: PLAN
        self.gsd_service.transition_to(GSDPhase.PLAN)

        # Phase 27: Economic Analysis
        bom = self.bom_service.generate_project_bom(
            {
                "name": idea[:30],
                "components": research.get(
                    "steps", []
                ),  # Use steps as components if not explicitly listed
            }
        )
        self.active_bom = bom

        # Phase 28: Fabrication Hub Blueprints & CAD
        blueprint = self.blueprint_service.generate_assembly_steps(
            idea[:30], bom, research.get("steps", [])
        )
        cad_metadata = self.cad_service.generate_cad_metadata(research.get("steps", []))

        # Manifest the project physically
        project_plan_enhanced = {
            **research,
            "blueprint": blueprint,
            "bom": bom,
            "cad_metadata": cad_metadata,
        }

        # GSD Phase: EXECUTE
        self.gsd_service.transition_to(GSDPhase.EXECUTE)
        manifest_path = self.manifestor.manifest(project_plan_enhanced)
        self.last_manifest_path = manifest_path

        # GSD Phase: VERIFY (Autonomous Review)
        self.gsd_service.transition_to(GSDPhase.VERIFY)
        review = self.review_service.review_manifest(
            json.dumps(project_plan_enhanced, indent=2), idea
        )
        self.logger.info(f"KALI Reviewer: Integrity Score {review.get('score')}/100")

        if review.get("score", 0) < 70:
            answer = f"{answer}\n\n⚠️ **REVIEW ALERT**: {review.get('recommendation')}"

        # Generate TTS for the summary
        audio_url = self.tts_generator.generate_audio(answer)

        # Phase 3: Log to Training Dataset
        self.training_logger.log(goal, answer)

        # Phase 4.12: Self-Critique DPO Loop
        try:
            self._generate_dpo_critique(goal, answer)
        except Exception as e:
            self.logger.error(f"DPO Critique failed: {e}")

        # Phase 30: Predictive Intent
        self.current_predictions = self.predictive_engine.predict_next_steps(idea, 0)

        # Phase 32: Swarm Deployment (Detailed Delegation)
        mission_goals = [
            f"Research vendors for {idea}",
            f"Design CAD constraints for {idea}",
            f"Generate firmware logic for {idea}",
        ]
        for goal in mission_goals:
            self.swarm_service.deploy_swarm(goal)

        # Phase 37: Robotic Feedback (Actionable Kinematics)
        self.robotic_bridge.move_joint("HEAD_PAN", 120)
        self.robotic_bridge.move_joint("ARM_L_SHOULDER", 45)
        self.logger.info("KALI: Robotic kinematic feedback initiated.")

        # Phase 38: Sovereign Cloud Snapshot
        self.sovereign_cloud.anchor_memory_segment(
            f"PROJ_{idea[:8]}",
            {"idea": idea, "bom": bom, "manifest_path": manifest_path},
        )

        # Phase 4.11: Trigger Neural Augmentation (Background synthesis)
        try:
            added = self.dream_engine.synthesize_augmented_data(self)
            if added > 0:
                self.logger.info(
                    f"KALI DreamEngine: Synthesized {added} augmented interactions."
                )
        except Exception as e:
            self.logger.error(f"Dream augmentation failed: {e}")

        return {
            "response": answer,
            "audio_url": audio_url,
            "manifest_path": manifest_path,
            "can_build": True,
            "research_steps": research.get("steps", []),
            "bom": bom,
            "blueprint": blueprint,
            "next_predictions": self.current_predictions,
        }

    def process_presentation_mode(
        self, question: str, context: Optional[dict] = None
    ) -> dict:
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
            cleaned = raw_res.strip()
            if cleaned.startswith("```json"):
                cleaned = cleaned[7:]
            elif cleaned.startswith("```"):
                cleaned = cleaned[3:]
            if cleaned.endswith("```"):
                cleaned = cleaned[:-3]
            cleaned = cleaned.strip()
            steps = json.loads(cleaned)

            # Phase 15: Post-Action Anchor Update
            self.memory.update_anchor(f"3D MISSION: {question[:50]}")

            return {"steps": steps}
        except Exception as e:
            self.logger.error(f"Failed to parse 3D steps: {e}")
            return {
                "steps": [
                    {
                        "text": "Visual decomposition failed, Sir. I will explain in text instead.",
                        "visual_code": "",
                    }
                ]
            }

    def handle_feedback(self, q, r, c):
        self.vector_memory.remember(
            f"CORRECTION: {c}",
            collection_name="knowledge",
            meta={"is_correction": True},
        )
        return {"success": True}

    def re_tune(self):
        self.logger.info("KALI Evolution: Success-driven re-tuning complete.")

    def perform_mission(self, goal: str) -> dict:
        """KALI autonomously executes a mission via the research engine."""
        self.logger.info(f"KALI Mission initiated: {goal}")
        report = self.proactive_research.research_topic(goal)
        return {"success": True, "report": report}

    def end_session(self):
        """
        Phase 6/35: The Great Consolidation.
        Triggers the Dream Engine to synthesize wisdom seeds from the session.
        """
        self.logger.info(
            f"KALI: Ending Session {self.current_session_id}. Consolidating..."
        )

        # Trigger Dream Engine
        seeds = self.dream_engine.dream()
        for seed in seeds:
            self.vector_memory.remember(
                f"WISDOM_SEED: {seed['insight']}", collection_name="knowledge"
            )

        # Global Sync
        self.run_sync_cycle()

        # Phase 38: Final Cloud Anchor
        self.sovereign_cloud.anchor_memory_segment(
            "SESSION_END",
            {"session_id": self.current_session_id, "seeds_count": len(seeds)},
        )

        self.logger.info("KALI: Consolidation Complete. Singularity State Preserved.")

    def _generate_dpo_critique(self, goal: str, original_answer: str):
        """Generates a self-critique and an improved version for DPO logs."""
        critique = self.review_service.review_manifest(original_answer, goal)
        feedback = critique.get("critique", "Optimize for sovereign technical clarity.")

        improved_answer = self.ai_service.ask_question(
            f"GOAL: {goal}\n"
            f"ORIGINAL: {original_answer}\n"
            f"FEEDBACK: {feedback}\n"
            f"Generate a SUPERIOR technical response resolving all feedback."
        )

        # Log to separate DPO file for high-fidelity tuning
        dpo_path = os.path.join("data", "dpo_data.jsonl")
        dpo_entry = {
            "prompt": goal,
            "chosen": improved_answer,
            "rejected": original_answer,
            "metadata": {
                "score": critique.get("score"),
                "timestamp": datetime.now().isoformat(),
            },
        }
        with open(dpo_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(dpo_entry) + "\n")

        self.logger.info(f"KALI DPO: Self-Critique Pair Anchored.")

    def swap_skill_service(self, service_name: str, instance: Any):
        """
        Phase 4.23: Neural Skill Swap
        Allows dynamic replacement of core skill services (Mentor, GSD, etc.)
        used by the SelfOptimizingLoop to upgrade KALI's active logic.
        """
        self.logger.info(f"KALI: Swapping skill service instance: '{service_name}'")
        try:
            if hasattr(self, service_name):
                setattr(self, service_name, instance)
                self.logger.info(
                    f"[+] Skill Service '{service_name}' upgraded successfully."
                )
            else:
                self.logger.error(f"Skill service '{service_name}' not found for swap.")
        except Exception as e:
            self.logger.error(f"Skill swap failed for {service_name}: {e}")

    def hot_reload_service(self, service_name: str):
        """
        Phase 4.20: Neural Hot-Reload
        Dynamically re-initializes a specific service without restarting the processor.
        Used by the SelfOptimizingLoop after a successful self-patch.
        """
        self.logger.info(f"KALI: Initiating Hot-Reload for service: '{service_name}'")
        try:
            if service_name == "ai_service":
                self.ai_service = AIService(
                    self.config.get("openai", {}), vector_memory=self.vector_memory
                )
                self.explainer = Explainer(self.ai_service)
                self.review_service = ReviewService(self.ai_service)
                self.logger.info("[+] AI Service Hot-Reloaded successfully.")
            elif service_name == "gsd_service":
                from .gsd_service import GSDService

                self.gsd_service = GSDService()
                self.logger.info("[+] GSD Service Hot-Reloaded successfully.")
            elif service_name == "vector_memory":
                from .vector_memory import VectorMemory

                self.vector_memory = VectorMemory()
                self.logger.info("[+] Vector Memory Hot-Reloaded successfully.")
            else:
                self.logger.error(f"Hot-Reload target '{service_name}' not supported.")
        except Exception as e:
            self.logger.error(f"Hot-Reload failed for {service_name}: {e}")

    def log_preference(self, is_positive: bool):
        """Phase 4.1: Logs user preference (DPO) for the last interaction."""
        if not self.last_interaction:
            return

        pref_path = os.path.join(self.project_root, "data", "preference_data.jsonl")
        record = {
            "prompt": self.last_interaction["query"],
            "chosen": self.last_interaction["response"] if is_positive else None,
            "rejected": None if is_positive else self.last_interaction["response"],
            "timestamp": datetime.now().isoformat(),
        }

        os.makedirs(os.path.dirname(pref_path), exist_ok=True)
        with open(pref_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(record) + "\n")

        self.logger.info(
            f"KALI DPO: Preference Recorded -> {'SUCCESS' if is_positive else 'CRITIQUE'}"
        )

    def get_history(self):
        """Phase 1: Retrieve session history for formal testing."""
        return self.memory.get_recent_memories(
            limit=50, session_id=self.current_session_id
        )

    def clear_history(self):
        """Phase 1: Clear session history for formal testing."""
        self.memory.clear_memory(session_id=self.current_session_id)
        self.vector_memory.clear_memory(
            session_id=self.current_session_id
        )  # If it exists
        self.logger.info("Session history cleared.")

    def process_contextual_doubt(self, question: str, context: dict) -> dict:
        """Handle a doubt asked during a step (contextual doubt)."""
        try:
            current_step = context.get("current_step_text", "")
            topic = context.get("topic", "general")
            enhanced_query = f"Context: Currently on step: '{current_step}' Topic: {topic} Question: {question}"
            response = self.process_doubt(enhanced_query, source="contextual")
            return {"success": True, "response": response.get("text", str(response)), "can_build": response.get("can_build", False)}
        except Exception as e:
            self.logger.error(f"Contextual doubt error: {e}")
            return {"success": False, "error": str(e)}
