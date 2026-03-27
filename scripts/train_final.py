import sys
sys.path.insert(0, r"D:\pinokio\bin\miniconda\Lib\site-packages")
import os
import json
import torch
from datasets import load_dataset
from unsloth import FastLanguageModel
from trl import SFTTrainer
from transformers import TrainingArguments
from datetime import datetime

# Phase 50: Sovereign Weight-Bake (Unsloth Edition)
# This script performs the actual fine-tuning of KALI's LLM.

def train_kali(data_path=r"d:\code\doubt-clearing-ai\data\training_data.jsonl", output_dir=r"d:\code\doubt-clearing-ai\kali_weights"):
    print("🔥 KALI: Initiating Sovereign Weight-Bake (Phase 50)...")
    
    # 1. Load Model and Tokenizer
    max_seq_length = 2048
    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name = "unsloth/llama-3-8b-instruct-bnb-4bit",
        max_seq_length = max_seq_length,
        load_in_4bit = True,
    )

    # 2. Add LoRA Adapters
    model = FastLanguageModel.get_peft_model(
        model,
        r = 16,
        target_modules = ["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
        lora_alpha = 16,
        lora_dropout = 0,
        bias = "none",
        use_gradient_checkpointing = True,
        random_state = 3407,
    )

    # 3. Formatter for KALI interactions
    kali_prompt = """Below is an interaction between a user and KALI, a sovereign AI mentor.

### User:
{}

### KALI:
{}"""

    def formatting_prompts_func(examples):
        inputs       = examples["user"]
        outputs      = examples["assistant"]
        texts = []
        for input, output in zip(inputs, outputs):
            text = kali_prompt.format(input, output)
            texts.append(text)
        return { "text" : texts, }

    # 4. Load Dataset
    def load_kali_data():
        with open(data_path, "r") as f:
            lines = [json.loads(line) for line in f]
        
        # Flatten into user/assistant pairs
        formatted_data = []
        for entry in lines:
            messages = entry.get("messages", [])
            user_msg = ""
            assistant_msg = ""
            for m in messages:
                if m["role"] == "user": user_msg = m["content"]
                if m["role"] == "assistant": assistant_msg = m["content"]
            if user_msg and assistant_msg:
                formatted_data.append({"user": user_msg, "assistant": assistant_msg})
        
        from datasets import Dataset
        return Dataset.from_list(formatted_data)

    dataset = load_kali_data()
    dataset = dataset.map(formatting_prompts_func, batched = True,)

    # 5. Trainer Configuration
    trainer = SFTTrainer(
        model = model,
        tokenizer = tokenizer,
        train_dataset = dataset,
        dataset_text_field = "text",
        max_seq_length = max_seq_length,
        args = TrainingArguments(
            per_device_train_batch_size = 2,
            gradient_accumulation_steps = 4,
            warmup_steps = 5,
            max_steps = 1000, # Adjust based on dataset size
            learning_rate = 2e-4,
            fp16 = not torch.cuda.is_bf16_supported(),
            bf16 = torch.cuda.is_bf16_supported(),
            logging_steps = 1,
            optim = "adamw_8bit",
            weight_decay = 0.01,
            lr_scheduler_type = "linear",
            seed = 3407,
            output_dir = output_dir,
        ),
    )

    # 6. Training Execution
    print(f"[*] Starting Fine-Tune on {len(dataset)} interactions...")
    trainer.train()

    # 7. Save the Sovereign Weights
    print(f"[*] Baking Complete. Saving KALI weights to {output_dir}...")
    model.save_pretrained_lora(output_dir)
    tokenizer.save_pretrained(output_dir)
    print("[+++] KALI Singularity State Achieved.")

if __name__ == "__main__":
    train_kali()
