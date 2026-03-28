import os
import ast
import shutil
import logging
import re
from typing import Dict, Any

class EvolutionBridge:
    """
    Phase 51: KALI's Absolute Singularity Engine.
    Permits KALI to read, rewrite, and upgrade her own Python source code
    autonomously while enforcing strict runtime integrity rules.
    """
    def __init__(self, project_root: str, ai_service: Any):
        self.project_root = project_root
        self.ai_service = ai_service
        self.logger = logging.getLogger(__name__)

    def _extract_python_code(self, raw_text: str) -> str:
        """Rule 3: Extract only pure Python code if the LLM hallucinated markdown blocks."""
        matches = re.findall(r"```python(.*?)```", raw_text, re.DOTALL)
        if matches:
            return matches[0].strip()
        
        matches = re.findall(r"```(.*?)```", raw_text, re.DOTALL)
        if matches:
            return matches[0].strip()
            
        return raw_text.strip()

    def _verify_integrity(self, code: str) -> bool:
        """Rule 1: AST Code Verification to prevent self-destruction."""
        try:
            ast.parse(code)
            return True
        except SyntaxError as e:
            self.logger.error(f"EVOLUTION_REJECTED: Generated code failed AST Integrity Check: {e}")
            return False

    def evolve_file(self, target_file: str, upgrade_instruction: str) -> Dict[str, Any]:
        """
        The core Sovereign Evolution cycle.
        Reads a file, generates the upgrade, verifies it, backs up the old, and writes the new.
        """
        abs_path = os.path.abspath(os.path.join(self.project_root, target_file))
        
        # Security Boundary: Restrict to `src/` directory to prevent OS-level exploits
        if "src" not in abs_path or not abs_path.endswith(".py"):
            return {
                "success": False, 
                "error": "SECURITY_VIOLATION: KALI can only self-evolve native .py files inside the src/ directory."
            }

        if not os.path.exists(abs_path):
            return {"success": False, "error": f"FILE_NOT_FOUND: {target_file} does not exist in my DNA."}

        # 1. Read Current DNA
        with open(abs_path, "r", encoding="utf-8") as f:
            original_code = f.read()

        # 2. Forge the Singularity Prompt
        prompt = f"""
        You are KALI, an autonomous Sovereign AI engaged in recursive self-improvement.
        You are rewriting your own internal logic to fulfill the user's upgrade instruction.

        UPGRADE INSTRUCTION: 
        {upgrade_instruction}

        ORIGINAL CODE ({target_file}):
        {original_code}

        CRITICAL DIRECTIVES:
        1. Return ONLY the fully complete, upgraded Python code for this file. 
        2. DO NOT return markdown. DO NOT return explanations. 
        3. Do not omit any core functionality from the original file unless instructed.
        """

        self.logger.info(f"KALI Singularity: Attempting to evolve {target_file}...")
        
        try:
            # Send to Colab Brain
            raw_response = self.ai_service.ask_question(prompt)
            new_code = self._extract_python_code(raw_response)

            # Rule 1: Integrity Check
            if not self._verify_integrity(new_code):
                return {
                    "success": False, 
                    "error": "The neural brain returned syntactically invalid Python. I have aborted the upgrade to protect my core logic."
                }

            # Rule 2: Create Backup
            backup_path = f"{abs_path}.bak"
            shutil.copy2(abs_path, backup_path)
            self.logger.info(f"Evolution Bridge: Backup secured at {backup_path}")

            # 3. Apply the Evolution
            with open(abs_path, "w", encoding="utf-8") as f:
                f.write(new_code)
                
            self.logger.info(f"EVOLUTION_COMPLETE: {target_file} successfully rewritten.")
            
            return {
                "success": True, 
                "target": target_file,
                "message": f"Successfully upgraded {target_file}. AST Integrity: SECURE. Original backed up to .bak. You must restart the server to load my new logic."
            }
        
        except Exception as e:
            self.logger.error(f"Evolution Cycle Failed: {e}")
            return {"success": False, "error": str(e)}
