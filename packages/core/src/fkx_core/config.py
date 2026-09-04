"""Settings FKX_ do kernel (FR-003). Env como fonte; arquivo nunca exigido."""

from pydantic import SecretStr, ValidationError
from pydantic_settings import BaseSettings, SettingsConfigDict

from fkx_core.exceptions import ConfigError
from fkx_core.models import EnvName, LogLevel


class Settings(BaseSettings):
    """Configuração tipada; segredos mascarados; falhas viram ConfigError."""

    model_config = SettingsConfigDict(env_prefix="FKX_")

    env: EnvName
    log_level: LogLevel = "INFO"
    api_secret: SecretStr | None = None


def load_settings() -> Settings:
    """Constrói Settings do ambiente; ausência/invalidade vira ConfigError nomeado."""
    try:
        return Settings()  # type: ignore[call-arg]  # `env` vem do ambiente em runtime
    except ValidationError as e:
        locs = [str(x) for err in e.errors() for x in err.get("loc", ())]
        var = f"FKX_{locs[0].upper()}" if locs else "settings"
        raise ConfigError(var, "ausente ou inválida") from e
