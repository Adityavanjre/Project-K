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
    integrations = [f for f in files if f.startswith('integrations/')]
    tools = [f for f in files if f.startswith('tools/')]
    
    print(f"Total integrations in repo: {len(integrations)}")
    print(f"Total tools in repo: {len(tools)}")
    print("Sample integrations (first 20):")
    for f in integrations[:20]:
        print(" -", f)
except Exception as e:
    print("Error:", str(e))
