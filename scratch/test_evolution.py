import sys
import os
import json
import argparse

def run():
    parser = argparse.ArgumentParser()
    parser.add_argument("--objective", default="Architecture")
    args = parser.parse_args()

    print(f"[TEST] Setting up environment for {args.objective}...")
    sys.path.append(os.getcwd())

    from modules.evolution import EvolutionEngine
    from modules.bridge import UniversalBridge

    print("[TEST] Initializing Bridge...")
    bridge = UniversalBridge()

    print("[TEST] Initializing Engine...")
    engine = EvolutionEngine(bridge=bridge)

    print(f"[TEST] Starting Training Session 001 ({args.objective})...")
    try:
        res = engine.start_session(args.objective)
        print(f"[TEST] Result: {json.dumps(res, indent=4)}")
    except Exception as e:
        print(f"[TEST] Session Failed: {e}")

if __name__ == '__main__':
    run()
