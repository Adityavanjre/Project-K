import time
import multiprocessing
import os
import psutil
import uuid
import random
from modules.kali_aider.module import AiderModule
from modules.kali_litellm.module import LiteLLMModule
from modules.kali_memory.module import MemPalaceModule
from modules.logger import log_execution, log_plan_event, log_goal_event
from modules.device import detect_device, get_system_stress
from modules.planner import TaskPlanner
from modules.validator import PlanValidator, PerformanceValidator
from modules.permissions import PermissionManager, RiskLevel
from modules.goals import GoalManager, Goal
from modules.intelligence import TelemetryStore, ModuleScorer, normalize_capability
from modules.agents import PlannerAgent, ExecutorAgent, MemoryAgent, CriticAgent
from modules.strategy import StrategyStore
from modules.registry import ModuleRegistry, ModuleState, SandboxTier

# Swarm Module Imports
from modules.kali_aider.module import AiderModule
from modules.kali_gitnexus.module import GitNexusModule
from modules.kali_litellm.module import LiteLLMModule
from modules.kali_memory.module import MemPalaceModule
from modules.kali_gsd.module import GSDModule
from modules.kali_wrkflw.module import WrkflwModule
from modules.kali_graphify.module import GraphifyModule
from modules.kali_airllm.module import AirLLMModule
from modules.kali_harness.module import KALIHarnessModule
from modules.kali_agentfm.module import AgentFMModule
from modules.kali_trainer.module import KALITrainerModule
from modules.kali_openfang.module import OpenFangModule
from modules.kali_vault.module import SovereignVaultModule
from modules.swarm_node import UniversalSwarmModule

def _worker_wrapper(module, task, device, result_queue):
    try:
        result = module.run(task, device=device)
        result_queue.put(result)
    except Exception as e:
        result_queue.put({"status": "fail", "output": str(e), "reason": f"Process error", "device": device})

class UniversalBridge:
    def __init__(self):
        self.modules = {}
        self.registry = ModuleRegistry()
        self.base_max_concurrent = 2
        self.active_processes = []
        self.active_goals = set()
        self.max_concurrent_goals = 1
        self.gpu_available = detect_device() == "gpu"
        # SOVEREIGN: Core System Initialization
        self.permission_manager = PermissionManager()
        self.permission_manager.bridge = self
        self.telemetry = TelemetryStore()
        self.scorer = ModuleScorer()
        
        # SOVEREIGN: Cognition Root
        try:
            from src.core.sovereign_intelligence import SovereignIntelligence
            self.kali = SovereignIntelligence(bridge=self)
            print("[KALI] Cognition Root: CONNECTED")
        except Exception as e:
            print(f"[KALI] Cognition Root Failure: {e}")
            self.kali = None
            
        # SOVEREIGN: Cognitive Module Initialization (AgentFM, OpenFang, etc.)
        self._init_modules()
        
        # SOVEREIGN: Bootstrap (Health & Connectivity Check)
        self.bootstrap()

    def _init_modules(self):
        """Initialize and register all KALI modules."""
        # Core Utilities
        self.register("code", AiderModule(), auto_activate=True, tier=SandboxTier.SAFE)
        self.register("gitnexus", GitNexusModule(), auto_activate=True, tier=SandboxTier.CONTROLLED)
        self.register("llm", LiteLLMModule(), auto_activate=True, tier=SandboxTier.SAFE)
        self.register("memory", MemPalaceModule(), auto_activate=True, tier=SandboxTier.SAFE)
        self.register("gsd", GSDModule(), auto_activate=True, tier=SandboxTier.CONTROLLED)
        self.register("wrkflw", WrkflwModule(), auto_activate=True, tier=SandboxTier.CONTROLLED)
        self.register("graphify", GraphifyModule(), auto_activate=True, tier=SandboxTier.SAFE)
        self.register("airllm", AirLLMModule(), auto_activate=True, tier=SandboxTier.SAFE)

        # Advanced Cognitive Modules
        self.register("agentfm", AgentFMModule(), auto_activate=True, tier=SandboxTier.CONTROLLED)
        
        trainer_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "integrations", "ai-for-beginners")
        self.register("trainer", KALITrainerModule(trainer_path), auto_activate=True, tier=SandboxTier.SAFE)
        
        self.register("openfang", OpenFangModule(), auto_activate=True, tier=SandboxTier.CONTROLLED)
        self.register("vault", SovereignVaultModule(), auto_activate=True, tier=SandboxTier.CONTROLLED)
        
        from modules.kali_openclaw.module import OpenClawModule
        self.register("openclaw", OpenClawModule(), auto_activate=True, tier=SandboxTier.CONTROLLED)
        
        harness_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "integrations", "claude-code-harness")
        self.register("harness", KALIHarnessModule(harness_path), auto_activate=True, tier=SandboxTier.SAFE)
        
        # Dynamic Swarm Discovery
        self._discover_swarm()
        
        # Specialized Agents
        self.planner = TaskPlanner(self)
        self.planner_agent = PlannerAgent(self)
        self.executor_agent = ExecutorAgent(self)
        self.memory_agent = MemoryAgent(self)
        self.critic_agent = CriticAgent(self)
        self.event_queue = multiprocessing.Queue()
        self.goal_controls = {} 

    def _wait_for_controls(self, goal_id: str):
        """Wait if the goal is paused, or abort if cancelled."""
        while self.goal_controls.get(goal_id, {}).get("paused"):
            time.sleep(1.0)
            if self.goal_controls.get(goal_id, {}).get("cancelled"):
                break
        if self.goal_controls.get(goal_id, {}).get("cancelled"):
            raise InterruptedError("Goal cancelled by user.")

    def set_autonomy_mode(self, enabled: bool):
        """Phase 9: Toggle Controlled Autonomy mode."""
        self.permission_manager.autonomy_enabled = enabled
        self.emit_event("autonomy_update", {"enabled": enabled})
        print(f"[BRIDGE] Controlled Autonomy: {'ENABLED' if enabled else 'DISABLED'}")

    def emit_event(self, event_type: str, data: dict):
        """Push an event to the UI stream."""
        event = {
            "type": event_type,
            "timestamp": time.time(),
            "data": data
        }
        self.event_queue.put(event)
        # Also print to console for debug
        print(f"[EVENT] {event_type}: {data}")

    def _discover_swarm(self):
        """Scan integrations folder and register all subdirectories."""
        integrations_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "integrations")
        if not os.path.exists(integrations_path): return
        
        for item in os.listdir(integrations_path):
            item_path = os.path.join(integrations_path, item)
            if os.path.isdir(item_path):
                # Only register if not already manually registered
                normalized_name = item.lower().replace("-", "_")
                if normalized_name not in self.modules:
                    node = UniversalSwarmModule(item, integrations_path)
                    # Register as EXPERIMENTAL/CONTROLLED by default
                    self.register(normalized_name, node, auto_activate=True, tier=SandboxTier.EXPERIMENTAL)

    def register(self, name: str, module_instance, auto_activate=False, tier=None):
        self.modules[name] = module_instance
        tier = tier or SandboxTier(module_instance.metadata.get("sandbox_tier", "experimental"))
        self.registry.register_module(name, tier)
        
        if auto_activate:
            self.registry.set_state(name, ModuleState.ACTIVE)
        
        print(f"[BRIDGE] Registered module: {name} (State: {self.registry.get_state(name).value})")

    def bootstrap(self):
        """
        Unified KALI Initialization Sequence.
        Ensures all decentralized and autonomous components are active and connected.
        """
        print("\n[KALI] --- SOVEREIGN BOOTSTRAP SEQUENCE ---")
        
        # 1. AgentFM Mesh Check
        agentfm = self.modules.get("agentfm")
        if agentfm and agentfm.is_available():
            print("[KALI] P2P Execution Mesh: CONNECTED (+50 Sovereign Boost)")
        else:
            print("[KALI] P2P Execution Mesh: LOCAL_FALLBACK (Check daemon)")

        # 2. OpenFang Agent OS Check
        openfang = self.modules.get("openfang")
        if openfang and openfang.is_available():
            print("[KALI] OpenFang Agent OS: ACTIVE (24/7 Autonomy Ready)")
            # Auto-activate Researcher Hand
            openfang.run({"command": "create_agent", "params": {"template": "kali-researcher"}})
        else:
            print("[KALI] OpenFang Agent OS: PENDING (Start Vertex to activate)")

        # 3. Trainer Module Readiness
        trainer = self.modules.get("trainer")
        if trainer:
            print("[KALI] Self-Training Engine: ARMED (Curriculum Linked)")

        # 4. Harness Sync
        harness = self.modules.get("harness")
        if harness:
            print("[KALI] Sovereign Harness: SYNCED (Plans.md Anchored)")
            self.execute({"type": "harness", "command": "sync"})

        print("[KALI] --- BOOTSTRAP COMPLETE: SYSTEM IS SOVEREIGN ---\n")

    def activate_module(self, name: str) -> bool:
        """Controlled activation pipeline: Testing -> Active."""
        module = self.modules.get(name)
        if not module: return False
        
        self.registry.set_state(name, ModuleState.TESTING)
        success, reason = PerformanceValidator.validate_module(module, self)
        
        if success:
            self.registry.set_state(name, ModuleState.ACTIVE, test_result=reason)
            return True
        else:
            self.registry.set_state(name, ModuleState.INACTIVE, test_result=reason)
            return False

    def resolve_module(self, capability: str, task_input: str = None, risk_level: str = "SAFE") -> str:
        # 1. Experience Check
        if task_input:
            best_proven = StrategyStore.get_best_module(task_input, capability)
            if best_proven and self.registry.is_active(best_proven) and not self.telemetry.is_disabled(best_proven):
                if self.registry.can_execute(best_proven, risk_level):
                    print(f"[STRATEGY] Reusing proven strategy: {best_proven} for {capability}")
                    return best_proven

        canonical_cap = normalize_capability(capability)
        candidates = []
        for name, mod in self.modules.items():
            # Phase 7: State and Tier checks
            if not self.registry.is_active(name): continue
            if not self.registry.can_execute(name, risk_level): continue

            # Phase 6.5: Negative Memory / Blacklist Check
            if task_input and StrategyStore.is_blacklisted(task_input, name, capability):
                continue

            # Phase 56: Explicit P2P Priority
            if name == "agentfm" and canonical_cap in ["reasoning", "llm"]:
                score = 1000.0 # Extreme priority
                candidates.append((name, score))
                continue

            mod_caps = [normalize_capability(c) for c in mod.metadata.get("capabilities", [])]
            if canonical_cap in mod_caps or capability == name:
                if not self.telemetry.is_disabled(name):
                    score = self.scorer.calculate_score(name, mod.metadata, self.telemetry)
                    candidates.append((name, score))
        if not candidates: return None
        if random.random() < 0.10:
            selected = random.choice(candidates)[0]
            self._emit_strategy_log(capability, task_input, selected, candidates)
            return selected
        candidates.sort(key=lambda x: x[1], reverse=True)
        selected = candidates[0][0]
        self._emit_strategy_log(capability, task_input, selected, candidates)
        return selected

    def _emit_strategy_log(self, capability: str, task_input: str, resolved_name: str, candidates: list):
        """Log the reasoning behind module selection."""
        details = []
        for name, score in candidates:
            details.append({"module": name, "score": round(score, 2)})
        
        task_input = task_input or ""
        self.emit_event("strategy_log", {
            "capability": capability,
            "selected": resolved_name,
            "candidates": details,
            "reason": "Highest calculated performance score." if not StrategyStore.get_best_module(task_input, capability) else "Proven historical strategy."
        })

    def _validate_output(self, result: dict) -> bool:
        output = str(result.get("output", ""))
        if not output or len(output) < 5: return False
        if "error" in output.lower() and result["status"] == "success": return False
        return True

    def process_directive(self, prompt: str) -> dict:
        """
        ANTIGRAVITY RELAY: High-level entry point.
        Relays objectives to KALI for sovereign reasoning.
        """
        if self.kali:
            print(f"[ANTIGRAVITY] Relaying objective to KALI: {prompt}")
            trace = self.kali.process_objective(prompt)
            self.emit_event("kali_trace", trace)
            
            # If KALI initiated a mission, we monitor the result
            if trace["status"] == "success":
                return {"status": "success", "trace": trace, "executor": "KALI"}
            else:
                return {"status": "fail", "reason": trace.get("error", "KALI reasoning failure"), "trace": trace}

        # LEGACY FALLBACK (Audited)
        print("[ANTIGRAVITY] KALI Cognition offline. Using legacy planner.")
        response = self.planner_agent.communicate({"task": prompt})
        goal = GoalManager.create_goal(prompt, enriched_plan)
        log_goal_event("GOAL_CREATED", goal.id, details=f"Objective: {prompt}")
        self.emit_event("goal_created", {
            "id": goal.id,
            "objective": prompt,
            "plan": [{"type": s["type"], "input": s["input"], "status": "pending"} for s in enriched_plan]
        })
        return self.execute_goal(goal.id)

    def execute_goal(self, goal_id: str) -> dict:
        if goal_id in self.active_goals or len(self.active_goals) >= self.max_concurrent_goals:
            return {"status": "queued"}
        if not GoalManager.acquire_lock(goal_id): return {"status": "fail", "reason": "Locked"}
        self.active_goals.add(goal_id)
        self.goal_controls[goal_id] = {"paused": False, "cancelled": False, "skip_step": False, "retry_step": False, "override_module": None}
        try:
            res = self.memory_agent.communicate({"task": "load", "context": {"goal_id": goal_id}})
            goal = res.get("goal")
            if not goal: return {"status": "fail"}
            goal.status = "in_progress"; self.memory_agent.communicate({"task": "save", "context": {"goal": goal}})
            while goal.current_step < len(goal.plan):
                self._wait_for_controls(goal_id)
                step = goal.plan[goal.current_step]
                if step.get("status") == "completed":
                    goal.current_step += 1; continue
                
                # Check for Step Skip
                if self.goal_controls[goal_id].get("skip_step"):
                    self.goal_controls[goal_id]["skip_step"] = False
                    self.emit_event("step_skipped", {"goal_id": goal_id, "step_num": goal.current_step})
                    goal.current_step += 1; continue

                step["status"] = "in_progress"; self.memory_agent.communicate({"task": "save", "context": {"goal": goal}})
                task_input = step["input"]
                for k, v in goal.context.items(): task_input = task_input.replace(f"{{{k}}}", str(v))
                task_type = step["type"]
                risk_level = step.get("risk", "SAFE")
                
                self.emit_event("step_started", {
                    "goal_id": goal.id,
                    "step_num": goal.current_step,
                    "type": task_type,
                    "input": task_input
                })

                print(f"[BRIDGE] Executing step {goal.current_step+1}: type={task_type} (Risk: {risk_level})")
                retries = 0; max_retries = 2; accepted = False; final_result = None
                while retries <= max_retries and not accepted:
                    self._wait_for_controls(goal_id)
                    
                    # Module Override Logic
                    forced = self.goal_controls[goal_id].get("override_module")
                    if forced:
                        resolved_name = forced
                        self.goal_controls[goal_id]["override_module"] = None
                        self.emit_event("module_overridden", {"module": resolved_name})
                    else:
                        resolved_name = self.resolve_module(task_type, task_input=task_input, risk_level=risk_level) or task_type
                    
                    task = {"type": resolved_name, "input": task_input, "context": {**goal.context, **step.get("context", {})}}
                    final_result = self.executor_agent.communicate({"task": task, "context": {"goal_id": goal.id, "step_num": goal.current_step+1}})
                    if final_result.get("status") == "denied": return {"status": "paused", "goal_id": goal.id}
                    
                    if final_result.get("status") == "fail" and final_result.get("reason") in ["Timeout.", "Process error"]:
                        retries += 1; continue

                    evaluation = self.critic_agent.communicate({"task": task, "result": final_result})
                    
                    StrategyStore.save_experience({
                        "task_input": task_input,
                        "capability": task_type,
                        "module": resolved_name,
                        "status": "success" if evaluation.get("accepted") else "fail",
                        "critic_feedback": evaluation.get("improvement_advice" if not evaluation.get("accepted") else "reason"),
                        "quality_score": evaluation.get("quality_score", 0.0),
                        "confidence": evaluation.get("confidence", 0.0)
                    })
                    if evaluation.get("accepted"):
                        accepted = True
                        self.emit_event("critic_log", {
                            "status": "accepted",
                            "reason": evaluation.get("reason"),
                            "quality": evaluation.get("quality_score")
                        })
                    else:
                        # Check for Manual Retry vs Auto Retry
                        if self.goal_controls[goal_id].get("retry_step"):
                            self.goal_controls[goal_id]["retry_step"] = False
                            print("[BRIDGE] Manual retry triggered.")
                        else:
                            retries += 1
                            
                        self.emit_event("critic_log", {
                            "status": "rejected",
                            "reason": evaluation.get("reason"),
                            "advice": evaluation.get("improvement_advice")
                        })
                        print(f"[CRITIC_REJECTED] Reason: {evaluation.get('reason')}. Retrying...")
                        
                        # Wait for user if retries exhausted
                        if retries > max_retries and not accepted:
                            self.emit_event("goal_paused", {"goal_id": goal_id, "reason": "Retries exhausted. Intervention required."})
                            self.goal_controls[goal_id]["paused"] = True
                            self._wait_for_controls(goal_id)
                            retries = 0 # Reset retries after intervention

                if not accepted:
                    goal.status = "failed"; self.memory_agent.communicate({"task": "save", "context": {"goal": goal}})
                    return {"status": "fail", "goal_id": goal.id}
                step_key = step.get("output_key", f"{task_type}_output")
                goal.context[step_key] = final_result.get("output", "")
                step["status"] = "completed"; goal.current_step += 1
                goal.progress = int((goal.current_step / len(goal.plan)) * 100)
                self.memory_agent.communicate({"task": "save", "context": {"goal": goal}})
                self.emit_event("goal_progress", {
                    "goal_id": goal.id,
                    "progress": goal.progress,
                    "current_step": goal.current_step
                })
            goal.status = "completed"; self.memory_agent.communicate({"task": "save", "context": {"goal": goal}})
            self.emit_event("goal_completed", {"goal_id": goal.id})
            return {"status": "success", "goal_id": goal.id, "context": goal.context}
        except InterruptedError:
            goal.status = "cancelled"; self.memory_agent.communicate({"task": "save", "context": {"goal": goal}})
            self.emit_event("goal_cancelled", {"goal_id": goal_id})
            return {"status": "cancelled", "goal_id": goal_id}
        finally:
            self.active_goals.discard(goal_id); GoalManager.release_lock(goal_id)
            if goal_id in self.goal_controls: del self.goal_controls[goal_id]

    def execute(self, task: dict, workflow_id: str = None, step_num: int = None) -> dict:
        start_time = time.time()
        task_type = task.get("type")
        risk_level = task.get("risk", "SAFE")
        resolved_name = self.resolve_module(task_type, task_input=task.get("input"), risk_level=risk_level) or task_type
        module = self.modules.get(resolved_name)
        if not module: 
            print(f"[BRIDGE] Module not found or inactive: {resolved_name}")
            return self._trigger_fallback(task_type, "None", "Unknown task or inactive", start_time, workflow_id, step_num)
        if self.telemetry.is_disabled(resolved_name):
            return self._trigger_fallback(task_type, resolved_name, "Circuit breaker open.", start_time, workflow_id, step_num)
        
        risk_level_calc = self.permission_manager.calculate_contextual_risk(task)
        if not self.permission_manager.request_approval(task, risk_level_calc):
            StrategyStore.save_experience({
                "task_input": task.get("input", ""),
                "capability": task_type,
                "module": resolved_name,
                "status": "fail",
                "is_human_feedback": True,
                "critic_feedback": "User denied execution.",
                "quality_score": 0.0,
                "confidence": 1.0
            })
            return {"status": "denied", "output": "Denied.", "latency": time.time() - start_time}
            
        limit = self._get_dynamic_concurrency_limit()
        while len(self.active_processes) >= limit:
            self.active_processes = [p for p in self.active_processes if p[0].is_alive()]
            if len(self.active_processes) >= limit: time.sleep(0.1)
            limit = self._get_dynamic_concurrency_limit()
        if not module.is_available(): 
            self.telemetry.record(resolved_name, "fail", time.time() - start_time)
            return self._trigger_fallback(task_type, module.name, "Unavailable.", start_time, workflow_id=workflow_id, step_num=step_num)
        device = self._select_optimal_device(task_type)
        result = self._run_in_process(module, task, device, start_time, workflow_id, step_num)
        effective_status = result["status"]
        if effective_status == "success" and not self._validate_output(result):
            effective_status = "fail"
        self.telemetry.record(resolved_name, effective_status, result.get("latency", time.time() - start_time))
        return result

    def _get_task_weight(self, task_type: str) -> str:
        return "heavy" if task_type in ["llm", "memory", "reasoning", "storage", "analysis"] else "light"

    def _get_dynamic_concurrency_limit(self) -> int:
        stress = get_system_stress()
        return 1 if stress["is_stressed"] else self.base_max_concurrent

    def _select_optimal_device(self, task_type: str) -> str:
        if self.gpu_available and self._get_task_weight(task_type) == "heavy": return "gpu"
        return "cpu"

    def _run_in_process(self, module, task, device, start_time, workflow_id=None, step_num=None) -> dict:
        result_queue = multiprocessing.Queue()
        p = multiprocessing.Process(target=_worker_wrapper, args=(module, task, device, result_queue))
        p.start(); pid = p.pid
        self.active_processes.append((p, start_time))
        try:
            p.join(timeout=7.0)
            if p.is_alive():
                p.terminate(); p.join()
                self.telemetry.record(module.name, "fail", 7.0)
                return self._trigger_fallback(task["type"], module.name, "Timeout.", start_time, is_timeout=True, pid=pid, device=device, workflow_id=workflow_id, step_num=step_num)
            if result_queue.empty(): 
                self.telemetry.record(module.name, "fail", time.time() - start_time)
                return self._trigger_fallback(task["type"], module.name, "No result.", start_time, pid=pid, device=device, workflow_id=workflow_id, step_num=step_num)
            result = result_queue.get()
            cpu, mem = 0.0, 0.0
            try:
                proc = psutil.Process(pid); cpu = proc.cpu_percent(interval=0.1); mem = proc.memory_info().rss / (1024 * 1024)
            except: pass
            log_execution(module.name, task["type"], result["status"], time.time() - start_time, pid=pid, cpu_usage=cpu, mem_usage=mem, device=device, failure_reason=result.get("reason"), timeout_event=result.get("timeout", False), workflow_id=workflow_id, step_num=step_num)
            return result
        except Exception as e:
            if p.is_alive(): p.terminate()
            return self._trigger_fallback(task["type"], module.name, f"Error: {str(e)}", start_time, pid=pid, device=device, workflow_id=workflow_id, step_num=step_num)

    def _trigger_fallback(self, task_type: str, module_name: str, reason: str, start_time: float, is_timeout: bool = False, pid: int = None, device: str = "cpu", workflow_id=None, step_num=None) -> dict:
        latency = time.time() - start_time
        log_execution(module_name, task_type, status="fail", latency=latency, fallback_triggered=True, failure_reason=reason, timeout_event=is_timeout, pid=pid, device=device, workflow_id=workflow_id, step_num=step_num)
        return {"status": "fail", "output": "Fallback triggered.", "latency": latency}
