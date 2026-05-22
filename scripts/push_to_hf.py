import os
import json
from huggingface_hub import HfApi, create_repo
from dotenv import load_dotenv

load_dotenv()

def push_models():
    # Fetch configurations from environment variables (Zero Hardcoding)
    token = os.getenv("HF_TOKEN")
    repo_name = os.getenv("HF_REPO_NAME", "KALI-Sovereign-Models")
    models_dir = os.getenv("MODELS_DIR", "models")
    weights_dir = os.getenv("WEIGHTS_DIR", "kali_weights")
    code_path_in_repo = os.getenv("CODE_PATH_IN_REPO", "code")

    if not token:
        print("ERROR: HF_TOKEN not found in .env")
        return

    api = HfApi(token=token)
    
    try:
        user = api.whoami()
        username = user["name"]
        repo_id = f"{username}/{repo_name}"
        print(f"KALI: Initializing Dynamic Hugging Face Repository: {repo_id}")
    except Exception as e:
        print(f"ERROR fetching user info: {e}")
        return
    
    try:
        create_repo(repo_id=repo_id, token=token, repo_type="model", exist_ok=True, private=True)
        print(f"Repository {repo_id} is ready.")
    except Exception as e:
        print(f"Repository initialization warning: {e}")

    # --- Models Migration ---
    if os.path.exists(models_dir):
        files = [f for f in os.listdir(models_dir) if f.endswith(".gguf")]
        print(f"Found {len(files)} models in {models_dir} to migrate.")

        for file in files:
            file_path = os.path.join(models_dir, file)
            size_gb = os.path.getsize(file_path) / (1024**3)
            print(f"Pushing {file} ({size_gb:.2f} GB) to Hub...")
            
            try:
                api.upload_file(
                    path_or_fileobj=file_path,
                    path_in_repo=f"{models_dir}/{file}",
                    repo_id=repo_id,
                    repo_type="model",
                )
                print(f"Successfully pushed model: {file}")
            except Exception as e:
                print(f"Failed to push model {file}: {e}")
    else:
        print(f"Directory {models_dir} not found. Skipping.")

    # --- Weights Migration ---
    if os.path.exists(weights_dir):
        print(f"Pushing weights from {weights_dir} to Hub...")
        try:
            api.upload_folder(
                folder_path=weights_dir,
                path_in_repo=weights_dir,
                repo_id=repo_id,
                repo_type="model",
            )
            print(f"Successfully pushed weights from: {weights_dir}")
        except Exception as e:
            print(f"Failed to push weights: {e}")

    # --- Codebase Migration ---
    print(f"Pushing codebase to Hub under path: {code_path_in_repo}")
    try:
        api.upload_folder(
            folder_path=".",
            path_in_repo=code_path_in_repo,
            repo_id=repo_id,
            repo_type="model",
            ignore_patterns=[
                f"{models_dir}/*", f"{weights_dir}/*", "node_modules/*", 
                ".git/*", ".venv/*", "venv/*", "data/*", 
                "**/__pycache__/*", "*.gguf", "*.zip"
            ]
        )
        print("Successfully synced codebase to Hugging Face.")
    except Exception as e:
        print(f"Failed to sync codebase: {e}")

if __name__ == "__main__":
    push_models()
