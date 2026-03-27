import os
import json
import logging
import argparse
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("KALI_TRAINER")

def prepare_data(log_file="data/training_data.jsonl"):
    """Prepare training data from KALI's interaction logs."""
    if not os.path.exists(log_file):
        logger.error(f"Training data not found at {log_file}")
        return []
        
    formatted = []
    with open(log_file, "r", encoding="utf-8") as f:
        for line in f:
            try:
                entry = json.loads(line)
                messages = entry.get("messages", [])
                
                # Extract user/assistant turn
                user_content = ""
                asst_content = ""
                
                for msg in messages:
                    if msg["role"] == "user":
                        user_content = msg["content"]
                    elif msg["role"] == "assistant":
                        asst_content = msg["content"]
                
                if user_content and asst_content:
                    formatted.append({
                        "instruction": user_content,
                        "input": "",
                        "output": asst_content
                    })
            except Exception as e:
                logger.error(f"Error parsing log line: {e}")
                
    return formatted

def train(dry_run=True):
    """
    KALI Local LoRA Trainer (Functional).
    Phase 3: Evolution.
    """
    logger.info("Initializing KALI Local-Trainer...")
    
    data = prepare_data()
    if not data or len(data) < 1:
        logger.warning("Insufficient interaction data found for training. Need at least 1000 samples for high-fidelity sovereign soul.")
        return
        
    logger.info(f"Loaded {len(data)} training samples from Digital Soul logs.")
    
    model_name = os.getenv("LOCAL_MODEL", "unsloth/llama-3.1-8b-bnb-4bit")
    
    if dry_run:
        logger.info("[DRY RUN] Would initiate LoRA fine-tuning using Unsloth...")
        logger.info(f"Target Model: {model_name}")
        logger.info("Output Path: models/kali-refined-v1")
        return

    try:
        from unsloth import FastLanguageModel
        import torch
        from trl import SFTTrainer
        from transformers import TrainingArguments
        from datasets import Dataset

        logger.info(f"Loading Base Soul: {model_name}...")
        
        load_in_4bit = torch.cuda.is_available()
        if not load_in_4bit:
            logger.warning("CUDA NOT DETECTED. Reverting to CPU-mode (Slow Evolution).")
            
        model, tokenizer = FastLanguageModel.from_pretrained(
            model_name = model_name,
            max_seq_length = 2048,
            load_in_4bit = load_in_4bit,
        )

        model = FastLanguageModel.get_peft_model(
            model,
            r = 16, 
            target_modules = ["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
            lora_alpha = 16,
            lora_dropout = 0,
            bias = "none",
        )

        # Convert list to Dataset
        dataset = Dataset.from_list(data)

        logger.info("Initiating deep-core evolution...")
        trainer = SFTTrainer(
            model = model,
            tokenizer = tokenizer,
            train_dataset = dataset,
            dataset_text_field = "instruction", # Matches our prepare_data keys
            max_seq_length = 2048,
            args = TrainingArguments(
                per_device_train_batch_size = 2,
                gradient_accumulation_steps = 4,
                warmup_steps = 5,
                max_steps = 60,
                learning_rate = 2e-4,
                fp16 = not torch.cuda.is_bf16_supported(),
                bf16 = torch.cuda.is_bf16_supported(),
                logging_steps = 1,
                output_dir = "models/kali-refined-v1",
            ),
        )

        trainer.train()
        model.save_pretrained_merged("models/kali-sovereign-soul", tokenizer, save_method = "merged_16bit")
        logger.info("EVOLUTION COMPLETE: KALI has refined its cognitive core.")

    except ImportError:
        logger.error("Training libraries (unsloth/torch) not found. Run 'pip install -r requirements.txt'")
    except Exception as e:
        logger.error(f"Evolution Aborted: {e}")
        
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", default=True)
    args = parser.parse_args()
    
    train(dry_run=args.dry_run)
