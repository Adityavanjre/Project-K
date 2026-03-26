import json
import logging
from typing import List, Dict, Optional, Any
from .tools.web_tools import search_web, browse_url
from .code_executor import CodeExecutor

class TaskPlanner:
    """
    ReAct-pattern task planner. KALI plans and executes multi-step internet research.
    """
    def __init__(self, ai_service, vector_memory):
        self.ai = ai_service
        self.memory = vector_memory
        self.executor = CodeExecutor()
        self.logger = logging.getLogger(__name__)

    def execute(self, goal: str, max_steps: int = 5) -> dict:
        self.logger.info(f"Agent executing goal: {goal}")

        # Step 1: Create a research plan
        plan_prompt = (
            f"You are KALI's Autonomous Research Agent. Create a clear research plan to achieve the following goal.\n"
            f"Goal: {goal}\n"
            f"Available tools: search_web(query), browse_url(url), execute_code(script)\n"
            f"Return ONLY a JSON object with a 'steps' list."
        )
        
        plan = self.ai.ask_json("Plan the research mission.", plan_prompt)
        # Type safety for steps
        raw_steps = plan.get("steps", []) if isinstance(plan, dict) else []
        steps: List[str] = [str(s) for s in raw_steps] if raw_steps else [goal]

        log = []
        last_results: List[Dict[str, str]] = []

        # Avoid slice operator for strict linter
        for i in range(min(len(steps), max_steps)):
            step = steps[i]
            kw = step.lower()
            
            # Action selection based on plan step
            if any(w in kw for w in ["search", "find", "look up", "research"]):
                # Extract query
                query = self.ai.ask_question(f"Extract ONLY a search query from this step: '{step}'").strip().strip('"')
                results = search_web(query, 3)
                last_results = results
                snippet = results[0]["snippet"] if results else "No results found."
                log.append({"step": step, "action": f"SEARCH: {query}", "result": snippet})
                
            elif any(w in kw for w in ["browse", "read", "visit", "open"]):
                # Check if last_results is a list before indexing
                url = ""
                if isinstance(last_results, list) and len(last_results) > 0:
                    url = last_results[0].get("url", "")
                content = browse_url(url) if url else "No relevant URL to browse."
                log.append({"step": step, "action": f"BROWSE: {url}", "result": content[:400]})
                
            elif "code" in kw or "calculate" in kw:
                script = self.ai.ask_question(f"Write ONLY the Python code to achieve this step: '{step}'").strip().strip('`').replace('python\n', '')
                res = self.executor.execute(script)
                log.append({"step": step, "action": "CODE", "result": res["output"] if res["success"] else res["error"]})

            else:
                context = "\n".join([f"Result: {e['result']}" for e in log])
                result = self.ai.ask_question(f"Based on research so far:\n{context}\n\nTask: {step}")
                log.append({"step": step, "action": "REASON", "result": result})

        # Synthesize final answer
        final_prompt = (
            f"GOAL: {goal}\n"
            f"RESEARCH LOG:\n{json.dumps(log, indent=2)}\n\n"
            f"Provide a comprehensive, technical, and actionable final report as KALI AI."
        )
        
        answer = self.ai.ask_question(final_prompt)
        
        # Store in long-term memory
        self.memory.remember(f"RESEARCH MISSION: {goal}\nSUMMARY: {answer[:1000]}", "tasks")
        
        return {
            "goal": goal,
            "steps": log,
            "answer": answer
        }
