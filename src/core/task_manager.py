import os
import json
import time
import uuid
import logging
import threading
import glob

class TaskManager:
    """
    KALI's Persistent Task Queue and Dead-Letter Rescue System.
    Ensures that KALI never forgets a mission even if she is forcefully put to sleep.
    """
    def __init__(self, processor):
        self.processor = processor
        self.logger = logging.getLogger("TaskManager")
        self.root_dir = processor.project_root
        
        self.base_dir = os.path.join(self.root_dir, "data", "neural", "tasks")
        self.pending_dir = os.path.join(self.base_dir, "pending")
        self.in_progress_dir = os.path.join(self.base_dir, "in_progress")
        self.completed_dir = os.path.join(self.base_dir, "completed")
        
        self._ensure_directories()
        self.is_active = False
        self.worker_thread = None

    def _ensure_directories(self):
        """Creates the queue structure if it does not exist."""
        os.makedirs(self.pending_dir, exist_ok=True)
        os.makedirs(self.in_progress_dir, exist_ok=True)
        os.makedirs(self.completed_dir, exist_ok=True)

    def resurrect_interrupted_tasks(self):
        """
        The Resurrection Protocol.
        Moves any stuck 'in_progress' tasks back to 'pending' on boot.
        """
        stuck_tasks = glob.glob(os.path.join(self.in_progress_dir, "*.json"))
        for task_path in stuck_tasks:
            try:
                filename = os.path.basename(task_path)
                new_path = os.path.join(self.pending_dir, filename)
                os.rename(task_path, new_path)
                self.logger.warning(f"Resurrected dropped task: {filename}")
            except Exception as e:
                self.logger.error(f"Failed to resurrect task {task_path}: {e}")

    def queue_task(self, source: str, task_text: str, context: dict = None) -> str:
        """
        Saves a new task to the persistent queue.
        """
        task_id = f"TASK_{uuid.uuid4().hex[:12].upper()}"
        task_data = {
            "id": task_id,
            "source": source,
            "text": task_text,
            "context": context or {},
            "status": "PENDING",
            "timestamp_queued": time.time()
        }
        
        task_path = os.path.join(self.pending_dir, f"{task_id}.json")
        try:
            with open(task_path, "w", encoding="utf-8") as f:
                json.dump(task_data, f, indent=4)
            self.logger.info(f"Task queued successfully: {task_id}")
            return task_id
        except Exception as e:
            self.logger.error(f"Failed to queue task: {e}")
            return None

    def start(self):
        """Starts the background worker thread."""
        if self.is_active: return
        self._ensure_directories()
        self.resurrect_interrupted_tasks()
        
        self.is_active = True
        self.worker_thread = threading.Thread(target=self._worker_loop, daemon=True)
        self.worker_thread.start()
        
        self.cron_thread = threading.Thread(target=self._cron_loop, daemon=True)
        self.cron_thread.start()
        
        self.logger.info("TaskManager background worker and autonomous cron activated.")

    def stop(self):
        """Stops the worker thread."""
        self.is_active = False

    def _worker_loop(self):
        """Continuously polls the pending directory and executes tasks."""
        while self.is_active:
            pending_tasks = sorted(glob.glob(os.path.join(self.pending_dir, "*.json")), key=os.path.getmtime)
            
            if not pending_tasks:
                # No tasks, sleep briefly to prevent CPU spinning
                time.sleep(2)
                continue
                
            task_path = pending_tasks[0]
            filename = os.path.basename(task_path)
            in_progress_path = os.path.join(self.in_progress_dir, filename)
            
            try:
                # 1. Claim the task (Move to in_progress)
                os.rename(task_path, in_progress_path)
                
                with open(in_progress_path, "r", encoding="utf-8") as f:
                    task_data = json.load(f)
                
                self.logger.info(f"Executing task: {task_data.get('id')}")
                
                # 2. Execute the task
                response = self.processor.process_doubt(
                    task_data.get("text", ""),
                    context=task_data.get("context", {})
                )
                
                # 3. Report back if it's from Telegram
                telegram_channel = self.processor.channel_manager.channels.get("telegram")
                if task_data.get("source") == "telegram" and telegram_channel:
                    reply_text = response.get("text", "Task completed, but no text output was generated.")
                    telegram_channel.send(reply_text)
                
                # 4. Mark as completed
                task_data["status"] = "COMPLETED"
                task_data["timestamp_completed"] = time.time()
                
                completed_path = os.path.join(self.completed_dir, filename)
                with open(completed_path, "w", encoding="utf-8") as f:
                    json.dump(task_data, f, indent=4)
                
                os.remove(in_progress_path)
                self.logger.info(f"Task completed: {task_data.get('id')}")
                
            except Exception as e:
                self.logger.error(f"Error executing task {filename}: {e}")
                # Keep it in 'in_progress' so it can be resurrected or debugged later,
                # or optionally move to a 'failed' directory.
                time.sleep(5)

    def _cron_loop(self):
        """Autonomous Earning & Maintenance Scheduler."""
        self.logger.info("Autonomous Cron Scheduler online. Starting immediate bug hunt.")
        # Trigger an initial hunt on boot
        os.system("python src/bug_hunter.py")
        
        while self.is_active:
            # Sleep for 12 hours (43200 seconds)
            time.sleep(43200)
            self.logger.info("Triggering scheduled autonomous bug hunt.")
            os.system("python src/bug_hunter.py")

