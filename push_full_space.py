import os
from huggingface_hub import HfApi

def load_token():
    if os.path.exists(".env"):
        with open(".env", "r") as f:
            for line in f:
                if line.startswith("HF_TOKEN="):
                    return line.strip().split("=", 1)[1].strip('"\'')
    return os.environ.get("HF_TOKEN")

def deploy_to_hf_space():
    print("Initializing Hugging Face deployment...")
    token = load_token()
    if not token:
        print("ERROR: HF_TOKEN not found in .env or environment variables!")
        return
    
    api = HfApi(token=token)
    
    # Identify the target Space
    repo_id = "adityavanjre/project-k"
    
    print(f"Uploading entire KALI workspace to {repo_id}...")
    
    # We will upload the current directory, but ignore heavy local artifacts
    ignore_patterns = [
        ".git/*",
        ".git",
        "venv/*",
        "venv",
        "models/*",
        "models",
        "__pycache__/*",
        "*.zip",
        "Project-K-Sovereign-Core.zip",
        "*.db",
        "data/*",
        "knowledge/*",
        "kali_weights/*",
        "graphify-out/*",
        "graphify-out",
        ".pytest_cache/*",
        ".sovereign_cloud/*",
        "node_modules/*",
        "node_modules",
        "**/node_modules/*",
        "**/node_modules",
        ".next/*",
        ".next",
        ".cache/*",
        ".cache",
        "reports/*",
        "reports",
        "archive/*",
        "archive",
        "results/*",
        "results",
        "kali-memory-out/*",
        "kali-memory-out",
        ".understand-anything/*",
        ".understand-anything"
    ]
    
    try:
        api.upload_folder(
            folder_path=".",
            repo_id=repo_id,
            repo_type="space",
            ignore_patterns=ignore_patterns,
            commit_message="Deploying Sovereign Wealth and Core Logic Updates"
        )
        print("Successfully deployed the full KALI workspace to the Hugging Face Space!")
        print(f"You can monitor the build at: https://huggingface.co/spaces/{repo_id}")
    except Exception as e:
        print(f"Failed to deploy to Hugging Face: {e}")

if __name__ == "__main__":
    deploy_to_hf_space()
