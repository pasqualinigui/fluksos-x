"""TDD US3 — erros de domínio (FR-006). REPROVA sem exceptions.py (T020)."""

import pytest
from fkx_core import ConfigError, FkxError, ModelError, StateError


def test_hierarquia():
    assert issubclass(ConfigError, FkxError)
    assert issubclass(StateError, FkxError)
    assert issubclass(ModelError, FkxError)
    assert issubclass(FkxError, Exception)


def test_mensagem_contextual_sem_base_nua():
    err = ConfigError("FKX_ENV", "ausente ou inválida")
    assert "FKX_ENV" in str(err)
    with pytest.raises(FkxError):
        raise StateError("etapa", "transição inválida")


def test_nao_e_base_exception_direta():
    assert FkxError.__bases__ == (Exception,)


def test_detail_estruturado():
    err = ConfigError("FKX_ENV", "ausente ou inválida")
    d = err.detail()
    assert (d.field, d.reason) == ("FKX_ENV", "ausente ou inválida")
