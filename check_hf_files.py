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
    files = api.list_repo_files(repo_id=repo_id, repo_type='space')
    print("Files in space repo (first 100):")
    for f in files[:100]:
        print(" -", f)
    print("Total files:", len(files))
except Exception as e:
    print("Error listing files:", str(e))
