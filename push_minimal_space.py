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

print('Deploying core web files...')
for file in ['start_web.py', 'requirements.txt', 'Dockerfile', 'README.md']:
    if os.path.exists(file):
        api.upload_file(path_or_fileobj=file, path_in_repo=file, repo_id=repo_id, repo_type='space', commit_message="Fix requirements.txt wandb version")

print('Deployment Complete!')
