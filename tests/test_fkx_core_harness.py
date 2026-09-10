"""TDD US1/US2/US3 — harness feedforward+feedback (FR-001..007, FR-012). REPROVA sem harness.py (T010)."""

import pytest
from fkx_core import HarnessError, harness


def test_us1_comando_ok_veredito_conforme():
    v = harness.run(["true"], requisito="FR-002")
    assert (v.exit, v.returncode, v.requisito) == (0, 0, "FR-002")
    assert len(v.evidencia) > 0


def test_us1_saida_3_falha_nomeada_com_rc():
    v = harness.run(["bash", "-c", "exit 3"], requisito="FR-002")
    assert v.exit == 1
    assert v.returncode == 3
    assert v.requisito == "FR-002"


def test_us1_morte_por_sinal_nunca_verde():
    v = harness.run(["bash", "-c", "kill -9 $$"], requisito="FR-002")
    assert v.exit == 1
    assert v.returncode == -9


def test_us1_timeout_expiracao_nomeada_fail_closed():
    v = harness.run(["sleep", "5"], requisito="FR-002", timeout=1)
    assert v.exit == 1
    lowered = v.evidencia.lower()
    assert "timeout" in lowered or "expir" in lowered


def test_us2_recusa_nao_gera_processo(tmp_path, monkeypatch):
    marker = tmp_path / "marker-017"
    monkeypatch.setenv("FKX_HARNESS_FORCE_PLATFORM", "nonposix")
    with pytest.raises(HarnessError):
        harness.run(["touch", str(marker)], requisito="FR-001")
    assert not marker.exists()


def test_us2_binario_ausente_erro_de_uso():
    v = harness.run(["binario-inexistente-017-fkxfk"], requisito="FR-001")
    assert v.exit == 2


def test_us2_plataforma_forcada_falha_fechada(monkeypatch):
    monkeypatch.setenv("FKX_HARNESS_FORCE_PLATFORM", "nonposix")
    with pytest.raises(HarnessError):
        harness.run(["true"], requisito="FR-012")


def test_us3_exits_no_alfabeto():
    for cmd, want in [(["true"], 0), (["bash", "-c", "exit 3"], 1)]:
        assert harness.run(cmd, requisito="FR-003").exit == want
    assert harness.run(["binario-inexistente-017-fkxfk"], requisito="FR-003").exit == 2


def test_harness_error_hierarquia():
    from fkx_core import FkxError

    assert issubclass(HarnessError, FkxError)
    with pytest.raises(FkxError):
        raise HarnessError("portao", "recusa nomeada")
