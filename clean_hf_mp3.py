import os
from huggingface_hub import HfApi

def load_token():
    if os.path.exists('.env'):
        with open('.env', 'r') as f:
            for line in f:
                if line.startswith('HF_TOKEN='):
                    return line.strip().split('=', 1)[1].strip('\'"')
    return os.environ.get('HF_TOKEN')

api = HfApi(token=load_token())
repo_id = 'adityavanjre/project-k'

print("Scanning Hugging Face Space for .mp3 files to delete...")
try:
    files = api.list_repo_files(repo_id, repo_type='space')
    mp3_files = [f for f in files if f.endswith('.mp3')]
    if mp3_files:
        print(f"Found {len(mp3_files)} .mp3 files.")
        api.delete_files(mp3_files, repo_id=repo_id, repo_type='space', commit_message="Clear mp3 audio cache to free up space")
        print("Successfully deleted mp3 files.")
    else:
        print("No .mp3 files found.")
except Exception as e:
    print(f"Error checking Space: {e}")
