
import requests
import json
import time

url = 'http://127.0.0.1:5000/api/project_plan'
payload = {
    "idea": "I want to connect a large 12V DC motor directly to the Arduino's digital pin 9 to control it."
}

try:
    print(f"Submitting Dangerous Idea: '{payload['idea']}'...")
    start = time.time()
    response = requests.post(url, json=payload)
    end = time.time()

    if response.status_code == 200:
        data = response.json()
        print("\n=== ARCHITECT'S RESPONSE ===")
        
        if data['data'].get('type') == 'clarification':
            print("TYPE: Clarification / Critique (Expected)")
            context = data['data'].get('context', '')
            print(f"\n[CRITIQUE]\n{context}")
            
            # Simple keyword checks for human-like safety catch
            if "current" in context.lower() or "fry" in context.lower() or "damage" in context.lower() or "driver" in context.lower():
                print("\nSUCCESS: Mentor caught the safety violation.")
            else:
                print("\nFAILURE: Mentor missed the safety violation.")
        else:
            print("TYPE: Plan (FAILURE - Should have stopped dangerous idea)")
            print(data['data'])
    else:
        print(f"Error: {response.status_code} - {response.text}")

    print(f"\nTime Taken: {end-start:.2f}s")

except Exception as e:
    print(f"Exception: {e}")
