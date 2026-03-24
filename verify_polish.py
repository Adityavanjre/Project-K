
import requests
import json
import time

url = 'http://127.0.0.1:8000/api/project_plan'
# Using Backdoor Key to force Plan Generation
payload = {
    "project_name": "Digital Clock",
    "project_description": "[TEST_MODE_FORCE_PLAN] Arduino Uno, SSD1306 OLED, DS3231 RTC. Digital Clock. USB Power. Libraries: Adafruit_SSD1306, RTClib."
}

try:
    print(f"Submitting Backdoor Request: 'Arduino OLED Clock'...")
    start = time.time()
    response = requests.post(url, json=payload)
    end = time.time()

    if response.status_code == 200:
        data = response.json()
        print("\n=== ARCHITECT'S RESPONSE ===")
        plan = data.get('data', {})
        
        if plan.get('type') == 'plan':
            print("TYPE: Plan (SUCCESS)")
            
            # Check Cost
            cost = plan.get('total_estimated_cost', 'N/A')
            print(f"Total Cost: {cost}")
            if cost != 'N/A':
                print("SUCCESS: Budget Calculated.")
            else:
                print("FAILURE: Missing Total Cost.")
            
            # Check Library Steps
            found_lib = False
            for phase in plan.get('roadmap', []):
                desc = str(phase.get('description', '')).lower()
                key = str(phase.get('key_concept', '')).lower()
                ph_title = str(phase.get('phase', '')).lower()
                if "library" in desc or "library" in key or "library" in ph_title:
                    found_lib = True
                    print(f"Found Phase: {phase.get('phase')} - {phase.get('key_concept')}")
            
            if found_lib:
                print("SUCCESS: Library/Setup Phase Found.")
            else:
                print("FAILURE: Missing Library Setup Instructions.")
                
        else:
            print(f"TYPE: {plan.get('type')} (Unexpected)")
            # Print context to debug critique
            print(plan.get('context', 'No context'))
    else:
        print(f"Error: {response.status_code} - {response.text}")

    print(f"\nTime Taken: {end-start:.2f}s")

except Exception as e:
    print(f"Exception: {e}")
