import sys
import io
import traceback
import logging
import multiprocessing
from typing import Dict, Any, Optional

class CodeExecutor:
    """
    KALI's Computational Hub.
    Executes Python code in a semi-sandboxed environment.
    """
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        # Restricted globals to prevent basic malicious acts
        self.safe_globals = {
            "__builtins__": {
                "abs": abs, "all": all, "any": any, "bin": bin, "bool": bool,
                "dict": dict, "dir": dir, "divmod": divmod, "enumerate": enumerate,
                "filter": filter, "float": float, "format": format, "getattr": getattr,
                "hasattr": hasattr, "hash": hash, "help": help, "hex": hex, "id": id,
                "int": int, "isinstance": isinstance, "issubclass": issubclass,
                "iter": iter, "len": len, "list": list, "map": map, "max": max,
                "min": min, "next": next, "object": object, "oct": oct, "ord": ord,
                "pow": pow, "print": print, "range": range, "repr": repr, "reversed": reversed,
                "round": round, "set": set, "slice": slice, "sorted": sorted, "str": str,
                "sum": sum, "tuple": tuple, "type": type, "zip": zip,
                "Exception": Exception, "ValueError": ValueError, "TypeError": TypeError,
                "ImportError": ImportError, "StopIteration": StopIteration
            },
            "math": __import__("math"),
            "json": __import__("json"),
            "datetime": __import__("datetime"),
            "random": __import__("random"),
            "numpy": None # Placeholder for heavy numerical work if installed
        }
        try:
            import numpy as np
            self.safe_globals["np"] = np
        except ImportError:
            pass

    def execute(self, code: str, timeout: int = 5) -> Dict[str, Any]:
        """Execute Python code and capture output."""
        self.logger.info("KALI executing computational script...")
        
        # Use a string buffer to capture stdout
        stdout_buffer = io.StringIO()
        stderr_buffer = io.StringIO()
        
        old_stdout = sys.stdout
        old_stderr = sys.stderr
        
        result = {
            "output": "",
            "error": None,
            "success": False
        }
        
        try:
            sys.stdout = stdout_buffer
            sys.stderr = stderr_buffer
            
            # Executing in restricted globals
            # Note: This is NOT a 100% secure sandbox (Python's exec is hard to fully secure)
            # but it prevents accidental system damage and simple escapes.
            exec(code, self.safe_globals)
            
            result["success"] = True
            result["output"] = stdout_buffer.getvalue()
            
        except Exception as e:
            result["success"] = False
            result["error"] = traceback.format_exc()
            result["output"] = stdout_buffer.getvalue() + "\n" + stderr_buffer.getvalue()
            
        finally:
            sys.stdout = old_stdout
            sys.stderr = old_stderr
            
        return result

    def solve_complex_problem(self, problem_description: str, code_snippet: str) -> str:
        """KALI wrapper for autonomous problem solving."""
        res = self.execute(code_snippet)
        if res["success"]:
            return f"CODE EXECUTION SUCCESSFUL.\nOUTPUT:\n{res['output']}"
        else:
            return f"CODE EXECUTION FAILED.\nERROR:\n{res['error']}"
