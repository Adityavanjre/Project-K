# KALI Sovereign Colab Bootstrapper
# Paste this into a single cell in Google Colab (https://colab.research.google.com/)

# 1. MOUNT DRIVE AND SET UP ENVIRONMENT
from google.colab import drive
import os
import subprocess

print(">>> MOUNTING SOVEREIGN MEMORY (GOOGLE DRIVE)...")
drive.mount('/content/drive')

# 2. DEFINITIONS
PROJECT_FOLDER = "/content/drive/MyDrive/KALI_Sovereign" # Change if needed
NGROK_TOKEN = "3BXU4SKODfpfM4FhSatkqXWle9d_6gfuUkpoyPH3Ru6HeoLgU"

# 3. INITIALIZE DIRECTORY
if not os.path.exists(PROJECT_FOLDER):
    print(f">>> CRITICAL: Please ZIP your local 'doubt-clearing-ai' folder, upload it to Google Drive, and rename it to 'KALI_Sovereign'.")
    print(f">>> Then restart this cell. I am waiting...")
else:
    os.chdir(PROJECT_FOLDER)
    print(f">>> NAVIGATED TO SOVEREIGN HUB: {PROJECT_FOLDER}")

    # 4. INSTALL DEPENDENCIES (FAST INSTALL)
    print(">>> INSTALLING NEURAL ARCHITECTURE DEPENDENCIES...")
    # Skipping heavy torch installs as colab has them, focusing on app requirements
    %pip install -r requirements.txt
    %pip install pyngrok flask-cors waitress

    # 5. START NGROK TUNNEL
    print(">>> INITIATING SECURE NGROK TUNNEL...")
    from pyngrok import ngrok
    ngrok.set_auth_token(NGROK_TOKEN)
    
    # Open local port 8000
    public_url = ngrok.connect(8000).public_url
    print(f"\n🚀 KALI SOVEREIGN INTERFACE ACCESSIBLE AT:\n{public_url}\n")

    # 6. BOOT KALI
    print(">>> BOOTING KALI OMEGA PROTOCOL...")
    !export PYTHONPATH=$PYTHONPATH:. && python start_web.py
