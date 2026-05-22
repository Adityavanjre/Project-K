import logging
import os
from typing import List, Dict, Any, Optional
from pypdf import PdfReader
from .vector_memory import VectorMemory

class DocumentIngestor:
    """
    KALI's Deep Reading Engine.
    Ingests PDFs, chunks them with sliding windows, and stores in Vector Memory.
    """
    def __init__(self, vector_memory: VectorMemory):
        self.vector_memory = vector_memory
        self.logger = logging.getLogger(__name__)

    def ingest_pdf(self, file_path: str, collection: str = "knowledge") -> Dict[str, Any]:
        """Parse PDF and push chunks to vector store."""
        try:
            if not os.path.exists(file_path):
                raise FileNotFoundError(f"Source file not found: {file_path}")

            reader = PdfReader(file_path)
            total_pages = len(reader.pages)
            self.logger.info(f"Ingesting PDF: {file_path} ({total_pages} pages)")

            filename = os.path.basename(file_path)
            all_chunks = []

            for i, page in enumerate(reader.pages):
                text = page.extract_text()
                if not text.strip():
                    continue

                # Recursive Chunking (Simple for now: fixed window + overlap)
                chunks = self._chunk_text(text, 1000, 200)
                
                for chunk_idx, chunk in enumerate(chunks):
                    meta = {
                        "source": filename,
                        "page": i + 1,
                        "chunk": chunk_idx,
                        "ingested_at": "now"
                    }
                    self.vector_memory.remember(chunk, collection, meta)
                    all_chunks.append(chunk)

            return {
                "success": True,
                "pages": total_pages,
                "chunks": len(all_chunks),
                "filename": filename
            }

        except Exception as e:
            self.logger.error(f"Ingestion failed: {e}")
            return {"success": False, "error": str(e)}

    def _chunk_text(self, text: str, size: int, overlap: int) -> List[str]:
        """Sliding window chunking logic."""
        chunks = []
        if len(text) <= size:
            return [text]
        
        start = 0
        while start < len(text):
            end = start + size
            chunk = text[start:end]
            chunks.append(chunk)
            start += (size - overlap)
            
        return chunks
