import os
import sys
import time
import logging
import uuid
from typing import Optional, Dict, Any

from rich.console import Console
from rich.panel import Panel
from rich.text import Text
from rich.theme import Theme

# Add src to path
sys.path.insert(0, os.path.join(os.getcwd(), 'src'))

from core.processor import DoubtProcessor

# Configuration
KALI_THEME = Theme({
    "kali": "bold cyan",
    "commander": "bold yellow",
    "system": "bold white",
    "error": "bold red",
    "security": "bold blue",
})

class CleanSovereignTUI:
    """
    🔱 KALI SOVEREIGN - CLEAN CHAT INTERFACE
    Eliminates flicker, repetition, and layout mess.
    """
    def __init__(self):
        self.console = Console(theme=KALI_THEME)
        self.processor = DoubtProcessor({"project_root": os.getcwd()})
        self.is_running = True
        
    def _print_header(self):
        """Prints a single, clean header at the start."""
        status = self.processor.get_system_status()
        is_ollama = getattr(self.processor.ai_service, "is_connected", False)
        ollama_text = "OLLAMA" if is_ollama else "OFFLINE"
        
        header = Panel(
            Text.from_markup(
                f"🔱 [bold white on blue] KALI SOVEREIGN v4.0 [/] | [bold green]{status.get('sovereign_msg', 'SOVEREIGN')}[/] | [bold]{ollama_text}[/]\n"
                f"[dim]Deep Hardware Verified | Neural Tunnel Active[/]"
            ),
            border_style="blue",
            expand=False
        )
        self.console.print(header)
        self.console.print("\n[dim]Initialization complete. Type 'exit' to shutdown.[/]\n")
        
        # Silence verbose background logs from cluttering the TUI
        logging.getLogger().setLevel(logging.WARNING)
        logging.getLogger("core.processor").setLevel(logging.WARNING)
        logging.getLogger("core.local_ai_service").setLevel(logging.WARNING)

    def log(self, sender: str, message: str):
        """Prints a clean, formatted message to the terminal."""
        style = sender.lower()
        if style not in KALI_THEME.styles: style = "system"
        
        self.console.print(f"[{style}]{sender.upper():10}>[/{style}] {message}")

    def main_loop(self):
        self._print_header()
        user_name = self.processor.user_dna.get_name() or "COMMANDER"
        
        while self.is_running:
            try:
                # Use a simple, non-flickering input prompt
                user_input = self.console.input(f"\n[bold yellow]{user_name} > [/]").strip()
                
                if not user_input:
                    continue
                
                if user_input.lower() in ['exit', 'quit', 'bye']:
                    self.log("SYSTEM", "Shutting down KALI Sovereign...")
                    break

                # Process Interaction
                self.log("SYSTEM", "Cognition in progress...")
                
                # Cognitive Flow
                response = self.processor.process_doubt(user_input)
                
                # Clear the "progress" line (approximate)
                # self.console.print("\033[F\033[K", end="")
                
                # Display KALI's response
                self.log("KALI", response.get("text", response.get("answer", "No response generated.")))
                
                # Reasoning Trace if available
                if "reasoning_trace" in response:
                    trace = response["reasoning_trace"]
                    self.console.print(Panel(Text(trace, style="dim cyan"), title="[ REASONING TRACE ]", border_style="dim"))

            except KeyboardInterrupt:
                break
            except Exception as e:
                self.log("ERROR", f"Interference Detected: {str(e)}")

        self.console.print("\n[bold red]🔱 KALI SOVEREIGN OFFLINE.[/]\n")

if __name__ == "__main__":
    tui = CleanSovereignTUI()
    tui.main_loop()
