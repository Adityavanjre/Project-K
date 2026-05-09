import subprocess
import time
import os
import sys
import logging

def start_component(name, command, cwd=None):
    print(f"[KALI] Activating {name}...")
    try:
        # [KALI] SOVEREIGN: Ollama Pre-Flight
        if "ollama" in command.lower():
            import requests
            try:
                requests.get("http://localhost:11434/api/tags")
                print(f"[+] {name} (Ollama) is already running.")
                return None
            except:
                print(f"[KALI] Waking Ollama Neuron...")
                
        process = subprocess.Popen(
            command if os.name == 'nt' else command.split(),
            cwd=cwd or os.getcwd(),
            shell=True if os.name == 'nt' else False,
            creationflags=subprocess.CREATE_NEW_CONSOLE if os.name == 'nt' else 0
        )
        return process
    except Exception as e:
        print(f"[-] Failed to activate {name}: {e}")
        return None

def genesis():
    # 2. Start the Jarvis Backend (The Voice/Body)
    jarvis_backend = start_component("Jarvis Backend", "python server.py", cwd="integrations/jarvis")
    time.sleep(3)
    
    # 3. Start the Jarvis Frontend (The Orb/STT)
    # We use 'npm run dev' in the frontend folder
    jarvis_ui = start_component("Jarvis UI", "npm run dev", cwd="integrations/jarvis/frontend")
    time.sleep(2)
    
    # 4. Start the KALI Frontend (DanceUI)
    frontend = start_component("DanceUI Server", "python start_web.py")
    time.sleep(2)
    
    # 5. Start the Cognitive Daemon (The Mind)
    daemon = start_component("Sovereign Daemon", "python start_daemon.py")
    time.sleep(2)
    
    # 7. Launch the Unified Interface (Zero-Gesture Mode)
    print("[KALI] Launching Sovereign Interfaces (Aural Field Active)...")
    import webbrowser
    import subprocess
    
    # We launch Chrome specifically with flags to bypass 'First Click' requirements for mic/audio
    chrome_cmd = [
        "start", "chrome",
        "--use-fake-ui-for-media-stream",
        "--autoplay-policy=no-user-gesture-required",
        "http://localhost:5000" # Master Singularity (Unified KALI & Jarvis)
    ]
    subprocess.Popen(chrome_cmd, shell=True)


if __name__ == "__main__":
    genesis()
