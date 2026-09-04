"""Schema TypedDict do grafo futuro (FR-004). Sem comportamento, sem Pydantic."""

from operator import add
from typing import Annotated, TypedDict


class KernelState(TypedDict):
    """Canais fixos; `erros` acumula, demais sobrescrevem (default)."""

    status: str
    etapa: str
    erros: Annotated[list[str], add]
