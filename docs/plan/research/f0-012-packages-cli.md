# RESEARCH — F0/012 · `packages/cli` — entry point `fkx` (--help, --version)

> **Item do plano:** 0.7 (§17 Fase 0) · **Ordem de execução:** 012/016 (ADR-011)
> **Data da verificação:** 2026-09-05 · **Papel:** Pesquisador
> **Método:** consulta direta a fontes canônicas e ao disco. Nenhum dado por memória.
> **Hierarquia de fontes (ADR-025):** P0 = registry API + executado + arquivos do repo ·
> P1 = docs oficiais + GitHub releases · P2 = padrões estáveis · P3 = comunidade (só
> com corroboração P0/P1). Versão ou comportamento externo exige ≥2 fontes
> independentes incluindo P0.
> **Insumo anterior:** `specs/011-packages-core/spec.md` › Contratos (superfície
> `fkx_core` importável) + `docs/plan/decisions.md` (ADR-011, ADR-015, ADR-017,
> ADR-018, ADR-023, ADR-024, ADR-025) + `docs/plan/implementation_plan.md` §§3–4,
> 15, 17 (item 0.7: entry point, --help, --version; §15: `packages/cli/src/fkx_cli/main.py`)
> + `specs/001-git-branching-strategy/contracts/oracle-cli.md`
> **Base:** harness 11/11 + manifest 11/11 verdes em run limpo 2026-09-05 (nota: duas
> reprovações aninhadas heterogêneas e isolado-verdes durante a sessão — `f0-001` e
> `f0-007` em runs `f0-011` distintos, retry limpo 12/12 — classe ADR-019, sem
> amostra repetida na mesma FR; sem ADR nova por §4 da ADR-019).

Este item entrega **o segundo pacote de produção**: `packages/cli/` (membro UV,
módulo `fkx_cli`) com entry point `fkx` (`--help` exit 0, `--version` exit 0,
opção inválida exit 2), `typer` + `rich` como runtime do pacote, importando a
superfície pública da 011 sem duplicá-la, sob `ruff` + `mypy --strict` + `pytest`
(fronteira inversa da 009). Não cria subcomandos de domínio (`init/dev/interview/
spec/run/...` são Fase 1+, quando houver o que comandar), `docker-compose` (015),
`.env` real (Lei Zero), release/publish (013) nem `docs/tree.md` (016).

---

## Q1 — Pins canônicos: typer (plano diz 0.27.1)?

**Fonte (P0):** `https://pypi.org/pypi/typer/json` → **0.27.2**, `requires_python >=3.10`
— fetch 2026-09-05. `https://pypi.org/pypi/typer/0.27.1/json` existe (não yanked,
mesmo `requires_python`), logo o plano está **defasado em um patch**, não errado.

**Fonte (P1, independente):** `https://api.github.com/repos/fastapi/typer/releases/latest`
→ tag **0.27.2**, publicada **2026-08-28T10:26:38Z** — fetch 2026-09-05. Confere com o PyPI.

**Fonte (P0, executada):** `uv run --with "typer==0.27.2" -- python -c "import typer"`
+ `typer.Typer` instanciado e `--help` renderizado (Q4) — fetch 2026-09-05.

**Achado:** pin **0.27.2** (latest estável, triangulado P0+P1+P0-executado). 0.27.1
permanece instalável mas não é o mais recente — fixar o verificado, nunca o lembrado.
`requires_python >=3.10` cobre a matriz do repo (`>=3.12,<3.14`).

## Q2 — Pin canônico: rich (plano diz 15.0.0)?

**Fonte (P0):** `https://pypi.org/pypi/rich/json` → **15.0.0**, `requires_python >=3.9.0`,
`yanked: False`, 2 arquivos — fetch 2026-09-05. Confere com o plano §4.

**Fonte (P1, independente):** `https://api.github.com/repos/Textualize/rich/releases/tags/v15.0.0`
→ tag **v15.0.0**, publicada **2026-04-12**, `prerelease: False` — fetch 2026-09-05.

**Fonte (P0, repo):** `uv.lock` contém `rich 15.0.0` (transitiva de `pip-audit 2.10.1`)
— fetch 2026-09-05. É evidência de existência no lock, **não** de suficiência: vir
por transitividade não é pin do pacote (determinismo I exige declarado).

**Fonte (P0, executada):** `uv run --with "rich==15.0.0"` + painel Rich renderizado no
`--help` da probe (Q4) — fetch 2026-09-05.

**Achado:** pin **15.0.0** explícito como runtime de `packages/cli` (typer já exige
`rich>=13.8.0` como piso transitivo — ver Q3 — piso não é pin; declarar é o que torna
o build reproduzível).

## Q3 — Typer ainda depende de click? O que viaja junto?

**Fonte (P0):** `https://pypi.org/pypi/typer/0.27.2/json` → `requires_dist`:
`shellingham>=1.3.0`, `rich>=13.8.0`, `annotated-doc>=0.0.2`,
`colorama; platform_system == "Windows"` — **sem click** — fetch 2026-09-05.

**Fonte (P0, executada):** `python -c "import click"` sob `uv run --with typer==0.27.2`
→ `ModuleNotFoundError: No module named 'click'`; `pip list` mostra
`typer 0.27.2 + shellingham 1.5.4 + rich 15.0.0 + typing-extensions + markdown-it-py +
pygments`, sem click — fetch 2026-09-05.

**Achado:** typer 0.27.2 é **standalone** (sem click). Nada de pin `click` na 012 —
adicionar seria dependência fantasma. Transitivos (`shellingham`, `annotated-doc`)
viajam pelo lock; só `typer` + `rich` são declarados.

## Q4 — Comportamento executado: --help / --version / erro (exit codes)?

**Fonte (P0, executada):** probe mínima em `/tmp` (fora do repo — nenhum artefato da
012 criado antes da spec) sob `uv run --with typer==0.27.2 + rich==15.0.0` —
fetch 2026-09-05:

```
--help     → exit 0, 1040 bytes, painel Rich "Options" (--version, --help)
--version  → exit 0, imprime versão ("fkx 0.1.0" na probe)
--nope     → exit 2, "No such option: --nope" + dica "--help"
```

**Armadilha de medição registrada:** `cmd | head` faz `$?` ser o do `head` (observado
`bad_exit=0` no pipe); medir com redirect + `$?` (`bad_exit=2` correto). Oráculo da
012 MUST medir sem pipe mascarador.

**Achado para o SPECIFY:** contrato mínimo da 012 = `--help` exit 0 com painel Rich,
`--version` exit 0 imprimindo a versão do pacote, opção inválida exit 2 com mensagem
em stderr. Números exatos de bytes do help **não** são contrato (largura de terminal
varia) — o contrato é presença de marcadores + códigos.

## Q5 — Entry point: forma canônica de expor `fkx`?

**Fonte (P1, via Context7):** tutorial oficial Typer "Configure pyproject.toml for CLI"
(`https://typer.tiangolo.com/tutorial/package`) — fetch 2026-09-05:

```toml
[project.scripts]
rick-portal-gun = "rick_portal_gun.main:app"
```

**Fonte (P1, via Context7):** tutorial `--version` — callback com `raise typer.Exit()`
(padrão com e sem `Annotated`) — fetch 2026-09-05.

**Fonte (P0, repo):** `packages/core/pyproject.toml` usa `hatchling` +
`[tool.hatch.build.targets.wheel] packages = ["src/fkx_core"]` (layout `src/`) —
fetch 2026-09-05. A 012 espelha com `src/fkx_cli` + `[project.scripts] fkx = "fkx_cli.main:app"`.

**Achado:** entry point = `[project.scripts]` (standard packaging, P2 estável) +
objeto `app: typer.Typer` em `fkx_cli/main.py`. `--version` via callback + `typer.Exit`
(padrão oficial, não invenção). `py.typed` desde o esqueleto (lição ADR-024 — sem ele
o pacote instalado é opaco ao mypy).

## Q6 — Rich na CLI: Console/print, markup?

**Fonte (P1, via Context7):** `console.print(...)` com `markup`/`style`, `rich.markup.escape`
para strings dinâmicas (não injetar dado cru em markup) — fetch 2026-09-05.

**Fonte (P0, executada):** probe com rich instalado renderiza painel `╭─ Options ─╮`
automaticamente (`rich_markup_mode="rich"` é default quando rich presente — assinatura
de `typer.Typer` conferida via `help()` executado) — fetch 2026-09-05.

**Achado:** 012 usa Rich para saída (help rico é automático com rich instalado);
texto dinâmico (ex.: versão, mensagens com dado de ambiente) passa por `escape`
quando interpolado em markup. `pretty_exceptions_show_locals` permanece `False`
(default — dado delicado nunca em trace rico; converge com Lei Zero).

## Q7 — Layout UV + dependência de `fkx-core`?

**Fonte (P0, repo):** raiz `pyproject.toml` (`members = ["packages/*"]`,
`[tool.uv] package = false`), CI com `uv sync --frozen --all-packages` (6 jobs),
`packages/core` membro com `dependencies = ["pydantic==2.13.5", ...]` — fetch 2026-09-05.

**Fonte (P0, repo):** superfície importável da 011 em
`packages/core/src/fkx_core/__init__.py` (`Settings`, `load_settings`, `KernelState`,
`FkxError` + 3, `EnvName`, `ErrorDetail`, `LogLevel`) — fetch 2026-09-05.

**Achado:** `packages/cli/pyproject.toml` (membro) + `src/fkx_cli/` (`main.py`,
`__init__.py`, `py.typed`); `dependencies = ["fkx-core", "typer==0.27.2",
"rich==15.0.0"]` (workspace resolve o membro; `uv.lock` fonte única — doutrina 010).
`--all-packages` já é o padrão de setup (ADR-023) — nenhum ajuste de CI por este motivo.
CLI **consome** `fkx_core` (ex.: settings/env para `--version` estendido futuro);
**não duplica** config/estado/modelos (princípio IV + Escada).

## Q8 — `mypy --strict` + `ruff` sobre código novo: algo especial?

**Fonte (P0, repo):** `[tool.mypy] strict = true`, `[tool.ruff]` + hook `lefthook.yml`
(`ruff check` + `format --check` + `mypy --strict` + `pytest` + `pip-audit`, sem
`--fix`) — fetch 2026-09-05. Lição ADR-024: `py.typed` vazio + `disallow_untyped_defs`
(toda função anotada, inclusive callbacks typer).

**Achado:** nada especial além de obedecer desde o esqueleto; fronteira inversa da
009 (código novo mantém ganchos verdes). Callbacks typer (`version_callback`) anotados
(`value: bool) -> None`).

## Q9 — Onde vivem os testes da 012?

**Fonte (P0, repo):** `[tool.pytest.ini_options] testpaths = ["tests"]`,
`tests/` com `test_fkx_core_*.py` + `conftest.py` mínimo — fetch 2026-09-05.

**Achado:** `tests/test_fkx_cli_*.py` (config existente; sem `packages/cli/tests/` —
mesma razão da 011/Q7: reconfigurar `testpaths`+coverage seria mudança de contrato
da 005 sem ganho). CLI testada via `typer.testing.CliRunner` (runner oficial —
forma canônica de invocar sem subprocesso; a decidir no SPECIFY/PLAN com prova
executada no PLAN, não aqui).

## Q10 — Fronteira: o que reprova hoje se `packages/cli/` existir?

**Fonte (P0, repo — levantamento mecânico `grep -n "packages" scripts/verify/f0-00*.sh`):**
— fetch 2026-09-05:

| Oráculo | Asserção | Forma exata hoje |
|---|---|---|
| `f0-004` | FR-012 | admite `packages/` **só** com `core/pyproject.toml` de membro (ADR-023); `EXTRA_PKG = ls packages \| grep -v -x core` não-vazio reprova |
| `f0-005` | FR-015 | idem (`grep -v -x "core"`) |
| `f0-006` | FR-014 | idem |
| `f0-007` | FR-014 | idem |
| `f0-008` | FR-013 | idem |
| `f0-011` | FR-002 | `if [ -d packages/cli ]; then FR2_OK=0` ("deve ser 012") |

`f0-009`/`f0-010` não mencionam `packages/`/`typer`/`cli` (grep vazio — sem conflito).
`lefthook.yml`, `ci.yml`, `.env.example`, `testpaths` **não** precisam mudar pela 012
(nenhuma ferramenta nova além das deps do pacote; nenhuma var nova; nenhum job novo).

**Achado:** conflito previsto e legítimo em **6 pontos** (forma `EXTRA_PKG` + 1 ponto
011). Procedimento ADR-017 (6ª execução): PLAN declara → ADR prévia autoriza →
só a Fase C aplica → manifest cita. Legitimidade via `uv.lock` (padrão ADR-018:
`typer`/`rich`/`fkx-cli` em `uv.lock`, nunca nome estático). Lição da 010 (ADR-022):
a tabela acima varreu **assertions literais**, não só arquivos.

## Decisões (insumo ao SPECIFY/CLARIFY — nada aqui é norma)

- **D1.** Pins: `typer==0.27.2` + `rich==15.0.0` como **runtime** de `packages/cli`
  (pacote publicado precisa ser funcional; 013 não herdará correção — mesmo
  fundamento da 011/D1). `click` ausente por desenho (Q3).
- **D2.** Superfície mínima: `fkx --help` + `fkx --version` (+ códigos 0/0/2); objeto
  `app` em `fkx_cli/main.py`; entry point `[project.scripts] fkx`.
- **D3.** CLI consome `fkx_core` (dependência de membro `fkx-core`); sem duplicar
  tipos; erros de domínio viram saída nomeada + exit code (detalhe ao SPECIFY;
  contrato pleno de saída é 4.11 — aqui só o mínimo 0.7).
- **D4.** Sem subcomandos de domínio nesta spec (Escada): `init/dev/interview/spec/
  run/...` são Fase 1+ com consumidor real; antecipá-los viola IV.
- **D5.** Layout `src/fkx_cli/` + `py.typed` desde o esqueleto (ADR-024); testes em
  `tests/test_fkx_cli_*.py` via `CliRunner`.
- **D6.** Rich para saída; `escape` em dado dinâmico; `pretty_exceptions_show_locals`
  `False`; segredo nunca interpolado (Lei Zero — espelho 011/Q10).
- **D7.** Fronteira Q10 (6 pontos; `EXTRA_PKG` passa a admitir `core` + `cli` com
  `pyproject.toml` de membro; resto proibido).

## Declaração de impacto de fronteira (insumo ao PLAN — ADR-017)

012 cria `packages/cli/` pela primeira vez: 6 asserções (tabela Q10) asserem sua
**ausência** — conflito previsto e legítimo (a existência do diretório é o objeto
da spec). Forma do ajuste (padrão ADR-018/023, só na Fase C, via ADR prévia se o
vermelho confirmar): admitir `packages/cli/` com `pyproject.toml` de membro
(jurisdição da 012), mantendo a proibição a qualquer outro conteúdo; `f0-011` FR-002
passa a admitir `cli/` (sua guarda cumpriu o papel). Nenhum outro oráculo é tocado;
`ci.yml`/`lefthook.yml`/lock-legitimidade seguem ADR-023/018 sem ajuste. Se a
implementação descobrir necessidade além destes 6 pontos, volta ao PLAN + ADR prévia.

## Out of Scope (Escada)

Subcomandos de domínio (`init`, `dev`, `interview`, `spec`, `run`, `audit`, `status`,
`config`, `doctor`, `benchmark`, `guardian` — §15 lista o destino final, 012 entrega
só o entry point) · TUI `textual` (Fase 4) · `docker-compose*`/Dockerfile (015) ·
`.env` real ou segredo (Lei Zero) · grafo compilado, agentes, tools (Fase 2) ·
`docs/tree.md` (016) · release/publish (013) · matriz de verificação provado-vs-declarado
(roteamento ADR-025 — item DevOps/Fase 2, sem instrumento antecipado).
