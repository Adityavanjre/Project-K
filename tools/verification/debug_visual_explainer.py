
import sys
import os

# Add src to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from core.processor import DoubtProcessor
from core.data_structures import DoubtContext

def test_visual_explainer():
    print("--- Testing Visual Explainer (Presentation Mode) ---")
    processor = DoubtProcessor()
    
    # Mock Context (mimicking what Project Mentor would provide)
    mock_context = {
        "project": "Automatic Plant Waterer",
        "bom": [
            {"part": "Arduino Uno", "color": "standard"},
            {"part": "Soil Moisture Sensor", "color": "red"},
            {"part": "Water Pump", "color": "white"}
        ],
        "roadmap": [
            {"phase": 1, "description": "Connect Sensor to Analog Pin A0"},
            {"phase": 2, "description": "Connect Pump to Digital Pin 8 via Relay"}
        ]
    }
    
    query = "Show me how to assemble the plant waterer"
    
    # Call the function
    try:
        result = processor.process_presentation_mode(query, context=mock_context)
        
        print("\n[Result Keys]:", result.keys())
        if "steps" in result:
            print(f"[Steps Generated]: {len(result['steps'])}")
            for i, step in enumerate(result['steps']):
                print(f"\nStep {i+1}:")
                print(f"  Text: {step.get('text')}")
                print(f"  Visual Code Preview: {step.get('visual_code')[:100]}...") # Print first 100 chars
        else:
            print("[ERROR] No steps generated.")
            print(result)
            
    except Exception as e:
        print(f"[EXCEPTION]: {e}")

if __name__ == "__main__":
    test_visual_explainer()
