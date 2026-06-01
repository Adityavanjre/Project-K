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
    commits = api.list_repo_commits(repo_id=repo_id, repo_type='space')
    print("=== LATEST COMMITS ON HF SPACE ===")
    for c in commits[:3]:
        print(f"Commit ID: {c.commit_id}")
        print(f"Author: {c.authors}")
        print(f"Message: {c.message}")
        print(f"Created At: {c.created_at}")
        print("-" * 40)
except Exception as e:
    print(f"Error checking commits: {e}")
