
import requests
import json
import time

url = "http://127.0.0.1:5000/api/project_plan"

# Simulate the "Enriched Prompt" that comes after Consultation
payload = {
    "idea": """
    User wants: High speed racing drone.
    
    [USER CLARIFICATIONS]
    Q: What is the desired speed?
    A: 150km/h
    Q: Frame material?
    A: Carbon Fiber
    Q: Flight time?
    A: 5-8 minutes
    Q: Camera type?
    A: Analog FPV
    
    [INSTRUCTION]: Generate the final PLAN now.
    """
}

print(f"Sending request to {url}...")
try:
    start = time.time()
    response = requests.post(url, json=payload)
    end = time.time()
    
    if response.status_code == 200:
        data = response.json()
        if data.get('success'):
            print("RAW DATA:", json.dumps(data['data'], indent=2))
            plan = data['data']
            print("\n=== DRONE PROJECT BLUEPRINT GENERATED ===")
            print(f"Title: {plan.get('project_name')}")
            
            print("\n[TOOLS REQUIRED]")
            for tool in plan.get('tools', []):
                print(f"- {tool['item']}: {tool.get('specs')} ({tool.get('reason')})")

            print("\n[SAFETY GUIDELINES]")
            for rule in plan.get('safety_guidelines', []):
                print(f"- {rule}")
                
            print("\n[BILL OF MATERIALS]")
            for item in plan.get('bom', []):
                print(f"- {item['part']}: {item['specs']} (${item.get('estimated_cost')})")
            
            print("\n[TOOLS REQUIRED]")
            for tool in plan.get('tools', []):
                print(f"- {tool['item']}: {tool.get('specs')} ({tool.get('reason')})")

            print("\n[SAFETY GUIDELINES]")
            for rule in plan.get('safety_guidelines', []):
                print(f"- {rule}")

            print("\n[MERMAID DIAGRAM]")
            print(plan.get('mermaid_diagram'))
            
            print("\n[EXTERNAL REFERENCES]")
            for ref in plan.get('external_references', []):
                print(f"- {ref['label']}: {ref.get('url')}")
                
            print("\n[FUTURE IMPROVEMENTS]")
            for idea in plan.get('future_improvements', []):
                print(f"- {idea}")
            
            print("\n[GLOSSARY]")
            for term in plan.get('glossary', []):
                print(f"- {term['term']}: {term.get('definition')}")
            
            print("\n[PINOUT MAP]")
            for pin in plan.get('pinout_map', []):
                print(f"- {pin['component']} ({pin.get('component_pin')}) <--> {pin.get('board_pin')} [{pin.get('note')}]")
            
            print("\n[ROADMAP]")
            for step in plan.get('roadmap', []):
                print(f"Phase {step.get('phase')} ({step.get('time_estimate', 'N/A')}): {step.get('key_concept')}")
            
            print("\n[TROUBLESHOOTING]")
            for issue in plan.get('troubleshooting', []):
                print(f"- Symptom: {issue.get('symptom')} -> Fix: {issue.get('fix')}")
            
            print("\n[VERIFICATION STEPS]")
            for check in plan.get('verification_steps', []):
                print(f"- {check['step']}: {check.get('action')}")
            
            print("\n[MAINTENANCE]")
            for task in plan.get('maintenance_log', []):
                print(f"- {task['frequency']}: {task.get('task')}")

            print("\n[COMPLIANCE / LEGAL]")
            for note in plan.get('compliance_notes', []):
                print(f"- {note}")
            
            print(f"\nTime Taken: {end-start:.2f}s")
            print("========================================")
        else:
            print("FAILED:", data.get('error'))
    else:
        print(f"HTTP Error: {response.status_code}")
except Exception as e:
    print(f"System Error: {e}")
