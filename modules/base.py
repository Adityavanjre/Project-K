from abc import ABC, abstractmethod

class Module(ABC):
    name: str
    
    @property
    def metadata(self) -> dict:
        """
        Phase 7: Controlled Ecosystem Metadata.
        {
            "capabilities": list[str],
            "cost": float, (0.0 to 1.0)
            "latency_class": "fast" | "medium" | "slow",
            "risk": "SAFE" | "CONTROLLED" | "CRITICAL",
            "base_quality": float (0.0 to 1.0),
            "sandbox_tier": "safe" | "controlled" | "experimental"
        }
        """
        return {
            "capabilities": [],
            "cost": 0.0,
            "latency_class": "medium",
            "risk": "SAFE",
            "base_quality": 0.8,
            "sandbox_tier": "experimental"
        }

    @abstractmethod
    def is_available(self) -> bool:
        pass

    @abstractmethod
    def run(self, task: dict, device: str = "cpu") -> dict:
        pass
