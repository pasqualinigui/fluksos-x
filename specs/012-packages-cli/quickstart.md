# Quickstart: `packages/cli` — entry point `fkx`

**Spec**: `specs/012-packages-cli/spec.md` · **Contrato**: `contracts/oracle-cli.md` · **Modelo**: `data-model.md`

Pré-requisito: setup canônico `uv sync --frozen --all-packages` (`uv sync` puro remove membros — armadilha ADR-023).

## Validação completa em um comando

```bash
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done
sha256sum -c scripts/verify/manifest.sha256
uv run ruff check . && uv run ruff format --check packages/cli/ && uv run mypy --strict . && uv run pytest -q
```

## Cenário 1 — Ajuda instalável (US1)

```bash
uv run fkx --help      # exit 0; contém --help e --version (painel Rich)
uv run fkx             # exit 0; equivale a --help (CLARIFY)
uv run fkx --nope > /tmp/out.txt 2> /tmp/err.txt; echo $?  # exit 2; err nomeia a opção + dica --help
```

> Armadilha: nunca medir `$?` após pipe (`cmd | head` retorna o exit do `head`).

## Cenário 2 — Versão (US2)

```bash
uv run fkx --version   # exit 0; imprime só X.Y.Z
```

Confere com `version` de `packages/cli/pyproject.toml` no ambiente sincronizado.

## Cenário 3 — Erro nomeado (US3)

```bash
grep -rn "except:" packages/cli/src/fkx_cli/  # zero ocorrências
grep -rni "sk-\|secret\|token\s*=" packages/cli/src/  # zero segredo literal
```

Domínio (`ConfigError` e irmãos via `fkx_core`): saída nomeada + exit 1; uso: exit 2.

## Cenário 4 — Fumaça do instalado

```bash
uv run --no-sync -- python -c "import importlib.metadata as m; print(m.version('fkx-cli'))"
```

## Cenário 5 — CONVERGE

```bash
scripts/verify/f0-012-cli.sh            # 12/12
grep -c "^- \[ \]" specs/012-packages-cli/tasks.md  # 0
git log --oneline | grep -E "test\(harness\).*012|feat\(packages\).*012"  # vermelho antes do verde
```

## Troubleshooting

| Sintoma | Causa provável | Ação |
|---|---|---|
| `m.version('fkx-cli')` → `PackageNotFoundError` | sync sem `--all-packages` | `uv sync --frozen --all-packages` |
| `mypy` reclama de callback | função sem anotação | anotar `(value: bool) -> None` (`disallow_untyped_defs`) |
| `ruff format --check` reprova | formatação | `ruff format packages/cli/` (fora do hook; hook é `--check`) |
| help sem painel Rich | rich ausente do env | sync com `--all-packages`; rich é runtime declarado |
