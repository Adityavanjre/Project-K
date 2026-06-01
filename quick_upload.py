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

try:
    api.upload_file(
        path_or_fileobj='start_web.py',
        path_in_repo='start_web.py',
        repo_id='adityavanjre/project-k',
        repo_type='space'
    )
    print('SUCCESS')
except Exception as e:
    print('FAIL:', str(e))
