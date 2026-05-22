import os
import sys

# Define all the cloned plugins
PLUGINS = [
    "openhuman",
    "mempalace",
    "obscura",
    "Windows-MCP",
    "rlm",
    "cua",
    "skills",
    "parrot",
    "wrkflw",
    "no-mistakes",
    "ml-intern",
    "ra-h_os",
    "lucebox-hub",
    "llm-rl-environments-lil-course",
    "DanceUI",
    "GitNexus",
    "easy-vibe",
    "OpenMythos",
    "Decepticon",
    "hackingtool",
    "gstack",
    "jcode",
    "kali_airllm",
    "kali_locally-uncensored",
    "kali_aider",
    "kali_litellm",
    "kali_BitNet",
    "kali_jarvis",
    "kali_shannon",
    "kali_automaton",
    "kali_graphify",
    "kali_get-shit-done",
    "kali_ralph",
    "kali_openclaw",
]

TEMPLATE = """
import os
import subprocess

class {class_name}Plugin:
    def __init__(self):
        self.plugin_path = os.path.join(os.path.dirname(__file__), "{repo_name}")

    def run(self, *args, **kwargs):
        # Default placeholder: list the files in the plugin directory to prove it works
        # or execute a default command
        try:
            print(f"[{class_name}] Activating plugin...")
            # For now we just return a message showing it was invoked
            # Later we can configure specific CLI calls per tool
            return f"{class_name} tool wrapper invoked. Add exact subprocess.run logic here to interact with {repo_name}."
        except Exception as e:
            return f"[{class_name}] Error: {{e}}"

def initialize():
    return {class_name}Plugin()
"""

def generate():
    plugins_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "plugins")
    for plugin in PLUGINS:
        # Convert e.g., 'kali_aider' to 'KaliAider' and 'Windows-MCP' to 'WindowsMcp'
        class_name = "".join(word.capitalize() for word in plugin.replace("-", "_").split("_"))
        file_name = f"{plugin.lower().replace('-', '_')}_plugin.py"
        file_path = os.path.join(plugins_dir, file_name)

        content = TEMPLATE.format(class_name=class_name, repo_name=plugin)
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Generated {file_path}")

if __name__ == "__main__":
    generate()
