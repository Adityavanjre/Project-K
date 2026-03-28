import os
import logging
import json
from typing import List, Dict, Any
from .evolution_bridge import EvolutionBridge

class AutonomousCoder:
    """
    Phase 4.14: The Sovereign Autonomous Coder.
    Bridges the gap between the Commander's high-level intent and the 
    technical implementation of self-evolution.
    """
    def __init__(self, processor):
        self.processor = processor
        self.bridge = processor.evolution_bridge
        self.ai_service = processor.ai_service
        self.logger = logging.getLogger("AutonomousCoder")

    def execute_mission(self, goal: str) -> Dict[str, Any]:
        """
        Takes a high-level mission goal (e.g. "Optimize the memory engine")
        and autonomously implements the changes.
        """
        self.logger.info(f"MISSION_START: {goal}")
        
        # 1. Analyze the Mission (Identify files to change)
        analysis_prompt = f"""
        You are KALI, an autonomous Sovereign AI.
        Commander Request: "{goal}"
        
        Analyze your current project structure and identify which files in 'src/core/' 
        need to be modified to fulfill this request.
        
        Return ONLY a JSON array of strings representing the relative file paths.
        Example: ["src/core/memory.py", "src/core/processor.py"]
        """
        
        try:
            raw_analysis = self.ai_service.ask_question(analysis_prompt)
            # Clean JSON
            json_str = raw_analysis.strip()
            if "```json" in json_str:
                json_str = json_str.split("```json")[1].split("```")[0].strip()
            elif "```" in json_str:
                json_str = json_str.split("```")[1].split("```")[0].strip()
            
            target_files = json.loads(json_str)
            self.logger.info(f"MISSION_PLAN: Identified {len(target_files)} files for evolution.")

            results = []
            for file_path in target_files:
                # 2. Execute Evolution per file
                self.logger.info(f"MISSION_EXECUTION: Evolving {file_path} for mission: {goal}")
                res = self.bridge.evolve_file(file_path, f"Modify this file to support the goal: {goal}")
                results.append(res)
                
                if not res["success"]:
                    self.logger.error(f"MISSION_FAILED: Aborting mission at {file_path} due to error: {res.get('error')}")
                    break

            # 3. Final Summary
            success_count = sum(1 for r in results if r["success"])
            return {
                "success": success_count == len(target_files),
                "goal": goal,
                "files_processed": len(target_files),
                "success_count": success_count,
                "details": results
            }

        except Exception as e:
            self.logger.error(f"MISSION_CRITICAL_FAIL: {e}")
            return {"success": False, "error": str(e)}
