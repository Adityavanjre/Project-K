import sys
import io
import traceback
import logging
import multiprocessing
from typing import Dict, Any, Optional

class CodeExecutor:
    """
    KALI's Computational Hub.
    Executes Python code in a semi-sandboxed environment with hard timeouts.
    """
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        self.whitelist_imports = ["math", "json", "datetime", "random", "numpy", "np", "re"]
        # Hardened globals: removed traversal builtins like getattr, hasattr, dir
        self.safe_builtins = {
            "abs": abs, "all": all, "any": any, "bin": bin, "bool": bool,
            "dict": dict, "divmod": divmod, "enumerate": enumerate,
            "filter": filter, "float": float, "format": format,
            "hash": hash, "help": help, "hex": hex, "id": id,
            "int": int, "isinstance": isinstance, "issubclass": issubclass,
            "iter": iter, "len": len, "list": list, "map": map, "max": max,
            "min": min, "next": next, "object": object, "oct": oct, "ord": ord,
            "pow": pow, "print": print, "range": range, "repr": repr, "reversed": reversed,
            "round": round, "set": set, "slice": slice, "sorted": sorted, "str": str,
            "sum": sum, "tuple": tuple, "type": type, "zip": zip,
            "Exception": Exception, "ValueError": ValueError, "TypeError": TypeError,
            "ImportError": ImportError, "StopIteration": StopIteration
        }
        import math
        import json
        import datetime
        import random
        self.safe_libs = {
            "math": math,
            "json": json,
            "datetime": datetime,
            "random": random
        }
        try:
            import numpy as np
            self.safe_libs["np"] = np
        except (ImportError, ModuleNotFoundError):
            pass

    @staticmethod
    def _worker(code, queue, safe_builtins, lib_names):
        """Worker function for subprocess execution."""
        import sys
        import io
        import traceback
        import math
        import json
        import datetime
        import random
        
        stdout_buffer = io.StringIO()
        old_stdout = sys.stdout
        sys.stdout = stdout_buffer
        
        try:
            full_globals = {"__builtins__": safe_builtins}
            
            # Re-import safe libs
            libs = {"math": math, "json": json, "datetime": datetime, "random": random}
            if "np" in lib_names:
                try: import numpy as np; libs["np"] = np
                except: pass
                
            full_globals.update(libs)
            exec(code, full_globals)
            queue.put({"success": True, "output": stdout_buffer.getvalue(), "error": None})
        except Exception:
            queue.put({"success": False, "output": stdout_buffer.getvalue(), "error": traceback.format_exc()})
        finally:
            sys.stdout = old_stdout

    def dry_run_verify(self, code: str) -> Dict[str, Any]:
        """Perform static analysis before execution (Claude-style Safety)."""
        import ast
        try:
            tree = ast.parse(code)
            for node in ast.walk(tree):
                # Block unauthorized imports
                if isinstance(node, (ast.Import, ast.ImportFrom)):
                    for alias in node.names:
                        name = alias.name.split('.')[0]
                        if name not in self.whitelist_imports:
                            return {"success": False, "error": f"SECURITY_VIOLATION: Import '{name}' is not in the Sovereign Whitelist."}
                
                # Block attribute traversal/obfuscation
                if isinstance(node, ast.Attribute):
                    if node.attr.startswith("__"):
                        return {"success": False, "error": f"SECURITY_VIOLATION: Private attribute access detected."}
                
                # Block problematic builtins
                if isinstance(node, ast.Call) and isinstance(node.func, ast.Name):
                    if node.func.id in ["eval", "exec", "getattr", "setattr", "delattr", "hasattr", "open"]:
                         return {"success": False, "error": f"SECURITY_VIOLATION: Restricted builtin '{node.func.id}' detected."}
                         
            return {"success": True, "error": None}
        except SyntaxError as e:
            return {"success": False, "error": f"SYNTAX_ERROR: {e}"}

    def execute(self, code: str, timeout: int = 5) -> Dict[str, Any]:
        """Execute Python code in a separate process with a timeout."""
        # 1. Perform Claude-style Dry Run (Safety first)
        verify = self.dry_run_verify(code)
        if not verify["success"]:
            self.logger.warning(f"KALI blocked unsafe code: {verify['error']}")
            return verify

        self.logger.info(f"KALI executing computational script (Timeout: {timeout}s)...")
        
        import multiprocessing
        queue = multiprocessing.Queue()
        lib_names = list(self.safe_libs.keys())
        process = multiprocessing.Process(target=self._worker, args=(code, queue, self.safe_builtins, lib_names))
        
        try:
            process.start()
            process.join(timeout=timeout)
            
            if process.is_alive():
                process.terminate()
                process.join()
                return {
                    "output": "",
                    "error": f"Execution timed out after {timeout} seconds.",
                    "success": False
                }
            
            if not queue.empty():
                return queue.get()
            
            return {"output": "", "error": "Unknown execution error (No result in queue).", "success": False}
            
        except Exception as e:
            self.logger.error(f"Execution system failure: {e}")
            return {"output": "", "error": str(e), "success": False}

    def solve_complex_problem(self, problem_description: str, code_snippet: str) -> str:
        """KALI wrapper for autonomous problem solving."""
        res = self.execute(code_snippet)
        if res["success"]:
            return f"CODE EXECUTION SUCCESSFUL.\nOUTPUT:\n{res['output']}"
        else:
            return f"CODE EXECUTION FAILED.\nERROR:\n{res['error']}"
