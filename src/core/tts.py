"""
Text-to-Speech (TTS) module for Project-K.
Uses gTTS (Google Text-to-Speech) to generate audio from text.
"""

import os
import uuid
from gtts import gTTS
import logging

logger = logging.getLogger(__name__)

class TTSGenerator:
    """Handles text-to-speech generation."""
    
    def __init__(self, output_dir="src/static/audio"):
        """Initialize TTS generator with output directory."""
        self.output_dir = output_dir
        
        # Ensure output directory exists
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)
            logger.info(f"Created audio directory: {self.output_dir}")

    def generate_audio(self, text: str, lang: str = 'en') -> str:
        """
        Generate audio file from text.
        
        Args:
            text (str): The text to convert to speech.
            lang (str): Language code (default: 'en').
            
        Returns:
            str: The filename of the generated audio (relative to static folder).
        """
        try:
            # Generate unique filename
            filename = f"speech_{uuid.uuid4().hex}.mp3"
            filepath = os.path.join(self.output_dir, filename)
            
            # Generate audio
            logger.info(f"Generating audio for text: {text[:30]}...")
            tts = gTTS(text=text, lang=lang, slow=False)
            tts.save(filepath)
            
            logger.info(f"Audio saved to: {filepath}")
            
            # Return path relative to static folder for frontend access
            # Assuming output_dir is src/static/audio, we return audio/filename
            return f"audio/{filename}"
            
        except Exception as e:
            logger.error(f"TTS Generation failed: {e}")
            return ""
