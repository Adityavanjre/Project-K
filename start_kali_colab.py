# KALI Singularity: Sovereign Ascension (Google Colab T4)
# Paste this into a single cell in Google Colab and RUN.

import os
import subprocess
import sys

# 1. Configuration (Set your Ngrok token here)
NGROK_TOKEN = "YOUR_NGROK_AUTHTOKEN_HERE" 
PROJECT_NAME = "doubt-clearing-ai"

def run_cmd(cmd):
    print(f">>> Executing: {cmd}")
    subprocess.run(cmd, shell=True, check=True)

try:
    # 2. Mount Google Drive
    from google.colab import drive
    drive.mount('/content/drive')
    
    # 3. Navigate to Project
    project_path = f"/content/drive/MyDrive/{PROJECT_NAME}"
    if not os.path.exists(project_path):
        print(f"ERROR: Project not found at {project_path}. Please ensure you uploaded 'doubt-clearing-ai' to your Google Drive root.")
        sys.exit(1)
        
    os.chdir(project_path)
    print(f"COGNITIVE_RESONANCE: Anchored at {project_path}")

    # 4. Install specialized Colab requirements
    print("SUMMONING_DEPENDENCIES (T4_OPTIMIZED)...")
    run_cmd("pip install -r requirements_colab.txt")
    run_cmd("pip install git+https://github.com/huggingface/transformers.git") # Ensure latest for Unsloth
    
    # 5. Set up Ngrok
    if NGROK_TOKEN != "YOUR_NGROK_AUTHTOKEN_HERE":
        print("INITIATING_SECURE_TUNNEL...")
        import ngrok
        ngrok.set_code(NGROK_TOKEN)
        listener = ngrok.forward(5000, authtoken=NGROK_TOKEN)
        print(f"\n🚀 KALI DASHBOARD ACCESS: {listener.url()}\n")
    else:
        print("\n⚠️ WARNING: NGROK_TOKEN NOT SET. You will not be able to access the UI from your browser.")
        print("Please stop this cell, update the NGROK_TOKEN variable, and run again.\n")

    # 6. Launch KALI
    print("IGNITING_NEURAL_CORE...")
    os.environ["USE_LOCAL_AI"] = "true" # Force local model on T4
    os.environ["FLASK_ENV"] = "production"
    
    # We use a simple python call to start the web app
    run_cmd("python src/web_app.py")

except Exception as e:
    print(f"ASCENSION_FAILED: {e}")
