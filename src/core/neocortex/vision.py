import os
import time
import base64
import logging
from io import BytesIO
from typing import Dict, Any, Optional
from PIL import Image
import mss

try:
    from src.core.local_ai_service import LocalAIService
except ImportError:
    from core.local_ai_service import LocalAIService

class NeocortexVision:
    """
    The Vision system of KALI's Neocortex.
    Handles screen capture, visual processing, and context synthesis.
    """
    def __init__(self, ai_service: Optional[LocalAIService] = None):
        self.logger = logging.getLogger(__name__)
        self.ai_service = ai_service or LocalAIService()
        self.sct = mss.mss()
        
        # Configuration
        self.capture_delay = 0.5
        self.max_image_size = (1024, 1024) # Optimize for VLM input
        self.vision_model = os.getenv("VISION_MODEL", "moondream:latest")

    def capture_screen(self, monitor_index: int = 1) -> Image.Image:
        """Capture the primary or specified monitor."""
        try:
            screenshot = self.sct.grab(self.sct.monitors[monitor_index])
            return Image.frombytes("RGB", screenshot.size, screenshot.bgra, "raw", "BGRX")
        except Exception as e:
            self.logger.error(f"Screen capture failed: {e}")
            raise

    def process_image(self, img: Image.Image) -> BytesIO:
        """Resize and compress image for efficient neural transfer."""
        # Maintain aspect ratio while fitting in max_image_size
        img.thumbnail(self.max_image_size, Image.Resampling.LANCZOS)
        
        img_byte_arr = BytesIO()
        img.save(img_byte_arr, format='JPEG', quality=85)
        img_byte_arr.seek(0)
        return img_byte_arr

    def get_screen_context(self, prompt: Optional[str] = None) -> Dict[str, Any]:
        """
        Main entry point: captures screen and returns visual context.
        """
        if not prompt:
            prompt = (
                "Describe what is happening on this screen right now. "
                "Identify active applications, open files, and the user's primary focus. "
                "Be concise and technical."
            )

        try:
            # 1. Capture
            img = self.capture_screen()
            
            # 2. Process
            img_io = self.process_image(img)
            
            # 3. Analyze via Local AI (targeting moondream/llava)
            self.logger.info(f"Synthesizing visual context using {self.vision_model}...")
            
            # Ensure we use the vision model specifically
            context_text = self.ai_service.analyze_image(
                img_io, 
                prompt=prompt
            )
            
            return {
                "timestamp": time.time(),
                "summary": context_text,
                "model": self.vision_model,
                "status": "success"
            }
            
        except Exception as e:
            self.logger.error(f"Vision synthesis failure: {e}")
            return {
                "timestamp": time.time(),
                "error": str(e),
                "status": "failure"
            }

    def close(self):
        """Release screen capture resources."""
        if self.sct:
            self.sct.close()

if __name__ == "__main__":
    # Quick Diagnostic
    logging.basicConfig(level=logging.INFO)
    vision = NeocortexVision()
    print("Initiating visual reflex...")
    res = vision.get_screen_context()
    print(f"\n[NEOCORTEX VISION]:\n{res['summary']}\n")
    vision.close()
