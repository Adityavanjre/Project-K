"""Model router — resolves role to model name(s).

Thin layer over LLMModelMapping that provides convenience methods
for primary-only and primary+fallback resolution.
"""

from __future__ import annotations

from decepticon.llm.models import LLMModelMapping, ModelAssignment


class ModelRouter:
    """Resolves agent roles to model names."""

    def __init__(self, mapping: LLMModelMapping | None = None):
        self.mapping = mapping or LLMModelMapping()

    def resolve(self, role: str) -> str:
        """Return the primary model name for a role."""
        return self.get_assignment(role).primary

    def resolve_with_fallback(self, role: str) -> list[str]:
        """Return [primary, fallback] model names. Single-element if no fallback."""
        assignment = self.get_assignment(role)
        chain = [assignment.primary]
        if assignment.fallback:
            chain.append(assignment.fallback)
        return chain

    def get_assignment(self, role: str) -> ModelAssignment:
        """Return full ModelAssignment for a role."""
        return self.mapping.get_assignment(role)
