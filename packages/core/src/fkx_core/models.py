"""Vocabulário compartilhado do kernel (FR-005). Sem lógica de negócio."""

from typing import Literal

from pydantic import BaseModel, ConfigDict

EnvName = Literal["dev", "test", "prod"]
LogLevel = Literal["DEBUG", "INFO", "WARNING", "ERROR"]


class ErrorDetail(BaseModel):
    """Forma estruturada de um FkxError (observabilidade X, base do Guardião)."""

    model_config = ConfigDict(extra="forbid", frozen=True)

    field: str
    reason: str
