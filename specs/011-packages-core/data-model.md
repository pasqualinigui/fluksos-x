# Data Model: `packages/core` — kernel do motor

## Entidades

### 1. Settings (`config.py`)

| Campo | Tipo | Regra |
|---|---|---|
| `env` | `Literal["dev","test","prod"]` | default `"dev"`; prefixo `FKX_` |
| `log_level` | `Literal[...]` | default `"INFO"`; prefixo `FKX_` |
| `api_secret` | `SecretStr \| None` | default `None`; mascarado em `repr`; acesso via `.get_secret_value()` no ponto de uso |
| ausente-obrigatória | — | var sem default ausente → `ConfigError` nomeando a var |

### 2. State (`state.py`)

| Canal | Tipo | Reducer |
|---|---|---|
| `status` | `str` | overwrite (default) |
| `etapa` | `str` | overwrite (default) |
| `erros` | `list[str]` | acúmulo (`operator.add` via `Annotated`) |

Sem canal de mensagens; sem comportamento; extensão por ADR/spec do consumidor.

### 3. Models (`models.py`)

Payloads Pydantic (validação, sem lógica): tipos fechados, `model_config` estrito onde aplicável. Nomes exatos na implementação (contrato: validação pura).

### 4. Errors (`exceptions.py`)

`FkxError(Exception)` + `ConfigError`, `StateError`, `ModelError`; mensagens contextuais (campo/valor, nunca segredo); `except:` nu e `BaseException` direta proibidos.

## Superfície pública (`fkx_core/__init__.py`)

`load_settings` (constrói `Settings`), `Settings`, `KernelState`, `FkxError`,
`ConfigError`, `StateError`, `ModelError`. Nomes fixos neste contrato; o que
012/Fase 1 importam vem daqui, nunca de submódulo direto.

## Relações

- Settings alimenta construção (fora do grafo); State é schema do futuro grafo; Models validam payloads que fluem; Errors nomeiam falhas dos três.
- `__init__.py` exporta superfície pública (o que 012/Fase 1 importam).

## Ciclo de vida

Ausente (vermelho 🔴) → presente + verde (🟢) → convergido. Tipos são imutáveis por compatibilidade: renomear chave/campo exige spec (fonte LangGraph: renomear perde estado salvo).

## Volume / escala

4 módulos; 3 canais; 4 tipos de erro; 0 serviços.
