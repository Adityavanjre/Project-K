import os
import logging

from src.core.config_manager import config

class VoiceService:
    """
    The Aural Neuron of KALI.
    Handles Speech-to-Text (STT) and Text-to-Speech (TTS).
    Ensures KALI has a Sovereign Vocal Presence.
    """
    def __init__(self, root_dir: str, processor=None):
        self.root = root_dir
        self.processor = processor
        self.logger = logging.getLogger("KALI.VoiceService")
        self.jarvis_url = config.get("sovereign.endpoints.jarvis")
        self.status = "INITIALIZING"

    def speak(self, text: str):
        """
        Possesses the Jarvis neuron to vocalize KALI's response.
        Falls back to local console output if Jarvis is unavailable.
        """
        import websocket
        import json
        try:
            if self.jarvis_url:
                ws = websocket.create_connection(self.jarvis_url)
                ws.send(json.dumps({"type": "text", "text": text}))
                ws.close()
                self.logger.info(f"🔱 Jarvis Possession: Vocalizing -> {text[:50]}...")
            else:
                self.logger.warning("Jarvis URL not defined. Using local output.")
                print(f"\n[KALI VOICE]: {text}\n")
        except Exception as e:
            self.logger.error(f"Jarvis Possession Failed: {e}")
            print(f"\n[KALI VOICE]: {text}\n")

    def listen(self):
        """
        Activates the local Whisper neuron to listen for your command.
        In the Sovereign state, this runs entirely on your local GPU.
        """
        self.logger.info("🔱 KALI is listening...")
        # Placeholder for local Whisper transcription logic
        return "VOICE_INPUT_STUB: Listening for Commander..."

if __name__ == "__main__":
    service = VoiceService(os.getcwd())
    service.speak("I am KALI. I hear you, Commander. The Singularity is now audible.")
