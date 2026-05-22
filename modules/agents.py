import json
from abc import ABC, abstractmethod
from modules.strategy import StrategyStore

class Agent(ABC):
    @abstractmethod
    def communicate(self, message: dict) -> dict:
        pass

class PlannerAgent(Agent):
    def __init__(self, bridge):
        self.bridge = bridge

    def communicate(self, message: dict) -> dict:
        prompt = message.get("task")
        past_feedback = StrategyStore.get_feedback(prompt)
        enhanced_prompt = prompt
        if past_feedback:
            feedback_str = "\n- ".join(past_feedback)
            enhanced_prompt = f"{prompt}\n\n[PAST STRATEGIC INSIGHTS]:\n- {feedback_str}"
            print(f"[STRATEGY] Planner incorporating {len(past_feedback)} insights (including human feedback).")
            
        plan = self.bridge.planner.generate_plan(enhanced_prompt)
        return {"status": "success", "plan": plan}

class ExecutorAgent(Agent):
    def __init__(self, bridge):
        self.bridge = bridge

    def communicate(self, message: dict) -> dict:
        task = message.get("task")
        workflow_id = message.get("context", {}).get("goal_id")
        step_num = message.get("context", {}).get("step_num")
        result = self.bridge.execute(task, workflow_id=workflow_id, step_num=step_num)
        return result

class MemoryAgent(Agent):
    def __init__(self, bridge):
        self.bridge = bridge

    def communicate(self, message: dict) -> dict:
        from modules.goals import GoalManager
        action = message.get("task", "").lower()
        if "save" in action:
            goal = message.get("context", {}).get("goal")
            GoalManager.save_goal(goal)
            return {"status": "success"}
        elif "load" in action:
            goal_id = message.get("context", {}).get("goal_id")
            goal = GoalManager.load_goal(goal_id)
            return {"status": "success", "goal": goal}
        return {"status": "fail"}

class CriticAgent(Agent):
    def __init__(self, bridge):
        self.bridge = bridge

    def communicate(self, message: dict) -> dict:
        task = message.get("task", {})
        result = message.get("result", {})
        
        if result.get("status") != "success":
            return {
                "accepted": False, 
                "reason": f"Execution failed: {result.get('reason', 'Unknown error')}",
                "confidence": 1.0,
                "quality_score": 0.0
            }
            
        output = str(result.get("output", ""))
        
        evaluation_prompt = f"""
        Evaluate if the output satisfies the task.
        Task: {task.get('input')}
        Output: {output[:800]}
        
        Respond only in JSON: 
        {{
          "accepted": bool, 
          "reason": str, 
          "improvement_advice": str,
          "quality_score": float (0.0 to 1.0),
          "confidence": float (0.0 to 1.0)
        }}
        """
        
        llm = self.bridge.modules.get("llm")
        if not llm:
            accepted = len(output) > 20
            return {
                "accepted": accepted, 
                "reason": "Heuristic check", 
                "improvement_advice": "Provide more detail",
                "quality_score": 0.8 if accepted else 0.3,
                "confidence": 0.5
            }
            
        eval_task = {"type": "llm", "input": evaluation_prompt}
        eval_res = llm.run(eval_task)
        
        try:
            content = eval_res.get("output", "")
            if "{" in content:
                content = content[content.find("{"):content.rfind("}")+1]
            data = json.loads(content)
            # Ensure keys exist
            data.setdefault("quality_score", 0.8 if data.get("accepted") else 0.2)
            data.setdefault("confidence", 0.9)
            return data
        except:
            return {
                "accepted": len(output) > 20, 
                "reason": "Parse error", 
                "improvement_advice": "Ensure valid JSON output",
                "quality_score": 0.5,
                "confidence": 0.3
            }
