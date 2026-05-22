#!/usr/bin/env python3
import os
import sys
import argparse
import logging

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, os.path.join(project_root, 'src'))

from core.processor import DoubtProcessor

def main():
    parser = argparse.ArgumentParser(description="KALI Sovereign Command Bridge")
    parser.add_argument("query", type=str, help="The instruction for KALI")
    parser.add_argument("--role", type=str, default="general", help="KALI's persona (general, engineer, economist, etc.)")
    args = parser.parse_args()

    # Suppress non-critical logs
    logging.getLogger().setLevel(logging.ERROR)
    
    processor = DoubtProcessor()
    
    # Prepend Sovereign Directive for consistency
    full_query = args.query
    if args.role != "general":
        full_query = f"ACTIVATE ROLE: {args.role.upper()}. Task: {args.query}"

    print(f"\n[*] TRANSMITTING TO KALI CORE: {full_query[:100]}...")
    
    res = processor.process_doubt(full_query)
    
    print("\n--- [KALI SOVEREIGN RESPONSE] ---")
    if isinstance(res, dict):
        print(res.get("text", str(res)))
    else:
        print(res)
    print("---------------------------------")

if __name__ == "__main__":
    main()
