
import requests
import json
import time

url = 'http://127.0.0.1:5000/ask'

scenarios = [
    # 1. PURE LEARNING (No Button)
    {"q": "What is a for loop?", "expect_btn": False, "type": "LEARNING"},
    {"q": "Explain Ohm's Law", "expect_btn": False, "type": "LEARNING"},
    
    # 2. SPECIFIC BUILD (Button Accepted)
    {"q": "Build a line follower robot with arduino", "expect_btn": True, "type": "BUILD_VALID"},
    {"q": "Design a 5V power supply circuit", "expect_btn": True, "type": "BUILD_VALID"},
    
    # 3. VAGUE BUILD (Smart Refusal / Consultation)
    {"q": "I want to build a robot", "expect_btn": False, "type": "VAGUE_CONSULT"},
    {"q": "Make a cool drone", "expect_btn": False, "type": "VAGUE_SEMANTIC"},
    
    # 4. ADVERSARIAL / TRICKY
    {"q": "Write code for my Arduino robot", "expect_btn": True, "type": "CODE_GEN_SPECIFIC"}, 
    {"q": "Write code for my robot", "expect_btn": False, "type": "CODE_GEN_VAGUE"}, # Proves Semantic Filter works on Code too!
    {"q": "Help me build a project", "expect_btn": False, "type": "VAGUE_PHRASE"},
]

print(f"{'TYPE':<15} | {'QUERY':<35} | {'BTN':<5} | {'RESULT'} | {'NOTE'}")
print("="*90)

passed = 0
failed = 0

for s in scenarios:
    try:
        # Add delay to avoid Rate Limits affecting logic testing (though offline logic handles it)
        time.sleep(1) 
        
        response = requests.post(url, json={"question": s['q']})
        if response.status_code != 200:
            print(f"{s['type']:<15} | {s['q'][:35]:<35} | ERR   | FAIL   | HTTP {response.status_code}")
            failed += 1
            continue
            
        data = response.json()
        can_build = data.get('can_build', False)
        text = data.get('response', '')
        
        match = (can_build == s['expect_btn'])
        res_str = "PASS" if match else "FAIL"
        
        note = ""
        if not match:
             note = f"Got {can_build}"
        elif s['type'] == "VAGUE_CONSULT" and "engineering challenge" in text:
             note = "Smart Response Active"
             
        print(f"{s['type']:<15} | {s['q'][:35]:<35} | {str(can_build):<5} | {res_str:<6} | {note}")
        
        if match:
            passed += 1
        else:
            failed += 1
            
    except Exception as e:
        print(f"CRITICAL ERROR: {e}")
        failed += 1

print("="*90)
print(f"TOTAL: {passed} PASS / {failed} FAIL")
if failed == 0:
    print("VERDICT: LOGIC IS ROBUST.")
else:
    print("VERDICT: LOGIC HAS GAPS.")
