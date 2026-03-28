import sys, os, pytest, sqlite3, json
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src')))

from core.user_dna import UserDNA

@pytest.fixture
def dna_service(tmp_path):
    db_file = tmp_path / "test_user_dna.db"
    return UserDNA(db_path=str(db_file))

def test_dna_initialization(dna_service):
    """DNA database should be created and default profile loaded."""
    assert os.path.exists(dna_service.db_path)
    assert dna_service.profile["identity"]["spoken_language"] == "English"
    
    with sqlite3.connect(dna_service.db_path) as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT user_id FROM user_dna WHERE user_id='default'")
        assert cursor.fetchone() is not None

def test_dna_profile_update(dna_service):
    """Updating profile fields should persist to DB."""
    dna_service.set_name("Aditya")
    dna_service.add_known_concept("Quantum Gravity", score_delta=50)
    
    # Reload from DB
    new_dna = UserDNA(db_path=dna_service.db_path)
    assert new_dna.get_name() == "Aditya"
    assert new_dna.profile["expertise"]["known_concepts"]["QUANTUM GRAVITY"] == 50

def test_dna_consent_logic(dna_service):
    """Consent status should be correctly toggled and retrieved."""
    assert dna_service.get_consent() is False
    dna_service.set_consent(True)
    assert dna_service.get_consent() is True
    
    # Reload check
    new_dna = UserDNA(db_path=dna_service.db_path)
    assert new_dna.get_consent() is True

def test_dna_purge_logic(dna_service):
    """Purging a profile should reset it to defaults and clear consent."""
    dna_service.set_name("Aditya")
    dna_service.set_consent(True)
    
    dna_service.purge_profile()
    
    assert dna_service.get_name() is None
    assert dna_service.get_consent() is False
    assert dna_service.profile["interaction_stats"]["questions_asked"] == 0
