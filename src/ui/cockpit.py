import os
import sys
import time
from datetime import datetime
from typing import Dict, Any, List

from rich.console import Console
from rich.layout import Layout
from rich.panel import Panel
from rich.live import Live
from rich.table import Table
from rich.text import Text
from rich.progress import BarColumn, Progress, TextColumn
from rich.columns import Columns

class SovereignCockpit:
    """
    KALI SOVEREIGN COCKPIT [TUI ENGINE]
    Powered by Rich — Zero Relay Mode.
    """
    def __init__(self, processor):
        self.processor = processor
        self.console = Console()
        self.layout = Layout()
        self.history = []
        self.start_time = datetime.now()
        
        # UI Configuration
        self._setup_layout()

    def _setup_layout(self):
        """Initializes a clean, single-pane interaction surface."""
        self.layout.split(
            Layout(name="header", size=3),
            Layout(name="body", ratio=1),
            Layout(name="footer", size=3)
        )

    def _get_header(self) -> Panel:
        """Renders the top status bar."""
        try:
            status = self.processor.get_system_status()
        except:
            status = {}
        uptime = str(datetime.now() - self.start_time).split(".")[0]
        
        is_sov = status.get("is_sovereign", False)
        sov_color = "green" if is_sov else "red"
        
        # BIOS safety
        bios_status = getattr(self.processor, "boot_guardian", None)
        is_bios = bios_status.is_secure_ready if bios_status else False
        bios_color = "green" if is_bios else "red"
        bios_text = "SECURE" if is_bios else "BREACH"
        
        # Ollama health
        is_ollama = getattr(self.processor.ai_service, "is_connected", False)
        ollama_color = "green" if is_ollama else "red"
        ollama_text = "OLLAMA" if is_ollama else "OFFLINE"
        
        grid = Table.grid(expand=True)
        grid.add_column(justify="left", ratio=1)
        grid.add_column(justify="center", ratio=1)
        grid.add_column(justify="right", ratio=1)
        
        grid.add_row(
            Text(f" 🔱 KALI SOVEREIGN v4.0 ", style="bold white on blue"),
            Text(f" {status.get('sovereign_msg', 'UNKNOWN')} | {ollama_text} | BIOS:{bios_text} ", style=f"bold {sov_color}"),
            Text(f" UPTIME: {uptime} ", style="dim")
        )
        
        return Panel(grid, style="blue")

    def _get_swarm_panel(self) -> Panel:
        """Renders the swarm telemetry pane."""
        try:
            status = self.processor.get_system_status()
        except:
            status = {}
        swarm = status.get("swarm_status", {})
        
        table = Table(box=None, expand=True)
        table.add_column("Node", style="cyan")
        table.add_column("Status", style="magenta")
        
        if isinstance(swarm, dict):
            for node, state in swarm.items():
                table.add_row(node.upper(), str(state))
        else:
            table.add_row("SWARM", str(swarm))

        metrics = Table.grid(padding=(0, 1))
        metrics.add_row("CPU", f"{status.get('cpu_usage', 0):.1f}%")
        metrics.add_row("MEM", f"{status.get('memory_usage', 0):.1f}%")
        metrics.add_row("DNA", f"{status.get('dna_count', 0)}")
        
        # Use a list of renderables or a Table for the side layout
        side_grid = Table.grid(expand=True)
        side_grid.add_row(Panel(table, title="Swarm Nodes", border_style="cyan"))
        side_grid.add_row(Panel(metrics, title="Telemetry", border_style="magenta"))
        
        return Panel(side_grid, title="[ SYSTEM ]", border_style="cyan")

    def _get_bio_panel(self) -> Panel:
        """Renders the biometrics and alignment pane."""
        try:
            status = self.processor.get_system_status()
        except:
            status = {}
        tension = status.get("tension", 0)
        alignment = status.get("alignment_status", "0")
        
        try:
            if isinstance(alignment, str):
                alignment = float(alignment.strip('%'))
            else:
                alignment = float(alignment)
        except:
            alignment = 0.0

        tension_color = "green" if tension < 0.4 else "yellow" if tension < 0.7 else "red"
        
        bio_grid = Table.grid(expand=True)
        bio_grid.add_row(Text("Neural Tension", style="dim"))
        bio_grid.add_row(f"[{tension_color}]{'█' * int(tension * 20)}{'░' * (20 - int(tension * 20))} {tension*100:.1f}%")
        bio_grid.add_row("")
        bio_grid.add_row(Text("Alignment Score", style="dim"))
        bio_grid.add_row(f"[bold cyan]{alignment:.1f}% Sovereign Sync")
        
        preds = status.get("next_predictions", [])
        pred_text = Text("\nIntent Stream:\n", style="bold italic")
        for p in preds[:3]:
            pred_text.append(f" • {p}\n", style="dim cyan")
            
        res_grid = Table.grid()
        res_grid.add_row(bio_grid)
        res_grid.add_row(pred_text)
            
        return Panel(res_grid, title="[ BIOMETRICS ]", border_style="magenta")

    def _get_body_panel(self) -> Panel:
        """Renders the main cognition console."""
        text = Text()
        # Filter and render history
        for sender, msg in self.history[-15:]:
            if sender == "KALI":
                color = "bold cyan"
            elif sender == "SYSTEM":
                color = "bold white"
            elif sender == "ERROR":
                color = "bold red"
            elif sender == "SECURITY":
                color = "bold blue"
            else:
                color = "bold yellow" # User
                
            text.append(f"{sender:10}> ", style=color)
            text.append(f"{msg}\n")
            
        return Panel(text, title="[ COGNITION CONSOLE ]", border_style="white")

    def _get_footer(self, current_input: str = "") -> Panel:
        """Renders the command input area."""
        return Panel(Text(f"> {current_input}", style="bold green"), title="[ INPUT ]", border_style="blue")

    def update(self, current_input: str = ""):
        """Refreshes all layout components."""
        self.layout["header"].update(self._get_header())
        self.layout["body"].update(self._get_body_panel())
        self.layout["footer"].update(self._get_footer(current_input))

    def log(self, sender: str, message: str):
        """Adds a message to the cognition history."""
        self.history.append((sender, message))
        if len(self.history) > 100:
            self.history.pop(0)

    def render(self, live: Live, current_input: str = ""):
        """Updates the live display."""
        self.update(current_input)
        live.update(self.layout)
