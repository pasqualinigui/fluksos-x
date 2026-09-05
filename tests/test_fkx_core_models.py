"""TDD US1/US2 — modelos Pydantic sem lógica (FR-005). REPROVA sem models.py (T022)."""

import pytest
from fkx_core.models import EnvName
from pydantic import TypeAdapter, ValidationError

_ADAPTER: TypeAdapter[EnvName] = TypeAdapter(EnvName)


def test_env_name_aceita_validos():
    assert _ADAPTER.validate_python("dev") == "dev"


def test_env_name_rejeita_invalido():
    with pytest.raises(ValidationError):
        _ADAPTER.validate_python("staging")
