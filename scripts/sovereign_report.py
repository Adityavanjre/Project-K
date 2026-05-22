import json
import os

def check_sovereignty():
    path = "data/skill_sovereignty.json"
    if not os.path.exists(path):
        print("Sovereignty file not found.")
        return

    with open(path, "r") as f:
        data = json.load(f)

    total_skills = len(data)
    sovereign_count = sum(1 for s in data.values() if s.get("status") == "SOVEREIGN" or s.get("sovereignty_level") == 100.0)
    
    avg_level = sum(s.get("sovereignty_level", 0) for s in data.values()) / total_skills
    
    print(f"--- KALI SOVEREIGNTY REPORT ---")
    print(f"Total Skills: {total_skills}")
    print(f"Sovereign (100%): {sovereign_count}")
    print(f"Average Sovereignty: {avg_level:.2f}%")
    print(f"-------------------------------")
    
    # List top and bottom
    sorted_skills = sorted(data.items(), key=lambda x: x[1].get("sovereignty_level", 0), reverse=True)
    
    print("\n[TOP ASCENSION]")
    for name, s in sorted_skills[:5]:
        print(f" - {name}: {s.get('sovereignty_level', 0):.1f}% ({s.get('status')})")
        
    print("\n[BOTTOM REMEDIATION]")
    for name, s in sorted_skills[-5:]:
        print(f" - {name}: {s.get('sovereignty_level', 0):.1f}% ({s.get('status')})")

if __name__ == "__main__":
    check_sovereignty()
