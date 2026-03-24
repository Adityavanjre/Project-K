import chromadb
import uuid
import logging
import os
from chromadb.config import Settings
from sentence_transformers import SentenceTransformer
from datetime import datetime
from typing import List, Dict, Any, Optional

class VectorMemory:
    """
    Long-term semantic memory using ChromaDB.
    Stores and recalls memories by MEANING, not keyword.
    """
    def __init__(self, path: str = "data/vector_memory"):
        self.logger = logging.getLogger(__name__)
        # Ensure path is absolute
        self.path = os.path.abspath(path)
        os.makedirs(self.path, exist_ok=True)
        
        # Load embedding model (Lite)
        try:
            self.embedder = SentenceTransformer("all-MiniLM-L6-v2")
        except Exception as e:
            self.logger.error(f"Failed to load sentence-transformers: {e}")
            self.embedder = None

        # Init Chroma (Lazy Loading)
        try:
            self.client = chromadb.PersistentClient(path=self.path, settings=Settings(anonymized_telemetry=False))
            self._collections = {}
            self.logger.info("Vector Memory (ChromaDB) initialized with lazy-loading")
        except Exception as e:
            self.logger.error(f"Failed to initialize ChromaDB: {e}")
            self.client = None

    def _get_collection(self, name: str):
        """Lazy get or create collection."""
        if not self.client: return None
        if name not in self._collections:
            self._collections[name] = self.client.get_or_create_collection(name)
        return self._collections[name]

    def _embed(self, text: str) -> List[float]:

    def _embed(self, text: str) -> List[float]:
        if not self.embedder:
            return []
        return self.embedder.encode(text).tolist()

    def remember(self, text: str, collection_name: str = "knowledge", meta: Optional[Dict[str, Any]] = None):
        if not self.client:
            return
        try:
            col = self._get_collection(collection_name)
            if col:
                col.add(
                    embeddings=[self._embed(text)],
                    documents=[text],
                    metadatas=[{"ts": datetime.now().isoformat(), **(meta or {})}],
                    ids=[str(uuid.uuid4())]
                )
        except Exception as e:
            self.logger.error(f"Recall failed in {collection_name}: {e}")

    def recall(self, query: str, collection_name: str = "knowledge", n: int = 5) -> List[str]:
        if not self.client:
            return []
        try:
            col = self._get_collection(collection_name)
            if not col: return []
            res = col.query(query_embeddings=[self._embed(query)], n_results=n)
            return res["documents"][0] if res["documents"] else []
        except Exception as e:
            self.logger.error(f"Recall failed in {collection_name}: {e}")
            return []

    def remember_user_fact(self, fact: str, user_id: str = "default"):
        self.remember(fact, "user_facts", {"user_id": user_id})

    def recall_user(self, query: str, user_id: str = "default") -> List[str]:
        return self.recall(query, "user_facts", n=5)

    def remember_project(self, desc: str, meta: Optional[Dict[str, Any]] = None):
        self.remember(desc, "projects", meta)

    def recall_projects(self, query: str) -> List[str]:
        return self.recall(query, "projects", n=3)

    def get_context_for_query(self, question: str) -> str:
        """Build a rich context string from relevant memories."""
        facts = self.recall_user(question)
        projects = self.recall_projects(question)
        knowledge = self.recall(question, "knowledge")
        
        parts = []
        if facts:
            parts.append("RELEVANT USER FACTS:\n" + "\n".join(f"- {f}" for f in facts))
        if projects:
            parts.append("PAST PROJECTS:\n" + "\n".join(f"- {p}" for p in projects))
        if knowledge:
            parts.append("PAST KNOWLEDGE:\n" + "\n".join(f"- {k}" for k in knowledge))
            
        return "\n\n".join(parts)
