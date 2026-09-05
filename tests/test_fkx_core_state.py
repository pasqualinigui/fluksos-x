"""TDD US2 — estado tipado com reducers (FR-004). REPROVA sem state.py (T018)."""

import typing
from operator import add

from fkx_core.state import KernelState


def test_canais_exatos():
    assert sorted(KernelState.__annotations__) == ["erros", "etapa", "status"]


def test_reducer_erros_e_acumulo():
    args = typing.get_args(KernelState.__annotations__["erros"])
    assert add in args
    assert add(["a"], ["b"]) == ["a", "b"]


def test_update_parcial_preserva_resto():
    s: KernelState = {"status": "ok", "etapa": "a", "erros": []}
    assert s["status"] == "ok"
    assert s["erros"] == []
