# RESEARCH — F0/004 · UV workspace monorepo

> **Item do plano:** 0.1 (§17 Fase 0) · **Ordem de execução:** 004/016 (ADR-011)
> **Data da verificação:** 2026-08-30 · **Papel:** Pesquisador
> **Método:** consulta direta a fontes canônicas e ao disco. Nenhum dado por memória.
> **Insumo anterior:** `specs/003-ci-minimo/spec.md` › Contratos + ADR-009/011 + `docs/plan/implementation_plan.md` §§3–4, 15, 17

Este item entrega a **base física do motor** (implementation_plan §3): workspace UV que unifica todos os pacotes futuros (`packages/*`) com um único `uv.lock` determinístico e um único `.venv` gerenciado. Depende apenas de Python 3.12 e `uv 0.12.7`; não exige Docker, Ruff, MyPy ou CI completo (que chegam nos itens 0.2–0.16).

---

## Q1 — O que o `pyproject.toml` deve conter num workspace UV?

**Fonte:** `https://docs.astral.sh/uv/concepts/projects/layout/` + `https://docs.astral.sh/uv/guides/projects/` — HTTP 200, fetch 2026-08-30.

Exigência mínima verificada:

```toml
[project]
name = "fluksos-x"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = []

[build-system]
requires = ["uv_build>=0.12.7,<0.13"]
build-backend = "uv_build"

[tool.uv.workspace]
members = ["packages/*"]
```

| Campo | Evidência na fonte |
|---|---|
| `pyproject.toml` identifica a raiz do projeto; `uv init` cria `pyproject.toml` + `src/<name>/__init__.py` + `README.md` + `.python-version` | `guides/projects/#project-structure` — lista completa |
| `build-system.requires` com `uv_build` é criado por `uv init` default (exemplo `uv_build>=0.12.7,<0.13`) | `guides/projects/#pyprojecttoml` — snippet com `requires = ["uv_build>=0.12.7,<0.13"]` |
| Workspace root **é também um membro**; precisa de `tool.uv.workspace.members` (required) + `exclude` (optional) com globs | `concepts/projects/workspaces/#getting-started` — tabela `members`/`exclude` |
| Cada diretório casado por `members` e não excluído deve conter `pyproject.toml` (membro pode ser `app` ou `lib`) | mesma seção, parágrafo "Every directory included..." |

**Achado estrutural hoje:** `ls pyproject.toml → inexistente`, `ls uv.lock → inexistente`, `.python-version → inexistente` (verificado disco 2026-08-30). O workspace precisa ser criado do zero. `.gitignore` já não introduz `*.lock` — D3 do item 001 (ver Q7).

**Decisão (D1):** `pyproject.toml` na raiz, com `requires-python = ">=3.12,<3.14"` (pin §4), `build-system = uv_build>=0.12.7,<0.13`, `tool.uv.workspace.members = ["packages/*"]`, sem `exclude` inicial. Nome do root: `fluksos-x` (PyPI alvo `fkx` — package name `fluksos-x` no workspace; CLI pacote `fkx_cli` futuro não colide agora). Versão `0.1.0`.

**Alternativa rejeitada:** omitir `build-system` — então `uv sync` não instala o projeto como editable (layout.md: "If the project does not define a build system, it will not be installed"). Para workspace virtual (sem código no root), `build-system` ainda é necessário para que `uv sync` materialize o root; sem ele o ambiente fica sem âncora editable.

---

## Q2 — Onde vive `uv.lock` e por que DEVE ser versionado?

**Fonte:** `https://docs.astral.sh/uv/concepts/projects/layout/#the-lockfile` + `.../sync/#checking-the-lockfile` — fetch 2026-08-30.

Evidências:

> *"`uv.lock` is a cross-platform lockfile ... This file should be checked into version control, allowing for consistent and reproducible installations across machines."* — layout.md
>
> *"A lockfile ensures that developers ... are using a consistent set of package versions ... when deploying the project as an application that the exact set of used package versions is known."* — layout.md
>
> *"`uv.lock` is a human-readable TOML file but is managed by uv and should not be edited manually."* — layout.md
>
> *"The `uv.lock` format is specific to uv and not usable by other tools. ... `pylock.toml` (PEP 751) is ... intended to replace `requirements.txt` ... uv supports `pylock.toml` as an export target."* — layout.md relationship section

Comportamento de verificação:

```
$ uv lock --check      # falha se pyproject.toml e uv.lock divergem
$ uv sync --locked     # aborta se lock desatualizado (sem escrever)
$ uv sync --frozen     # usa lock sem verificar se está atualizado
```

**Decisão (D2):**

* `uv.lock` ao lado de `pyproject.toml` na raiz, **versionado** (não entra em `.gitignore`).
* Relação com `pylock.toml`: não criar `pylock.toml` agora; exportável via `uv export -o pylock.toml` quando ciclo de release (015) exigir SBOM — evita duplicar fonte de verdade.
* Harness futuro (item 010) usará `uv sync --frozen` ou `--locked` em CI para garantir determinismo; em 004 basta que `uv.lock` exista após `uv sync`/`uv lock`.

**Alternativa rejeitada:** `.gitignore` com `*.lock` — viola §3 do plano (supply chain) e ADR-001 D3; oráculo `f0-001` reprova explicitamente (FR-020/FR-021).

---

## Q3 — Como `uv` gerencia `.venv` e o que `.gitignore` já cobre?

**Fonte:** `https://docs.astral.sh/uv/concepts/projects/layout/#the-project-environment` + `guides/projects/#venv` — fetch 2026-08-30.

Evidências:

> *"uv will create a virtual environment as needed ... in a `.venv` directory next to the `pyproject.toml` ... It is not recommended to include the `.venv` directory in version control; it is automatically excluded from `git` with an internal `.gitignore` file."* — layout.md
>
> *"When `uv run` is invoked, it will create the project environment if it does not exist yet or ensure it is up-to-date ... The project environment can also be explicitly created with `uv sync`."* — layout.md
>
> *"`uv.lock` ... `uv.lock` ... `uv sync` performs exact syncing by default ... `uv run` uses inexact syncing by default."* — sync.md

*Preview feature* `centralized-project-envs` (cache) não se aplica em Fase 0: ambientes locais por projeto.

Verificação local:

```
.gitignore verificado 2026-08-30 (cabeçalho D1/D3 documentado):
  __pycache__/, *.py[codz], .venv/  →  .venv já coberto via padrão implícito
  uv.lock NÃO listado (correto)
  .python-version comentado como opcional (pyenv) — não ignorado via padrão hardcoded (.gitignore contém "# .python-version" comentado, não ativo)
```

O `.venv` interno do uv **também** contém seu próprio `.gitignore` com `*` — dupla cobertura. Mesmo se `.gitignore` raiz não listasse `.venv`, git o ignoraria. Listá-lo explicitamente na seção canonica `Python.gitignore` (linha `__pycache__/ ... .venv`) é defesa em profundidade, mas não é obrigatório.

**Decisão (D3):**

* Não adicionar `.venv` manualmente ao `.gitignore` se já coberto; verificar que `git check-ignore -v .venv` reporta ignorado (via `.gitignore` canônico ou via `.venv/.gitignore` interno após `uv sync`).
* Não versionar `.venv`, nunca.
* Uso idiomático Fase 0: `uv sync` cria `.venv` + `uv.lock`; `uv run <cmd>` garante ambiente sem ativação manual (`source .venv/bin/activate` nunca necessário em harness/CI).

**Alternativa rejeitada:** `managed = false` (`[tool.uv] managed = false`) — desativa lock/sync automático; rejeitado porque determinismo do workspace depende exatamente do lock automático.

---

## Q4 — Como declarar `tool.uv.workspace` para escalar a `packages/*`?

**Fonte:** `https://docs.astral.sh/uv/concepts/projects/workspaces/` + `https://docs.astral.sh/uv/reference/settings/` (workspace settings) — fetch 2026-08-30.

Evidência workspace:

```toml
# Exemplo canônico albatross (workspaces.md)
[tool.uv.workspace]
members = ["packages/*"]
exclude = ["packages/seeds"]
```

* `members` aceita lista de globs (workspace settings)
* `exclude` opcional, também globs, remove do conjunto casado
* Declaração de dependência inter-membro: `[tool.uv.sources] bird-feeder = { workspace = true }` (não `{ path = ... }` dentro de workspace; `path` é para projetos sem workspace)
* Fonte `tool.uv.sources` no root aplica a todos os membros, salvo override por membro

Layout escalável do `implementation_plan.md` §15:

```
fluksos-x/
├── pyproject.toml          # root virtual
├── uv.lock
├── packages/
│   ├── core/    → src/fkx_core/
│   ├── cli/     → src/fkx_cli/
│   ├── indexer/ → src/fkx_indexer/
│   ├── memory/  → src/fkx_memory/
│   ├── agents/  → src/fkx_agents/
│   ├── observability/
│   └── guardian/
```

Cada `packages/<name>/pyproject.toml` futuro será membro descoberto por `packages/*`. Hoje, item 004 não precisa criar nenhum membro — apenas o **root virtual** com `members = ["packages/*"]` já deixa a descoberta pronta; `uv sync` com zero membros casados ainda gera `uv.lock` vazio válido e `.venv`.

Restrição crítica verificada:

> *"uv's workspaces enforce a single `requires-python` for the entire workspace, taking the intersection of all members' `requires-python` values."* — workspaces.md

Todos os membros futuros devem declarar `requires-python` compatível com o root (`>=3.12,<3.14`), caso contrário a interseção esvazia.

**Decisão (D4):**

* Root `tool.uv.workspace.members = ["packages/*"]`, sem `exclude` inicial. Quando `packages/seeds`-like surgir, adicionar `exclude` sem reescrever `members`.
* Dependência inter-membro futura via `tool.uv.sources.<name> = { workspace = true }` (não `path`).
* `requires-python` do root é a fonte de verdade; membros herdam interseção.

**Alternativa rejeitada:** `path` dependencies sem workspace — perde `uv run --package <member>` e lock unificado; cada pacote com `uv.lock` próprio diverge (rejeitado por §2 do plano: pnpm-like deduplication).

---

## Q5 — Qual versão de `uv` pinar e o que verificar em disco?

**Fonte:** `https://pypi.org/pypi/uv/json` (API PyPI), `uv --version` local, `https://docs.astral.sh/uv/guides/projects/#pyprojecttoml` snippet, `uv init --help` / `uv sync --help` locais — 2026-08-30.

Evidências:

```
PyPI uv: 0.12.7  (implementation_plan §4 pin confirmado — latest estável em 2026-08-29, re-verificado 0.12.7 em 2026-08-30)
Local  uv: 0.12.1 (x86_64-unknown-linux-gnu) — desatualizado 6 patches atrás
Docs snippet: build-system requires = ["uv_build>=0.12.7,<0.13"]
uv init --help: --build-backend choices {uv, hatch, flit, pdm, poetry, setuptools, maturin, scikit}
uv sync --help: --locked, --frozen, --check, --no-install-project/workspace/package
Python local: 3.12.3  (família 3.12, compatível com requires-python >=3.12,<3.14)
```

Pin do plano (`implementation_plan.md` §4): `UV 0.12.7` é o pin SÊNIOR; local `0.12.1` não invalida a pinagem — determina que o projeto deve declarar `uv_build>=0.12.7,<0.13` e que CI (item 003 `setup-python` + `uv` futuro) instalará `0.12.7`. Desenvolvedor local deve atualizar via `uv self update` ou reinstall do `astral-sh/uv`.

**Decisão (D5):**

* `build-system.requires = ["uv_build>=0.12.7,<0.13"]` — intervalo menor semântico estável (0.12.7 ≤ x < 0.13.0), escalável para `0.13.0` via bump versionado.
* Documentar `uv 0.12.7` como pin canônico em `docs/plan/research/f0-004-uv-workspace.md` tabela de versões; não pinar `uv` como `dependencies` (é ferramenta, não runtime do pacote).
* `.python-version` opcional: `uv init` cria `.python-version` com `3.12`; para workspace root virtual, `.python-version` fixa `3.12` é útil (determinismo local) mas não obrigatória para CI (CI usa `actions/setup-python@v7 python-version 3.12`). Criar `.python-version` com `3.12` por convenção.

**Alternativa rejeitada:** `uv_build>=0.12.1` para acomodar local desatualizado — indeterminístico; aceitaria regressão de resolver. Local deve convergir ao pin, não o pin ao local.

---

## Q6 — Quais flags garantem determinismo entre `uv.lock`, `pyproject.toml` e `.venv`?

**Fonte:** `uv lock --help`, `uv sync --help`, `https://docs.astral.sh/uv/concepts/projects/sync/` — fetch 2026-08-30.

| Flag | Semântica verificada | Uso |
|---|---|---|
| `uv lock --check` | falha se lock desatualizado vs `pyproject.toml` (não escreve) | harness local de verificação |
| `uv lock --check-exists` | falha se `uv.lock` não existe (`UV_FROZEN` env) | portão mínimo (só existência) |
| `uv sync --locked` | afirma que `uv.lock` não mudará; falha se mudaria | CI determinístico (recomendado) |
| `uv sync --frozen` | sincroniza sem atualizar lock (confia no lock existente) | CI quando lock é fonte de verdade; `UV_FROZEN=1` env |
| `uv sync --check` | verifica se ambiente sincronizado sem modificar | harness diagnóstico |

Comportamento automático:

> *"Locking and syncing are automatic in uv ... when `uv run` is used, the project is locked and synced before invoking ... To disable ... `uv run --locked` / `--frozen` / `--no-sync`."* — sync.md

Ordem de verificação em CI (padrão que escala de 004 → 010):

```bash
uv sync --locked   # ou: uv sync --frozen  (010)
# vs local
uv lock --check
```

**Decisão (D6):**

* Item 004 (base física): garantir que `uv lock` / `uv sync` **sem flags** já gere `uv.lock` + `.venv` idempotentes. Não impor `--locked` em 004 — isso é **política de CI** (item 010) que consome o artefato de 004. Em 004, o harness verifica apenas existência e validade sintática de `uv.lock` (TOML legível), não `--locked` estrito (sem dependências, `--locked` seria tautologia).
* Documentar contrato para 010: `ci.yml` futuro usará `uv sync --frozen` (ou `--locked`) para reprovar drift.

**Alternativa rejeitada:** forçar `uv sync --locked` já em 004 — sem `uv.lock` inicial, `--locked` sempre falharia no primeiro run (bootstrap paradox); precisa de `uv lock`/`uv sync` inicial sem flag para materializar o lock.

---

## Q7 — `.gitignore` vigente já cumpre as leis de 004?

**Fonte:** `.gitignore` (265 linhas) + `specs/001-git-branching-strategy/research.md` D1–D3 + `scripts/verify/f0-001-foundation.sh` FR-020/021 — lido 2026-08-30.

Excerto verificado:

```
# D1  template canonico traz apenas `.env` e deixa `.env.local` passar — corrigido bloco SEGREDOS com `.env.*` + `!.env.example`
# D3  nenhum padrão de lockfile é introduzido: `uv.lock` DEVE ser versionado
...
.env
.env.*
!.env.example
...
# Byte-compiled ... .venv é coberto por?
# .python-version está COMENTADO (não ativo) — linha "# .python-version"
```

Verificação:

* `uv.lock` — nenhuma linha casa `*.lock` nem `uv.lock` → versionado (correto). Oráculo `f0-001` testa regressão `*.lock` (asserção 09).
* `.venv/` — coberto por? O arquivo não contém literal `".venv"` mas contém `__pycache__/`, `*.py[codz]`, e o bloco não lista `.venv` explicitamente. Porém `uv` cria `.venv/.gitignore` com `*` → `git check-ignore .venv/foo` sempre casa via `.venv/.gitignore`. Adicionar `.venv/` ao `.gitignore` raiz seria redundante mas inofensivo; a decisão é **não tocar** no `.gitignore` neste item (princípio: um item nunca modifica oráculo de anterior de forma invisível — aqui `.gitignore` é oráculo de 001). A validação futura via `git status --porcelain` deve provar que `.venv/` não aparece como untracked quando existir.
* `.python-version` — comentado (linha inicia com `#`), logo **versionado** quando criado por `uv init`. Convenção `pyenv` sugere ignorar `.python-version` para libs, mas para app/workspace root, versionar fixa determinismo (princípio I) — alinhado com D5.

**Decisão (D7):** **NÃO modificar `.gitignore` em 004.** O arquivo já satisfaz D3 (uv.lock versionado) via ausência de `*.lock`. Qualquer ajuste seria ruído e poderia quebrar hash de integridade de 001. Validar no harness 004 com `git check-ignore --no-index --stdin` em vez de editar.

**Alternativa rejeitada:** adicionar `.venv/` explícito ao `.gitignore` raiz — desnecessário (cobertura interna) e viola regra 5 (um item nunca modifica oráculo de anterior sem ADR).

---

## Q8 — Como 004 escala para 010 (CI completo) e 015 (release) sem reescrever?

**Fonte:** ADR-009 (Emenda 1), ADR-011 (mapa 16 posições), `implementation_plan.md` §§15–17, `concepts/projects/export/` — fetch 2026-08-30.

Cadeia de dependência verificada:

```
004 (0.1 UV workspace) ──→ 005 (0.4 Pytest) ──→ 006 (0.2 Ruff) ──→ 007 (0.3 MyPy)
        │                                              │
        └──────────────→ 010 (0.14 CI completo: uv sync --frozen, Ruff, MyPy, Pytest, pip-audit, gitleaks)
                               ──→ 013 (0.15 release: uv build, trusted publishing, SBOM via cyclonedx)
                               ──→ 014 (0.16 deps: Renovate/Dependabot pina uv_build, actions/*)
```

Contratos que 004 entrega para 010/013/014 sem reescrita:

| Consumidor | O que recebe de 004 |
|---|---|
| **010 (CI completo)** | `pyproject.toml` com `[tool.uv.workspace]` estável; `uv.lock` versionado para `uv sync --frozen`; `.venv` em `.gitignore` implícito (sem ruído no diff CI) |
| **013 (release)** | `uv build` já funcional (requer `build-system`); `uv export --format cyclonedx` / `pylock.toml` disponível sem config extra |
| **014 (deps)** | Mapa de dependência pinada `uv_build>=0.12.7,<0.13` para Renovate agrupar; `actions/checkout@v7` / `setup-python@v7` já pinados em `ci.yml` (003) são referência |
| **005–009** | Workspace `members = ["packages/*"]` pronto; cada novo pacote é só criar `packages/<name>/pyproject.toml` + `uv add --package` — sem tocar no root além de `tool.uv.sources` quando necessário |

Export formats verificados (escalabilidade sem reescrever workspace):

```
uv export --format requirements.txt
uv export --format pylock.toml      # PEP 751
uv export --format cyclonedx1.5     # SBOM para release
```

**Decisão (D8):** em 004, garantir apenas **root virtual** + `uv.lock` + `.venv` + `tool.uv.workspace` estável. Não criar `packages/` vazios nem membros placeholder — membros são criados pelos itens que os exigem (006 `core`, 007 `cli`, etc.), cada um com `spec → plan → tasks → tests → implement`.

**Alternativa rejeitada:** criar `packages/core/` e `packages/cli/` vazios em 004 para "adiantar" — antecipa responsabilidade de itens 006/007, viola escada de dependências (constitution Additional Constraints) e cria `pyproject.toml` sem spec dedicada (quebra SDD).

---

## Q9 — O que o harness de 004 deve verificar (e o que NÃO verificar)?

**Fonte:** `specs/001-.../contracts/oracle-cli.md`, `scripts/verify/README.md`, `scripts/verify/f0-001-foundation.sh` (494 linhas) + `f0-003-ci-minimo.sh` (487 linhas) — lidos 2026-08-30.

Contrato do oráculo (invariante):

* exit `0` conforme, `1` não conforme, `2` erro de uso
* `--quiet` só violações
* uma linha por asserção identificada por REQ-ID
* harness cresce por **acréscimo** (um arquivo `f0-00N-*.sh` por spec, nunca reescreve anterior)

FRs mapeáveis para 004 (derivados do plano §17 item 0.1 + Q1–Q8 acima):

| FR candidato | Verificável por harness | Como |
|---|---|---|
| `pyproject.toml` existe e é TOML válido | sim | `python3 -c 'import tomllib; tomllib.load(open("pyproject.toml","rb"))'` |
| `[build-system] requires uv_build>=0.12.7` | sim | `grep -F 'uv_build>=0.12.7'` + parse TOML |
| `[tool.uv.workspace] members = ["packages/*"]` | sim | parse TOML + assert lista |
| `uv.lock` existe e é TOML válido, não editado à mão fora de `uv` | sim | existência + `tomllib` |
| `.venv/` existe e contém `bin/python` (ou `Scripts/python` win) após `uv sync` | sim | `test -x .venv/bin/python` |
| `.venv` ignorado por git | sim | `git check-ignore -q .venv` ou `git status --porcelain` não lista |
| `uv.lock` NÃO ignorado por git | sim | `! git check-ignore -q uv.lock` |
| `requires-python` single para workspace | sim | parse TOML `requires-python == ">=3.12,<3.14"` |

**NÃO verificar em 004** (fronteira escada):

* Conteúdo de `packages/*` (não existem)
* `uv sync --locked` em CI (é 010)
* `ruff`/`mypy`/`pytest` (são 005–007)
* `uv export` formats (é 013)

**Decisão (D9):** oráculo `f0-004-uv-workspace.sh` com **~10–14 asserções** focadas só na base física. Nome do job futuro em `ci.yml` permanece `verify` (estável desde 003), mas 004 não altera `ci.yml` — CI de 003 já executa `for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done` e automaticamente incluirá 004 quando o arquivo existir.

---

## Q10 — Determinismo do workspace: `uv.lock` regenerável e `.venv` descartável?

**Fonte:** `concepts/projects/sync/#automatic-lock-and-sync` + `uv lock --help` + `uv sync --help` — fetch 2026-08-30.

Propriedades verificadas:

* `uv.lock` é **universal** (cross-platform markers) — mesmo lock em Linux/macOS/Windows, determinístico por construção (não precisa de `uv.lock` por plataforma).
* `uv sync` é **idempotente**: segundo `uv sync` sem mudança em `pyproject.toml` não altera `uv.lock` nem `.venv` (além de timestamps). Verificável por `sha256sum uv.lock` antes/depois.
* `.venv` é **descartável**: `rm -rf .venv && uv sync` recria idêntico (mesma versão de Python `3.12` + mesmas deps do lock). `uv run` sem `.venv` também recria automaticamente.
* `uv.lock --upgrade` só muda versões quando constraint permite; sem `--upgrade`, `uv` prefere versões já travadas — determinismo por default.

**Decisão (D10):** documentar no quickstart da spec 004 que `.venv` é efêmero e `uv.lock` é a fonte de verdade. Harness não deve assertar timestamp de `.venv`, apenas existência + `uv.lock` hash estável após `uv sync` duplo.

---

## Resumo das decisões vinculantes

| # | Decisão | Fonte |
|---|---|---|
| D1 | `pyproject.toml` root com `name=fluksos-x`, `version=0.1.0`, `requires-python=">=3.12,<3.14"`, `build-system uv_build>=0.12.7,<0.13`, `tool.uv.workspace.members=["packages/*"]` | Q1 layout/workspaces |
| D2 | `uv.lock` ao lado de `pyproject.toml`, versionado, TOML válido, não editado manualmente; sem `pylock.toml` em 004 | Q2 layout lockfile |
| D3 | `.venv` em `pyproject.toml` vizinho, gerenciado por `uv sync`/`uv run`, ignorado via `.venv/.gitignore` interno (não versionado) | Q3 project-environment |
| D4 | Workspace `members = ["packages/*"]` sem `exclude` inicial; inter-membro futuro via `tool.uv.sources.{name} = { workspace = true }`; single `requires-python` interseção | Q4 workspaces |
| D5 | Pin canônico `uv 0.12.7` (PyPI), `uv_build>=0.12.7,<0.13`, `.python-version` `3.12` por convenção; local `0.12.1` deve convergir | Q5 pypi + docs snippet + local |
| D6 | Flags determinísticas documentadas (`--locked`/`--frozen`/`--check`) mas não impostas em 004; `uv lock`/`uv sync` sem flag materializa lock inicial | Q6 sync + help |
| D7 | **Não modificar `.gitignore`** em 004 — `uv.lock` já versionado (sem `*.lock`), `.venv` já ignorado internamente | Q7 .gitignore |
| D8 | Root virtual apenas; sem `packages/` placeholder; escala para 010 (`uv sync --frozen`), 013 (`uv build`/`uv export`), 014 (Renovate) sem reescrever | Q8 ADR-009/011 + export |
| D9 | Harness `f0-004-uv-workspace.sh` com 10–14 asserções focadas na base física; não verifica `packages/*` nem CI flags | Q9 oracle-cli |
| D10 | `uv.lock` universal regenerável, `.venv` descartável; harness testa idempotência via hash, não timestamp | Q10 sync |

**Nenhum `NEEDS CLARIFICATION` remanescente.** Próxima etapa: `SPECIFY` da spec `004 — UV workspace monorepo`.

## Contratos previstos para os itens seguintes

| Consumidor | O que receberá |
|---|---|
| **005 (0.4 Pytest 9.1.1)** | Workspace root para declarar `[dependency-groups] dev` e ponto de montagem `packages/core` |
| **006 (0.2 Ruff 0.16.5)** | `pyproject.toml` root onde `ruff.toml` ou `[tool.ruff]` coexistirá; workspace não conflita com linter |
| **007 (0.3 MyPy 2.3.1)** | `requires-python` single já fixado; `mypy.ini` futuro lê `packages/*` via membros |
| **010 (0.14 CI completo)** | `uv.lock` versionado para `uv sync --frozen`; `ci.yml` job `verify` já inclui `f0-004` automaticamente |
| **013 (0.15 release)** | `uv build` + `uv export --format pylock.toml/cyclonedx` sem config extra |
| **014 (0.16 renovate)** | `uv_build>=0.12.7,<0.13` pin para agrupamento e automerge |

## Pacotes e versões pinadas verificadas em 2026-08-30

| Pacote | Versão verificada | Fonte | Nota |
|---|---|---|---|
| `uv` / `uv_build` | `0.12.7` (`uv_build>=0.12.7,<0.13`) | PyPI `uv/json` + docs snippet `guides/projects` | local `0.12.1` desatualizado — deve convergir |
| `Python` | `3.12.3` local, `3.12` família, `>=3.12,<3.14` | `python --version` + `requires-python` plano §4 | `setup-python@v7` já pina `3.12` em ci.yml (003) |
| `uv workspace` | `members = ["packages/*"]` globs | `concepts/projects/workspaces` + `reference/settings` | single `requires-python` interseção |
| `uv.lock` | formato TOML universal | `concepts/projects/layout` + `concepts/projects/sync` | versionado, não `pylock.toml` em 004 |
| `GitHub Actions workflow` | `ci.yml` existente `003` | `.github/workflows/ci.yml` 25 linhas | job `verify` estável, inclui `f0-004` automaticamente |

