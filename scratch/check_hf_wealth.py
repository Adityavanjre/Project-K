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

for path in ['data/wealth_ledger.json', 'logs/sovereign_vault.json']:
    try:
        url = api.get_space_runtime(repo_id=repo_id) # Just to check connectivity
        local_path = api.download_file(
            repo_id=repo_id,
            filename=path,
            repo_type='space'
        )
        with open(local_path, "r") as f:
            print(f"=== CONTENT OF {path} ON HF SPACE ===")
            print(f.read())
    except Exception as e:
        print(f"Error reading {path}: {e}")
