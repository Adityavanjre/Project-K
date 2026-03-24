
import requests
import json
import time

url = 'http://127.0.0.1:8000/api/project_plan'
payload = {
    "project_name": "Drone",
    "project_description": "I want to build a drone that flies really fast."
}

try:
    print(f"Submitting Vague Idea: '{payload['project_description']}'...")
    start = time.time()
    response = requests.post(url, json=payload)
    end = time.time()

    if response.status_code == 200:
        data = response.json()
        print("\n=== ARCHITECT'S RESPONSE ===")
        # The new prompt maps the critique to 'context' or 'reason' depending on how the AI interprets it.
        # But our JSON schema explicitly asked for 'context' in clarification.
        
        if data['data'].get('type') == 'clarification':
            print("TYPE: Clarification / Critique")
            print(f"\n[CRITIQUE CONTEXT]\n{data['data'].get('context')}")
            print(f"\n[DECISIONS REQUIRED]")
            for q in data['data'].get('questions', []):
                print(f"- {q}")
        else:
            print("TYPE: Plan (Unexpected for vague input)")
            print(data['data'])
    else:
        print(f"Error: {response.status_code} - {response.text}")

    print(f"\nTime Taken: {end-start:.2f}s")

except Exception as e:
    print(f"Exception: {e}")
