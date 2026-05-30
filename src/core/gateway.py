import os
import json
import time
import uuid
import requests
import logging
import subprocess
import sys
from src.core.gstack_manager import GStackManager
from src.core.understand_manager import UnderstandManager

try:
    import msvcrt
except ImportError:
    msvcrt = None
import sys

class NeuralGateway:
    """
    Centralized Neural Gateway for Project-K.
    Maintains a single persistent connection to Ollama to prevent WinError 10048.
    Implements Zero-Port Pipe communication via filesystem inbox/outbox.
    """
    _lock_file = os.path.join(os.getcwd(), "data", ".neural_gateway.lock")

    @classmethod
    def is_running(cls):
        """Check if another instance is already running by trying to lock the file."""
        if not os.path.exists(cls._lock_file):
            return False
        if msvcrt is None:
            return False
        try:
            f = open(cls._lock_file, "r+")
            msvcrt.locking(f.fileno(), msvcrt.LK_NBLCK, 1)
            msvcrt.locking(f.fileno(), msvcrt.LK_UNLCK, 1)
            f.close()
            return False # We got the lock, so it wasn't running
        except (IOError, PermissionError):
            return True # Lock held by another process

    def __init__(self, root_dir):
        # SOVEREIGN: Singleton Enforcement
        self._lock_handle = open(self._lock_file, "w")
        if msvcrt is not None:
            try:
                msvcrt.locking(self._lock_handle.fileno(), msvcrt.LK_NBLCK, 1)
            except (IOError, PermissionError):
                print("[!] NeuralGateway is already running. Protocol Aborted.")
                sys.exit(0)

        self.root = root_dir
        self.gstack = GStackManager(self.root)
        self.understand = UnderstandManager(self.root)
        self.inbox = os.path.join(self.root, "data", "neural", "inbox")
        self.outbox = os.path.join(self.root, "data", "neural", "outbox")
        self.api_url = "http://127.0.0.1:11434/api/chat"
        
        # Ensure Zero-Port Infrastructure
        os.makedirs(self.inbox, exist_ok=True)
        os.makedirs(self.outbox, exist_ok=True)
        
        # 🔱 SINGLE TUNNEL: Direct Requests (No persistent session to avoid Windows stalls)
        self.logger = logging.getLogger(__name__)
        # Mute Internal Noise
        import warnings
        warnings.filterwarnings("ignore", category=UserWarning)
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s [%(levelname)s] NeuralGateway: %(message)s'
        )
        self.logger = logging.getLogger("NeuralGateway")
        self.logger.info("🔱 Neural Gateway Online. Monitoring pipe...")

    def run(self):
        while True:
            try:
                files = os.listdir(self.inbox)
                if not files:
                    time.sleep(0.1) # Synaptic idle
                    continue

                # Process oldest first
                files.sort(key=lambda x: os.path.getmtime(os.path.join(self.inbox, x)))
                for file_name in files:
                    file_path = os.path.join(self.inbox, file_name)
                    if not file_name.endswith('.json'): continue
                    
                    try:
                        with open(file_path, 'r') as f:
                            request_data = json.load(f)
                        
                        request_id = request_data.get("id", str(uuid.uuid4()))
                        self.logger.info(f"[+] Processing Thought: {request_id}")
                        
                        # Sequential Ollama Call with Exponential Backoff
                        resp_payload = None
                        base_delay = 1
                        max_retries = 5
                        
                        for retry_attempt in range(max_retries):
                            try:
                                if request_data.get("command") == "ping":
                                    resp_payload = {"status": 200, "content": "PONG"}
                                elif request_data.get("command") == "models":
                                    resp = requests.get("http://127.0.0.1:11434/api/tags", timeout=10, proxies={'http': None, 'https': None})
                                    resp_payload = {"status": resp.status_code, "content": resp.json()}
                                else:
                                    # 🔱 G-STACK & UNDERSTAND INTERCEPTION
                                    payload = request_data["payload"]
                                    user_msg = payload["messages"][-1]["content"]
                                    
                                    if user_msg.startswith('/'):
                                        skill_name = user_msg.split()[0].lstrip('/')
                                        
                                        # 1. Check Understand-Anything (Pedagogical)
                                        soul = self.understand.get_skill_soul(skill_name)
                                        if soul:
                                            self.logger.info(f"🔱 Understand-Anything Triggered: {skill_name}")
                                            payload["messages"].insert(0, {"role": "system", "content": soul['prompt']})
                                        else:
                                            # 2. Check G-Stack (Governance)
                                            soul = self.gstack.get_skill_soul(skill_name)
                                            if soul:
                                                self.logger.info(f"🔱 G-Stack Triggered: {skill_name}")
                                                context = self.gstack.execute_preamble(skill_name)
                                                system_prompt = f"{soul['prompt']}\n\n## CURRENT PROJECT CONTEXT\n{context}"
                                                payload["messages"].insert(0, {"role": "system", "content": system_prompt})

                                    # 🔱 Execute thought through the Single Tunnel
                                    self.logger.info(f"🔱 Inference Start: {request_id}")
                                    start_time = time.time()
                                    
                                    # SOVEREIGN: Use direct requests (no session) to avoid stale connection issues on Windows
                                    # And explicitly use 127.0.0.1 to avoid IPv6 resolution delays/failures
                                    response = requests.post(
                                        "http://127.0.0.1:11434/api/chat",
                                        json=payload,
                                        timeout=600,
                                        proxies={'http': None, 'https': None}
                                    )
                                    
                                    self.logger.info(f"🔱 Inference Complete: {request_id} [{time.time()-start_time:.1f}s]")
                                    resp_payload = {
                                        "status": response.status_code,
                                        "content": response.json()["message"]["content"] if response.status_code == 200 else response.text
                                    }
                                break # Success
                            except Exception as e:
                                delay = base_delay * (2 ** retry_attempt)
                                self.logger.warning(f"[-] Tunnel Breach ({retry_attempt+1}/{max_retries}). Retrying in {delay}s... {e}")
                                
                                # Cycle the Tunnel
                                try: self.session.close()
                                except: pass
                                self.session = requests.Session() 
                                self.session.headers.update({"Connection": "keep-alive"})
                                
                                time.sleep(delay)
                                if retry_attempt == max_retries - 1:
                                    resp_payload = {"status": 500, "content": f"Neural Tunnel Collapse: {str(e)}"}

                        # Write Response atomically
                        out_path = os.path.join(self.outbox, f"{request_id}.json")
                        tmp_out = out_path + ".tmp"
                        with open(tmp_out, 'w') as f:
                            json.dump({
                                "id": request_id,
                                **resp_payload
                            }, f)
                        os.rename(tmp_out, out_path)
                            
                        # Cleanup inbox
                        os.remove(file_path)
                        self.logger.info(f"[✔] Thought Resolved: {request_id}")
                        
                    except Exception as e:
                        self.logger.error(f"[-] Thought Processing Failure: {e}")
                        if os.path.exists(file_path): os.remove(file_path)
                        
            except KeyboardInterrupt:
                self.logger.info("[-] Neural Gateway Shutting Down...")
                break
            except Exception as e:
                self.logger.critical(f"[!] Critical Gateway Failure: {e}")
                time.sleep(1)

if __name__ == "__main__":
    # Started from kali_terminal.py with project root as CWD
    gateway = NeuralGateway(os.getcwd())
    gateway.run()
