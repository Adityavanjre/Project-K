import hashlib
import sys
import os

def get_sha256(file_path):
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python hash_file.py <file_path>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    if os.path.exists(file_path):
        print(get_sha256(file_path))
    else:
        print(f"File not found: {file_path}")
        sys.exit(1)
