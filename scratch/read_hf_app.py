import os
import sys
from huggingface_hub import hf_hub_download

if sys.platform.startswith('win'):
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def load_token():
    if os.path.exists('.env'):
        with open('.env', 'r') as f:
            for line in f:
                if line.startswith('HF_TOKEN='):
                    return line.strip().split('=', 1)[1].strip('"\'')
    return os.environ.get('HF_TOKEN')

token = load_token()
repo_id = 'adityavanjre/project-k'

try:
    path = hf_hub_download(repo_id=repo_id, filename='data/wealth_ledger.json', repo_type='space', token=token)
    with open(path, 'r', encoding='utf-8') as f:
        print("Content of remote data/wealth_ledger.json:")
        print(f.read())
except Exception as e:
    print("Error reading wealth_ledger.json:", str(e))
