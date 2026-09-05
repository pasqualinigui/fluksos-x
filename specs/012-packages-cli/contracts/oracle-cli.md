# Contrato do oráculo: `f0-012-cli.sh` — mapa FR↔asserção (ADR-015b)

**Spec**: `specs/012-packages-cli/spec.md` (12 FRs, 6 SCs, 3 US) · **Oráculo**: `scripts/verify/f0-012-cli.sh`
**Contrato de interface**: `specs/001-git-branching-strategy/contracts/oracle-cli.md` (exit 0/1/2, `--quiet`/`--list`, uma linha por asserção, raiz pelo script, somente leitura, determinismo)

Identidade 1:1 — o oráculo emite os IDs **da spec**, sem remapeamento (qualquer fragmentação futura exige mapa aqui, nunca silenciosa).

| Asserção | FR | Verifica |
|---|---|---|
| FR-001 | FR-001 | `typer==0.27.2` + `rich==15.0.0` runtime em `packages/cli` + hash `uv.lock`; ausência de `click` declarado |
| FR-002 | FR-002 | membro UV + exatamente `__init__.py`, `main.py`, `py.typed` (nada além); `[project.scripts] fkx` |
| FR-003 | FR-003 | `fkx --help` exit 0 com marcadores `--help`/`--version` |
| FR-004 | FR-004 | `fkx --version` exit 0 imprimindo só `X.Y.Z` == versão declarada |
| FR-005 | FR-005 | opção inválida exit 2 + stderr com dica `--help` |
| FR-006 | FR-006 | dep `fkx-core` de membro; consumo sem duplicação; domínio → saída nomeada exit 1 |
| FR-007 | FR-007 | `ruff check` + `format --check` + `mypy --strict` zeros sobre `src/fkx_cli/` |
| FR-008 | FR-008 | `tests/test_fkx_cli_*.py` presentes e verdes (TDD, vermelho→verde separado) |
| FR-009 | FR-009 | zero segredo literal; `escape` em markup dinâmico; locals off |
| FR-010 | FR-010 | contrato: `--list` 12 IDs, `--invalido` exit 2, 2× byte-idêntico <5s, self-check `f0-001…f0-011`, manifest 12/12 |
| FR-011 | FR-011 | `specs/README.md` `012 ✅` + hash |
| FR-012 | FR-012 | `tasks.md` zero `[ ]` + vermelho-antes-do-verde |

### Entregue por este item

- Oráculo `f0-012-cli.sh` (12 asserções identidade) + 12ª linha do manifest.

### Recebido de itens anteriores

- Contrato `oracle-cli.md` (001); molde de oráculo + guardas de `f0-011` (011); `testpaths`/`coverage` (005).

### Transferido a itens posteriores

- Mapa como referência para `f0-013…f0-016` (padrão identidade 1:1, ADR-015b).
