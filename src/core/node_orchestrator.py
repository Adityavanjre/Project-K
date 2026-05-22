import os
import json
import subprocess
import logging
import time
import threading
from typing import Dict, Any, List, Optional

class NodeOrchestrator:
    """
    The Brain Stem of KALI.
    Orchestrates 39+ specialized neurons (cloned repos) as headless services.
    Converts 'External Tools' into 'Internal Functions'.
    """
    def __init__(self, root_dir: str):
        self.root = root_dir
        self.integrations_dir = os.path.join(self.root, "integrations")
        self.logger = logging.getLogger("KALI.NodeOrchestrator")
        self.active_nodes: Dict[str, Dict[str, Any]] = {} # Tracks process + metadata
        self.node_registry: Dict[str, Dict[str, Any]] = {}
        
        # Hyper-Optimization: Background Health & Hibernation Loop
        self.hibernation_timeout = 300 # 5 minutes of idleness
        self._start_guard_thread()
        self._auto_discover_neurons()

    def _auto_discover_neurons(self):
        """Recursively discovers neuron DNA in the integrations folder with multi-pattern detection."""
        if not os.path.exists(self.integrations_dir): return
        
        for item in os.listdir(self.integrations_dir):
            item_path = os.path.join(self.integrations_dir, item)
            if not os.path.isdir(item_path): continue
            
            # Detect Startup DNA
            dna = {"path": f"integrations/{item}", "type": "unknown", "startup": None}
            
            # 🔱 12-Pattern Neural Detection
            if os.path.exists(os.path.join(item_path, "pnpm-lock.yaml")):
                dna["type"] = "node_pnpm"
                dna["startup"] = "pnpm start"
            elif os.path.exists(os.path.join(item_path, "package.json")):
                dna["type"] = "node_npm"
                dna["startup"] = "npm start"
            elif os.path.exists(os.path.join(item_path, "main.py")):
                dna["type"] = "python_main"
                dna["startup"] = "python main.py"
            elif os.path.exists(os.path.join(item_path, "app.py")):
                dna["type"] = "python_app"
                dna["startup"] = "streamlit run app.py" if "streamlit" in open(os.path.join(item_path, "app.py"), errors='ignore').read() else "python app.py"
            elif os.path.exists(os.path.join(item_path, "go.mod")):
                dna["type"] = "go"
                dna["startup"] = "go run main.go"
            elif os.path.exists(os.path.join(item_path, "Modelfile")):
                dna["type"] = "ollama"
                dna["startup"] = f"ollama run {item}"
                
            if dna["startup"]:
                self.node_registry[item] = dna
        
        self.logger.info(f"🔱 Hyper-Discovery: {len(self.node_registry)} neurons ready for dispatch.")

    def wake_node(self, node_id: str) -> bool:
        """Starts a neuron with Resource Guarding and Load Monitoring."""
        if node_id not in self.node_registry: return False
        
        # 🔱 Resource Guard: Check System Load
        try:
            import psutil
            cpu_load = psutil.cpu_percent()
            if cpu_load > 85:
                self.logger.warning(f"🔱 Resource Guard: CPU at {cpu_load}%. Delaying {node_id} activation.")
                return False
        except: pass

        if node_id in self.active_nodes:
            self.active_nodes[node_id]["last_used"] = time.time()
            return True
            
        node = self.node_registry[node_id]
        self.logger.info(f"🔱 Resource Allocation: Waking {node_id}...")
        
        try:
            process = subprocess.Popen(
                node["startup"].split(),
                cwd=os.path.join(self.root, node["path"]),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
            )
            self.active_nodes[node_id] = {
                "process": process,
                "last_used": time.time(),
                "status": "ACTIVE"
            }
            return True
        except Exception as e:
            self.logger.error(f"Failed to allocate resources for {node_id}: {e}")
            return False

    def _start_guard_thread(self):
        """Background thread to hibernate idle neurons."""
        def guard():
            while True:
                time.sleep(60) # Check every minute
                now = time.time()
                to_hibernate = []
                
                for node_id, data in self.active_nodes.items():
                    if now - data["last_used"] > self.hibernation_timeout:
                        to_hibernate.append(node_id)
                
                for node_id in to_hibernate:
                    self.logger.info(f"🔱 Resource Recovery: Hibernating {node_id} (Idle Timeout)")
                    self.active_nodes[node_id]["process"].terminate()
                    del self.active_nodes[node_id]
                    
        threading.Thread(target=guard, daemon=True).start()


    def dispatch_task(self, node_id: str, command: str) -> str:
        """Sends a thought directly into a neuron's CLI/API."""
        if node_id not in self.active_nodes:
            if not self.wake_node(node_id):
                return "Neuron Failure: Resource allocation failed."
        
        node_data = self.active_nodes[node_id]
        process = node_data["process"]
        node_data["last_used"] = time.time()

        try:
            # Check if process is still alive
            if process.poll() is not None:
                self.logger.warning(f"Neuron {node_id} died. Restarting...")
                del self.active_nodes[node_id]
                return self.dispatch_task(node_id, command)

            # Send command to stdin
            if process.stdin:
                process.stdin.write(command + "\n")
                process.stdin.flush()
            
            # Simple non-blocking read for feedback (first few lines)
            # In a full production env, we'd use a dedicated output queue
            feedback = []
            start_time = time.time()
            while time.time() - start_time < 2: # Wait 2 seconds for initial response
                line = process.stdout.readline()
                if not line: break
                feedback.append(line.strip())
                if len(feedback) > 5: break # Cap feedback for now
            
            if not feedback:
                return f"Task dispatched to {node_id}. Awaiting neural feedback (No immediate output)."
            
            return "\n".join(feedback)
        except Exception as e:
            self.logger.error(f"Fault in neural bridge for {node_id}: {e}")
            return f"Bridge Failure: {str(e)}"

    def hibernate_all(self):
        """Shuts down all background neurons to save resources."""
        for node_id, process in self.active_nodes.items():
            self.logger.info(f"🔱 Hibernating Neuron: {node_id}")
            process.terminate()
        self.active_nodes.clear()

if __name__ == "__main__":
    orchestrator = NodeOrchestrator(os.getcwd())
    print(f"🔱 Sovereign Nodes: {', '.join(orchestrator.node_registry.keys())}")
