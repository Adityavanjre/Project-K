import sys, os, pytest, sqlite3
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src')))

from core.memory import MemoryService

@pytest.fixture
def memory_service(tmp_path):
    db_file = tmp_path / "test_jarvis.db"
    return MemoryService(db_path=str(db_file))

def test_memory_initialization(memory_service):
    """Memory database should be created and table should exist."""
    assert os.path.exists(memory_service.db_path)
    
    with sqlite3.connect(memory_service.db_path) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='memories'")
        assert cursor.fetchone() is not None

def test_add_and_retrieve_memory(memory_service):
    """Saving a memory should allow retrieving it later."""
    memory_service.add_memory("user", "Hello KALI", session_id="test_session")
    memory_service.add_memory("assistant", "Greetings, Architect.", session_id="test_session")
    
    history = memory_service.get_recent_memories(limit=10, session_id="test_session")
    assert len(history) == 2
    assert history[0]["role"] == "user"
    assert history[0]["content"] == "Hello KALI"
    assert history[1]["role"] == "assistant"
    assert history[1]["content"] == "Greetings, Architect."

def test_clear_memory(memory_service):
    """Clearing a session should remove its memories."""
    memory_service.add_memory("user", "Secret", session_id="secret_session")
    memory_service.clear_memory(session_id="secret_session")
    
    history = memory_service.get_recent_memories(session_id="secret_session")
    assert len(history) == 0

def test_get_sessions(memory_service):
    """Retrieving sessions should return distinct session IDs with topic previews."""
    memory_service.add_memory("user", "How to build a reactor?", session_id="session_1")
    memory_service.add_memory("user", "What is the meaning of life?", session_id="session_2")
    
    sessions = memory_service.get_sessions()
    # Note: 'default' session is usually ignored in get_sessions if it's the only one
    assert len(sessions) >= 2
    ids = [s["session_id"] for s in sessions]
    assert "session_1" in ids
    assert "session_2" in ids
    
    # Check topic preview (first user message)
    s1 = next(s for s in sessions if s["session_id"] == "session_1")
    assert "reactor" in s1["topic"]

def test_context_manager_robustness(memory_service):
    """The context manager should handle rapid, interleaved calls without locking errors."""
    import threading
    
    def worker(i):
        for _ in range(10):
            memory_service.add_memory("user", f"Worker {i} msg", session_id="stress_test")
            
    threads = [threading.Thread(target=worker, args=(i,)) for i in range(5)]
    for t in threads: t.start()
    for t in threads: t.join()
    
    history = memory_service.get_recent_memories(limit=100, session_id="stress_test")
    assert len(history) == 50
