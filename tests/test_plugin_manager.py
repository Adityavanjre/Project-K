"""
Test Suite: Phase 8 — PluginManager (Autonomous Skill Generation)
"""
import sys, os, pytest
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from core.plugin_manager import PluginManager


@pytest.fixture
def manager(tmp_path):
    return PluginManager(plugin_dir=str(tmp_path))


VALID_PLUGIN_CODE = """
class MockSkill:
    def run(self, *args, **kwargs):
        return "MOCK_SKILL_OUTPUT"

def initialize():
    return MockSkill()
"""

INVALID_PLUGIN_CODE = """
# Missing initialize function entirely
class BrokenSkill:
    pass
"""


def test_plugin_manager_initializes(manager):
    """PluginManager initializes with empty plugin registry."""
    assert isinstance(manager.plugins, dict)


def test_create_plugin_from_query(manager):
    """PluginManager can write a valid plugin to disk."""
    success = manager.create_plugin_from_query("TestSkill", VALID_PLUGIN_CODE)
    assert success is True
    plugin_file = os.path.join(manager.plugin_dir, "test_skill.py")
    assert os.path.exists(plugin_file)


def test_plugin_loads_after_creation(manager):
    """Autonomously created plugin is loaded into the registry."""
    manager.create_plugin_from_query("TestSkill", VALID_PLUGIN_CODE)
    assert "test_skill" in manager.plugins


def test_plugin_executes_correctly(manager):
    """Loaded plugin can be executed and returns correct output."""
    manager.create_plugin_from_query("TestSkill", VALID_PLUGIN_CODE)
    result = manager.execute_plugin("TestSkill")
    assert result == "MOCK_SKILL_OUTPUT"


def test_plugin_name_normalization(manager):
    """PluginManager normalizes camelCase names to snake_case."""
    manager.create_plugin_from_query("WeatherAgent", VALID_PLUGIN_CODE)
    # Should find it with multiple naming conventions
    result = manager.execute_plugin("weather_agent")
    assert "MOCK_SKILL_OUTPUT" in result


def test_nonexistent_plugin_returns_message(manager):
    """Executing a non-existent plugin returns a safe error string."""
    result = manager.execute_plugin("ghost_plugin")
    assert "not found" in result


def test_missing_initialize_not_registered(manager):
    """Plugins without initialize() are not added to the registry."""
    manager.create_plugin_from_query("BrokenSkill", INVALID_PLUGIN_CODE)
    assert "broken_skill" not in manager.plugins
