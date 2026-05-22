import os
import psutil

def detect_device() -> str:
    """
    Automatically detect the best available hardware device.
    Returns: "gpu" if CUDA is available, else "cpu".
    """
    try:
        import torch
        if torch.cuda.is_available():
            return "gpu"
    except ImportError:
        pass
        
    if os.environ.get("CUDA_VISIBLE_DEVICES") and os.environ.get("CUDA_VISIBLE_DEVICES") != "-1":
        return "gpu"
        
    return "cpu"

def get_system_stress() -> dict:
    """
    Get real-time system resource usage.
    """
    cpu_load = psutil.cpu_percent(interval=0.1)
    ram_usage = psutil.virtual_memory().percent
    
    return {
        "cpu_load": cpu_load,
        "ram_usage": ram_usage,
        "is_stressed": cpu_load > 80 or ram_usage > 85
    }

def get_device_info() -> dict:
    device = detect_device()
    info = {"device": device}
    
    if device == "gpu":
        try:
            import torch
            info["name"] = torch.cuda.get_device_name(0)
            info["count"] = torch.cuda.device_count()
        except:
            info["name"] = "Unknown GPU"
    else:
        info["name"] = "System CPU"
        
    return info
