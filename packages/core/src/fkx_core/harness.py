"""Portão feedforward + julgamento feedback do motor (017, FR-001..007, FR-012).

Feedforward: valida plataforma e resolubilidade do binário ANTES de gerar
qualquer processo; recusa retorna veredito de erro de uso (exit 2).
Feedback: executa uma única vez com captura total e returncode preservado
(negativo por sinal); morte, expiração e saída anômala viram falha nomeada.
Tentativa única por invocação, sempre: sem laço, sem reagendamento, sem espera.

Lei Zero estrutural: este módulo nunca despeja o ambiente na evidência —
só a saída do comando executado. Mascarar segredos que o COMANDO imprime
é dever do chamador (o módulo não conhece segredos; heurística de máscara
seria julgamento dentro da regra — princípio I).
"""

import os
import subprocess

from fkx_core.exceptions import HarnessError

FORCE_VAR = "FKX_HARNESS_FORCE_PLATFORM"


class Veredito:
    """Julgamento nomeado de uma execução (data-model Veredito)."""

    def __init__(
        self,
        requisito: str,
        evidencia: str,
        exit: int,  # noqa: A002 (`exit` é campo contratual)
        returncode: int,
    ) -> None:
        self.requisito = requisito
        self.evidencia = evidencia
        self.exit = exit
        self.returncode = returncode


def _plataforma() -> str:
    """Posix efetivo: forçamento explícito vence a detecção (ANALYZE C3)."""
    forca = os.environ.get(FORCE_VAR, "")
    if forca == "nonposix":
        return "nonposix"
    if forca == "posix":
        return "posix"
    return "posix" if os.name == "posix" else "nonposix"


def _recusa(requisito: str, campo: str, motivo: str) -> Veredito:
    """Recusa feedforward: erro nomeado, sem processo (returncode 0 = nada correu)."""
    return Veredito(requisito, "HarnessError(" + campo + "): " + motivo, 2, 0)


def _texto(valor: object) -> str:
    """TimeoutExpired carrega bytes mesmo em modo texto (CPython); normaliza."""
    if valor is None:
        return ""
    if isinstance(valor, bytes):
        return valor.decode("utf-8", errors="replace")
    return str(valor)


def run(
    cmd: list[str],
    *,
    timeout: float | None = None,
    requisito: str = "HARNESS",
) -> Veredito:
    """Executa cmd uma vez e julga (contrato Superfície, ANALYZE F1)."""
    if len(cmd) == 0:
        raise HarnessError("cmd", "sequencia vazia (mau uso da API)")
    if timeout is not None and timeout <= 0:
        raise HarnessError("timeout", "nao-positivo (mau uso da API)")
    if _plataforma() != "posix":
        return _recusa(requisito, "plataforma", "nao-POSIX: recusa fail-closed")
    try:
        proc = subprocess.run(
            list(cmd),
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        saida = _texto(exc.stdout) + _texto(exc.stderr)
        return Veredito(
            requisito,
            "timeout apos "
            + str(timeout)
            + "s (fail-closed)\nreturncode=124\n"
            + saida.strip(),
            1,
            124,
        )
    except OSError as exc:
        return _recusa(requisito, "binario", type(exc).__name__ + ": " + str(exc))
    rc = proc.returncode
    out = proc.stdout if proc.stdout is not None else ""
    err = proc.stderr if proc.stderr is not None else ""
    evidencia = (
        "returncode=" + str(rc) + "\nstdout=" + out.strip() + "\nstderr=" + err.strip()
    )
    if rc == 0:
        return Veredito(requisito, evidencia, 0, rc)
    return Veredito(requisito, evidencia, 1, rc)
