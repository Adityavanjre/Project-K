import os
import shutil
import zipfile
import logging
from datetime import datetime
from fpdf import FPDF
from typing import List, Dict, Any

class ReportGenerator:
    """
    KALI's Output Engine.
    Generates PDF research reports and ZIP project archives.
    """
    def __init__(self, output_dir="data/exports"):
        self.output_dir = output_dir
        os.makedirs(self.output_dir, exist_ok=True)
        self.logger = logging.getLogger(__name__)

    def generate_pdf_report(self, title: str, content: str, user_name: str = "Sir") -> str:
        """Create a professional PDF report of research findings."""
        try:
            pdf = FPDF()
            pdf.add_page()
            
            # Header
            pdf.set_font("Helvetica", "B", 16)
            pdf.cell(0, 10, "K.A.L.I. RESEARCH ARCHIVE", ln=True, align="C")
            pdf.set_font("Helvetica", "I", 10)
            pdf.cell(0, 10, f"Generated for: {user_name} | Date: {datetime.now().strftime('%Y-%m-%d %H:%M')}", ln=True, align="C")
            pdf.ln(10)
            
            # Title
            pdf.set_font("Helvetica", "B", 14)
            pdf.set_text_color(0, 102, 255) # Cyber Blue
            pdf.cell(0, 10, title.upper(), ln=True)
            pdf.set_text_color(0, 0, 0)
            pdf.ln(5)
            
            # Content
            pdf.set_font("Helvetica", size=11)
            # Replace non-latin characters if necessary or use Unicode font
            # For now, simple multi-line text
            pdf.multi_cell(0, 8, content)
            
            # Footer
            pdf.set_y(-20)
            pdf.set_font("Helvetica", "I", 8)
            pdf.cell(0, 10, "CONFIDENTIAL | Universal Intelligence Sovereignty | Phase 16 Output", align="C")
            
            filename = f"KALI_Report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
            filepath = os.path.join(self.output_dir, filename)
            pdf.output(filepath)
            
            self.logger.info(f"Report generated: {filepath}")
            return filepath
        except Exception as e:
            self.logger.error(f"PDF Generation failed: {e}")
            return ""

    def export_project_zip(self, project_name: str, files: List[Dict[str, str]]) -> str:
        """Package code files into a ZIP archive for the user."""
        try:
            zip_filename = f"{project_name.replace(' ', '_')}_{datetime.now().strftime('%Y%m%d')}.zip"
            zip_path = os.path.join(self.output_dir, zip_filename)
            
            with zipfile.ZipFile(zip_path, 'w') as zf:
                for file_info in files:
                    # file_info = {"name": "main.py", "content": "print('hello')"}
                    zf.writestr(file_info["name"], file_info["content"])
            
            self.logger.info(f"Project exported: {zip_path}")
            return zip_path
        except Exception as e:
            self.logger.error(f"ZIP Export failed: {e}")
            return ""
