import requests
import os
import sys

def load_token():
    if os.path.exists('.env'):
        with open('.env', 'r') as f:
            for line in f:
                if line.startswith('HF_TOKEN='):
                    val = line.strip().split('=', 1)[1]
                    return val.strip('"').strip("'")
    return os.environ.get('HF_TOKEN')

token = load_token()
headers = {"Authorization": "Bearer " + token}

for path in ["Dockerfile", "app.py", "requirements.txt", "start.sh", "start_web.py"]:
    url = "https://huggingface.co/spaces/adityavanjre/project-k/raw/main/" + path
    r = requests.get(url, headers=headers, timeout=10)
    out = "=== " + path + " (status " + str(r.status_code) + ") ===\n"
    if r.status_code == 200:
        out += r.text[:3000]
    else:
        out += r.text[:200]
    out += "\n"
    sys.stdout.buffer.write(out.encode("utf-8", errors="replace"))
    sys.stdout.buffer.flush()
