
import requests
import json
import sys

def debug_project_plan():
    url = "http://127.0.0.1:5000/api/project_plan"
    payload = {"idea": "Gesture Controlled Car"}
    try:
        response = requests.post(url, json=payload)
        response.raise_for_status()
        data = response.json()
        print("Status Code:", response.status_code)
        print("Full JSON Response:")
        print(json.dumps(data, indent=2))
        
        if data.get("success"):
            plan = data.get("data", {})
            print("\n--- Plan Keys ---")
            print(plan.keys())
            print("\n--- Roadmap Preview ---")
            print(json.dumps(plan.get("roadmap", []), indent=2))
        else:
            print("\nAPI Returned Error:", data.get("error"))
            
    except Exception as e:
        print("Request Failed:", e)

if __name__ == "__main__":
    debug_project_plan()
