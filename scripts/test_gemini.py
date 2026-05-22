import requests
import os
import json
from dotenv import load_dotenv

load_dotenv()
key = os.getenv("GOOGLE_API_KEY")

def test_gemini(url):
    payload = {
        "contents": [{"parts": [{"text": "Hello, how are you?"}]}]
    }
    try:
        r = requests.post(f"{url}?key={key}", json=payload)
        print(f"Testing {url}: {r.status_code}")
        if r.status_code == 200:
            print("SUCCESS")
            return True
    except:
        pass
    return False

urls = [
    "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent",
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent",
    "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent"
]

for u in urls:
    if test_gemini(u):
        print(f"WINNER: {u}")
        break
