import os
import sys
import logging

# Set up logging to see BIOS output
logging.basicConfig(level=logging.INFO)

# Add src to path
sys.path.append(os.path.abspath("src"))

from core.secure_boot import BootGuardian

bios = BootGuardian(".")
success = bios.perform_secure_boot()

print(f"BIOS Success: {success}")
print(f"BIOS Status: {bios.get_bios_status()}")
