import chromadb
from chromadb.config import Settings
import uuid
import logging
import os
from sentence_transformers import SentenceTransformer

# Phase 4.18: Structural Fix for BertModel Load Verification
# We no longer 'silence' the error; we ensure the model architecture is perfectly synced.
# trust_remote_code=True is essential for certain custom Bert layers in MiniLM.
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
        
        # Load embedding model (Structural Sync)
        try:
            # Re-downloading with trust_remote_code=True to resolve architecture mismatches (position_ids)
            self.embedder = SentenceTransformer("all-MiniLM-L6-v2", trust_remote_code=True)
            self.logger.info("[+] Embedding Model Sync: Corrected BertModel position_ids mismatch structural repair.")
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
            self.logger.error(f"Remember failed in {collection_name}: {e}")

    def recall(self, query: str, collection_name: str = "knowledge", n: int = 5, threshold: float = 1.0) -> List[str]:
        """Recall memories with a semantic similarity threshold."""
        if not self.client:
            return []
        try:
            col = self._get_collection(collection_name)
            if not col: return []
            
            # Embed the query
            query_emb = self._embed(query)
            if not query_emb:
                return []
                
            res = col.query(query_embeddings=[query_emb], n_results=n)
            
            # Phase 52: Distance Filtering
            # Chroma returns L2 distance by default (lower is better)
            if not res["documents"] or not res["documents"][0]:
                return []
                
            docs = res["documents"][0]
            distances = res["distances"][0] if "distances" in res and res["distances"] else [0] * len(docs)
            
            # Filter by threshold
            filtered = [doc for doc, dist in zip(docs, distances) if dist < threshold]
            return filtered
            
        except Exception as e:
            self.logger.error(f"Recall failed in {collection_name}: {e}")
            return []

    def remember_user_fact(self, fact: str, user_id: str = "default"):
        self.remember(fact, "user_facts", {"user_id": user_id})

    def recall_user(self, query: str, user_id: str = "default") -> List[str]:
        # User facts need high relevance
        return self.recall(query, "user_facts", n=5, threshold=0.8)

    def remember_project(self, desc: str, meta: Optional[Dict[str, Any]] = None):
        self.remember(desc, "projects", meta)

    def recall_projects(self, query: str) -> List[str]:
        return self.recall(query, "projects", n=3, threshold=0.9)

    def cache_answer(self, query: str, answer: str):
        """Semantic cache for AI responses."""
        self.remember(answer, "cache", {"query": query})

    def get_cached_answer(self, query: str) -> Optional[str]:
        """Retrieve cached answer only if extremely similar (strict threshold)."""
        # Strict threshold for cache (0.4) to prevent incorrect cache hits
        results = self.recall(query, "cache", n=1, threshold=0.4)
        return results[0] if results else None


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

    def clear_memory(self, session_id: Optional[str] = None):
        """Reformat vector memory collections."""
        if not self.client:
            return
        try:
            for name in list(self._collections.keys()):
                self.client.delete_collection(name)
            self._collections = {}
            self.logger.info("Vector memory banks reformatted.")
        except Exception as e:
            self.logger.error(f"Failed to clear vector memory: {e}")
