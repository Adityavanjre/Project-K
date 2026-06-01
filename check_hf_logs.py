import os
import requests

def load_token():
    if os.path.exists('.env'):
        with open('.env', 'r') as f:
            for line in f:
                if line.startswith('HF_TOKEN='):
                    return line.strip().split('=', 1)[1].strip('"\'')
    return os.environ.get('HF_TOKEN')

token = load_token()
headers = {"Authorization": f"Bearer {token}"} if token else {}
r = requests.get("https://huggingface.co/api/spaces/adityavanjre/project-k/logs", headers=headers)
if r.status_code == 200:
    print(r.text[-2000:])
else:
    print("Error:", r.status_code, r.text)
