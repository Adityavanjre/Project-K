import os
import json
import re

def extract_from_llama3_text(text):
    """Extracts user and assistant text from a Llama3 formatted string."""
    user_match = re.search(r'<\|start_header_id\|>user<\|end_header_id\|>\n(.*?)<\|eot_id\|>', text, re.DOTALL)
    assistant_match = re.search(r'<\|start_header_id\|>assistant<\|end_header_id\|>\n(.*?)<\|eot_id\|>', text, re.DOTALL)
    
    if user_match and assistant_match:
        return user_match.group(1).strip(), assistant_match.group(1).strip()
    return None, None

def compile_dataset():
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    training_dir = os.path.join(project_root, "training")
    
    input_files = [
        ("kali_training_data.jsonl", "format1"),
        ("universal_convergence_deep.jsonl", "format2"),
        ("universal_convergence.jsonl", "format2")
    ]
    
    output_file = os.path.join(training_dir, "master_kali_dataset.jsonl")
    
    total_entries = 0
    with open(output_file, 'w', encoding='utf-8') as outfile:
        for file_name, file_format in input_files:
            file_path = os.path.join(training_dir, file_name)
            if not os.path.exists(file_path):
                print(f"Skipping {file_name} (not found)")
                continue
                
            print(f"Processing {file_name}...")
            with open(file_path, 'r', encoding='utf-8') as infile:
                lines = infile.readlines()
                for line in lines:
                    line = line.strip()
                    if not line:
                        continue
                        
                    try:
                        data = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                        
                    user_content = ""
                    assistant_content = ""
                    
                    if file_format == "format1":
                        user_content = data.get("instruction", "").strip()
                        assistant_content = data.get("response", "").strip()
                    elif file_format == "format2":
                        text = data.get("text", "")
                        user_content, assistant_content = extract_from_llama3_text(text)
                        
                    if user_content and assistant_content:
                        master_entry = {
                            "messages": [
                                {"role": "user", "content": user_content},
                                {"role": "assistant", "content": assistant_content}
                            ]
                        }
                        outfile.write(json.dumps(master_entry, ensure_ascii=False) + '\n')
                        total_entries += 1
                        
    print(f"\nCompilation complete! Wrote {total_entries} entries to {output_file}")

if __name__ == "__main__":
    compile_dataset()
