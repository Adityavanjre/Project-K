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
    print("Error: HF_TOKEN not found in .env or environment")
    exit(1)

api = HfApi(token=token)
repo_id = 'adityavanjre/project-k'

files_to_upload = [
    'start.sh',
    'start_web.py',
    'src/templates/base.html',
    'src/static/js/main.js',
    'src/static/css/kali.css',
    'src/static/css/tokens.css',
    'src/core/local_ai_service.py',
    'src/core/sovereign_wealth.py',
    'src/core/processor.py',
    'src/web_app.py',
    'data/recovery/processor.py',
    'data/recovery/web_app.py',
    'data/kali_core.manifest',
    'data/wealth_ledger.json',
    'logs/transaction_ledger.json',
    'logs/sovereign_vault.json',
    'logs/credential_vault.json',
    'credentials.json',
    'token.json',
    'src/core/tools/gmail_tool.py',
    'data/recovery/sovereign_wealth.py',
    'logs/sovereign_nodes.json',
    'src/core/universal_bridge.py',
    'data/recovery/universal_bridge.py',
    'logs/wealth_state.json'
]

print(f"Deploying modified files to {repo_id}...")
for file in files_to_upload:
    if os.path.exists(file):
        try:
            print(f"Uploading {file}...")
            api.upload_file(
                path_or_fileobj=file,
                path_in_repo=file,
                repo_id=repo_id,
                repo_type='space'
            )
            print(f"Successfully uploaded {file}")
        except Exception as e:
            print(f"Failed to upload {file}: {e}")
    else:
        print(f"Warning: File {file} does not exist locally.")

print("Deployment Complete!")
