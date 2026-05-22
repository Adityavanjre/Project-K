#!/usr/bin/env python3
import os
import shutil
import json
from datetime import datetime

def export_for_cloud():
    """
    KALI CLOUD EXPORT
    Prepares interaction logs and preference data for remote GPU training (Colab/RunPod).
    """
    print("☁️  KALI CLOUD EXPORT: Preparing Sovereign Data...")
    print("-" * 60)
    
    export_dir = os.path.join("data", "exports", datetime.now().strftime("%Y%m%d_%H%M%S"))
    os.makedirs(export_dir, exist_ok=True)
    
    files_to_export = [
        "data/training_data.jsonl",
        "data/preference_data.jsonl",
        "config/config.json",
        "scripts/train_model.py"
    ]
    
    exported_count = 0
    for file in files_to_export:
        if os.path.exists(file):
            shutil.copy(file, export_dir)
            print(f"[+] Exported: {file}")
            exported_count += 1
        else:
            print(f"[-] Missing: {file} (Skipping)")
            
    if exported_count > 0:
        print("-" * 60)
        print(f"✅ EXPORT COMPLETE: {exported_count} files archived.")
        print(f"📍 Location: {os.path.abspath(export_dir)}")
        print("\nINSTRUCTION: Upload this directory to Google Colab or similar GPU node.")
        print("Run 'python train_model.py' on the remote node to initiate Evolution.")
    else:
        print("[!] FAILED: No data found to export.")

if __name__ == "__main__":
    export_for_cloud()
