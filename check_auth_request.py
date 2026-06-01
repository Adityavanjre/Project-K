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

# Try directly to /api/state
r = requests.get("https://adityavanjre-project-k.hf.space/api/state", headers=headers)
print("api/state response code:", r.status_code)
try:
    print("api/state JSON response:")
    print(r.json())
except Exception as e:
    print("Failed to decode JSON:", e)
    print("Response text:", r.text[:500])

# Let's check space metadata to see if it is private
r_meta = requests.get("https://huggingface.co/api/spaces/Adityavanjre/Project-K", headers=headers)
if r_meta.status_code == 200:
    data = r_meta.json()
    print("Is private:", data.get("private"))
else:
    print("Failed to get metadata:", r_meta.status_code)
