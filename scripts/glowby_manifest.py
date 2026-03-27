import os
import sys
import asyncio
import logging

# Add src to path
sys.path.append(os.getcwd())

from src.core.ai_service import AIService
from src.core.tools.visual_tools import VisualManifestationTool

async def demonstrate_manifestation():
    logging.basicConfig(level=logging.INFO)
    print("--- KALI Visual Manifestation Channel (Glowby-Inspired) ---")
    
    ai = AIService("./config") # Mock config or None
    v_tool = VisualManifestationTool(ai)
    
    # 1. UI Manifestation
    sketch = "A glassmorphism dashboard showing real-time biometric pulse, CPU usage, and KALI's current thought-stream."
    print(f"\nManifesting UI: {sketch}")
    ui_code = v_tool.manifest_from_sketch(sketch)
    
    # Save the manifest
    output_path = "d:/code/doubt-clearing-ai/data/manifests/biometric_dashboard.tsx"
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(ui_code)
    print(f"UI Code manifested to {output_path}")

    # 2. CAD Manifestation
    part = "A structural base for a balcony-mounted vertical hydroponic tower with M5 screw holes."
    print(f"\nManifesting CAD: {part}")
    cad_code = v_tool.generate_cad_model(part)
    
    cad_path = "d:/code/doubt-clearing-ai/data/manifests/hydro_base.scad"
    with open(cad_path, "w", encoding="utf-8") as f:
        f.write(cad_code)
    print(f"CAD Model manifested to {cad_path}")

if __name__ == "__main__":
    asyncio.run(demonstrate_manifestation())
