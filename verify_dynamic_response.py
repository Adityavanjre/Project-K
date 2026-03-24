
import requests
import json

url = 'http://127.0.0.1:8000/ask'

queries = [
    # Should trigger Regex (Dynamic Noun Extraction) + No Button(False)
    ("Build a Toaster", False), 
    ("Make a Spaceship", False),
    
    # "Build a Smart Garden" -> Space makes Regex fail -> API -> Semantic Check
    # (Smart is in DETAILS) -> True
    ("Build a Smart Garden", True)
]

print("=== DYNAMIC SMART RESPONSE VERIFICATION ===")
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
        
        # Check extraction
        if "Toaster" in q and "your Toaster" in text:
             print("   -> [CONFIRMED] Dynamic Noun 'Toaster' extracted.")
        if "Spaceship" in q and "your Spaceship" in text:
             print("   -> [CONFIRMED] Dynamic Noun 'Spaceship' extracted.")
             
    except Exception as e:
        print(f"Error: {e}")
