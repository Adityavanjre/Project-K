import os
import re
import yaml
import logging
import subprocess

class GStackManager:
    """
    Manages the 23 specialist roles from the G-Stack integration.
    Allows KALI to 'wear the hats' of CEO, Designer, Eng Manager, etc.
    """
    def __init__(self, root_dir):
        self.root = root_dir
        self.gstack_path = os.path.join(self.root, "integrations", "swarm", "gstack")
        self.skills_dir = self.gstack_path
        
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger("GStackManager")

    def list_skills(self):
        """Returns a list of all available gstack slash commands."""
        skills = []
        if not os.path.exists(self.gstack_path):
            return skills
            
        for item in os.listdir(self.gstack_path):
            item_path = os.path.join(self.gstack_path, item)
            if os.path.isdir(item_path) and os.path.exists(os.path.join(item_path, "SKILL.md")):
                skills.append(f"/{item}")
        return sorted(skills)

    def get_skill_soul(self, skill_name):
        """
        Extracts the system prompt and metadata for a specific skill.
        Example: skill_name = 'office-hours'
        """
        skill_path = os.path.join(self.gstack_path, skill_name.lstrip('/'), "SKILL.md")
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

    def execute_preamble(self, skill_name):
        """
        Executes the bash preamble found in SKILL.md to gather project context.
        This is a 'Sovereign Step' where KALI checks the local state.
        """
        soul = self.get_skill_soul(skill_name)
        if not soul: return "Skill not found."
        
        # Extract bash blocks from the prompt
        bash_blocks = re.findall(r'```bash\n(.*?)\n```', soul['prompt'], re.DOTALL)
        if not bash_blocks: return "No preamble detected."
        
        # Execute the first block (usually context gathering)
        preamble = bash_blocks[0]
        self.logger.info(f"Executing Preamble for {skill_name}...")
        
        # Clean up some Claude-specific bash commands that might fail in standard shell
        # or replace them with local equivalents.
        try:
            result = subprocess.run(
                ["bash", "-c", preamble],
                cwd=self.root,
                capture_output=True,
                text=True,
                timeout=30
            )
            return result.stdout
        except Exception as e:
            return f"Preamble Failure: {str(e)}"

if __name__ == "__main__":
    manager = GStackManager(os.getcwd())
    print(f"🔱 G-Stack Roles Detected: {', '.join(manager.list_skills())}")
    
    # Test extraction
    # soul = manager.get_skill_soul("office-hours")
    # print(f"--- CEO SOUL EXTRACTED ---\n{soul['prompt'][:200]}...")
