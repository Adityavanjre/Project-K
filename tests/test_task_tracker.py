"""
Test Suite: Phase 8 — TaskTracker (Persistent Project State)
"""
import sys, os, pytest
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from core.task_tracker import TaskTracker


@pytest.fixture
def tracker(tmp_path):
    state_file = str(tmp_path / "project_status.json")
    return TaskTracker(state_path=state_file)


def test_task_tracker_initializes(tracker):
    """TaskTracker initializes with empty project state."""
    assert isinstance(tracker.state, dict)
    assert "projects" in tracker.state


def test_task_tracker_creates_project(tracker):
    """TaskTracker creates a new project entry."""
    tracker.update_project("Test Mission", 10, "In progress.")
    assert "Test Mission" in tracker.state["projects"]


def test_task_tracker_updates_progress(tracker):
    """TaskTracker correctly updates project progress."""
    tracker.update_project("Test Mission", 10, "Started.")
    tracker.update_project("Test Mission", 75, "Halfway through.")
    assert tracker.state["projects"]["Test Mission"]["progress"] == 75


def test_task_tracker_clamps_progress(tracker):
    """TaskTracker clamps progress between 0 and 100."""
    tracker.update_project("Test Mission", 999, "Overflow test.")
    assert tracker.state["projects"]["Test Mission"]["progress"] == 100
    tracker.update_project("Test Mission", -50, "Underflow test.")
    assert tracker.state["projects"]["Test Mission"]["progress"] == 0


def test_task_tracker_active_projects(tracker):
    """get_active_projects returns only incomplete projects."""
    tracker.update_project("Mission A", 50, "Active.")
    tracker.update_project("Mission B", 100, "Done.")
    active = tracker.get_active_projects()
    names = [p["name"] for p in active]
    assert "Mission A" in names
    assert "Mission B" not in names


def test_task_tracker_autonomy_report(tracker):
    """get_autonomy_report returns a formatted status string."""
    tracker.update_project("Mission C", 30, "In lab.")
    report = tracker.get_autonomy_report()
    assert "Mission C" in report
    assert "30%" in report
