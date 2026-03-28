import json
import hashlib
import subprocess
import tempfile
import sys
from datetime import datetime
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
        self.proposals_dir = os.path.join(project_root, "data", "proposals")
        os.makedirs(self.proposals_dir, exist_ok=True)
        
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

        # 2. Phase 52: Dangerous Code Pattern Check (Anti-RCE)
        dangerous_patterns = [
            r"os\.system\(", r"subprocess\.", r"exec\(", r"eval\(", 
            r"__import__", r"getattr\(.*?,\s*['\"]", r"__builtin__",
            r"open\(.*?,.*?[wa]\+?['\"]", r"shutil\.rmtree"
        ]
        for pattern in dangerous_patterns:
            if re.search(pattern, code):
                self.logger.error(f"SECURITY_REJECTED: Dangerous code pattern detected: {pattern}")
                return {"valid": False, "error": f"SECURITY_VIOLATION: KALI detected a dangerous code pattern in the proposal. Evolutionary path blocked."}

        # 3. Phase 53: Mutation Scope Fence (E-2)
        # Critical security files are immutable even if an evolution is valid
        mutation_blocklist = [
            "src/core/secure_boot.py",
            "src/core/integrity.py",
            "src/core/auth.py",
            "src/core/evolution_bridge.py"
        ]
        
        rel_target = os.path.relpath(target_file, self.project_root).replace("\\", "/")
        if rel_target in mutation_blocklist:
            self.logger.error(f"FENCE_VIOLATION: Attempted mutation of critical security file: {rel_target}")
            return {"valid": False, "error": f"FENCE_VIOLATION: {rel_path} is an IMMUTABLE security core file. Mutation blocked."}

        # 4. Origin Protection
        protected = [p.replace("\\", "/") for p in immut.get("OriginProtection", [])]
        rel_target = os.path.relpath(target_file, self.project_root).replace("\\", "/")
        
        if rel_target in protected:
             self.logger.warning(f"KALI_CORE: Origin file detected -> {rel_target}. Checking for Commander Override.")
             # In full implementation, this would check for a signed override token

        return {"valid": True}

            
    def _run_sandbox_test(self, code: str, target_file: str) -> Dict[str, Any]:
        """
        Phase 53: Enhanced Evolution Sandbox (G-1).
        Creates an isolated temporary workspace, injects the new DNA, 
        and runs the existing test suite to detect regressions.
        """
        self.logger.info(f"SANDBOX: Initializing isolated test gate for {target_file}...")
        
        with tempfile.TemporaryDirectory() as temp_dir:
            # 1. Setup Sandbox Workspace
            sandbox_src = os.path.join(temp_dir, "src")
            sandbox_tests = os.path.join(temp_dir, "tests")
            
            try:
                # Copy current environment
                shutil.copytree(os.path.join(self.project_root, "src"), sandbox_src)
                shutil.copytree(os.path.join(self.project_root, "tests"), sandbox_tests)
                
                # 2. Inject Proposal into Sandbox
                rel_target = os.path.relpath(target_file, self.project_root) if os.path.isabs(target_file) else target_file
                sandbox_target_path = os.path.join(temp_dir, rel_target)
                
                # Ensure the path exists in sandbox
                os.makedirs(os.path.dirname(sandbox_target_path), exist_ok=True)
                with open(sandbox_target_path, "w", encoding="utf-8") as f:
                    f.write(code)
                
                # 3. Execution Phase: Run Pytest
                self.logger.info(f"SANDBOX: Running pytest in {temp_dir}...")
                
                env = os.environ.copy()
                env["PYTHONPATH"] = f"{temp_dir}{os.pathsep}{env.get('PYTHONPATH', '')}"
                
                process = subprocess.run(
                    [sys.executable, "-m", "pytest", sandbox_tests, "-v", "--tb=short"],
                    cwd=temp_dir,
                    capture_output=True,
                    text=True,
                    timeout=60,
                    env=env
                )
                
                logs = f"STDOUT:\n{process.stdout}\n\nSTDERR:\n{process.stderr}"
                
                if process.returncode == 0:
                    self.logger.info("SANDBOX_SUCCESS: Evolution proposal passed verification.")
                    return {"valid": True, "logs": logs}
                else:
                    self.logger.error("SANDBOX_FAIL: Evolution proposal failed tests.")
                    return {"valid": False, "error": "Evolution proposal failed functional verification.", "logs": logs}
                    
            except subprocess.TimeoutExpired:
                 return {"valid": False, "error": "SANDBOX_TIMEOUT: The proposal caused an infinite loop."}
            except Exception as e:
                self.logger.error(f"SANDBOX_ERROR: Failure during workspace setup: {e}")
                return {"valid": False, "error": f"SANDBOX_ERROR: {str(e)}"}

    def _generate_diff(self, original: str, new: str) -> str:
        """Calculate a unified diff for user review."""
        import difflib
        diff = difflib.unified_diff(
            original.splitlines(keepends=True),
            new.splitlines(keepends=True),
            fromfile="original",
            tofile="proposed"
        )
        return "".join(diff)

    def propose_evolution(self, target_file: str, upgrade_instruction: str) -> Dict[str, Any]:
        """
        Stage 1: Generates a proposal and validates it in the sandbox.
        """
        abs_path = os.path.abspath(os.path.join(self.project_root, target_file))
        allowed_extensions = (".py", ".html", ".css", ".js")
        
        if "src" not in abs_path or not abs_path.endswith(allowed_extensions):
             return {"success": False, "error": "ZONE_VIOLATION: KALI can only propose changes within src/"}

        if not os.path.exists(abs_path):
            return {"success": False, "error": "FILE_NOT_FOUND"}

        with open(abs_path, "r", encoding="utf-8") as f:
            original_code = f.read()

        rules_context = f"SOVEREIGN DIRECTIVES: {json.dumps(self.rules.get('ImmutableRules'))}"
        prompt = f"REWRITE THIS FILE: {target_file}\nINSTRUCTION: {upgrade_instruction}\nRULES: {rules_context}\nCODE:\n{original_code}"
        
        try:
            raw_response = self.ai_service.ask_question(prompt)
            new_code = self._extract_python_code(raw_response)
            
            if not self._verify_integrity(new_code):
                 return {"success": False, "error": "AST_INTEGRITY_FAIL"}

            rule_check = self._check_rules(new_code, abs_path)
            if not rule_check["valid"]:
                return {"success": False, "error": rule_check["error"]}

            sandbox_check = self._run_sandbox_test(new_code, target_file)
            if not sandbox_check["valid"]:
                return {
                    "success": False, 
                    "error": sandbox_check["error"],
                    "sandbox_logs": sandbox_check.get("logs", "")
                }

            diff = self._generate_diff(original_code, new_code)
            
            proposal_id = hashlib.sha256(f"{target_file}_{datetime.now()}".encode()).hexdigest()[:12]
            proposal_data = {
                "id": proposal_id,
                "target": target_file,
                "instruction": upgrade_instruction,
                "proposed_code": new_code,
                "diff": diff,
                "timestamp": datetime.now().isoformat(),
                "status": "PENDING",
                "sandbox_report": "PASSED",
                "sandbox_logs": sandbox_check.get("logs", "")
            }
            
            with open(os.path.join(self.proposals_dir, f"{proposal_id}.json"), "w") as f:
                json.dump(proposal_data, f, indent=4)

            return {
                "success": True,
                "proposal_id": proposal_id,
                "diff": diff,
                "message": "PROPOSAL_GENERATED: Evolution passed sandbox and is pending confirmation."
            }
        except Exception as e:
            return {"success": False, "error": str(e)}

    def confirm_evolution(self, proposal_id: str) -> Dict[str, Any]:
        """Stage 2: Applies a confirmed proposal to the source code."""
        proposal_path = os.path.join(self.proposals_dir, f"{proposal_id}.json")
        if not os.path.exists(proposal_path):
            return {"success": False, "error": "PROPOSAL_NOT_FOUND"}

        with open(proposal_path, "r") as f:
            proposal = json.load(f)

        target_file = proposal["target"]
        new_code = proposal["proposed_code"]
        abs_path = os.path.abspath(os.path.join(self.project_root, target_file))

        self.vault.create_backup(target_file)
        
        with open(abs_path, "w", encoding="utf-8") as f:
            f.write(new_code)

        proposal["status"] = "APPLIED"
        with open(proposal_path, "w") as f:
            json.dump(proposal, f, indent=4)

        return {"success": True, "message": f"EVOLUTION_COMMITTED: {target_file} upgraded."}

    def evolve_file(self, target_file: str, upgrade_instruction: str) -> Dict[str, Any]:
        """DEPRECATED: Redirecting to proposal workflow in Phase 53."""
        return self.propose_evolution(target_file, upgrade_instruction)
