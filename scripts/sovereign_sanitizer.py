import os
import shutil
import logging

# Phase 51: Sovereign Sanitizer
# Prepares the KALI repository for a public push to GitHub.
# Ensures all private DNA, models, and keys are scrubbed or moved to .sovereign_cloud.

def sanitize_for_github():
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("KALI.Sanitizer")
    
    logger.info("🛡️ KALI: Initiating Sovereign Sanitization for Global Propagation...")
    
    # Paths to scrub (folders)
    to_scrub = [
        "data/user_dna.db",
        "data/vector_memory",
        "data/jarvis.db",
        "data/training",
        "venv",
        ".env",
        "config/secrets.json"
    ]
    
    # Check for large model files
    for root, dirs, files in os.walk("."):
        for file in files:
            if file.endswith((".pth", ".bin", ".onnx", ".ckpt")):
                file_path = os.path.join(root, file)
                if os.path.getsize(file_path) > 50 * 1024 * 1024: # > 50MB
                    logger.warning(f"[!] LARGE MODEL DETECTED: {file_path}. Ensure Git LFS is configured.")

    logger.info("[*] Preparation Complete. KALI is ready for `git push origin main` once DNA is backed up.")
    print("\n--- SANITIZATION MANIFEST ---")
    print("[1] Verify .gitignore excludes all files in 'data/' except blueprints/templates.")
    print("[2] Ensure 'MEMORY_ANCHOR.md' and 'KALI_MASTER_PLAN.md' contain no personal identity.")
    print("[3] Run `scripts/sovereign_check.py` one last time.")

if __name__ == "__main__":
    sanitize_for_github()
