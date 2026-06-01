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

print("Scanning Hugging Face Space for large files to delete...")
try:
    files = api.list_repo_files(repo_id, repo_type='space')
    large_files = [f for f in files if f.endswith('.gguf') or f.endswith('.bin') or f.endswith('.pt') or f.endswith('.safetensors')]
    if large_files:
        print(f"Found large files taking up space: {large_files}")
        api.delete_files(large_files, repo_id=repo_id, repo_type='space', commit_message="Clear space for build")
        print("Successfully deleted large files.")
    else:
        print("No .gguf or .bin files found. The repository git history might be taking up space.")
except Exception as e:
    print(f"Error checking Space: {e}")
