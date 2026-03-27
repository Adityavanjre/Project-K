#!/usr/bin/env python3
import re
import logging
import os
import sys

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_dependency_grapher():
    """
    KALI DEPENDENCY GRAPHING (Vector 13)
    Analyzes imports to understand module relationships.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("DEP_GRAPHER")
    processor = DoubtProcessor()
    
    logger.info("🕸️  KALI Dependency Graphing: Mapping module topology...")
    
    src_dir = os.path.join(project_root, "src", "core")
    dependencies = {}
    
    for f in os.listdir(src_dir):
        if f.endswith(".py"):
            with open(os.path.join(src_dir, f), "r", encoding="utf-8") as file:
                content = file.read()
                imports = re.findall(r"from \.([\w_]+) import", content)
                dependencies[f] = list(set(imports))
                
    dep_str = json.dumps(dependencies, indent=2)
    
    analysis = processor.ai_service.ask_question(
        f"You are the KALI SYSTEMS ENGINEER. Analyze this dependency map for potential circularity or architectural optimization:\n"
        f"MAP:\n{dep_str}"
    )
    
    # Log to training data
    processor.training_logger.log("Dependency Analysis", analysis)
    logger.info("[+] Dependency Interaction Anchored.")

if __name__ == "__main__":
    import json
    run_dependency_graphing()
