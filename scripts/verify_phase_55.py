import os
import sys

# Add src to path
sys.path.append(os.path.join(os.getcwd(), "src"))

from core.processor import DoubtProcessor
from core.shadow_evaluator import ShadowEvaluator

def test_sovereignty_init():
    print("--- [VERIFY] Phase 55 Sovereignty Initialization ---")
    try:
        processor = DoubtProcessor()
        status = processor.get_system_status()
        
        print(f"Sovereignty Score: {status.get('sovereignty_score')}")
        print(f"Local Node Ready: {status.get('local_node_ready')}")
        
        if status.get('sovereignty_score') is not None:
            print("[SUCCESS] Sovereignty score is active.")
        else:
            print("[FAILURE] Sovereignty score is missing.")
            
        # Check shadow evaluator
        if hasattr(processor, 'shadow_evaluator'):
            print("[SUCCESS] ShadowEvaluator initialized.")
        else:
            print("[FAILURE] ShadowEvaluator missing.")

    except Exception as e:
        print(f"[ERROR] Initialization failed: {e}")

if __name__ == "__main__":
    test_sovereignty_init()
