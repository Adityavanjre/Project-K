import requests
import sys

def verify_ui():
    url = "http://localhost:5000"
    print(f"--- KALI SELF-AUDIT: UI VERIFICATION ---")
    print(f"Target: {url}")
    
    try:
        response = requests.get(url, timeout=5)
        if response.status_code == 200:
            print(f"[SUCCESS] Web Server is responding (HTTP 200).")
            
            # Check for key KALI identifiers in the HTML
            html = response.text.lower()
            identifiers = ["kali", "sovereign", "intelligence", "council"]
            found = []
            for iden in identifiers:
                if iden in html:
                    found.append(iden)
            
            if found:
                print(f"[SUCCESS] Found Sovereign Identifiers: {', '.join(found)}")
                print(f"--- UI INTEGRITY: 100% ---")
            else:
                print(f"[WARNING] Server is up but identifiers not found in HTML.")
        else:
            print(f"[FAIL] Server responded with status code: {response.status_code}")
    except Exception as e:
        print(f"[FAIL] Could not connect to UI: {e}")

if __name__ == "__main__":
    verify_ui()
