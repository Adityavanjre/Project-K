import os
import sys
import requests
import json

if sys.platform.startswith('win'):
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def load_token():
    if os.path.exists('.env'):
        with open('.env', 'r') as f:
            for line in f:
                if line.startswith('HF_TOKEN='):
                    return line.strip().split('=', 1)[1].strip('"\'')
    return os.environ.get('HF_TOKEN')

token = load_token()
headers = {"Authorization": f"Bearer {token}"} if token else {}

import time
url = f"https://adityavanjre-project-k.hf.space/api/state?t={time.time()}"
try:
    r = requests.get(url, headers=headers)
    print("Response JSON:")
    print(json.dumps(r.json(), indent=2))
except Exception as e:
    print("Error:", str(e))
