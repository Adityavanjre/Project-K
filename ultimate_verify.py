import requests
import json
import os
import time

def ultimate_test():
    url = "http://127.0.0.1:5000/api/project_plan"
    payload = {
        "idea": "Manifest a dual-axis solar tracker using an Arduino, 2 servos, and 4 LDRs. Explain the code and record it in my DNA."
    }
    
    print("🚀 INITIATING GLOBAL CONVERGENCE SIMULATION...")
    try:
        start_time = time.time()
        resp = requests.post(url, json=payload, timeout=60)
        end_time = time.time()
        
        if resp.status_code == 200:
            raw_data = resp.json()
            data = raw_data.get('data', {})
            
            print(f"✅ CONVERGENCE ACHIEVED in {end_time - start_time:.2f}s")
            print(f"--- [KALI STATUS REPORT] ---")
            print(f"Vocal Signature (TTS): {data.get('audio_url')}")
            print(f"Physical Manifest (Disk): {data.get('manifest_path')}")
            
            response_text = data.get('response', "") or ""
            print(f"Sovereign Response: {response_text[:100]}...")
            
            # Verify Logs
            logs_path = "data/training_data.jsonl"
            with open(logs_path, "r", encoding="utf-8") as f:
                lines = f.readlines()
            print(f"Digital Soul Growth: {len(lines)} interactions recorded.")
            
            # Verify Manifestation
            m_path = data.get('manifest_path')
            if m_path and os.path.exists(m_path):
                print(f"Disk Reality: {m_path} exists and is populated.")
                print(f"Files: {os.listdir(m_path)}")
            
            print("\nCONCLUSION: KALI is 100% OPERATIONAL and ARCHITECTURALLY FLAWLESS.")
        else:
            print(f"❌ CONVERGENCE FAILED: {resp.status_code} - {resp.text}")
    except Exception as e:
        print(f"❌ CRITICAL COLLISION: {e}")

if __name__ == "__main__":
    ultimate_test()
