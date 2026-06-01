import os
from huggingface_hub import hf_hub_download

def load_token():
    if os.path.exists('.env'):
        with open('.env', 'r') as f:
            for line in f:
                if line.startswith('HF_TOKEN='):
                    return line.strip().split('=', 1)[1].strip('"\'')
    return os.environ.get('HF_TOKEN')

token = load_token()
repo_id = 'adityavanjre/project-k'

for filename in ['data/wealth_ledger.json', 'logs/sovereign_vault.json', 'logs/wealth_state.json']:
    try:
        print(f"Downloading {filename}...")
        local_path = hf_hub_download(
            repo_id=repo_id,
            filename=filename,
            repo_type='space',
            token=token
        )
        with open(local_path, "r") as f:
            print(f"=== CONTENT OF {filename} ===")
            print(f.read())
    except Exception as e:
        print(f"Error downloading {filename}: {e}")
