import json

class TaskPlanner:
    def __init__(self, bridge):
        self.bridge = bridge

    def generate_plan(self, prompt: str) -> list:
        """
        Phase 4.5: Planning by CAPABILITIES.
        """
        caps = set()
        for mod in self.bridge.modules.values():
            caps.update(mod.metadata.get("capabilities", []))
        
        caps_str = ", ".join(sorted(list(caps)))
        
        # Escaping curly braces for f-string
        system_prompt = f"""
        You are the KALI Orchestration Planner. Decompose the user directive into a multi-step execution plan.
        
        AVAILABLE CAPABILITIES:
        {caps_str}
        
        RULES:
        1. Max 3 steps.
        2. Use JSON format: [{{"type": "capability_name", "input": "detailed instruction", "output_key": "optional_key"}}]
        3. Use capabilities (e.g., 'code_edit', 'vcs', 'reasoning', 'storage') as the 'type'.
        4. If a step depends on a previous output, use {{key_name}} in the input.
        """
        
        task = {
            "type": "llm",
            "input": f"Directive: {prompt}",
            "context": {"system_prompt": system_prompt}
        }
        
        llm = self.bridge.modules.get("llm")
        if not llm: return [{"type": "llm", "input": prompt}]
            
        response = llm.run(task)
        
        try:
            content = response.get("output", "[]")
            if "```json" in content:
                content = content.split("```json")[1].split("```")[0].strip()
            elif "```" in content:
                content = content.split("```")[1].split("```")[0].strip()
            
            plan = json.loads(content)
            return plan if isinstance(plan, list) else []
        except:
            return [{"type": "llm", "input": prompt}]
