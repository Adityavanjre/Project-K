import os
import json
from datetime import datetime
import argparse

# Phase 50: Sovereign Weight-Bake (Unsloth Edition)
# This script performs the actual fine-tuning of KALI's LLM.

def train_kali(data_path=None, output_dir=None):
    """
    Refined Sovereign Training Pipeline for Phase 52.
    """
    # Defensive imports for non-CUDA environments
    try:
        import torch
        from unsloth import FastLanguageModel
        from trl import SFTTrainer
        from transformers import TrainingArguments
        from datasets import Dataset
    except ImportError as e:
        print(f"ERROR: Missing training dependencies: {e}")
        print("Please run 'pip install -r requirements_colab.txt' to prepare the environment.")
        return

    # Use relative paths by default
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    if data_path is None:
        data_path = os.path.join(project_root, "data", "training_data.jsonl")
    if output_dir is None:
        output_dir = os.path.join(project_root, "kali_weights")

    print(f"🔥 KALI: Initiating Sovereign Weight-Bake (Phase 52) on {data_path}...")
    
    # 1. Load Model and Tokenizer
    max_seq_length = 2048
    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name = "unsloth/llama-3-8b-instruct-bnb-4bit",
        max_seq_length = max_seq_length,
        load_in_4bit = torch.cuda.is_available(),
    )

    # 2. Add LoRA Adapters
    model = FastLanguageModel.get_peft_model(
        model,
        r = 16,
        target_modules = ["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
        lora_alpha = 16,
        lora_dropout = 0.05, # Phase 52: Added regularization
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
    if not os.path.exists(data_path):
        print(f"FAILED: Data path {data_path} not found. Ensure knowledge_check has anchored some data.")
        return

    with open(data_path, "r", encoding="utf-8") as f:
        lines = [json.loads(line) for line in f if line.strip()]
    
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
    
    if len(formatted_data) == 0:
        print("FAILED: No valid user/assistant pairs found in training data.")
        return

    full_dataset = Dataset.from_list(formatted_data)
    
    # Phase 52: Add 90/10 Validation Split
    dataset_split = full_dataset.train_test_split(test_size=0.1, seed=3407)
    train_dataset = dataset_split["train"].map(formatting_prompts_func, batched = True,)
    eval_dataset = dataset_split["test"].map(formatting_prompts_func, batched = True,)

    # 5. Trainer Configuration (T-4: Evaluation Gate)
    batch_size = 2
    grad_accum = 4
    epochs = 3
    steps_per_epoch = len(train_dataset) // (batch_size * grad_accum)
    max_steps = max(10, steps_per_epoch * epochs)

    trainer = SFTTrainer(
        model = model,
        tokenizer = tokenizer,
        train_dataset = train_dataset,
        eval_dataset = eval_dataset,
        dataset_text_field = "text",
        max_seq_length = max_seq_length,
        args = TrainingArguments(
            per_device_train_batch_size = batch_size,
            gradient_accumulation_steps = grad_accum,
            warmup_steps = 5,
            max_steps = max_steps,
            learning_rate = 2e-4,
            fp16 = not torch.cuda.is_bf16_supported(),
            bf16 = torch.cuda.is_bf16_supported(),
            logging_steps = 1,
            evaluation_strategy = "steps",
            eval_steps = 25,
            optim = "adamw_8bit",
            weight_decay = 0.01,
            lr_scheduler_type = "linear",
            seed = 3407,
            output_dir = output_dir,
        ),
    )

    # 6. Training Execution
    print(f"[*] Starting Fine-Tune on {len(train_dataset)} training / {len(eval_dataset)} eval samples...")
    train_result = trainer.train()
    
    # Phase 52: T-4 Evaluation Gate Check
    metrics = trainer.evaluate()
    eval_loss = metrics.get("eval_loss", 999)
    print(f"[*] Post-Bake Evaluation: Loss = {eval_loss:.4f}")
    
    if eval_loss > 1.0:
        print("⚠️ CRITICAL ERROR: Evaluation Loss exceeds safety threshold (1.0).")
        print("⚠️ KALI: The bake is unstable. Sovereign weights will NOT be deployed.")
        return False

    # 6. Training Execution
    print(f"[*] Starting Fine-Tune on {len(train_dataset)} training / {len(eval_dataset)} eval samples...")
    trainer.train()

    # 7. Save the Sovereign Weights
    print(f"[*] Baking Complete. Saving KALI weights to {output_dir}...")
    model.save_pretrained_lora(output_dir)
    tokenizer.save_pretrained(output_dir)
    print("[+++] KALI Singularity State Achieved.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", type=str, help="Path to training_data.jsonl")
    parser.add_argument("--output", type=str, help="Path to save weights")
    args = parser.parse_args()
    
    train_kali(data_path=args.data, output_dir=args.output)
