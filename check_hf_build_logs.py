import os
import sys
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
    sys.exit(1)

api = HfApi(token=token)
repo_id = 'adityavanjre/project-k'

# Get build level or run level logs
is_build = True
if len(sys.argv) > 1 and sys.argv[1] == 'run':
    is_build = False

print(f"Fetching {'build' if is_build else 'run'} logs for {repo_id}...")
try:
    log_iter = api.fetch_space_logs(repo_id=repo_id, build=is_build)
    # Collect some logs since it is an iterable
    logs_list = []
    for line in log_iter:
        logs_list.append(line)
        if len(logs_list) > 200: # Limit lines to avoid huge output
            logs_list.pop(0)
    out_str = "".join(logs_list)
    sys.stdout.buffer.write(out_str.encode("utf-8", errors="replace"))
    sys.stdout.buffer.flush()
except Exception as e:
    err_str = "Error fetching logs: " + str(e) + "\n"
    sys.stdout.buffer.write(err_str.encode("utf-8", errors="replace"))
    sys.stdout.buffer.flush()
