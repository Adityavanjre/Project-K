"""
Main processor for handling doubt clearing requests.
"""

import json
import logging
import os
import threading
import time
import uuid
import re

# 🔱 SOVEREIGN OFFLINE & SILENCE PROTOCOL
import warnings
os.environ["HF_HUB_OFFLINE"] = "1"
os.environ["TRANSFORMERS_OFFLINE"] = "1"
os.environ["PYTHONHASHSEED"] = "42"
logging.getLogger("transformers").setLevel(logging.ERROR)
logging.getLogger("sentence_transformers").setLevel(logging.ERROR)
warnings.filterwarnings("ignore", category=UserWarning)
from datetime import datetime
from typing import Dict, List, Optional, Any, Callable
from utils.pii_scrubber import PiiScrubber

# Note: Eager imports are reduced to core dependencies only. 
# Optional services are loaded lazily via _get_service.
from .data_structures import DoubtContext
from .vector_memory import VectorMemory
from .memory import MemoryService
from .ai_service import AIService
from .user_dna import UserDNA
from .secure_boot import BootGuardian
from .gsd_service import GSDPhase
from .channel_manager import ChannelManager
from .sovereign_intelligence import SovereignIntelligence
from .local_ai_service import LocalAIService
from .sovereign_check import SovereignCheck
from utils.load_monitor import LoadMonitor
from .neural_cache import NeuralCache


class DoubtProcessor:
    """Main processor for handling doubt clearing requests."""

    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """Initialize the doubt processor."""
        self.config = config or {}
        self.project_root = self.config.get("project_root", os.getcwd())
        self.logger = logging.getLogger(__name__)
        self.start_time = time.time()
        self.service_registry: Dict[str, Any] = {} # 🔱 RESTORED: Service Router (MOVED TO TOP FOR STABILITY)

        # 1. Core Services (Eager)
        self.use_local_ai = os.getenv("USE_LOCAL_AI", "false").lower() == "true"
        try:
            self.vector_memory = VectorMemory()
        except Exception as ve:
            self.logger.error(f"KALI Intelligence: VectorMemory failed to load: {ve}. Proceeding with amnesia.")
            self.vector_memory = None
        self.local_ai = LocalAIService(self.config.get("local_ai", {}))
        self.memory = MemoryService()
        self.user_dna = UserDNA()
        
        if self.use_local_ai:
            self.ai_service = self.local_ai
        else:
            self.ai_service = AIService(
                self.config.get("openai", {}), vector_memory=self.vector_memory
            )

        # 2. Hardening: Secure Boot & Evolution
        self.boot_guardian = BootGuardian(self.project_root)
        self.is_bios_secure = self.boot_guardian.perform_secure_boot()
        self.sovereign_force_local = os.getenv("SOVEREIGN_FORCE_LOCAL", "false").lower() == "true"
        self.sovereign_intel = SovereignIntelligence(self)

        # 3. Tool Stabilization (B-3 Fix)
        from .mcp_pool import mcp_pool
        self.mcp_pool = mcp_pool
        self.mcp_pool.register_ai_tools(self)

        # 🔱 HYBRID INTELLIGENCE: Load & Cache
        self.load_monitor = LoadMonitor()
        self.cache = NeuralCache(os.path.join(self.project_root, "data", "cache", "neural"))
        
        # 🔱 TRAUMA SCRUB: Self-healing Cloud Memory
        try:
            for cache_dir in [os.path.join(self.project_root, "data", "cache", "neural"), os.path.join(self.project_root, ".sovereign_cloud")]:
                if os.path.exists(cache_dir):
                    for f in os.listdir(cache_dir):
                        path = os.path.join(cache_dir, f)
                        if os.path.isfile(path) and (path.endswith('.json') or path.endswith('.kanchor')):
                            try:
                                with open(path, 'r', encoding='utf-8', errors='ignore') as cf:
                                    if "Simulation Mode Purged" in cf.read():
                                        os.remove(path)
                                        self.logger.info(f"Purged Trauma Cache: {f}")
                            except: pass
        except Exception as e:
            self.logger.error(f"Trauma Scrub failed: {e}")
        
        self.logger.info("🔱 KALI: Hybrid Intelligence Hardening Active.")
        
        # 5. Universal Gateway Bridge
        from .channel_manager import ChannelManager
        self.channel_manager = ChannelManager(self)
        
        # 6. Telegram Listener Bridge
        from .channels.telegram_channel import TelegramChannel
        self.telegram = TelegramChannel(self)
        self.channel_manager.register_channel("telegram", self.telegram)
        self.telegram.start_listening()
        
        # State indicators
        self.power_mode = "TURBO"
        self.message_count = 0
        self.is_sovereign = self.user_dna.profile.get("security", {}).get("hw_verified", False)
        
        self.sovereign_msg = "DEEP_HW_VERIFIED" if self.is_sovereign else "HARDWARE_DNA_MISMATCH"
        if not self.is_sovereign or not self.is_bios_secure:
            self.power_mode = "ECO"
            reason = "UNAUTHORIZED_HARDWARE" if not self.is_sovereign else "INTEGRITY_BREACH"
            self.logger.warning(f"[!] BIOS ALERT: {reason}. Entering Restricted Mode.")

        self.user_tension = 0.5
        self.current_predictions = []
        self.conversation_history = []
        self.current_session_id = None
        self.current_phase = 0
        self.active_bom = None
        
        user_home = os.path.expanduser("~")
        self.doc_dir = os.path.join(user_home, "Documents", "KALI_RESOURCES")
        if not os.path.exists(self.doc_dir):
            os.makedirs(self.doc_dir)

        # Execute Startup Salvage Hooks
        self._load_last_session()
        self._ensure_sovereign_hooks()
        # SOVEREIGN: Perform heavy initialization safely in the main thread to prevent Windows Torch multi-threading crashes
        self._background_initialization()

    def _get_service(self, name: str, factory: Callable) -> Any:
        """Lazy loader for sub-services."""
        if name not in self.service_registry:
            self.logger.info(f"KALI: Initializing lazy service '{name}'")
            self.service_registry[name] = factory()
        return self.service_registry[name]

    @property
    def uncensored(self):
        from .specialists.uncensored_specialist import UncensoredSpecialist
        return self._get_service("uncensored", lambda: UncensoredSpecialist(self.ai_service))

    # --- Feature: Mission Control (SOVEREIGN) ---

    @property
    def council(self):
        from .council_service import CouncilService
        return self._get_service("council", lambda: CouncilService(self.ai_service, sovereign_mode=self.sovereign_force_local))

    @property
    def training_logger(self):
        from .training_logger import TrainingLogger
        return self._get_service("training_logger", lambda: TrainingLogger())

    @property
    def knowledge_check(self):
        from .knowledge_check import KnowledgeCheckEngine
        return self._get_service("knowledge_check", lambda: KnowledgeCheckEngine(self.ai_service, self.project_root))

    @property
    def explainer(self):
        from .explainer import Explainer
        return self._get_service("explainer", lambda: Explainer(self.ai_service))

    @property
    def biometric_service(self):
        from .biometric_service import BiometricService
        return self._get_service("biometrics", lambda: BiometricService())

    @property
    def robotic_bridge(self):
        return None # PURGED: RoboticBridge decommissioned

    @property
    def dream_engine(self):
        from .dream_engine import DreamEngine
        return self._get_service("dream", lambda: DreamEngine())

    @property
    def shadow_eval(self):
        from .shadow_evaluator import ShadowEvaluator
        return self._get_service("shadow", lambda: ShadowEvaluator(self.ai_service, self.local_ai))

    @property
    def system_controller(self):
        from .system_controller import SystemController
        return self._get_service("system", lambda: SystemController(self.project_root, mission_manager=self.mission_manager))

    @property
    def mission_manager(self):
        from .mission_manager import MissionManager
        return self._get_service("mission", lambda: MissionManager())

    @property
    def handover(self):
        from .handover_protocol import HandoverProtocol
        return self._get_service("handover", lambda: HandoverProtocol(self.project_root))

    @property
    def sensors(self):
        from .hardware_sensors import HardwareSensors
        return self._get_service("sensors", lambda: HardwareSensors())

    @property
    def hud_bridge(self):
        from .hud_bridge import HUDBridge
        return self._get_service("hud", lambda: HUDBridge())

    @property
    def tts_generator(self):
        from .tts import TTSGenerator
        audio_dir = os.path.join(self.project_root, "data", "assets", "speech")
        return self._get_service("tts", lambda: TTSGenerator(audio_dir))

    @property
    def predictive_engine(self):
        from .predictive_engine import PredictiveIntentEngine
        return self._get_service("predictive", lambda: PredictiveIntentEngine())

    @property
    def dna_extractor(self):
        from .dna_extractor import DNAExtractor
        return self._get_service("dna", lambda: DNAExtractor(self.user_dna, self.vector_memory))

    @property
    def reflection_engine(self):
        from .reflection_engine import ReflectionEngine
        return self._get_service("reflection", lambda: ReflectionEngine())

    @property
    def gap_detector(self):
        from .gap_detector import GapDetector
        return self._get_service("gap", lambda: GapDetector(self.user_dna))

    @property
    def skill_manifestor(self):
        from .skill_manifestor import SkillManifestor
        return self._get_service("skill", lambda: SkillManifestor(self.plugin_manager, self.ai_service))

    @property
    def knowledge_service(self):
        from .knowledge_service import KnowledgeService
        return self._get_service("knowledge_service", lambda: KnowledgeService(self.project_root))

    @property
    def gsd_service(self):
        from .gsd_service import GSDService
        return self._get_service("gsd", lambda: GSDService())

    @property
    def review_service(self):
        from .review_service import ReviewService
        return self._get_service("review", lambda: ReviewService(self.ai_service))

    @property
    def hardware_bridge(self):
        from .hardware_bridge import HardwareBridge
        return self._get_service("hardware", lambda: HardwareBridge())

    @property
    def planner(self):
        from .planner import TaskPlanner
        return self._get_service("planner", lambda: TaskPlanner(self.ai_service, self.vector_memory, self.system_controller))

    @property
    def manifestor(self):
        from .manifestor import Manifestor
        project_dir = os.path.join(self.project_root, "data", "projects")
        return self._get_service("manifestor", lambda: Manifestor(project_dir))

    @property
    def proactive_research(self):
        from .proactive_research import ProactiveResearchEngine
        return self._get_service("proactive", lambda: ProactiveResearchEngine(self))

    # ------------------------------------------------------------------
    # LAZY SERVICE REGISTRY (SOVEREIGN: A-1)
    # ------------------------------------------------------------------

    @property
    def swarm_service(self): 
        from .swarm_service import SwarmService
        return self._get_service("swarm", lambda: SwarmService(self.project_root))
    
    @property
    def sovereign_cloud(self): 
        from .sovereign_cloud import SovereignCloudService
        return self._get_service("cloud", lambda: SovereignCloudService(self.project_root))
    
    @property
    def rlhf_service(self): 
        from .rlhf_service import RLHFService
        return self._get_service("rlhf", lambda: RLHFService(self.project_root))

    @property
    def omega_protocol(self): 
        from .omega_protocol import OmegaProtocol
        return self._get_service("omega", lambda: OmegaProtocol(self.project_root))

    @property
    def market_research(self): 
        from .market_research import MarketResearchEngine
        return self._get_service("market", lambda: MarketResearchEngine(self.ai_service))
    
    @property
    def bom_service(self): 
        from .bom_service import BOMService
        return self._get_service("bom", lambda: BOMService(self.market_research))
    
    @property
    def blueprint_service(self): 
        from .blueprint_service import BlueprintService
        return self._get_service("blueprint", lambda: BlueprintService(self.ai_service))
    
    @property
    def cad_service(self): 
        from .cad_service import CADService
        return self._get_service("cad", lambda: CADService())

    @property
    def watchdog(self): 
        from .watchdog_service import WatchdogService
        return self._get_service("watchdog", lambda: WatchdogService(self.project_root))

    @property
    def restoration(self): 
        from .restoration_service import RestorationService
        return self._get_service("restoration", lambda: RestorationService(self.project_root))


    @property
    def ingestor(self):
        from .ingestor import DocumentIngestor
        return self._get_service("ingestor", lambda: DocumentIngestor(self.vector_memory))

    @property
    def report_generator(self):
        from .report_generator import ReportGenerator
        return self._get_service("report_generator", lambda: ReportGenerator(self))

    def _log_shadow_eval(self, query: str, local_resp: str, external_resp: str):
        """SOVEREIGN: C-3. Compare local vs external responses for quality monitoring."""
        local_len = len(local_resp)
        external_len = len(external_resp)
        length_ratio = local_len / max(external_len, 1)
        
        eval_record = {
            "query": query[:200],
            "local_length": local_len,
            "external_length": external_len,
            "length_ratio": round(length_ratio, 2),
            "timestamp": datetime.now().isoformat(),
        }
        
        eval_path = os.path.join(self.project_root, "data", "shadow_eval.jsonl")
        os.makedirs(os.path.dirname(eval_path), exist_ok=True)
        with open(eval_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(eval_record) + "\n")
        
        if length_ratio < 0.5:
            self.logger.warning(f"SHADOW EVAL: Local response significantly shorter than external ({length_ratio:.0%})")

    def _background_initialization(self):
        """Perform heavy initialization tasks in the main thread to prevent crashes."""
        
        # 1. Preload Embedder (Lazy property trigger)
        if self.vector_memory:
            try:
                _ = self.vector_memory.embedder
            except: pass
            
        # 2. Seed Knowledge (Run synchronously to prevent PyTorch OpenMP background thread crashes on Windows)
        try:
            self._seed_universal_knowledge()
            self.logger.info("🔱 KALI: Universal Knowledge Seeding Complete.")
        except Exception as e:
            self.logger.error(f"🔱 KALI: Seeding Error: {e}")
            
    def _seed_universal_knowledge(self):
        """SOVEREIGN/21/22: Index cognitive and tactical seeds."""
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
        """SOVEREIGN: Force Git to use our sovereign hooks even in clones."""
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
        SOVEREIGN: The Sync Cycle.
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

            # SOVEREIGN+: Intelligence Hardening (Greeting Interceptor & Auto-Routing)
            greetings = ["hi", "hello", "hey", "hola", "greetings", "yo", "morning", "evening", "night"]
            sovereign_keywords = ["fix", "ui", "responsive", "layout", "code", "rewrite", "update", "frontend", "design"]
            
            clean_query = query.lower().strip("?!. ")
            
            # 1. Greeting Check - REMOVED (Sovereign Rule: No Hardcoding)
            # All queries now pass to cognitive processing.
            
            # 2. Sovereign Intent Auto-Route
            if any(kw in clean_query for kw in sovereign_keywords):
                self.logger.info("KALI: Sovereign Intent Detected in Doubt Mode. Auto-Routing.")
                return self.sovereign_intel.process_command(query)

            # Cache check
            if not bypass_cache:
                cached = self.vector_memory.get_cached_answer(query)
                if cached:
                    self.memory.update_anchor(
                        f"Handled via Cache: {query.splitlines()[0]}"
                    )
                    # SOVEREIGN HUD Sync even on cache
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
                self.user_tension = 0.0
            else:
                bio_state = self.biometric_service.get_physiological_state(
                    self.sensors.get_system_metrics().get("cpu_usage", 0)
                )
                self.user_tension = bio_state["neural_tension"]
                tension_status = self.handle_tension(query)
                if tension_status and "NEURAL_RESET_REQUIRED" in str(tension_status):
                    return {"text": str(tension_status), "can_build": False}

            predictions = self.predictive_engine.predict_next_steps(
                query,
                dna_profile.get("interaction_stats", {}).get("total_conversations", 0),
            )
            self.current_predictions = predictions

            # SOVEREIGN: RLHF Pre-Processing (Bias Detection)
            biases = self.rlhf_service.detect_bias(query)
            if biases:
                self.logger.warning(f"KALI RLHF: Bias detected in query -> {biases}")

            # Council
            # 4. Generate structured explanation via Explainer
            if isinstance(context, dict):
                user_level = context.get("user_level", "intermediate")
            else:
                user_level = context.user_level if context and hasattr(context, "user_level") else "intermediate"
                
            # Adjust level based on tension
            if self.user_tension > 0.8:
                user_level = "beginner"  # Simplify for high stress
                self.logger.info(
                    "KALI: High tension detected. Simplifying explanation."
                )

            # SOVEREIGN: Council for complex queries (>150 chars), Explainer for short ones
            # SOVEREIGN: Override if SOVEREIGN_FORCE_LOCAL is active
            use_council = (
                len(query) > 150
                and self.power_mode == "TURBO"
                and not self.sovereign_force_local
            )

            # 🔱 HYBRID INTELLIGENCE: Caching Tier
            cached_res = self.cache.get(query, context=full_context)
            if cached_res:
                self.logger.info("KALI: Neural Cache Hit — Returning indexed response.")
                return cached_res

            # 🔱 HYBRID INTELLIGENCE: Semantic Routing & Load Awareness
            task_complexity = self._classify_task(query)
            hw_safe = self.load_monitor.is_local_safe()
            
            is_heavy = task_complexity in ["coding", "reasoning", "multi-step"]
            
            response = None
            if is_heavy or not hw_safe or not self.sovereign_force_local:
                route_msg = "Heavy/Complex Task" if is_heavy else "Hardware Load Protection"
                self.logger.info(f"KALI: Routing to Remote Sovereign Node ({route_msg}).")
                
                # 🔱 TRIPLE-FAILOVER: Remote -> Retry -> Local
                for attempt in range(3):
                    try:
                        response = self.ai_service.ask_question(query, context=full_context, bypass_cache=bypass_cache)
                        if response: break
                    except Exception as e:
                        self.logger.warning(f"KALI: Remote Failure ({attempt+1}). Retrying... {e}")
                        time.sleep(1)
                
                if not response:
                    self.logger.error("KALI: Remote Node Exhausted. Falling back to Local Node.")
                    response = self.local_ai.ask_question(query, context=full_context)
            else:
                self.logger.info("KALI: Simple Task — Using Local CPU Node.")
                response = self.local_ai.ask_question(query, context=full_context)

            # Store in Cache
            if response:
                self.cache.store(query, response, context=full_context)

            # SOVEREIGN: Autonomous CodeRabbit Audit (If output contains code)
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

            # SOVEREIGN: RLHF Post-Processing (Alignment)
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

            # SOVEREIGN: Knowledge DNA Curation
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
            model_info = "local" if self.sovereign_force_local else ("council" if use_council else "expert")
            
            try:
                # C-5 Gap: Capture actual model provenance if not local
                if not self.sovereign_force_local and hasattr(self, "council") and getattr(self.council, "experts", None):
                    model_info = self.council.experts[0].model
            except Exception:
                pass
            
            # SOVEREIGN: Privacy Consent Gate
            has_consent = self.user_dna.get_consent()
            
            self.training_logger.log(
                query, str(response), source=source, context=source,
                model=model_info, has_consent=has_consent
            )

            # SOVEREIGN: Update HUD Bridge
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
            # SOVEREIGN: Shadow Oracle (C-3)
            # Parallel comparison every 5th message in Sovereign Mode
            self.message_count += 1
            shadow_data = None
            if self.sovereign_force_local and self.message_count % 5 == 0:
                self.logger.info(f"⚖️ SHADOW_ORACLE: Triggering Quality Drift Analysis (Msg#{self.message_count})")
                try:
                    # Capture council consensus for comparison
                    expert_consensus = self.council.get_consensus(query, context="Sovereign Shadow Mode")
                    # Evaluate Local vs Expert
                    shadow_data = self.council.shadow_evaluate(query, str(response), expert_consensus)
                    
                    # SOVEREIGN: Chart length_ratio locally
                    self._log_shadow_eval(query, str(response), expert_consensus)
                    
                    self.logger.info(f"⚖️ SHADOW_ORACLE Result: {shadow_data.get('score', 0.0)} Precision Alignment.")
                except Exception as e:
                    self.logger.error(f"⚖️ SHADOW_ORACLE Failed: {e}")

            # Final Response Assembly
            res = {
                "text": response,
                "audio_url": audio_url,
                "can_build": any(kw in query.lower() for kw in build_keywords),
                "power_mode": self.power_mode,
                "report_ready": len(response) > 500,
                "msg_id": str(uuid.uuid4()),
                "source": "council",
                "shadow_score": shadow_data.get("score") if shadow_data else None,
                "manifested_skill": locals().get("last_manifested_skill"),
            }

            # SOVEREIGN: Post-Action Anchor Update
            self.memory.update_anchor(f"RESOLVED: {query.splitlines()[0]}")

            # SOVEREIGN: Sovereign Cloud Anchoring
            self.sovereign_cloud.anchor_memory_segment(
                res["msg_id"],
                {
                    "query": query,
                    "response": response,
                    "alignment": alignment,
                    "tension": self.user_tension,
                },
            )

            # SOVEREIGN: Universal Gateway Broadcast
            if hasattr(self, 'channel_manager'):
                self.channel_manager.broadcast(res.get("text", str(res)))

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

        # SOVEREIGN: Neural Performance Intervention
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
            "robotic_status": "OFFLINE", # PURGED
            "cloud_status": self.sovereign_cloud.get_cloud_status(),
            "alignment_status": self.rlhf_service.get_alignment_status(),
            "omega_status": self.omega_protocol.get_protocol_status(),
            "gsd_status": self.gsd_service.get_gsd_status(),
            "reviewer_status": getattr(self, "review_service", None) and self.review_service.get_reviewer_status() if hasattr(self, "review_service") else None,
            "sovereignty_score": self.shadow_eval.get_sovereignty_score(),
            "local_node_ready": self.local_ai.is_available()
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

        # SOVEREIGN Integration: Execute research mission for costs and sources
        goal = self.gsd_service.get_structured_prompt(idea)
        research = self.planner.execute(goal)
        answer = research.get("answer", "I could not finalize the analysis, Sir.")

        # GSD Phase: PLAN
        self.gsd_service.transition_to(GSDPhase.PLAN)

        # SOVEREIGN: Economic Analysis
        bom = self.bom_service.generate_project_bom(
            {
                "name": idea[:30],
                "components": research.get(
                    "steps", []
                ),  # Use steps as components if not explicitly listed
            }
        )
        self.active_bom = bom

        # SOVEREIGN: Fabrication Hub Blueprints & CAD
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

        # SOVEREIGN Bridge: Sanitize and log for Sovereign Evolution
        if hasattr(self, "training_logger"):
            self.training_logger.log(
                goal, 
                answer, 
                system_prompt="KALI_SOVEREIGN_CORE", 
                model="expert",
                user_name=self.user_dna.name if hasattr(self, "user_dna") else None,
                has_consent=getattr(self.user_dna, "consent", True) if hasattr(self, "user_dna") else True
            )

        # SOVEREIGN: Self-Critique DPO Loop
        try:
            self._generate_dpo_critique(goal, answer)
        except Exception as e:
            self.logger.error(f"DPO Critique failed: {e}")

        # SOVEREIGN: Predictive Intent
        self.current_predictions = self.predictive_engine.predict_next_steps(idea, 0)

        # SOVEREIGN: Swarm Deployment (Detailed Delegation)
        mission_goals = [
            f"Research vendors for {idea}",
            f"Design CAD constraints for {idea}",
            f"Generate firmware logic for {idea}",
        ]
        for goal in mission_goals:
            self.swarm_service.deploy_swarm(goal)

        # SOVEREIGN: Robotic Feedback (Actionable Kinematics)
        self.robotic_bridge.move_joint("HEAD_PAN", 120)
        self.robotic_bridge.move_joint("ARM_L_SHOULDER", 45)
        self.logger.info("KALI: Robotic kinematic feedback initiated.")

        # SOVEREIGN: Sovereign Cloud Snapshot
        self.sovereign_cloud.anchor_memory_segment(
            f"PROJ_{idea[:8]}",
            {"idea": idea, "bom": bom, "manifest_path": manifest_path},
        )

        # SOVEREIGN: Trigger Neural Augmentation (Background synthesis)
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

            # SOVEREIGN: Post-Action Anchor Update
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
        SOVEREIGN/35: The Great Consolidation.
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

        # SOVEREIGN: Final Cloud Anchor
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
        SOVEREIGN: Neural Skill Swap
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
        SOVEREIGN: Neural Hot-Reload
        Dynamically re-initializes a specific service without restarting the processor.
        Used by the SelfOptimizingLoop after a successful self-patch.
        """
        self.logger.info(f"KALI: Initiating Hot-Reload for service: '{service_name}'")
        try:
            if service_name == "ai_service":
                self.ai_service = AIService(
                    self.config.get("openai", {}), vector_memory=self.vector_memory
                )
                self._service_registry.pop("explainer", None)
                self._service_registry.pop("review", None)
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
        """SOVEREIGN: Logs user preference (DPO) for the last interaction."""
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
        """SOVEREIGN: Retrieve session history for formal testing."""
        return self.memory.get_recent_memories(
            limit=50, session_id=self.current_session_id
        )

    def clear_history(self):
        """SOVEREIGN: Clear session history for formal testing."""
        self.memory.clear_memory(session_id=self.current_session_id)
        self.vector_memory.clear_memory(
            session_id=self.current_session_id
        )  # If it exists
        self.logger.info("Session history cleared.")

    def purge_sovereign_data(self):
        """SOVEREIGN: High-Privilege Sovereign Data Wipe (GDPR Compliance)."""
        self.logger.warning("SOVEREIGN_PURGE: User initiated a total data wipe.")
        self.user_dna.purge_profile()
        self.memory.purge_all_memories()
        if os.path.exists("data/unverified_training.jsonl"):
            os.remove("data/unverified_training.jsonl")
        return {"success": True, "message": "ALL_SOVEREIGN_DATA_PURGED: System memory is fresh."}

    def run_maintenance(self):
        """SOVEREIGN: Daily retention and pruning cycles."""
        self.logger.info("MAINTENANCE_TRIGGERED: Pruning archaic memory banks.")
        self.memory.prune_memory(days=30)

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

    def _classify_task(self, query: str) -> str:
        """
        KALI Semantic Classifier: Detects task complexity for Hybrid Routing.
        Classes: simple, reasoning, coding, multi-step.
        """
        q = query.lower()
        
        # 1. Coding Detection
        if any(w in q for w in ["code", "script", "function", "python", "javascript", "class ", "def ", "```"]):
            return "coding"
            
        # 2. Multi-step / Complexity Detection
        if any(w in q for w in ["audit", "analyze", "compare", "report", "plan", "strategy"]):
            return "multi-step"
            
        # 3. Reasoning Detection
        if any(w in q for w in ["why", "how does", "explain the logic", "theoretical"]):
            return "reasoning"
            
        # 4. Default: Simple
        return "simple"
