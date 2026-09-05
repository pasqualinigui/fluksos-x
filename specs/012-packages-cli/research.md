# Research: `packages/cli` — entry point `fkx`

**Fonte vinculante**: `docs/plan/research/f0-012-packages-cli.md` (Q1–Q10, fetch 2026-09-05) · **Consolidação**: decisões abaixo, sem NEEDS CLARIFICATION restante (superfície mínima, códigos e formato resolvidos no CLARIFY 2026-09-05, 4/4).

## Decision: typer 0.27.2 + rich 15.0.0 como runtime do pacote, sem click

- **Decision**: `typer==0.27.2` + `rich==15.0.0` em `dependencies` de `packages/cli`; `uv.lock` fonte única; `click` não declarado (0.27.2 standalone, provado por `ModuleNotFoundError` executado).
- **Rationale**: pacote publicado precisa ser funcional; rich explícito porque piso transitivo (`rich>=13.8.0` de typer) não é pin (determinismo I).
- **Alternatives considered**: typer 0.27.1 do plano (rejeitado: defasado em um patch, 0.27.2 triangulado PyPI+GitHub+execução); rich só-transitivo (rejeitado: build não reproduzível).

## Decision: callback-raiz mínimo com --help/--version; códigos 0/0/2/1

- **Decision**: `app: typer.Typer` callback-raiz, sem subcomando; `fkx` sem args ≡ `--help` (exit 0); `--version` imprime só o número (exit 0); uso inválido exit 2; erro de domínio exit 1.
- **Rationale**: YAGNI/Escada (grupo vazio antecipa forma sem consumidor); 2 reservado a uso, 1 a domínio — base do futuro 4.11; número puro é máquina-legível para CI.
- **Alternatives considered**: grupo vazio preparado (rejeitado: forma sem consumidor); `fkx 0.1.0` com nome (rejeitado: asserção por sufixo, pior para parse); ação padrão sem args (rejeitado: sem consumidor definido); códigos por domínio (rejeitado: granularidade sem leitor).

## Decision: versão via importlib.metadata, fonte única [project].version

- **Decision**: `--version` lê `importlib.metadata.version("fkx-cli")` (stdlib); fonte única = `version` do `packages/cli/pyproject.toml`.
- **Rationale**: zero duplicação (estático `__version__` diverge do instalado); provado executado (`fkx-core 0.1.0` pós `uv sync --all-packages`; sem sync o metadata some — mesma armadilha ADR-023).
- **Alternatives considered**: `__version__` estático em `__init__.py` (rejeitado: duas fontes); ler `pyproject.toml` em runtime (rejeitado: arquivo de build não viaja instalado).

## Decision: entry point [project.scripts] + py.typed desde o esqueleto

- **Decision**: `[project.scripts] fkx = "fkx_cli.main:app"` (PEP 621, tutorial oficial); `py.typed` vazio no esqueleto; testes em `tests/test_fkx_cli_*.py` via `typer.testing.CliRunner` (import provado).
- **Rationale**: padrão oficial Typer, não invenção; `py.typed` evita pacote opaco ao mypy (lição ADR-024); CliRunner testa sem subprocesso.
- **Alternatives considered**: `[project.entry-points]` manual (rejeitado: não é o padrão do tutorial); testes via subprocesso `fkx` (rejeitado: acoplam instalação ao teste unitário; smoke instalado cabe ao quickstart); `packages/cli/tests/` (rejeitado: quebra contrato 005).

## Decision: Rich com escape, locals off; CLI consome fkx_core sem duplicar

- **Decision**: saída via Rich; dado dinâmico em markup passa por `rich.markup.escape`; `pretty_exceptions_show_locals` desligado; dependência de membro `fkx-core`; `ConfigError` e irmãos viram saída nomeada + exit 1.
- **Rationale**: Lei Zero em profundidade (trace rico com locals vaza segredo); consumo sem duplicação (IV).
- **Alternatives considered**: print puro sem Rich (rejeitado: help rico é o padrão com rich instalado; plano §4 fixa Rich); pretty locals on para debug (rejeitado: risco de segredo em log).
