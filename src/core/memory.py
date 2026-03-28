
import sqlite3
import json
import logging
import os
from datetime import datetime
from typing import List, Dict, Any, Optional
import threading

class MemoryService:
    """
    Long-term memory module for KALI.
    Handles persistence of conversation history using SQLite.
    """
    _local = threading.local()
    
    def __init__(self, db_path: str = "data/jarvis.db"):
        self.logger = logging.getLogger(__name__)
        self.db_path = db_path
        self._init_db()

    def _get_conn(self):
        """Get or create a thread-local SQLite connection."""
        if not hasattr(self._local, "conn") or self._local.conn is None:
            self._local.conn = sqlite3.connect(self.db_path, check_same_thread=False)
            self._local.conn.execute("PRAGMA journal_mode=WAL") # Improved concurrency
        return self._local.conn
        
    def _init_db(self):
        """Initialize the database schema."""
        try:
            # Ensure directory exists
            os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
            
            conn = self._get_conn()
            cursor = conn.cursor()
            
            # Create conversations table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS memories (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    role TEXT NOT NULL,
                    content TEXT NOT NULL,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    session_id TEXT
                )
            ''')
            conn.commit()
            self.logger.info(f"Memory modules initialized at {self.db_path}")
            
        except Exception as e:
            self.logger.error(f"Failed to initialize memory database: {e}")

    def add_memory(self, role: str, content: str, session_id: str = "default"):
        """Save a new interaction to long-term memory."""
        try:
            conn = self._get_conn()
            with conn: # Phase 52 hardener: Context-managed transaction
                cursor = conn.cursor()
                cursor.execute(
                    'INSERT INTO memories (role, content, timestamp, session_id) VALUES (?, ?, ?, ?)',
                    (role, content, datetime.now(), session_id)
                )
            
        except Exception as e:
            self.logger.error(f"Failed to save memory: {e}")

    def get_recent_memories(self, limit: int = 10, session_id: str = "default") -> List[Dict[str, str]]:
        """Retrieve recent context for the AI."""
        try:
            conn = self._get_conn()
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            
            cursor.execute(
                'SELECT role, content FROM memories WHERE session_id = ? ORDER BY timestamp DESC LIMIT ?',
                (session_id, limit)
            )
            
            rows = cursor.fetchall()
            
            # Return reversed (oldest first) for context window
            return [{"role": row["role"], "content": row["content"]} for row in reversed(rows)]
            
        except Exception as e:
            self.logger.error(f"Failed to retrieve memories: {e}")
            return []

    def clear_memory(self, session_id: str = "default"):
        """Wipe memory for a specific session."""
        try:
            conn = self._get_conn()
            with conn:
                cursor = conn.cursor()
                cursor.execute('DELETE FROM memories WHERE session_id = ?', (session_id,))
            self.logger.info("Memory banks reformatted.")
        except Exception as e:
            self.logger.error(f"Failed to clear memory: {e}")

    def get_sessions(self) -> List[Dict[str, Any]]:
        """Retrieve a list of unique sessions with their latest timestamp and a topic preview."""
        try:
            conn = self._get_conn()
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            
            # Group by session_id, get latest timestamp and a preview content
            # We filter for 'user' messages to get a better topic preview if possible
            cursor.execute('''
                SELECT session_id, MAX(timestamp) as last_active, 
                (SELECT content FROM memories m2 WHERE m2.session_id = m1.session_id AND role = 'user' ORDER BY id ASC LIMIT 1) as topic
                FROM memories m1
                WHERE session_id != 'default'
                GROUP BY session_id
                ORDER BY last_active DESC
            ''')
            
            rows = cursor.fetchall()
            
            return [
                {
                    "session_id": row["session_id"],
                    "timestamp": row["last_active"],
                    "topic": row["topic"] or "Untitled Session"
                }
                for row in rows
            ]
        except Exception as e:
            self.logger.error(f"Failed to get sessions: {e}")
            return []

    def get_session_content(self, session_id: str) -> List[Dict[str, str]]:
        """Retrieve full history for a specific session."""
        return self.get_recent_memories(limit=100, session_id=session_id)

    def sync_anchor(self, anchor_path: str = "MEMORY_ANCHOR.md") -> Dict[str, str]:
        """
        Phase 15: Sync Cycle - Extract key state from the anchor file.
        Returns a dictionary of cleaned state values.
        """
        try:
            if not os.path.exists(anchor_path):
                return {}
                
            with open(anchor_path, "r", encoding="utf-8") as f:
                content = f.read()
                
            state = {}
            # Extract phase
            if "Current Phase**:" in content or "Current Phase:" in content:
                import re
                match = re.search(r"Phase (\d+)", content)
                if match:
                    state["phase"] = match.group(1)
            
            # Extract last action
            match = re.search(r"- \*\*Last Action\*\*: (.*)", content)
            if not match:
                match = re.search(r"- Last Action: (.*)", content)
            if match:
                state["last_action"] = match.group(1).strip()
                
            return state
        except Exception as e:
            self.logger.error(f"Failed to sync anchor: {e}")
            return {}

    def purge_all_memories(self):
        """Phase 54: Total Sovereign Purge (Right to be forgotten)."""
        try:
            conn = self._get_conn()
            with conn:
                cursor = conn.cursor()
                cursor.execute('DELETE FROM memories')
            self.logger.warning("SOVEREIGN_PURGE: All long-term memories have been permanently erased.")
        except Exception as e:
            self.logger.error(f"Failed to purge all memories: {e}")

    def prune_memory(self, days: int = 30):
        """Phase 54: Retention pruning for dated memories."""
        try:
            conn = self._get_conn()
            with conn:
                cursor = conn.cursor()
                cursor.execute(
                    "DELETE FROM memories WHERE timestamp < datetime('now', ?)",
                    (f'-{days} days',)
                )
                count = cursor.rowcount
            if count > 0:
                self.logger.info(f"Memory Maintenance: Pruned {count} archaic interaction records.")
        except Exception as e:
            self.logger.error(f"Failed to prune memory: {e}")

    def update_anchor(self, last_action: str, anchor_path: str = "MEMORY_ANCHOR.md"):
        """Phase 15: Sync Cycle - Update the anchor file with the latest system state."""
        try:
            # We don't write to DB here, but we ensure the file is updated
            # This is a file-system 'memory' used for cross-process sync.
            import os
            from .gsd_service import GSDPhase
            
            # Use current date/time
            now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            
            # If path doesn't exist, create a baseline
            if not os.path.exists(anchor_path):
                with open(anchor_path, "w", encoding="utf-8") as f:
                    f.write("# KALI MEMORY ANCHOR\n\n")
            
            # Append or overwrite? Usually we overwrite the state block
            # For simplicity, let's keep it as a clean state manifest
            content = f"""# KALI MEMORY ANCHOR
- **Timestamp**: {now}
- **Last Action**: {last_action}
- **System State**: SOVEREIGN
- **Integrity**: VERIFIED
"""
            with open(anchor_path, "w", encoding="utf-8") as f:
                f.write(content)
                
            self.logger.info("Memory Anchor updated.")
        except Exception as e:
            self.logger.error(f"Failed to update anchor: {e}")
