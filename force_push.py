"""
Force upload specific files to HuggingFace Space repository regardless of change detection.
"""
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
    print("Error: HF_TOKEN not found")
    exit(1)

api = HfApi(token=token)
repo_id = 'adityavanjre/project-k'

# Files that were actually changed and need pushing
files_to_upload = [
    'src/core/processor.py',
    'data/wealth_ledger.json',
    'logs/sovereign_vault.json',
    'logs/credential_vault.json',
    'push_modified_files.py'
]

print(f"Force-uploading changed files to {repo_id}...")
for file in files_to_upload:
    if os.path.exists(file):
        try:
            print(f"Uploading {file}...")
            api.upload_file(
                path_or_fileobj=file,
                path_in_repo=file,
                repo_id=repo_id,
                repo_type='space',
                commit_message=f"Fix: wealth display and capabilities fallback - {file}"
            )
            print(f"  OK: {file}")
        except Exception as e:
            print(f"  FAILED {file}: {e}")
    else:
        print(f"  SKIP (not found): {file}")

print("\nDone! HF Space container will rebuild.")
