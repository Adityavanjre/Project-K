"""
THE MANIFESTOR
KALI Phase 33.1: Physical Task Manifestation
Handles creation of project structures, templates, and scaffolding.
"""

import os
import shutil
import logging
from typing import Dict, List, Any, Optional

class Manifestor:
    """Bridges the gap between AI architectural plans and physical disk reality."""
    
    def __init__(self, base_path: str = "d:/code/kali_manifest"):
        self.base_path = base_path
        self.logger = logging.getLogger(__name__)
        self._ensure_base()
        
    def _ensure_base(self):
        if not os.path.exists(self.base_path):
            os.makedirs(self.base_path)
            self.logger.info(f"Manifest base created at {self.base_path}")

    def manifest_project(self, name: str, structure: Dict[str, Any]) -> Dict[str, Any]:
        """
        Recursively creates a project structure.
        Structure format: {"filename": "content"} or {"dirname": {"filename": "content"}}
        """
        project_path = os.path.join(self.base_path, name)
        results = {"created": [], "errors": []}
        
        try:
            if not os.path.exists(project_path):
                os.makedirs(project_path)
            
            self._create_recursive(project_path, structure, results)
            return {"status": "SUCCESS", "path": project_path, "files": results["created"]}
            
        except Exception as e:
            self.logger.error(f"Manifestation failed for {name}: {e}")
            return {"status": "FAILED", "error": str(e)}

    def _create_recursive(self, current_path: str, structure: Dict[str, Any], results: Dict):
        for key, value in structure.items():
            path = os.path.join(current_path, key)
            
            if isinstance(value, dict):
                # Directory
                if not os.path.exists(path):
                    os.makedirs(path)
                self._create_recursive(path, value, results)
            else:
                # File
                try:
                    with open(path, "w", encoding="utf-8") as f:
                        f.write(value)
                    results["created"].append(path)
                except Exception as e:
                    results["errors"].append(f"{path}: {str(e)}")

    def clean_manifest(self, name: str):
        """Removes a manifested project."""
        project_path = os.path.join(self.base_path, name)
        if os.path.exists(project_path):
            shutil.rmtree(project_path)
            return True
        return False

if __name__ == "__main__":
    # Test Manifestation
    m = Manifestor()
    test_struct = {
        "index.html": "<html><body><h1>KALI TEST</h1></body></html>",
        "js": {
            "main.js": "console.log('KALI ONLINE');"
        },
        "css": {
            "style.css": "body { background: black; color: cyan; }"
        }
    }
    res = m.manifest_project("test_alpha", test_struct)
    print(res)
