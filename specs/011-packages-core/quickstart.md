# Quickstart: `packages/core` — kernel do motor

Validação fim-a-fim da 011. Detalhes em `contracts/oracle-cli.md`, entidades em `data-model.md`.

## Pré-requisitos

Harness 10/10 + manifest 10/10 · `uv sync` verde.

## Cenário 1 — Settings de env limpo (SC-001, FR-003)

```bash
env -i PATH="$PATH" HOME="$HOME" uv run python3 -c "
from fkx_core import load_settings
s = load_settings()
print(type(s.env).__name__, type(s.api_secret).__name__)
print(repr(s.api_secret))  # esperado: mascarado, nunca o valor
"
# esperado: tipos corretos + máscara; var obrigatória ausente → ConfigError nomeado
```

## Cenário 2 — Estado mescla pelo reducer (SC-002, FR-004)

```bash
uv run python3 -c "
from fkx_core.state import KernelState
s: KernelState = {'status': 'ok', 'etapa': 'a', 'erros': []}
print(sorted(KernelState.__annotations__))  # esperado: ['erros', 'etapa', 'status']
"
uv run mypy --strict packages/core/src/fkx_core/state.py  # esperado: 0
```

## Cenário 3 — Erros nomeados (SC-003, FR-006)

```bash
grep -rn "except:" packages/core/src/fkx_core/ && echo "VIOLAÇÃO" || echo "sem except nu OK"
uv run python3 -c "from fkx_core import FkxError, ConfigError, StateError, ModelError; print(issubclass(ConfigError, FkxError))"
# esperado: True; mensagens contextuais sem segredos
```

## Cenário 4 — Portão total sobre código novo (SC-004, FR-007/008)

```bash
uv run ruff check packages/core/ && uv run ruff format --check packages/core/
uv run mypy --strict packages/core/
uv run pytest -q tests/test_fkx_core_*.py
# esperado: tudo 0; ganchos locais verdes
```

## Cenário 5 — Harness, manifest e inquebráveis (SC-005/006, FR-010/011/012)

```bash
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done  # 11/11
sha256sum -c scripts/verify/manifest.sha256                        # 11/11
grep -E "^- \[ \]" specs/011-packages-core/tasks.md | wc -l        # 0
git log --oneline | grep -E "test\(harness\).*011|feat\(packages\).*011"
# esperado: vermelho em commit separado ANTES do verde
```

## Validação completa em um comando

```bash
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done && sha256sum -c scripts/verify/manifest.sha256 && uv run pytest -q | tail -1
```

## Troubleshooting

- `import fkx_core` falha: `uv sync` + membro declarado no workspace (`members`); pacote instalado como editable no `.venv`.
- `mypy` reclama de `TypedDict`/`Annotated`: conferir `state.py` contra `data-model.md` (contrato, não improviso).
- Segredo em log: `SecretStr` + `.get_secret_value()` só no ponto de uso; oráculo grepa literal.
