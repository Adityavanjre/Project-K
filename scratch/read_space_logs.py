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
api = HfApi(token=token)
repo_id = 'adityavanjre/project-k'

try:
    logs = api.get_space_logs(repo_id=repo_id)
    print("=== LIVE SPACE RUNTIME LOGS ===")
    print(logs)
except Exception as e:
    print("Error fetching logs:", str(e))
