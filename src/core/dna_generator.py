import os
import json

PROJECT_ROOT = os.getcwd()
INTEGRATIONS_DIR = os.path.join(PROJECT_ROOT, "integrations")
DNA_PATH = os.path.join(PROJECT_ROOT, "src", "core", "swarm_dna.json")

def generate_dna():
    print("Initiating Autonomous DNA Ingestion...")
    dna_registry = {"swarm_neurons": {}}
    
    for node_id in os.listdir(INTEGRATIONS_DIR):
        node_path = os.path.join(INTEGRATIONS_DIR, node_id)
        if not os.path.isdir(node_path) or node_id.startswith("."):
            continue
            
        print(f"Interviewing Node: {node_id}...")
        expertise = []
        role = "Specialized Neuron"
        
        # 🔱 1. Read README for Expertise
        readme_path = os.path.join(node_path, "README.md")
        if os.path.exists(readme_path):
            with open(readme_path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read(2000) # Sample first 2000 chars
                # Basic heuristic extraction
                if "security" in content.lower() or "hack" in content.lower():
                    expertise.append("Cybersecurity")
                if "voice" in content.lower() or "speech" in content.lower():
                    expertise.append("Voice Interaction")
                if "ui" in content.lower() or "interface" in content.lower():
                    expertise.append("UI/UX")
                if "llm" in content.lower() or "model" in content.lower():
                    expertise.append("LLM Intelligence")
                if "code" in content.lower() or "develop" in content.lower():
                    expertise.append("Software Engineering")

        # 🔱 2. Detect Tech Stack
        if os.path.exists(os.path.join(node_path, "package.json")):
            stack = "Node.js"
        elif os.path.exists(os.path.join(node_path, "requirements.txt")):
            stack = "Python"
        else:
            stack = "Unknown"
            
        dna_registry["swarm_neurons"][node_id] = {
            "role": role,
            "expertise": list(set(expertise)) if expertise else ["General Utility"],
            "stack": stack,
            "path": f"integrations/{node_id}"
        }

    with open(DNA_PATH, "w") as f:
        json.dump(dna_registry, f, indent=2)
        
    print(f"\nDNA INGESTION COMPLETE. {len(dna_registry['swarm_neurons'])} neurons mapped.")

if __name__ == "__main__":
    generate_dna()
