
import requests
import json

url = 'http://127.0.0.1:5000/ask'

queries = [
    # Should trigger Universal Smart Response (Senior Architect) + No Button
    ("Build a clock", False), 
    
    # Should be Specific -> Button
    ("Build a smart garden", True)
]

print("=== UNIVERSAL SMART RESPONSE VERIFICATION ===")
print(f"{'QUERY':<30} | {'EXP':<5} | {'ACT':<5} | {'RES'} | {'TEXT (First 60 chars)'}")
print("-" * 100)

for q, expected in queries:
    try:
        response = requests.post(url, json={"question": q})
        data = response.json()
        actual = data.get('can_build', False)
        text = data.get('response', '')
        text_preview = text[:60].replace('\n', ' ')
        
        result = "PASS" if actual == expected else "FAIL"
        print(f"{q[:30]:<30} | {str(expected):<5} | {str(actual):<5} | {result} | {text_preview}...")
        
        # Check if text matches new Template
        if "Build a clock" in q and "Senior Architect" in text:
             print("   -> [CONFIRMED] Universal Template used.")
             
    except Exception as e:
        print(f"Error: {e}")
