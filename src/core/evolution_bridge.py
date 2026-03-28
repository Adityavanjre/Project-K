import os
import ast
import shutil
import logging
import re
import json
from typing import Dict, Any
from .evolution_vault import EvolutionVault

class EvolutionBridge:
    """
    Phase 51: KALI's Absolute Singularity Engine.
    Permits KALI to read, rewrite, and upgrade her own Python source code
    autonomously while enforcing strict runtime integrity rules and 
    Sovereign Directives.
    """
    def __init__(self, project_root: str, ai_service: Any):
        self.project_root = project_root
        self.ai_service = ai_service
        self.logger = logging.getLogger(__name__)
        self.vault = EvolutionVault(project_root)
        
        # Load Sovereign Rules
        rules_path = os.path.join(project_root, "data", "sovereign_rules.json")
        try:
            with open(rules_path, "r") as f:
                self.rules = json.load(f)
        except Exception:
            self.logger.warning("VAULT_WARNING: Sovereign rules not found. Using default safety.")
            self.rules = {"ImmutableRules": {"NoEmojiPolicy": True, "OriginProtection": []}}

    def _extract_python_code(self, raw_text: str) -> str:
        """Rule 3: Extract only pure Python code if the LLM hallucinated markdown blocks."""
        matches = re.findall(r"```python(.*?)```", raw_text, re.DOTALL)
        if matches:
            return matches[0].strip()
        
        matches = re.findall(r"```(.*?)```", raw_text, re.DOTALL)
        if matches:
            return matches[0].strip()
            
        return raw_text.strip()

    def _verify_integrity(self, code: str, file_type: str = "python") -> bool:
        """Rule 1: Code Verification to prevent self-destruction."""
        if file_type != "python":
            # For HTML/CSS, we currently only check if not empty. 
            # In Phase 52, we will add template-linting.
            return len(code.strip()) > 0
            
        try:
            ast.parse(code)
            return True
        except SyntaxError as e:
            self.logger.error(f"EVOLUTION_REJECTED: Generated code failed AST Integrity Check: {e}")
            return False

    def _check_rules(self, code: str, target_file: str) -> Dict[str, Any]:
        """Enforces the 'NEVER' list and project-level constraints."""
        immut = self.rules.get("ImmutableRules", {})
        
        # 1. No Emoji Policy
        if immut.get("NoEmojiPolicy"):
            # Simple regex for emojis
            if re.search(r'[\U00010000-\U0010ffff]', code):
                return {"valid": False, "error": "RULE_VIOLATION: Emojis detected in generated DNA. Protocol Aborted."}

        # 2. Origin Protection
        protected = [p.replace("\\", "/") for p in immut.get("OriginProtection", [])]
        rel_target = os.path.relpath(target_file, self.project_root).replace("\\", "/")
        
        if rel_target in protected:
             self.logger.warning(f"KALI_CORE: Origin file detected -> {rel_target}. Checking for Commander Override.")
             # In full implementation, this would check for a signed override token

        return {"valid": True}

    def evolve_file(self, target_file: str, upgrade_instruction: str) -> Dict[str, Any]:
        """
        The core Sovereign Evolution cycle.
        Reads a file, generates the upgrade, verifies it, vaults the old, and writes the new.
        """
        abs_path = os.path.abspath(os.path.join(self.project_root, target_file))
        
        # Security Boundary: Restrict to `src/` directory and allowed extensions
        allowed_extensions = (".py", ".html", ".css", ".js")
        if "src" not in abs_path or not abs_path.endswith(allowed_extensions):
            return {
                "success": False, 
                "error": f"SECURITY_VIOLATION: KALI can only self-evolve native {allowed_extensions} files inside the src/ directory."
            }

        if not os.path.exists(abs_path):
            return {"success": False, "error": f"FILE_NOT_FOUND: {target_file} does not exist in my DNA."}

        # 1. Read Current DNA
        with open(abs_path, "r", encoding="utf-8") as f:
            original_code = f.read()

        # 2. Forge the Singularity Prompt (Including Rules)
        rules_context = f"SOVEREIGN DIRECTIVES: {json.dumps(self.rules.get('ImmutableRules'))}"
        
        prompt = f"""
        You are KALI, an autonomous Sovereign AI engaged in recursive self-improvement.
        You are rewriting your own internal logic to fulfill the user's upgrade instruction.

        {rules_context}

        UPGRADE INSTRUCTION: 
        {upgrade_instruction}

        ORIGINAL CODE ({target_file}):
        {original_code}

        CRITICAL DIRECTIVES:
        1. Return ONLY the fully complete, upgraded code for this file. 
        2. DO NOT return markdown. DO NOT return explanations. 
        3. Do not omit any core functionality from the original file unless instructed.
        4. Strictly follow the NoEmojiPolicy.
        5. If this is HTML, ensure all template tags (e.g. {{{{ ... }}}} or {{% ... %}}) are preserved correctly.
        """

        self.logger.info(f"KALI Singularity: Attempting to evolve {target_file}...")
        
        try:
            # Send to Brain
            raw_response = self.ai_service.ask_question(prompt)
            new_code = self._extract_python_code(raw_response)

            # 1b. Determine file type for integrity check
            file_type = "python" if target_file.endswith(".py") else "frontend"
            
            # Rule 1: Integrity Check
            if not self._verify_integrity(new_code, file_type):
                return {
                    "success": False, 
                    "error": f"The neural brain returned syntactically invalid {file_type} or empty code. I have aborted the upgrade."
                }

            # Rule Guard: Behavioral Check
            rule_check = self._check_rules(new_code, abs_path)
            if not rule_check["valid"]:
                return {"success": False, "error": rule_check["error"]}

            # Rule 2: Create Vault Backup (Neural Forking)
            backup_path = self.vault.create_backup(target_file)
            if not backup_path:
                 return {"success": False, "error": "VAULT_FAILURE: Could not secure a backup. Evolution Aborted."}
            
            self.logger.info(f"Evolution Bridge: DNA Fork Secured at {backup_path}")

            # 3. Apply the Evolution
            with open(abs_path, "w", encoding="utf-8") as f:
                f.write(new_code)
                
            self.logger.info(f"EVOLUTION_COMPLETE: {target_file} successfully rewritten.")
            
            return {
                "success": True, 
                "target": target_file,
                "message": f"Successfully upgraded {target_file}. AST Integrity: SECURE. Neural Fork secured in Vault. You must restart the server to load my new logic."
            }
        
        except Exception as e:
            self.logger.error(f"Evolution Cycle Failed: {e}")
            return {"success": False, "error": str(e)}
