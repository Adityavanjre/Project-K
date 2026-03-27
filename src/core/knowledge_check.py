"""
KALI KNOWLEDGE CHECK ENGINE
Phase 4.70: Per-Skill Sovereign Verification

Each skill/role runs its own independent check.
A topic is only ANCHORED when it passes 100% in isolation.
No aggregate scoring. No wasted 100% atoms.
"""

import json
import logging
import os
from datetime import datetime
from typing import Dict, List, Any, Optional

logger = logging.getLogger(__name__)


class KnowledgeCheckEngine:
    """
    Verifies that KALI actually retained what she was trained on.
    A training run is only marked SUCCESS when this check passes.
    """

    PASS_THRESHOLD = 100  # Score out of 100 required to pass (Perfect Recall)

    def __init__(self, ai_service, project_root: str = None):
        self.ai = ai_service
        if project_root is None:
            project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
        self.project_root = project_root
        self.training_log_path = os.path.join(project_root, "data", "training_log.json")
        self.failures_path = os.path.join(project_root, "data", "training_failures.jsonl")
        self.pending_path = os.path.join(project_root, "data", "pending_checks.jsonl")
        self.pinned_path = os.path.join(project_root, "data", "pinned_topics.jsonl")
        self.unverified_path = os.path.join(project_root, "data", "unverified_training.jsonl")
        self.anchored_path = os.path.join(project_root, "data", "training_data.jsonl")
        self.skill_log_path = os.path.join(project_root, "data", "skill_sovereignty.json")
        os.makedirs(os.path.join(project_root, "data"), exist_ok=True)

    def is_atom_mastered(self, fact: str) -> bool:
        """Checks if a fact has already reached FINALIZED_SOVEREIGN status."""
        if not os.path.exists(self.anchored_path):
            return False
        try:
            with open(self.anchored_path, "r", encoding="utf-8") as f:
                for line in f:
                    if not line.strip(): continue
                    data = json.loads(line)
                    if data.get("fact") == fact and data.get("status") == "FINALIZED_SOVEREIGN":
                        return True
        except Exception:
            pass
        return False

    # ------------------------------------------------------------------
    # PER-SKILL SOVEREIGN API (Phase 4.70)
    # ------------------------------------------------------------------

    def run_skill_check(self, skill_name: str, source_response: str) -> Dict[str, Any]:
        """
        Runs an independent 100% knowledge check for a SINGLE skill/role.
        Unlike run_check, this tracks pass/fail against the skill's own history.
        A skill is SOVEREIGN only when it passes 100% (all atoms).
        """
        logger.info(f"[SKILL CHECK] Verifying '{skill_name}' independently...")
        result = self.run_check(skill_name, source_response)

        # Load or create skill log
        skill_log = self._load_skill_log()
        entry = skill_log.get(skill_name, {
            "pass_count": 0,
            "fail_count": 0,
            "partial_count": 0,
            "sovereignty_level": 0.0,
            "best_score": 0.0,
            "status": "UNTESTED"
        })

        current_score = result.get("score", 0.0)
        previous_best = entry.get("best_score", 0.0)

        # Progressive Mastery: Track high-water mark
        if current_score > previous_best:
            entry["best_score"] = current_score
            logger.info(f"[MASTERY] New High-Water Mark for '{skill_name}': {current_score}% (Previous: {previous_best}%)")

            # Phase 4.75: Every improvement counts — 0.001%, 1%, 50% — all recorded.
            # Delta is proportional: bigger gain = bigger DNA boost. No gate, no threshold.
            try:
                from src.core.user_dna import UserDNA as _UserDNA
                _dna = _UserDNA()
                improvement = current_score - previous_best
                # Even the tiniest gain gets delta=1 minimum
                delta = max(1, int(improvement))
                _dna.add_known_concept(skill_name, score_delta=delta)
                logger.info(
                    f"[DNA] Progress for '{skill_name}': "
                    f"+{improvement:.3f}% improvement -> new best {current_score:.1f}% (DNA +{delta}pts)."
                )
            except Exception as _e:
                logger.debug(f"DNA incremental update skipped: {_e}")


        status = result.get("status", "SKIPPED")
        if status == "PASSED":
            entry["pass_count"] += 1
            # Sovereignty requires 3 passes at 100%
            entry["sovereignty_level"] = min(100.0, entry["pass_count"] / 3 * 100)
            if entry["pass_count"] >= 3:
                entry["status"] = "SOVEREIGN"
                logger.info(f"[SOVEREIGN] Skill '{skill_name}' is now FULLY SOVEREIGN.")
            else:
                entry["status"] = f"PASSING_{entry['pass_count']}_OF_3"
        elif status == "PARTIAL":
            entry["partial_count"] += 1
            entry["status"] = "PARTIAL_REMEDIATION_NEEDED"
        else:
            entry["fail_count"] += 1
            entry["status"] = "FAILED_PINNED"

        entry["last_checked"] = datetime.now().isoformat()
        skill_log[skill_name] = entry
        self._save_skill_log(skill_log)
        result["skill_name"] = skill_name
        result["skill_status"] = entry["status"]
        result["sovereignty_level"] = entry["sovereignty_level"]
        result["best_score"] = entry.get("best_score", 0.0)
        return result

    def get_skill_sovereignty_report(self) -> Dict[str, Any]:
        """Returns a per-skill sovereignty report. Every skill must be at 100% independently."""
        skill_log = self._load_skill_log()
        sovereign_count = sum(1 for s in skill_log.values() if s.get("status") == "SOVEREIGN")
        total = len(skill_log)
        report = {
            "total_skills_tracked": total,
            "sovereign_skills": sovereign_count,
            "skills_remaining": total - sovereign_count,
            "skills": skill_log
        }
        return report

    def _load_skill_log(self) -> Dict:
        if not os.path.exists(self.skill_log_path):
            return {}
        try:
            with open(self.skill_log_path, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}

    def _save_skill_log(self, log: Dict):
        try:
            with open(self.skill_log_path, "w", encoding="utf-8") as f:
                json.dump(log, f, indent=2, ensure_ascii=False)
        except Exception as e:
            logger.error(f"Failed to save skill log: {e}")

    # ------------------------------------------------------------------
    # PUBLIC API
    # ------------------------------------------------------------------

    def queue_check(self, topic: str, ai_response: str, context: str = "general"):
        """
        Called automatically after every training log entry.
        Stores a pending check for later evaluation.
        """
        if not topic or not ai_response or len(ai_response) < 30:
            return

        record = {
            "topic": topic[:200],
            "response_summary": ai_response[:800],
            "queued_at": datetime.now().isoformat(),
            "status": "PENDING"
        }
        self._append_jsonl(self.pending_path, record)
        logger.debug(f"KALI Knowledge Check queued for: {topic[:60]}")

    def run_pending_checks(self, limit: int = 5) -> List[Dict[str, Any]]:
        """
        Runs up to `limit` pending checks from the queue.
        Returns a list of results.
        """
        pending = self._load_pending(limit)
        if not pending:
            logger.info("KALI Knowledge Check: No pending checks.")
            return []

        results = []
        for item in pending:
            result = self.run_check(item["topic"], item["response_summary"])
            results.append(result)

        return results

    def run_check(self, topic: str, source_response: str) -> Dict[str, Any]:
        """
        Full check cycle:
        1. Generate questions from the source response.
        2. Ask KALI those questions cold.
        3. Score and log.
        """
        logger.info(f"KALI Knowledge Check: Verifying retention for '{topic[:60]}'")

        questions = self._generate_questions(source_response)
        if not questions:
            logger.warning(f"Knowledge Check: Could not generate questions for '{topic[:60]}'")
            return {"topic": topic, "status": "SKIPPED", "score": None}

        total_score = 0.0
        scored_qa = []

        for qa in questions:
            question = qa.get("question", "")
            expected = qa.get("expected_answer", "")
            if not question:
                continue

            # Ask KALI cold — no source material in context
            kali_answer = self.ai.ask_question(
                f"Knowledge check: {question}\nAnswer concisely in 1-3 sentences."
            )
            score = self._evaluate(expected, kali_answer)
            total_score += score
            scored_qa.append({
                "question": question,
                "expected": expected,
                "kali_answer": kali_answer,
                "score": round(score, 1)
            })

        # Phase 4.50: Atomized Anchoring Protocol (AAP)
        atoms_anchored = 0
        atoms_failed = 0
        
        for qa in scored_qa:
            if qa["score"] >= self.PASS_THRESHOLD:
                self._anchor_atom(topic, qa)
                atoms_anchored += 1
            else:
                self._flag_atom_failure(topic, qa)
                atoms_failed += 1
        
        total_atoms = len(scored_qa)
        if atoms_anchored == total_atoms:
            logger.info(f"[PASS] Interaction fully ANCHORED ({atoms_anchored}/{total_atoms} atoms).")
            return {"topic": topic, "status": "PASSED", "score": 100.0, "atoms": total_atoms}
        elif atoms_anchored > 0:
            logger.warning(f"[PARTIAL] {atoms_anchored}/{total_atoms} atoms ANCHORED. {atoms_failed} quarantined.")
            return {"topic": topic, "status": "PARTIAL", "score": round((atoms_anchored/total_atoms)*100, 1), "atoms": total_atoms}
        else:
            logger.error(f"[FAIL] All {total_atoms} atoms failed. TOPIC PINNED.")
            return {"topic": topic, "status": "FAILED", "score": 0.0, "atoms": total_atoms}

    def get_training_log(self) -> List[Dict[str, Any]]:
        """Returns the full training log (all pass/fail records)."""
        if not os.path.exists(self.training_log_path):
            return []
        try:
            with open(self.training_log_path, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return []

    def get_pass_rate(self) -> Dict[str, Any]:
        """Returns aggregate statistics across all checks."""
        log = self.get_training_log()
        if not log:
            return {"total": 0, "passed": 0, "failed": 0, "pass_rate": 0}

        passed = [e for e in log if e.get("status") == "PASSED"]
        failed = [e for e in log if e.get("status") == "FAILED"]
        return {
            "total": len(log),
            "passed": len(passed),
            "failed": len(failed),
            "pass_rate": round((len(passed) / len(log)) * 100, 1),
            "avg_score": round(sum(e.get("score", 0) for e in log) / len(log), 1)
        }

    # ------------------------------------------------------------------
    # INTERNAL METHODS
    # ------------------------------------------------------------------

    def _generate_questions(self, source_response: str) -> List[Dict[str, str]]:
        """
        Asks KALI to produce 3-5 test Q&A pairs from the training content.
        Falls back to keyword extraction if AI returns unusable output (e.g. simulation mode).
        """
        prompt = (
            f"You are a rigorous examiner. Based ONLY on this training content, "
            f"generate exactly 3 test questions that verify factual retention.\n\n"
            f"TRAINING CONTENT:\n{source_response[:600]}\n\n"
            f"Return ONLY a JSON array, no markdown, no extra text: "
            f"[{{\"question\": \"...\", \"expected_answer\": \"...\"}}]\n"
            f"Questions must be directly answerable from the content above. "
            f"Expected answers should be concise key facts (5-15 words max)."
        )
        import re
        try:
            raw = self.ai.ask_question(prompt)
            if raw and len(raw) > 30:
                raw = raw.strip()
                if raw.startswith("```"):
                    raw = "\n".join(raw.split("\n")[1:])
                if raw.endswith("```"):
                    raw = raw.rsplit("```", 1)[0]
                raw = raw.strip()

                try:
                    parsed = json.loads(raw)
                    if isinstance(parsed, list) and len(parsed) > 0:
                        return parsed[:5]
                except json.JSONDecodeError:
                    pass

                match = re.search(r'\[.*?\]', raw, re.DOTALL)
                if match:
                    try:
                        parsed = json.loads(match.group(0))
                        if isinstance(parsed, list) and len(parsed) > 0:
                            return parsed[:5]
                    except Exception:
                        pass

        except Exception as e:
            logger.debug(f"Question generation (AI method) failed: {e}")

        # Fallback: keyword-based question extraction (works offline/simulation mode)
        logger.info("Using keyword extraction fallback for question generation.")
        return self._generate_questions_fallback(source_response)

    def _generate_questions_fallback(self, source_response: str) -> List[Dict[str, str]]:
        """
        Extracts key noun phrases from training content and constructs Q&A pairs.
        Used when AI question generation fails or is unavailable.
        This ensures the knowledge check is NEVER blocked by AI service availability.
        """
        import re
        sentences = [s.strip() for s in re.split(r'[.!?\n]', source_response) if len(s.strip()) > 30]
        qa_pairs = []
        seen = set()
        for sentence in sentences[:10]:
            # Extract significant noun phrases (2-5 capitalized/key words)
            words = sentence.split()
            if len(words) < 4:
                continue
            # Build a question from the sentence
            key_phrase = " ".join(words[:8])
            if key_phrase in seen:
                continue
            seen.add(key_phrase)
            question = f"What does the following describe? '{key_phrase}...'"
            expected = " ".join(words[8:16]) if len(words) > 8 else " ".join(words[-4:])
            if expected:
                qa_pairs.append({"question": question, "expected_answer": expected})
            if len(qa_pairs) >= 3:
                break

        if not qa_pairs:
            # Ultra-fallback: synthesize a single Q&A from the first 100 chars
            snippet = source_response[:120].strip()
            qa_pairs.append({
                "question": f"What is the main concept described in this training?",
                "expected_answer": snippet[:60]
            })
        return qa_pairs



    def _evaluate(self, expected: str, actual: str) -> float:
        """
        Scores an answer using keyword overlap.
        Returns 0-100.
        """
        if not expected or not actual:
            return 0.0

        expected_words = set(expected.lower().split())
        actual_words = set(actual.lower().split())

        # Remove common stop words
        stop = {"a", "an", "the", "is", "it", "in", "of", "to", "and", "or", "for", "with", "that", "this"}
        expected_words -= stop
        actual_words -= stop

        if not expected_words:
            return 50.0  # Cannot evaluate, give partial credit

        overlap = len(expected_words & actual_words)
        score = (overlap / len(expected_words)) * 100
        return min(100.0, round(score, 1))

    def _identify_gap(self, scored_qa: List[Dict]) -> str:
        """Finds which question scored worst and returns the gap description."""
        if not scored_qa:
            return "No scoreable Q&A pairs."
        worst = min(scored_qa, key=lambda x: x.get("score", 100))
        return (
            f"Weakest area: '{worst['question']}' "
            f"(score: {worst['score']}/100). "
            f"Expected: '{worst['expected']}'. "
            f"KALI answered: '{worst['kali_answer'][:100]}'"
        )

    def _mark_success(self, topic: str, score: float, scored_qa: list) -> Dict:
        """Persists a PASSED record and anchors the training data."""
        record = {
            "topic": topic[:200],
            "timestamp": datetime.now().isoformat(),
            "score": score,
            "status": "PASSED",
            "questions_count": len(scored_qa),
            "qa_summary": [{"q": qa["question"][:80], "score": qa["score"]} for qa in scored_qa]
        }
        self._append_training_log(record)
        
        # Phase 4.40: Anchor the training (Move from unverified once success is verified)
        self._anchor_training(topic)
        
        logger.info(f"[PASS] Knowledge Check: '{topic[:60]}' scored {score}/100. Interaction ANCHORED.")
        return record

    def _anchor_training(self, topic: str):
        """Moves any matching unverified training logs to the anchored dataset."""
        if not os.path.exists(self.unverified_path):
            return

        try:
            with open(self.unverified_path, "r", encoding="utf-8") as f:
                lines = f.readlines()

            remaining_unverified = []
            anchored_count = 0
            
            for line in lines:
                if not line.strip(): continue
                data = json.loads(line)
                messages = data.get("messages", [])
                user_msg = next((m["content"] for m in messages if m["role"] == "user"), "")
                
                # Check for match (fuzzy match first 50 chars of topic)
                if topic[:50] in user_msg:
                    self._append_jsonl(self.anchored_path, data)
                    anchored_count += 1
                else:
                    remaining_unverified.append(line)

            # Rewrite unverified with non-anchored records
            with open(self.unverified_path, "w", encoding="utf-8") as f:
                f.writelines(remaining_unverified)
            
            if anchored_count > 0:
                logger.info(f"Anchored {anchored_count} verified training records to core.")

        except Exception as e:
            logger.error(f"Failed to anchor training for '{topic[:30]}': {e}")

    def _flag_failure(self, topic: str, score: float, scored_qa: list, gap: str) -> Dict:
        """Persists a FAILED record and queues a retry."""
        record = {
            "topic": topic[:200],
            "timestamp": datetime.now().isoformat(),
            "score": score,
            "status": "FAILED",
            "gap": gap,
            "questions_count": len(scored_qa),
            "qa_summary": [{"q": qa["question"][:80], "score": qa["score"]} for qa in scored_qa]
        }
        self._append_training_log(record)
        # Also write to failures file for ralph loop to pick up
        failure_item = {
            "topic": topic[:200],
            "gap": gap,
            "score": score,
            "timestamp": datetime.now().isoformat(),
            "retry_prompt": f"CRITICAL KNOWLEDGE GAP DETECTED. Provide a comprehensive, detailed explanation of: {topic}. Focus especially on: {gap}"
        }
        self._append_jsonl(self.failures_path, failure_item)
        
        # Phase 4.40: Pin the topic for immediate remediation priority
        self._append_jsonl(self.pinned_path, {"topic": topic, "gap": gap, "pinned_at": datetime.now().isoformat()})
        
        logger.warning(f"[FAIL] Knowledge Check: '{topic[:60]}' scored {score}/100. Gap: {gap[:80]}. TOPIC PINNED.")
        return record

    def get_pinned_topics(self) -> List[Dict]:
        """Returns all currently pinned topics requiring immediate remediation."""
        if not os.path.exists(self.pinned_path):
            return []
        try:
            with open(self.pinned_path, "r", encoding="utf-8") as f:
                return [json.loads(l) for l in f if l.strip()]
        except Exception:
            return []

    def unpin_topic(self, topic: str):
        """Removes a topic from the pinned list after successful remediation."""
        if not os.path.exists(self.pinned_path):
            return
        try:
            with open(self.pinned_path, "r", encoding="utf-8") as f:
                lines = f.readlines()
            # Fuzzy match first 40 chars
            remaining = [l for l in lines if topic[:40] not in l]
            with open(self.pinned_path, "w", encoding="utf-8") as f:
                f.writelines(remaining)
        except Exception as e:
            logger.error(f"Failed to unpin topic: {e}")

    def _load_pending(self, limit: int) -> List[Dict]:
        """Reads and removes up to `limit` pending checks."""
        if not os.path.exists(self.pending_path):
            return []
        try:
            with open(self.pending_path, "r", encoding="utf-8") as f:
                lines = [l.strip() for l in f.readlines() if l.strip()]

            to_process = lines[:limit]
            remaining = lines[limit:]

            with open(self.pending_path, "w", encoding="utf-8") as f:
                f.write("\n".join(remaining) + ("\n" if remaining else ""))

            return [json.loads(l) for l in to_process]
        except Exception as e:
            logger.error(f"Failed to load pending checks: {e}")
            return []

    def _anchor_atom(self, topic: str, qa: Dict, current_context: str = "general"):
        """Phase 4.60: Cross-Context Verification (CCV). Atoms mature over 3 checks."""
        # Check if atom already exists
        existing_atoms = self._load_jsonl(self.anchored_path)
        match = next((a for a in existing_atoms if a.get("fact") == qa["expected"]), None)
        
        if match:
            v_count = match.get("verification_count", 1) + 1
            contexts = match.get("verified_contexts", ["general"])
            if current_context not in contexts:
                contexts.append(current_context)
            
            match["verification_count"] = v_count
            match["verified_contexts"] = contexts
            match["last_verified"] = datetime.now().isoformat()
            
            if v_count >= 3:
                match["status"] = "FINALIZED_SOVEREIGN | VERIFIED_100"
                logger.info(f"[SOVEREIGN] Atom matured: '{qa['expected'][:40]}' (3/3 CCV).")
            
            # Update the dataset
            self._update_jsonl_record(self.anchored_path, "fact", qa["expected"], match)
        else:
            atom_record = {
                "topic": topic,
                "fact": qa["expected"],
                "verification_count": 1,
                "verified_contexts": [current_context],
                "status": "PROBATION_1 | VERIFIED_100",
                "anchored_at": datetime.now().isoformat()
            }
            self._append_jsonl(self.anchored_path, atom_record)

    def _load_jsonl(self, path: str) -> List[Dict]:
        if not os.path.exists(path): return []
        with open(path, "r", encoding="utf-8") as f:
            return [json.loads(l) for l in f if l.strip()]

    def _update_jsonl_record(self, path: str, key: str, value: str, updated_record: Dict):
        records = self._load_jsonl(path)
        new_records = []
        for r in records:
            if r.get(key) == value:
                new_records.append(updated_record)
            else:
                new_records.append(r)
        with open(path, "w", encoding="utf-8") as f:
            for r in new_records:
                f.write(json.dumps(r) + "\n")

    def _flag_atom_failure(self, topic: str, qa: Dict):
        """Phase 4.50: Quarantines a single failed Knowledge Atom for remediation."""
        failure_item = {
            "topic": topic,
            "question": qa["question"],
            "expected": qa["expected"],
            "actual": qa["kali_answer"],
            "score": qa["score"],
            "timestamp": datetime.now().isoformat(),
            "retry_prompt": f"KNOWLEDGE ATOM FAILURE: Reinforce the following fact: {qa['expected']}. KALI previously thought: {qa['kali_answer']}"
        }
        self._append_jsonl(self.failures_path, failure_item)
        # Pin the topic if any atom fails
        self._append_jsonl(self.pinned_path, {"topic": topic, "gap": qa["question"], "pinned_at": datetime.now().isoformat()})

    def _append_training_log(self, record: Dict):
        """Appends a record to training_log.json (list format)."""
        log = self.get_training_log()
        log.append(record)
        try:
            with open(self.training_log_path, "w", encoding="utf-8") as f:
                json.dump(log, f, indent=2, ensure_ascii=False)
        except Exception as e:
            logger.error(f"Failed to write training log: {e}")

    def _append_jsonl(self, path: str, record: Dict):
        """Appends a record to a .jsonl file."""
        try:
            with open(path, "a", encoding="utf-8") as f:
                f.write(json.dumps(record, ensure_ascii=False) + "\n")
        except Exception as e:
            logger.error(f"Failed to append to {path}: {e}")
