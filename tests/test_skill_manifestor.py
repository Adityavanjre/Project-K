import pytest
import os
import shutil
from src.core.skill_manifestor import SkillManifestor

class MockAI:
    def ask_question(self, p):
        return """class AutonomousSkill:
    def execute(self, context):
        return {"result": "Logic Executed"}"""

class MockPM:
    def __init__(self):
        self.plugins_loaded = False
    def load_plugins(self):
        self.plugins_loaded = True

@pytest.fixture
def manifestor():
    pm = MockPM()
    ai = MockAI()
    m = SkillManifestor(pm, ai)
    yield m
    # Cleanup autonomous plugins after test
    if os.path.exists(m.plugin_dir):
        for f in os.listdir(m.plugin_dir):
            if f.startswith("skill_"):
                os.remove(os.path.join(m.plugin_dir, f))

def test_skill_generation(manifestor):
    """SkillManifestor should generate a file and trigger PM reload."""
    res = manifestor.manifest_skill("Test Skill Generation")
    assert res["success"] is True
    assert os.path.exists(res["path"])
    assert manifestor.plugin_manager.plugins_loaded is True

def test_ast_sanitization(manifestor):
    """Sanitizer should reject invalid Python code."""
    invalid_code = "this is not python : : :"
    sanitized = manifestor._sanitize_code(invalid_code)
    assert sanitized is None

def test_code_cleaning(manifestor):
    """Sanitizer should strip markdown blocks."""
    block_code = "```python\nclass X:\n    pass\n```"
    sanitized = manifestor._sanitize_code(block_code)
    assert "```python" not in sanitized
    assert "class X:" in sanitized
