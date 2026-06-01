import os
from huggingface_hub import HfApi

def load_token():
    if os.path.exists('.env'):
        with open('.env', 'r') as f:
            for line in f:
                if line.startswith('HF_TOKEN='):
                    return line.strip().split('=', 1)[1].strip('"\'')
    return os.environ.get('HF_TOKEN')

token = load_token()
if not token:
    print("Error: HF_TOKEN not found.")
    exit(1)

api = HfApi(token=token)
repo_id = 'adityavanjre/project-k'

print(f"Triggering manual restart for Space {repo_id}...")
try:
    api.restart_space(repo_id=repo_id)
    print("Successfully requested Space restart! Container is rebuilding.")
except Exception as e:
    print(f"Failed to restart Space: {e}")
