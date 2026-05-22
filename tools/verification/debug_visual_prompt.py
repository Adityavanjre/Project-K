
import os
import sys
import json
from dotenv import load_dotenv

# Add src to path
sys.path.append(os.path.join(os.getcwd(), 'src'))

from core.processor import DoubtProcessor
from core.data_structures import DoubtContext

def debug_visual_generation():
    load_dotenv()
    
    processor = DoubtProcessor()
    
    # Mock Context (BOM)
    context = {
        "project": "Test Distance Detector",
        "bom": [
            {"part": "Arduino Uno", "specs": "R3"},
            {"part": "Ultrasonic Sensor", "specs": "HC-SR04"}
        ],
        "roadmap": [
            {"phase": "1", "description": "Connect Sensor to Arduino"}
        ]
    }
    
    print("\n--- GENERATING VISUAL EXPLANATION ---")
    response = processor.process_presentation_mode("Show me the assembly wiring", context)
    
    print("\n--- RAW RESPONSE ---")
    # print(json.dumps(response, indent=2))
    
    if "steps" in response and len(response["steps"]) > 0:
        print("\n✅ 'steps' key found at root.")
        first_step = response["steps"][0]
        with open("debug_output.txt", "w", encoding="utf-8") as f:
            f.write(first_step.get('visual_code', 'NO VISUAL CODE'))
        print("Written visual code to debug_output.txt")
    else:
        print("\n❌ 'steps' key NOT found or empty.")

if __name__ == "__main__":
    debug_visual_generation()
