
import sqlite3
import json
import logging
import os
from datetime import datetime
from typing import List, Dict, Any, Optional

class MemoryService:
    """
    Long-term memory module for KALI.
    Handles persistence of conversation history using SQLite.
    """
    
    def __init__(self, db_path: str = "data/jarvis.db"):
        self.logger = logging.getLogger(__name__)
        self.db_path = db_path
        self._init_db()
        
    def _init_db(self):
        """Initialize the database schema."""
        try:
            # Ensure directory exists
            os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
            
            conn = sqlite3.connect(self.db_path)
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
            conn.close()
            self.logger.info(f"Memory modules initialized at {self.db_path}")
            
        except Exception as e:
            self.logger.error(f"Failed to initialize memory database: {e}")

    def add_memory(self, role: str, content: str, session_id: str = "default"):
        """Save a new interaction to long-term memory."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute(
                'INSERT INTO memories (role, content, timestamp, session_id) VALUES (?, ?, ?, ?)',
                (role, content, datetime.now(), session_id)
            )
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            self.logger.error(f"Failed to save memory: {e}")

    def get_recent_memories(self, limit: int = 10, session_id: str = "default") -> List[Dict[str, str]]:
        """Retrieve recent context for the AI."""
        try:
            conn = sqlite3.connect(self.db_path)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            
            cursor.execute(
                'SELECT role, content FROM memories WHERE session_id = ? ORDER BY timestamp DESC LIMIT ?',
                (session_id, limit)
            )
            
            rows = cursor.fetchall()
            conn.close()
            
            # Return reversed (oldest first) for context window
            return [{"role": row["role"], "content": row["content"]} for row in reversed(rows)]
            
        except Exception as e:
            self.logger.error(f"Failed to retrieve memories: {e}")
            return []

    def clear_memory(self, session_id: str = "default"):
        """Wipe memory for a specific session."""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute('DELETE FROM memories WHERE session_id = ?', (session_id,))
            conn.commit()
            conn.close()
            self.logger.info("Memory banks reformatted.")
        except Exception as e:
            self.logger.error(f"Failed to clear memory: {e}")

    def get_sessions(self) -> List[Dict[str, Any]]:
        """Retrieve a list of unique sessions with their latest timestamp and a topic preview."""
        try:
            conn = sqlite3.connect(self.db_path)
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
            conn.close()
            
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

    def update_anchor(self, last_action: str, anchor_path: str = "MEMORY_ANCHOR.md"):
        """Phase 15: Automatically update the anchor file with the latest mission status."""
        try:
            if not os.path.exists(anchor_path):
                return
                
            with open(anchor_path, "r", encoding="utf-8") as f:
                lines = f.readlines()
                
            new_lines = []
            for line in lines:
                if "Last Action" in line:
                    new_lines.append(f"- **Last Action**: {last_action}\n")
                elif "Status" in line:
                     new_lines.append(f"- **Status**: Operational Sync Complete. Waiting for directive.\n")
                else:
                    new_lines.append(line)
                    
            with open(anchor_path, "w", encoding="utf-8") as f:
                f.writelines(new_lines)
                
        except Exception as e:
            self.logger.error(f"Failed to update anchor: {e}")
