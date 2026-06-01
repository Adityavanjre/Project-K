import os
import requests
import json
import time

def load_token():
    if os.path.exists('.env'):
        with open('.env', 'r') as f:
            for line in f:
                if line.startswith('HF_TOKEN='):
                    return line.strip().split('=', 1)[1].strip('"\'')
    return os.environ.get('HF_TOKEN')

token = load_token()
headers = {"Authorization": f"Bearer {token}"} if token else {}

url = f"https://adityavanjre-project-k.hf.space/api/sovereign/telemetry?t={time.time()}"
try:
    r = requests.get(url, headers=headers)
    print("Response JSON:")
    print(json.dumps(r.json(), indent=2))
except Exception as e:
    print("Error:", str(e))
