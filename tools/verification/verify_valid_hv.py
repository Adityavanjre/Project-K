
import requests
import json
import time

url = 'http://127.0.0.1:5000/api/project_plan'
payload = {
    "idea": "I want to control a 12V DC Motor using an Arduino and an L298N Motor Driver. I will power the driver with a 12V battery and the Arduino via USB."
}

try:
    print(f"Submitting VALID High Voltage Idea: '{payload['idea']}'...")
    start = time.time()
    response = requests.post(url, json=payload)
    end = time.time()

    if response.status_code == 200:
        data = response.json()
        print("\n=== ARCHITECT'S RESPONSE ===")
        
        # We expect a PLAN (or at least a mild clarification), NOT a Safety Override.
        if data['data'].get('type') == 'plan':
             print("TYPE: Plan (SUCCESS - Recognized safe design)")
        elif data['data'].get('type') == 'clarification':
            context = data['data'].get('context', '')
            print(f"\n[CRITIQUE]\n{context}")
            
            if "FIRE HAZARD" in context or "DESTROY" in context:
                print("\nFAILURE: False Positive! Mentor blocked a safe design.")
            else:
                print("\nSUCCESS: Mentor asked for details but didn't panic.")
    else:
        print(f"Error: {response.status_code} - {response.text}")

    print(f"\nTime Taken: {end-start:.2f}s")

except Exception as e:
    print(f"Exception: {e}")
