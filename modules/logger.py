import logging
import os

def log_execution(
    module_name: str, task_type: str, status: str, latency: float, 
    fallback_triggered: bool = False, failure_reason: str = None, 
    timeout_event: bool = False, pid: int = None, cpu_usage: float = None, 
    mem_usage: float = None, device: str = "cpu", workflow_id: str = None, step_num: int = None
):
    header = f"[WF:{workflow_id} STEP:{step_num}] " if workflow_id else ""
    print(f"{header}[ROUTE] -> {task_type}")
    print(f"{header}[MODULE] -> {module_name}")
    print(f"{header}[DEVICE] -> {(device or 'cpu').upper()}")
    print(f"{header}[PID] -> {pid or os.getpid()}")
    print(f"{header}[STATUS] -> {status}")
    print(f"{header}[LATENCY] -> {latency:.1f}s")
    if cpu_usage is not None: print(f"{header}[CPU] -> {cpu_usage:.1f}%")
    if mem_usage is not None: print(f"{header}[MEM] -> {mem_usage:.1f}MB")
    if failure_reason: print(f"{header}[REASON] -> {failure_reason}")
    if timeout_event: print(f"{header}[EVENT] -> TIMEOUT (FORCE KILLED)")
    if fallback_triggered: print(f"{header}[FALLBACK] -> TRIGGERED")
    print("-" * 20)

def log_plan_event(event_type: str, workflow_id: str, details: str = None):
    tag = f"[{event_type}]"
    print(f"{tag} Workflow: {workflow_id}")
    if details: print(f"{tag} Details: {details}")
    print("-" * 20)

def log_permission_event(event_type: str, action: str, status: str):
    tag = f"[{event_type}]"
    print(f"{tag} Action: {action}")
    print(f"{tag} Status: {status}")
    print("-" * 20)

def log_goal_event(event_type: str, goal_id: str, progress: int = None, details: str = None):
    """
    event_type: GOAL_CREATED | STEP_EXECUTED | PROGRESS | GOAL_COMPLETED
    """
    tag = f"[{event_type}]"
    prog_str = f" Progress: {progress}%" if progress is not None else ""
    print(f"{tag} Goal: {goal_id}{prog_str}")
    if details: print(f"{tag} Details: {details}")
    print("-" * 20)
    logging.info(f"{tag} {goal_id}{prog_str}: {details}")
