import os
import json
import logging
import subprocess
import socket
from datetime import datetime

class KALI_AuditRecon:
    def __init__(self, target_url, project_root):
        # Strip protocol for socket checks
        self.target = target_url.replace("https://", "").replace("http://", "").split("/")[0]
        self.project_root = project_root
        self.checkpoint_file = os.path.join(project_root, "data", "recon_checkpoint.json")
        self.state = self.load_checkpoint()
        self.logger = logging.getLogger("KALI.Recon")

    def load_checkpoint(self):
        if os.path.exists(self.checkpoint_file):
            with open(self.checkpoint_file, "r") as f:
                return json.load(f)
        return {"phase": "RECON", "completed_steps": [], "findings": []}

    def save_checkpoint(self):
        os.makedirs(os.path.dirname(self.checkpoint_file), exist_ok=True)
        with open(self.checkpoint_file, "w") as f:
            json.dump(self.state, f, indent=4)

    def run_recon(self):
        """SOVEREIGN: Real Reconnaissance (Socket Port Scan)"""
        print(f"🔱 KALI Audit RECON: Target {self.target}...")
        
        if "PORT_SCAN" not in self.state["completed_steps"]:
            common_ports = [80, 443, 8000, 8080, 3000, 5000]
            for port in common_ports:
                with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                    s.settimeout(1)
                    result = s.connect_ex((self.target, port))
                    if result == 0:
                        self.state["findings"].append({
                            "type": "open_port", 
                            "port": port, 
                            "service": socket.getservbyport(port) if port in [80, 443] else "unknown",
                            "ts": datetime.now().isoformat()
                        })
            
            self.state["completed_steps"].append("PORT_SCAN")
            self.save_checkpoint()
            print(f"--- Port Scan Complete. Found {len(self.state['findings'])} open ports.")

    def run_vulnerability_analysis(self):
        """SOVEREIGN: Header Analysis (Real)"""
        if "HEADER_ANALYSIS" not in self.state["completed_steps"]:
            print(f"🔱 KALI Audit VULN: Analyzing headers for {self.target}...")
            try:
                import requests
                response = requests.get(f"http://{self.target}", timeout=5)
                headers = response.headers
                
                missing_security_headers = []
                for header in ["Content-Security-Policy", "X-Frame-Options", "X-Content-Type-Options"]:
                    if header not in headers:
                        missing_security_headers.append(header)
                
                if missing_security_headers:
                    self.state["findings"].append({
                        "type": "missing_security_headers",
                        "headers": missing_security_headers,
                        "status": "VERIFIED"
                    })
            except Exception as e:
                print(f"--- Header Analysis Failed: {e}")

            self.state["completed_steps"].append("HEADER_ANALYSIS")
            self.save_checkpoint()

    def generate_poc(self):
        """SOVEREIGN: 'No Exploit, No Report' - Generating verified PoC"""
        print("🔱 KALI Audit EXPLOIT: Consolidating verified findings...")
        verified_findings = [f for f in self.state["findings"] if f.get("status") == "VERIFIED"]
        return verified_findings

if __name__ == "__main__":
    # Test on localhost
    recon = KALI_AuditRecon("localhost", os.getcwd())
    recon.run_recon()
    recon.run_vulnerability_analysis()
    print(f"Verified Security Findings: {recon.generate_poc()}")
