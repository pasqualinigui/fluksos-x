"""Erros de domínio do kernel (FR-006)."""

from fkx_core.models import ErrorDetail


class FkxError(Exception):
    """Raiz dos erros do motor; carrega campo e motivo sem segredos."""

    def __init__(self, field: str, reason: str) -> None:
        self.field = field
        self.reason = reason
        super().__init__(f"{field}: {reason}")

    def detail(self) -> ErrorDetail:
        """Forma estruturada deste erro (observabilidade)."""
        return ErrorDetail(field=self.field, reason=self.reason)


class ConfigError(FkxError):
    """Configuração ausente ou inválida (US1)."""


class StateError(FkxError):
    """Estado inválido ou transição indevida (US2)."""


class ModelError(FkxError):
    """Payload inválido além da validação Pydantic (US1/US2)."""
