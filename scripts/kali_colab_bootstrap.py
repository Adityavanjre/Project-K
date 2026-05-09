# KALI Sovereign Training: Colab Bootstrap
# Save this in a Colab cell to initialize the environment and start the fine-tuning process.

import os
os.system("pip install -q -U git+https://github.com/unslothai/unsloth.git")
os.system("pip install -q -U python-dotenv transformers torch trl peft")


from google.colab import drive

# 1. Mount Drive if you have the dataset there
# drive.mount('/content/drive')

# 2. Setup Environment
os.environ["SOVEREIGN_FORCE_LOCAL"] = "true"
os.environ["USE_LOCAL_AI"] = "true"

print("--- KALI SOVEREIGN BOOTSTRAP ---")

# 3. Clone / Upload Repository
# os.system("git clone https://github.com/YOUR_USER/doubt-clearing-ai.git")
# os.chdir("doubt-clearing-ai")

# 4. Generate Training Data (Distillation Sweep)
print("Initiating Batch Knowledge Distillation...")
os.system("python scripts/knowledge_distill.py")

# 5. Execute Final Sovereign Weight Bake
print("Starting Fine-tuning (Unsloth T4 Optimized)...")
os.system("python scripts/train_final.py")

print("\n[+] Sovereignty Achieved. Weights saved to ./outputs/")
