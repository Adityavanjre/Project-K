#!/usr/bin/env python3
"""
KALI Wallet Anchor
Anchors the creator's wallet address in UserDNA and Config.
"""

import os
import sys
import json
import logging

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from core.user_dna import UserDNA
from utils.helpers import load_config, save_config

def anchor_wallet(wallet_address):
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("WALLET_ANCHOR")
    
    print(f"[*] ANCHORING WALLET: {wallet_address}")
    print("-" * 60)
    
    # 1. Update UserDNA
    dna = UserDNA()
    dna.save_dna_fact("creator_wallet", wallet_address)
    logger.info("Wallet anchored in UserDNA.")
    
    # 2. Update config/config.json
    config_path = os.path.join(os.path.dirname(__file__), '..', 'config', 'config.json')
    config = load_config(config_path)
    
    if "wealth" not in config:
        config["wealth"] = {}
    
    config["wealth"]["creator_wallet"] = wallet_address
    save_config(config_path, config)
    logger.info("Wallet anchored in config/config.json.")
    
    print("-" * 60)
    print("[+] SUCCESS: Wallet address anchored in the Sovereign Mesh.")

if __name__ == "__main__":
    wallet = "0x132ff51aa59a31a6bffdcde2d0b6bf22eda6815d"
    anchor_wallet(wallet)
