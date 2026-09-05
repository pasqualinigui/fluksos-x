# Data Model: `packages/cli` — entry point `fkx`

**Spec**: `specs/012-packages-cli/spec.md` · **Research**: `docs/plan/research/f0-012-packages-cli.md` (+ `research.md` consolidação)

## Entidades

### App

Raiz do entry point (`fkx_cli.main:app: typer.Typer`, callback-raiz, sem subcomandos).

| Atributo | Tipo | Regra |
|---|---|---|
| `help` | texto fixo | identifica o motor (`fkx`); sem segredo |
| `add_completion` | `False` | sem side-effect de shell na instalação (determinismo; sem escrita fora de stdout/stderr) |
| `no_args_is_help` / callback sem subcomando | comportamento | `fkx` sem args ≡ `--help`, exit 0 (CLARIFY) |
| `pretty_exceptions_show_locals` | `False` | Lei Zero (Q6) |
| `rich_markup_mode` | default (`"rich"` com rich instalado) | help rico automático; sem configuração exótica |

Relacionamento: `App` consome `Settings`/`FkxError` de `fkx_core` (011); não os redefine.

### Version

Versão do pacote instalado.

| Atributo | Tipo | Regra |
|---|---|---|
| `value` | `X.Y.Z` (só o número) | `importlib.metadata.version("fkx-cli")`; fonte única `[project].version` |
| `render` | stdout, uma linha | `fkx --version` → exit 0; sem prefixo, sem cor obrigatória |

Validação: `value` confere com `version` de `packages/cli/pyproject.toml` no ambiente sincronizado (`uv sync --all-packages`; sem sync o metadata pode ausentar-se — armadilha ADR-023, não defeito).

### CliFault

Falha nomeada da CLI.

| Atributo | Tipo | Regra |
|---|---|---|
| `cause` | texto | nomeia a causa (opção inválida, domínio); nunca segredo |
| `hint` | texto | erro de uso inclui dica de `--help` |
| `exit_code` | `2` uso inválido · `1` domínio · `0` sucesso | 2 reservado a uso (CLARIFY); base do 4.11 |
| `stream` | `stderr` para erro | stdout reservado a resultado (parseabilidade) |

Transições: `FkxError` (ConfigError/StateError/ModelError) → `CliFault(exit_code=1)`; opção inválida do parser → `CliFault(exit_code=2)`; sucesso → exit 0.

## Superfície pública (`fkx_cli/__init__.py`)

`app` (objeto raiz). Nada além: sem re-export de `fkx_core` (consumo é import direto, não duplicação).

## Regras de validação (para o oráculo)

- `main.py` define `app = typer.Typer(...)`; `[project.scripts]` mapeia `fkx` → `fkx_cli.main:app`.
- Callbacks anotados (`mypy --strict`); zero `except:` nu; zero literal de segredo; `escape()` em interpolação de dado dinâmico em markup.
- `py.typed` presente (PEP 561); `__init__.py` exporta `app`.
