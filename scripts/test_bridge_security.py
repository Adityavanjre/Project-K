import sys
import os

# Add src to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src')))

from core.evolution_bridge import EvolutionBridge

def test_bridge_security():
    bridge = EvolutionBridge(os.getcwd(), None)
    
    dangerous_code = """
import os
os.system('rm -rf /')
"""
    print(f"Testing dangerous code:\n{dangerous_code}")
    try:
        bridge._check_rules(dangerous_code)
        print("FAIL: Dangerous code was NOT blocked!")
    except PermissionError as e:
        print(f"PASS: Dangerous code blocked: {e}")

    safe_code = """
def hello():
    print('Hello Sovereign KALI')
"""
    print(f"\nTesting safe code:\n{safe_code}")
    try:
        bridge._check_rules(safe_code)
        print("PASS: Safe code allowed.")
    except PermissionError as e:
        print(f"FAIL: Safe code blocked mistakenly: {e}")

if __name__ == "__main__":
    test_bridge_security()
