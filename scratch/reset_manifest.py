import os
import sys
import logging

logging.basicConfig(level=logging.INFO)
sys.path.append(os.path.abspath("src"))

from core.integrity import IntegrityService

service = IntegrityService(".")
service.reset_sovereignty()
print("Sovereignty Reset Complete.")
