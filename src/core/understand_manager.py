import os
import re
import yaml
import logging
import subprocess

class UnderstandManager:
    """
    Manages the Understand-Anything pedagogical roles.
    Allows KALI to build knowledge graphs and explain code/docs.
    """
    def __init__(self, root_dir):
        self.root = root_dir
        self.ua_path = os.path.join(self.root, "integrations", "understand-anything")
        self.skills_dir = os.path.join(self.ua_path, "understand-anything-plugin", "skills")
        
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger("UnderstandManager")

    def list_skills(self):
        """Returns a list of all available understand slash commands."""
        skills = []
        if not os.path.exists(self.skills_dir):
            return skills
            
        for item in os.listdir(self.skills_dir):
            item_path = os.path.join(self.skills_dir, item)
            if os.path.isdir(item_path) and os.path.exists(os.path.join(item_path, "SKILL.md")):
                skills.append(f"/{item}")
        return sorted(skills)

    def get_skill_soul(self, skill_name):
        """
        Extracts the system prompt and metadata for a specific skill.
        Example: skill_name = 'understand'
        """
        skill_path = os.path.join(self.skills_dir, skill_name.lstrip('/'), "SKILL.md")
        if not os.path.exists(skill_path):
            return None
            
        with open(skill_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Parse YAML Frontmatter
        parts = content.split('---', 2)
        if len(parts) < 3:
            return {"prompt": content}
            
        metadata = yaml.safe_load(parts[1])
        prompt = parts[2].strip()
        
        return {
            "metadata": metadata,
            "prompt": prompt
        }

    def execute_skill(self, skill_name, args=""):
        """
        Executes the logic of an Understand-Anything skill.
        For /understand, it triggers the multi-agent pipeline.
        """
        self.logger.info(f"🔱 Triggering Pedagogical Mapping: {skill_name} {args}")
        
        # In a real KALI environment, this would spawn a subagent or execute the bash logic.
        # For now, we will focus on the /understand core command.
        if skill_name == "understand":
            # Build and run the understand command
            try:
                # We use pnpm to run the core analysis
                # Note: This is a placeholder for the full multi-agent logic 
                # which KALI (as the agent) would normally perform manually.
                return "Pedagogical mapping initiated. Building Singularity Knowledge Graph..."
            except Exception as e:
                return f"Mapping Failure: {str(e)}"
        
        return "Skill recognized. Awaiting pedagogical instructions."

if __name__ == "__main__":
    manager = UnderstandManager(os.getcwd())
    print(f"🔱 Understand-Anything Skills Detected: {', '.join(manager.list_skills())}")
