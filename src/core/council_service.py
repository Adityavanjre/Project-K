import os
import logging
from typing import List, Dict, Any
from .agents.expert_agents import get_default_experts, ExpertAgent

class CouncilService:
    """
    The Great Council: A Multi-Agent MsgHub for KALI.
    Orchestrates specialized experts to debate and reach consensus.
    """
    def __init__(self, ai_service, sovereign_mode: bool = False, project_root: str = None):
        self.ai = ai_service
        self.logger = logging.getLogger(__name__)
        self.sovereign_mode = sovereign_mode
        self.project_root = project_root or os.getcwd()
        self.scores_path = os.path.join(self.project_root, "data", "sovereignty_scores.json")
        
        self.scores = self._load_scores()
        
        if sovereign_mode:
            self.logger.info("🛡️ COUNCIL: Sovereign Mode Active. All experts mapped to Local Node.")
            self.experts = self._get_sovereign_experts()
        else:
            self.experts = self._get_experts_with_cutover()

    def _load_scores(self) -> Dict[str, Any]:
        """Phase 52: Load expert sovereignty scores."""
        import json
        if not os.path.exists(self.scores_path):
            return {}
        try:
            with open(self.scores_path, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}

    def _save_scores(self):
        """Phase 52: Persist expert sovereignty scores."""
        import json
        os.makedirs(os.path.dirname(self.scores_path), exist_ok=True)
        try:
            with open(self.scores_path, "w", encoding="utf-8") as f:
                json.dump(self.scores, f, indent=2)
        except Exception as e:
            self.logger.error(f"Failed to save sovereignty scores: {e}")

    def _get_experts_with_cutover(self) -> List[ExpertAgent]:
        """
        Phase 52: Granular Sovereign Cutover (C-4).
        Prioritizes the 'sovereign_ready' flag. 
        Falls back to score-based cutover (score > 0.9 and pass_count >= 3).
        """
        experts = get_default_experts()
        for expert in experts:
            # 1. Check explicit flag
            if getattr(expert, "sovereign_ready", False):
                expert.model = "local"
                self.logger.info(f"✨ SOVEREIGN_READY: '{expert.name}' ({expert.domain}) is active on Local Node.")
                continue

            # 2. Fallback to performance-based cutover
            stats = self.scores.get(expert.name, {"score": 0.0, "pass_count": 0})
            if stats.get("score", 0.0) >= 0.9 and stats.get("pass_count", 0) >= 3:
                expert.model = "local"
                self.logger.info(f"📈 PERFORMANCE CUTOVER: '{expert.name}' exceeded 0.9 efficiency. Cutover active.")
                
        return experts

    def _get_sovereign_experts(self) -> List[ExpertAgent]:
        """
        Phase 52: Create local-model instances of the standard council experts.
        """
        experts = get_default_experts()
        for expert in experts:
            expert.model = "local" # Force local routing in AI Service
        return experts

    def shadow_evaluate(self, query: str, local_response: str, council_consensus: str) -> Dict[str, float]:
        """
        Phase 52: Shadow Evaluation (C-3).
        Compares local model output against council consensus.
        """
        self.logger.info("🛡️ Performing Sovereign Shadow Evaluation...")
        
        # Referee Prompt
        referee_prompt = (
            f"You are the KALI REFEREE. Compare the Local Response against the Council Consensus.\n\n"
            f"QUERY: {query}\n\n"
            f"LOCAL RESPONSE: {local_response}\n\n"
            f"COUNCIL CONSENSUS: {council_consensus}\n\n"
            "Score the Local Response relative to the Consensus on a scale of 0.0 to 1.0. "
            "Consider technical precision, alignment with council stance, and tone. "
            "Return ONLY a JSON object: {\"score\": 0.85, \"reasoning\": \"...\"}"
        )
        
        try:
            res = self.ai.ask_question(referee_prompt, context="Sovereign Referee Mode")
            # Simple cleanup for JSON
            import json
            cleaned = res.strip()
            if "```json" in cleaned: cleaned = cleaned.split("```json")[1].split("```")[0].strip()
            elif "```" in cleaned: cleaned = cleaned.split("```")[1].split("```")[0].strip()
            
            data = json.loads(cleaned)
            score = data.get("score", 0.0)
            
            # Update scores for the 'General' expert (or all active if multi-expert shadow)
            for expert in self.experts:
                if expert.model != "local": # Only score those still in 'shadow' mode
                    stats = self.scores.get(expert.name, {"score": 0.0, "pass_count": 0, "history": []})
                    stats["score"] = (stats["score"] * stats["pass_count"] + score) / (stats["pass_count"] + 1)
                    stats["pass_count"] += 1
                    stats["history"].append(score)
                    self.scores[expert.name] = stats
            
            self._save_scores()
            return data
        except Exception as e:
            self.logger.error(f"Shadow evaluation failed: {e}")
            return {"score": 0.0, "error": str(e)}

    def get_consensus(self, query: str, context: str = "", bypass_cache: bool = False, debate_rounds: int = 1) -> str:
        """
        Convenes the Council in a multi-round debate as a MsgHub.
        """
        self.logger.info(f"Convening KALI Council MsgHub for: {query.splitlines()[0]}...")
        
        debate_history = []
        
        # 1. Initial round: Each expert gives their perspective
        for expert in self.experts:
            prompt = expert.get_prompt_with_context(query, debate_history)
            sys_msg = f"{expert.system_prompt}\nYou are part of KALI's Council. User Context: {context}"
            
            # Phase 55: Pass role to LocalAIService if model is local
            role_hint = expert.name.lower() if expert.model == "local" else "general"
            
            response = self.ai.ask_question(
                prompt, 
                context=sys_msg, 
                temperature=0.7, 
                query_model=expert.model, 
                bypass_cache=bypass_cache,
                role=role_hint
            )
            
            if response:
                debate_history.append({"role": expert.name, "content": response})
                self.logger.info(f"Council: {expert.name} provides initial insight.")

        # 2. Subsequent rounds: Experts critique and refine (if debate_rounds > 1)
        for r in range(debate_rounds - 1):
            self.logger.info(f"Council: Round {r+2} of debate initiating.")
            for expert in self.experts:
                # Ask expert to critique and improve based on others' views
                critique_prompt = f"Review the previous council insights. Refine your own stance or resolve contradictions. FOCUS: {query}"
                prompt = expert.get_prompt_with_context(critique_prompt, debate_history)
                
                response = self.ai.ask_question(
                    prompt, 
                    context=f"CONTRADICTION RESOLUTION MODE. {expert.system_prompt}", 
                    temperature=0.5, 
                    query_model=expert.model, 
                    bypass_cache=bypass_cache
                )
                if response:
                    debate_history.append({"role": expert.name, "content": response})

        # 3. Final Synthesis (The Lead)
        self.logger.info("Consolidating final Council consensus...")
        
        synthesis_prompt = (
            f"GOAL: {query}\n"
            f"COUNCIL DEBATE LOG:\n" + 
            "\n---\n".join([f"[{m['role']}]: {m['content']}" for m in debate_history]) + 
            "\n\nSynthesize the debate above into a single, master-level KALI response. "
            "Resolve any remaining conflicts, ensure technical precision, and prioritize user safety."
        )
        
        final_answer = self.ai.ask_question(synthesis_prompt, bypass_cache=bypass_cache)
        return final_answer
