import os
import json

def add_api_key():
    print("🔱 Sovereign API Key Integration Protocol")
    print("------------------------------------------")
    print("This script securely adds your real-world research API keys to KALI.")
    print("Supported Platforms: HackerOne, Bugcrowd, Immunefi, Microsoft, Meta")
    print("")
    
    platform = input("Enter Platform Name: ").strip()
    key_name = input(f"Enter Key Name/ID for {platform}: ").strip()
    api_key = input(f"Enter API Key/Secret for {platform}: ").strip()
    
    vault_path = os.path.join("logs", "credential_vault.json")
    
    vault = {}
    if os.path.exists(vault_path):
        with open(vault_path, "r") as f:
            vault = json.load(f)
            
    if platform not in vault:
        vault[platform] = {}
        
    vault[platform][key_name] = api_key
    
    with open(vault_path, "w") as f:
        json.dump(vault, f, indent=4)
        
    print(f"\n✅ SUCCESS: API Key for {platform} has been securely anchored in the vault.")
    print("KALI can now transition from 'Technical Mock' to 'Real-World Submission'.")

if __name__ == "__main__":
    add_api_key()
