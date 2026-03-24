
import sys
import os

# Add src to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from core.processor import DoubtProcessor

def test_interconnectivity():
    print("--- Testing Interconnectivity (Project Mentor -> Doubt) ---")
    processor = DoubtProcessor()
    
    # 1. Generate Project Plan
    idea = "Gesture Controlled Car"
    print(f"\n[1] Generating Plan for: {idea}")
    plan = processor.process_project_mentor(idea)
    
    if "error" in plan or "roadmap" not in plan:
        print("[FAILED] Could not generate plan.")
        print(plan)
        return

    print("[SUCCESS] Plan Generated.")
    
    # 2. Simulate User asking a specific doubt about the plan
    # We pick a component from the BOM to ask about
    bom_item = plan['bom'][0]['part']
    question = f"Why do I need a {bom_item} for this project?"
    
    print(f"\n[2] User asks: '{question}'")
    
    # Simulate the flow where we might pass context
    # Note: process_doubt doesn't currently take 'context' dictionary in the signature shown in view_file
    # But process_contextual_doubt DOES. Let's test that one as it's designed for "mid-presentation" doubts.
    
    context_data = {
        "current_step_text": f"Reviewing BOM for {idea}",
        "topic": idea,
        "bom": plan['bom']
    }
    
    response = processor.process_contextual_doubt(question, context_data)
    
    print(f"\n[3] AI Answer:")
    print(response.get('answer'))
    
    if bom_item.lower() in response.get('answer', '').lower() or "context" in str(response):
         print("\n[VERDICT] Interconnectivity appears functional (Context used).")
    else:
         print("\n[VERDICT] Response might be generic. Check content manually.")

if __name__ == "__main__":
    test_interconnectivity()
