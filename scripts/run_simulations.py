import os
import sys
import logging

# Add src to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src")))

from core.ai_service import AIService
from core.council_service import CouncilService
from dotenv import load_dotenv

load_dotenv()

def test_simulations():
    print("🚀 KALI SIMULATION ENGINE: STARTING...")
    logging.basicConfig(level=logging.INFO)
    
    # 1. Initialize AI without keys to force simulation
    os.environ["GROQ_API_KEY"] = "" # Force offline
    ai = AIService()
    print(f"[STATUS] AI Connected: {ai.is_connected} (Expected: False)")
    
    # 2. Test Offline Question Simulation
    print("\n--- TEST: OFFLINE QUESTION ---")
    resp = ai.ask_question("Tell me about the Sensor in my project plan.", context="Project: Robot Car. BOM: HC-SR04 Sensor.")
    print(f"RES: {resp}")
    
    # 3. Test Offline JSON Simulation (Project Architect)
    print("\n--- TEST: OFFLINE JSON (PROJECT) ---")
    json_resp = ai.ask_json("Project Architect", "I want to build a rocket.")
    print(f"RES: {json_resp.get('project_name')} - {json_resp.get('difficulty')}")
    
    # 4. Test NVIDIA NIM Routing (Missing Key Case)
    print("\n--- TEST: NVIDIA ROUTING (MISSING KEY) ---")
    # This should trigger a fallback message or log an error and try Groq
    resp = ai.ask_question("Technical query", query_model="google/gemma-7b")
    print(f"RES: {resp}")

    # 5. Test Council Simulation
    print("\n--- TEST: COUNCIL SIMULATION ---")
    council = CouncilService(ai)
    consensus = council.get_consensus("Is the fusion reactor stable?", context="Temp: 100M Kelvin")
    # Avoid slice for linter
    preview = consensus.split('\n')[0]
    print(f"CONSENSUS PREVIEW: {preview}...")

    print("\n✅ SIMULATIONS COMPLETE.")

if __name__ == "__main__":
    test_simulations()
