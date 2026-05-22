import os
import json
import hashlib

def generate_checksums():
    root = r'c:\Users\adity\code\Project-K'
    core_dir = os.path.join(root, 'src', 'core')
    checksums = {}
    
    for f in os.listdir(core_dir):
        if f.endswith('.py'):
            path = os.path.join(core_dir, f)
            with open(path, 'rb') as file:
                hash_hex = hashlib.sha256(file.read()).hexdigest()
                rel_path = f"src/core/{f}"
                checksums[rel_path] = hash_hex
                
    out_path = os.path.join(root, 'data', 'checksums.kali')
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(checksums, f, indent=4)
    print(f'Generated checksums for {len(checksums)} files.')

if __name__ == '__main__':
    generate_checksums()
