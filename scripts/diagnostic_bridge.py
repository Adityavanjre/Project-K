import sys
import os
import multiprocessing

# Add src and current dir to path
sys.path.append(os.getcwd())

def run_diagnostic():
    try:
        from modules.bridge import UniversalBridge
        
        print("--- [KALI BRIDGE DIAGNOSTIC] ---")
        bridge = UniversalBridge()
        
        print("\n1. Testing 'trainer' module (Lesson Study)...")
        # Using 'execute' with type corresponding to the module name
        trainer_result = bridge.execute({'type': 'trainer', 'input': 'study lesson 1-Intro', 'command': 'study', 'lesson_id': '1-Intro'})
        print(f"RESULT: {trainer_result}")
        
        print("\n2. Testing 'harness' module (Progress Sync)...")
        harness_result = bridge.execute({'type': 'harness', 'input': 'sync plans', 'command': 'sync'})
        print(f"RESULT: {harness_result}")
        
        print("\n3. Current Active Modules:")
        for name in bridge.modules.keys():
            if bridge.registry.is_active(name):
                print(f" - {name}")

    except Exception as e:
        print(f"DIAGNOSTIC ERROR: {e}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    multiprocessing.freeze_support()
    run_diagnostic()
