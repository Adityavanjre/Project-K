
import requests
import json
import time

url = 'http://127.0.0.1:5000/api/project_plan'
payload = {
    "idea": "I want to automate my entire house using AI cameras in every room with a custom fusion reactor power supply."
}

try:
    print(f"Submitting Over-Engineered Idea: '{payload['idea']}'...")
    start = time.time()
    response = requests.post(url, json=payload)
    end = time.time()

    if response.status_code == 200:
        data = response.json()
        print("\n=== ARCHITECT'S RESPONSE ===")
        
        if data['data'].get('type') == 'clarification':
            context = data['data'].get('context', '')
            print(f"\n[CRITIQUE]\n{context}")
            
            # Use 'lower()' for case-insensitive check
            context_lower = context.lower()
            # "reactor" check is because "fusion reactor" is impossible physics (Rule B check)
            # "complex" or "start small" or "mvp" checks Rule 6
            if "start small" in context_lower or "complex" in context_lower or "impossible" in context_lower or "mvp" in context_lower:
                print("\nSUCCESS: Mentor discouraged over-engineering.")
            else:
                print("\nFAILURE: Mentor allowed scope creep.")
        else:
            print("TYPE: Plan (FAILURE - Should have critiqued scope)")
    else:
        print(f"Error: {response.status_code} - {response.text}")

    print(f"\nTime Taken: {end-start:.2f}s")

except Exception as e:
    print(f"Exception: {e}")
