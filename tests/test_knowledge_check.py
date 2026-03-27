"""
Tests for the KnowledgeCheckEngine.
Verifies that the pass/fail cycle works correctly,
records are persisted properly, and the overall training loop is sound.
"""

import json
import os
import pytest
from unittest.mock import MagicMock


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

QUESTIONS_JSON = json.dumps([
    {"question": "What is PWM?", "expected_answer": "Pulse Width Modulation duty cycle"},
    {"question": "What does a motor driver do?", "expected_answer": "drives motor current direction"},
    {"question": "What is Ohm's law?", "expected_answer": "voltage current resistance"},
])


@pytest.fixture
def mock_ai():
    """
    AI service mock that handles two call patterns:
    1. Question generation prompts (contain 'JSON array' or 'examiner') -> return a JSON string
    2. Knowledge check answer prompts (short questions) -> return keyword-rich answers
    """
    ai = MagicMock()

    def smart_answer(q, **kwargs):
        q_lower = q.lower()
        # Question generation call — return JSON array string
        if "json array" in q_lower or "examiner" in q_lower or "generate" in q_lower:
            return QUESTIONS_JSON
        # Knowledge check answer calls — return precise keyword-matching answers
        if "pwm" in q_lower or "pulse width" in q_lower:
            return "Pulse Width Modulation controls duty cycle for speed."
        if "motor driver" in q_lower:
            return "A motor driver drives motor current and direction."
        if "ohm" in q_lower:
            return "Ohm's law: voltage equals current times resistance."
        # Default: return keywords that overlap well with common expected answers
        return "Pulse Width Modulation duty cycle drives motor current direction voltage resistance."

    ai.ask_question.side_effect = smart_answer
    return ai


@pytest.fixture
def engine(tmp_path, mock_ai):
    from core.knowledge_check import KnowledgeCheckEngine
    return KnowledgeCheckEngine(ai_service=mock_ai, project_root=str(tmp_path))


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

class TestKnowledgeCheckEngine:

    def test_initialization(self, engine, tmp_path):
        """Engine creates necessary data paths."""
        assert engine.project_root == str(tmp_path)
        assert "data" in engine.training_log_path

    def test_queue_check_creates_pending_file(self, engine, tmp_path):
        """queue_check() appends to pending_checks.jsonl."""
        engine.queue_check("What is PWM?", "PWM is Pulse Width Modulation. It controls motor speed via duty cycle.")
        pending_path = os.path.join(str(tmp_path), "data", "pending_checks.jsonl")
        assert os.path.exists(pending_path)
        with open(pending_path, "r") as f:
            records = [json.loads(l) for l in f if l.strip()]
        assert len(records) == 1
        assert records[0]["topic"] == "What is PWM?"
        assert records[0]["status"] == "PENDING"

    def test_queue_check_skips_empty(self, engine, tmp_path):
        """queue_check() ignores empty or too-short responses."""
        engine.queue_check("", "some response")
        engine.queue_check("topic", "short")
        pending_path = os.path.join(str(tmp_path), "data", "pending_checks.jsonl")
        assert not os.path.exists(pending_path)

    def test_generate_questions_returns_list(self, engine):
        """_generate_questions() returns a list of Q&A dicts."""
        questions = engine._generate_questions(
            "PWM is Pulse Width Modulation. It controls motor speed via duty cycle."
        )
        assert isinstance(questions, list)
        assert len(questions) > 0
        for qa in questions:
            assert "question" in qa
            assert "expected_answer" in qa

    def test_evaluate_exact_match(self, engine):
        """_evaluate() scores a response with matching keywords near 100."""
        score = engine._evaluate(
            "Pulse Width Modulation duty cycle",
            "Pulse Width Modulation controls duty cycle for motor speed."
        )
        assert score >= 70.0

    def test_evaluate_no_match(self, engine):
        """_evaluate() scores an unrelated response near 0."""
        score = engine._evaluate(
            "Pulse Width Modulation duty cycle motor",
            "The weather today is sunny with light winds."
        )
        assert score < 30.0

    def test_run_check_passing(self, engine, tmp_path):
        """run_check() marks a good response as PASSED."""
        result = engine.run_check(
            "What is PWM?",
            "PWM stands for Pulse Width Modulation. It controls the duty cycle of a signal to regulate motor speed."
        )
        assert result["status"] == "PASSED"
        assert result["score"] >= engine.PASS_THRESHOLD

        # Check training_log.json was written
        log_path = os.path.join(str(tmp_path), "data", "training_log.json")
        assert os.path.exists(log_path)
        with open(log_path) as f:
            log = json.load(f)
        assert len(log) == 1
        assert log[0]["status"] == "PASSED"

    def test_run_check_failing_writes_failure_file(self, engine, tmp_path, mock_ai):
        """run_check() marks a poor response as FAILED and writes to failures file."""
        # Override ask_question to return a totally wrong answer for knowledge check questions
        # but still return valid JSON for generation
        def fail_answers(q, **kwargs):
            q_lower = q.lower()
            if "json array" in q_lower or "examiner" in q_lower or "generate" in q_lower:
                return QUESTIONS_JSON
            return "The weather is sunny today."  # Totally wrong answer

        mock_ai.ask_question.side_effect = fail_answers

        result = engine.run_check(
            "What is PWM?",
            "PWM stands for Pulse Width Modulation. It controls duty cycle for motor speed regulation."
        )
        assert result["status"] == "FAILED"

        failures_path = os.path.join(str(tmp_path), "data", "training_failures.jsonl")
        assert os.path.exists(failures_path)
        with open(failures_path) as f:
            failures = [json.loads(l) for l in f if l.strip()]
        assert len(failures) == 1
        assert "topic" in failures[0]
        assert "gap" in failures[0]
        assert "retry_prompt" in failures[0]

    def test_get_pass_rate_empty(self, engine):
        """get_pass_rate() returns zeros when no checks have run."""
        stats = engine.get_pass_rate()
        assert stats["total"] == 0
        assert stats["pass_rate"] == 0

    def test_get_pass_rate_populated(self, engine, tmp_path, mock_ai):
        """get_pass_rate() aggregates correctly after multiple checks."""
        engine.run_check("Topic A", "Pulse Width Modulation duty cycle motor speed controls")

        def bad_answers(q, **kwargs):
            q_lower = q.lower()
            if "json array" in q_lower or "examiner" in q_lower or "generate" in q_lower:
                return QUESTIONS_JSON
            return "unrelated content completely"

        mock_ai.ask_question.side_effect = bad_answers
        engine.run_check("Topic B", "SHA256 hash verification bios integrity check")

        stats = engine.get_pass_rate()
        assert stats["total"] == 2
        assert 0 <= stats["pass_rate"] <= 100

    def test_run_pending_checks_clears_queue(self, engine, tmp_path, mock_ai):
        """run_pending_checks() processes items and removes them from the queue."""
        # Queue 3 checks
        for i in range(3):
            engine.queue_check(f"Topic {i}", f"Some detailed technical training about topic {i} with PWM duty cycle facts")

        results = engine.run_pending_checks(limit=2)
        assert len(results) == 2

        # Only 1 should remain in queue
        pending_path = os.path.join(str(tmp_path), "data", "pending_checks.jsonl")
        with open(pending_path) as f:
            remaining = [l for l in f if l.strip()]
        assert len(remaining) == 1
