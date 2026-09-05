"""TDD US1 — settings tipadas (FR-003). REPROVA sem config.py (T015)."""

import pytest
from fkx_core import ConfigError, load_settings


def _clean(monkeypatch):
    for v in ("FKX_ENV", "FKX_LOG_LEVEL", "FKX_API_SECRET"):
        monkeypatch.delenv(v, raising=False)


def test_defaults_env_limpo(monkeypatch):
    _clean(monkeypatch)
    monkeypatch.setenv("FKX_ENV", "dev")
    s = load_settings()
    assert s.env == "dev"
    assert s.log_level == "INFO"
    assert s.api_secret is None


def test_segredo_mascarado(monkeypatch):
    _clean(monkeypatch)
    monkeypatch.setenv("FKX_ENV", "dev")
    monkeypatch.setenv("FKX_API_SECRET", "s3cr3t-valor")
    s = load_settings()
    assert "s3cr3t-valor" not in repr(s.api_secret)
    assert "s3cr3t-valor" not in repr(s)


def test_env_invalido_eleva_config_error(monkeypatch):
    _clean(monkeypatch)
    monkeypatch.setenv("FKX_ENV", "staging")
    with pytest.raises(ConfigError) as exc:
        load_settings()
    assert "FKX_ENV" in str(exc.value)


def test_var_obrigatoria_ausente_eleva_config_error(monkeypatch):
    _clean(monkeypatch)
    with pytest.raises(ConfigError) as exc:
        load_settings()
    assert "FKX_ENV" in str(exc.value)
