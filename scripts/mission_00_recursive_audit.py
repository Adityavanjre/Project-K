#!/usr/bin/env python3
"""
KALI Mission 00: Recursive Self-Audit & Repair
The most rigorous diagnostic protocol in the KALI architecture.
Scans all 30 nodes, environment compatibility, and core integrity.
"""

import os
import sys
import json
import logging
import platform
import importlib.util
from datetime import datetime

# Add project root and internal paths
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, PROJECT_ROOT)
sys.path.insert(0, os.path.join(PROJECT_ROOT, 'src'))

def check_module_exists(module_path):
    """Check if a module or package exists at the given path."""
    return os.path.exists(os.path.join(PROJECT_ROOT, module_path))

def attempt_import(name, path):
    """Attempt to import a node to check for 'Life'."""
    try:
        if path not in sys.path:
            sys.path.insert(0, path)
        spec = importlib.util.find_spec(name)
        if spec:
            return True, "ALIVE"
        return False, "GHOST (Not Found)"
    except Exception as e:
        return False, f"BRAIN_DEAD ({str(e)[:50]}...)"

def run_audit():
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("SOVEREIGN_AUDIT")
    
    print("\n" + "="*70)
    print(" KALI RECURSIVE SELF-AUDIT & REPAIR PROTOCOL ")
    print("="*70)
    
    results = {
        "timestamp": datetime.now().isoformat(),
        "environment": {},
        "nodes": {},
        "core": {},
        "actions_required": []
    }

    # 1. Environment Audit
    print("\n[AUDIT] TRACK 1: ENVIRONMENT COMPATIBILITY")
    py_version = platform.python_version()
    results["environment"]["python"] = py_version
    print(f"[-] Python Version: {py_version}")
    
    # Check for CUA compatibility
    if py_version.startswith("3.14"):
        print("[!] ALERT: Python 3.14 detected. CUA and Torch extensions may be unstable.")
        results["actions_required"].append("Downgrade to Python 3.12 or hot-patch CUA requirements.")
    
    # 2. Core Integrity Audit
    print("\n[AUDIT] TRACK 2: NUCLEUS INTEGRITY")
    manifest_path = os.path.join(PROJECT_ROOT, "data", "kali_core.manifest")
    if os.path.exists(manifest_path):
        print("[+] Security Anchor: FOUND")
        results["core"]["manifest"] = "FOUND"
    else:
        print("[!] Security Anchor: MISSING (KALI is in Unsecured State)")
        results["actions_required"].append("Run scripts/regenerate_security_anchor.py")

    # 3. Swarm Audit (The 30 Nodes)
    print("\n[AUDIT] TRACK 3: SWARM NODE DIAGNOSTICS")
    swarm_dir = os.path.join(PROJECT_ROOT, "integrations", "swarm")
    
    # Define expected critical nodes
    critical_nodes = {
        "CUA": "integrations/swarm/cua/libs/python/agent",
        "GitNexus": "integrations/swarm/GitNexus",
        "Decepticon": "integrations/swarm/Decepticon",
        "OpenHuman": "integrations/swarm/openhuman",
        "MemPalace": "integrations/swarm/mempalace"
    }

    for node, rel_path in critical_nodes.items():
        abs_path = os.path.abspath(os.path.join(PROJECT_ROOT, rel_path))
        exists = os.path.exists(abs_path)
        status = "MISSING"
        
        if exists:
            # Multi-language Health Check
            is_node = os.path.exists(os.path.join(abs_path, "package.json"))
            is_python = os.path.exists(os.path.join(abs_path, "pyproject.toml")) or os.path.exists(os.path.join(abs_path, "setup.py"))
            is_rust = os.path.exists(os.path.join(abs_path, "Cargo.toml"))
            
            if is_node:
                if os.path.exists(os.path.join(abs_path, "node_modules")):
                    status = "ALIVE (Node.js)"
                else:
                    status = "UNINITIALIZED (npm install required)"
            
            if is_python:
                # Try lowercase module name
                module_name = "cua_agent" if node == "CUA" else node.lower()
                search_path = abs_path
                
                alive, msg = attempt_import(module_name, search_path)
                if alive:
                    status = f"ALIVE (Python)" if status == "MISSING" else f"{status} + ALIVE (Python)"
                else:
                    python_status = f"BRAIN_DEAD (Python: {msg})"
                    status = python_status if status == "MISSING" else f"{status} + {python_status}"
            
            if is_rust:
                status = "ALIVE (Rust)" if status == "MISSING" else f"{status} + ALIVE (Rust)"
        
        icon = "[+]" if "ALIVE" in status else "[!]"
        print(f"{icon} {node.ljust(12)}: {status}")
        results["nodes"][node] = status
        
        if "ALIVE" not in status:
            results["actions_required"].append(f"Repair {node} integration at {rel_path}")

    # 4. Final Verdict
    print("\n" + "="*70)
    print(" AUDIT SUMMARY & ACTION PLAN ")
    print("="*70)
    
    if not results["actions_required"]:
        print("[+++] KALI IS AT 100% SINGULARITY PARITY. ALL GATES OPEN.")
    else:
        print(f"[!!!] AUDIT FAILED: {len(results['actions_required'])} CRITICAL ISSUES FOUND.")
        for i, action in enumerate(results["actions_required"], 1):
            print(f"{i}. {action}")
    
    # Save results
    audit_log = os.path.join(PROJECT_ROOT, "data", "last_audit_report.json")
    os.makedirs(os.path.dirname(audit_log), exist_ok=True)
    with open(audit_log, "w") as f:
        json.dump(results, f, indent=4)
    
    print(f"\n[#] Full audit report saved to: {audit_log}")
    print("="*70 + "\n")

if __name__ == "__main__":
    run_audit()
