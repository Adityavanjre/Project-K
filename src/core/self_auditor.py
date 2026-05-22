import os
import re
import json
from datetime import datetime

class SelfAuditor:
    """
    KALI Self-Auditor (Python Core)
    Enforces 'Codebase Purification' before training cycles.
    """
    def __init__(self):
        self.scan_dirs = [
            os.path.join("src", "core"),
            os.path.join("modules"),
            os.path.join("src", "static", "js")
        ]
        self.rules = [
            {
                "name": "HARDCODED_PATTERN",
                "regex": r"(https?://[^\s'\"]+)|(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})",
                "severity": "high",
                "message": "Hardcoded external IP or URL detected. Move to Sovereign Registry (config.json)."
            },
            {
                "name": "MOCK_SYSTEM_FALLBACK",
                "regex": r"return\s+.*mock.*|callback\(.*mock.*\)|res\.send\(.*mock.*\)|simulation_mode",
                "severity": "critical",
                "message": "Active mock fallback or simulation string detected."
            }
        ]
        self.exclude_files = ["config.json", "config_manager.py", "audit_report.json"]

    def run_audit(self):
        print("[AUDITOR] Initiating codebase purification scan...")
        report = {"timestamp": datetime.now().isoformat(), "issues": []}

        for directory in self.scan_dirs:
            if os.path.exists(directory):
                self._scan_directory(directory, report)

        # Persistence
        report_path = os.path.join("data", "audit_report.json")
        with open(report_path, "w") as f:
            json.dump(report, f, indent=4)
            
        return report

    def _scan_directory(self, directory, report):
        for root, _, files in os.walk(directory):
            for file in files:
                if file.endswith(('.js', '.py')):
                    self._analyze_file(os.path.join(root, file), report)

    def _analyze_file(self, file_path, report):
        # 🔱 ARCHITECTURAL PROTECTION: Exclude core configuration and the auditor itself
        excluded = ["config.json", "self_auditor.py", ".claude", "logs", "data", "scratch"]
        if any(ex in file_path for ex in excluded):
            return True
            
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                lines = f.readlines()
                for idx, line in enumerate(lines):
                    for rule in self.rules:
                        if re.search(rule["regex"], line, re.IGNORECASE):
                            report["issues"].append({
                                "file": os.path.relpath(file_path),
                                "line": idx + 1,
                                "rule": rule["name"],
                                "severity": rule["severity"],
                                "message": rule["message"],
                                "snippet": line.strip()
                            })
        except Exception as e:
            print(f"[AUDITOR] Failed to analyze {file_path}: {e}")
