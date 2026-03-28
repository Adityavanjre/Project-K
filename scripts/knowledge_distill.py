#!/usr/bin/env python3
import time
import logging
import os
import sys
import json
import re

# sys.path injection removed per Phase 52 standards. Use PYTHONPATH.

from src.core.processor import DoubtProcessor

def run_batch_distill():
    """
    Phase 52: KALI High-Density Batch Distillation (C-2).
    Generates 10 distinct, master-level instruction pairs per request to maximize tokens.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("DISTILL")
    
    processor = DoubtProcessor()
    
    # 10 High-Level Clusters
    clusters = [
        "Advanced Hardware (PCB Design, BOM Optimization, CAD Logic)",
        "Sovereign Software (Flask Security, API Hardening, Async Performance)",
        "Electronics & Robotics (Sensors, Swarm Logic, PID Control)",
        "Neural Engineering (Distillation, RLHF, Vector Alignment)",
        "System Stability (Secure Boot, Self-Healing, Integrity)",
        "Vedic Resonance & Quantum Logic Foundations",
        "Economic Intelligence (Market Analysis, Project Logistics)",
        "Autonomous Micro-Factories (Fabrication, CNC, 3D Print Ops)",
        "Cybersecurity (Encryption, RCE Guards, Identity Fences)",
        "Mathematical Foundations (Linear Algebra, Statistics for AI)"
    ]
    
    logger.info(f"💎 KALI: Initiating High-Density Batch Distillation for {len(clusters)} clusters...")
    
    total_samples = 0
    for cluster in clusters:
        logger.info(f"[*] Processing Cluster: {cluster}")
        
        # Batch Prompt for 10 pairs
        prompt = f"""
        You are the KALI CONSTITUTIONAL ARCHITECT.
        Your mission is to generate a 'Master-Level Instructional Cluster' for a local AI model replacement.
        
        CLUSTER TOPIC: {cluster}
        
        REQUIREMENTS:
        1. Generate exactly 10 distinct, technically complex question/response pairs.
        2. Questions should represent expert-level queries a developer or engineer would ask KALI.
        3. Responses must be definitive, precise, and sovereign (mentor-like).
        4. NO EMOJIS. Professional tone.
        
        OUTPUT FORMAT (JSON List):
        [
            {{"question": "...", "response": "..."}},
            ...
        ]
        """
        
        try:
            # Generate via high-fidelity API
            raw_res = processor.ai_service.ask_question(prompt, context="Batch Distillation Engine")
            
            # Use regex to find the JSON list block
            json_match = re.search(r'\[.*\]', raw_res, re.DOTALL)
            if not json_match:
                logger.error(f"[-] No JSON list found for cluster {cluster}")
                continue
                
            data_list = json.loads(json_match.group(0))
            
            if not isinstance(data_list, list):
                logger.error(f"[-] Decoded data is not a list for {cluster}")
                continue
                
            # Log each pair to the training logger
            for pair in data_list:
                processor.training_logger.log(
                    pair["question"], 
                    pair["response"], 
                    source="batch_distillation", 
                    context=cluster,
                    model="expert_distilled"
                )
                total_samples += 1
                
            logger.info(f"[+] Success: Distilled {len(data_list)} pairs for '{cluster}'.")
            
            # Anti-rate-limit jitter
            time.sleep(2)
            
        except Exception as e:
            logger.error(f"[-] Cluster Failure for '{cluster}': {e}")

    logger.info(f"✅ DISTILLATION_COMPLETE: Generated {total_samples} high-fidelity training samples.")

if __name__ == "__main__":
    run_batch_distill()
