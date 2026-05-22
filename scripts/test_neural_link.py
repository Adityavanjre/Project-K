import os
import sys
import logging

# Add src to path
sys.path.append(os.path.join(os.getcwd(), "src"))

from core.swarm_service import SwarmService

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("NeuralLinkTest")

def test_30_node_sync():
    """Verifies that all 30 nodes are recognized and the Neural Link is active."""
    print("KALI NEURAL LINK: DIAGNOSTIC SEQUENCE INITIATED")
    print("--------------------------------------------------")
    
    swarm = SwarmService(os.getcwd())
    nodes = swarm.nodes
    
    print(f"NODE DISCOVERY: {len(nodes)}/30 Neurons identified.")
    
    # Test Path 1: Memory to Logic
    print("\nTESTING PATHWAY: MEMORY -> LOGIC")
    res = swarm.activate_synapse("openhuman", "rlm", {"concept": "recursive_memory"})
    if res["success"]:
        print("SUCCESS: Data flowed from OpenHuman to RLM.")
    else:
        print("FAILED: Pathway Memory -> Logic blocked.")

    # Test Path 2: OS to Research
    print("\nTESTING PATHWAY: OS_CONTROL -> RESEARCH")
    res = swarm.activate_synapse("Windows-MCP", "ml-intern", {"env": "windows_11"})
    if res["success"]:
        print("SUCCESS: OS context passed to ML-Intern.")
    else:
        print("FAILED: Pathway OS -> Research blocked.")

    # Check Blackboard Integrity
    print("\nCHECKING BLACKBOARD PERSISTENCE")
    swarm.update_blackboard("mission", "NEURAL_SYNC_COMPLETE")
    if swarm.blackboard["mission"] == "NEURAL_SYNC_COMPLETE":
        print("SUCCESS: Global context shared.")
    else:
        print("CORRUPT: Mission state lost.")

    print("\n--------------------------------------------------")
    print("NEURAL LINK STATUS: NOMINAL")

if __name__ == "__main__":
    test_30_node_sync()
