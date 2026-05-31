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

files_to_upload = [
    "src/core/task_manager.py",
    "src/core/channels/telegram_channel.py",
    "src/core/processor.py",
    "src/core/tools/hackerone_tool.py",
    "src/bug_hunter.py",
    "config/config.json"
]

for file_path in files_to_upload:
    try:
        api.upload_file(
            path_or_fileobj=file_path,
            path_in_repo=file_path,
            repo_id='adityavanjre/project-k',
            repo_type='space'
        )
        print(f'SUCCESS: {file_path}')
    except Exception as e:
        print(f'FAIL {file_path}:', str(e))
