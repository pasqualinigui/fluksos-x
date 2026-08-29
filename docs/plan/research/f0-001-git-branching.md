# RESEARCH — F0/001 · Git init + Branching Strategy

> **Item do plano:** 0.9 (§17 Fase 0) · **Ordem de execução:** 001/012
> **Data da verificação:** 2026-08-29 · **Executado por:** Claude Code (papel: Pesquisador)
> **Método:** consulta direta a fontes canônicas. Nenhum dado por memória.

## Q1 — Qual a versão vigente da spec Conventional Commits?

```
$ curl -s https://www.conventionalcommits.org/en/v1.0.0/ ; echo $?
HTTP 200 · marcador "v1.0.0" presente
$ curl -s https://registry.npmjs.org/@commitlint/config-conventional/latest
config-conventional 21.2.2
$ curl -s https://registry.npmjs.org/conventional-commit-types/latest
conventional-commit-types 3.0.0
```

**Achado:** Conventional Commits **1.0.0** é a spec estável e vigente. O ecossistema
de tooling (commitlint 21.2.2) permanece alinhado a ela.

**Decisão:** o §18 do plano define o set normativo do projeto —
`feat, fix, docs, test, refactor, ci, chore`. O set canônico acrescenta
`perf, build, style, revert`. Adotamos o **superset** (11 tipos), pois `perf:` e
`build:` são necessários para o `python-semantic-release` classificar releases
corretamente (addendum R2 exige CHANGELOG automático a partir dos commits).
Formato: `<tipo>(<escopo>)!: <descrição>` + footer `BREAKING CHANGE:`.

## Q2 — `git init` cria `main` ou `master` nesta máquina?

```
$ git config --get init.defaultBranch
(vazio — não configurado)
$ git --version
git version 2.55.0
```

**Achado:** sem `init.defaultBranch`, o git 2.55 cria **`master`** e emite hint.
O §18 do plano exige **`main`**.

**Decisão:** usar `git init -b main` (explícito, não depende de config global do
usuário) **e** fixar `init.defaultBranch=main` na config *local* do repo. Não
alterar a config global da máquina.

## Q3 — `uv.lock` entra no controle de versão?

```
$ curl -s https://raw.githubusercontent.com/github/gitignore/main/Python.gitignore
linha 99: "# Similar to Pipfile.lock, it is generally recommended to include
           uv.lock in version control."
linha 102: "# uv.lock"   <- comentada por padrão no template
```

**Achado:** a recomendação canônica é **commitar** `uv.lock`.

**Decisão:** `uv.lock` é **commitado** — obrigatório. Reforça o item 10 do
checklist de segurança do addendum (§9): hash-pinning no lockfile = supply chain
security. O `.gitignore` do projeto NÃO deve ignorá-lo.

## Q4 — O que o `.gitignore` precisa cobrir?

Base canônica: `github/gitignore/Python.gitignore` (220 linhas). Entradas
relevantes já cobertas por ela:

| Padrão | Linha | Motivo |
|---|---|---|
| `__pycache__/` | 2 | bytecode |
| `htmlcov/`, `.coverage*` | 40,43,44 | pytest-cov (item 0.4) |
| `.pytest_cache/` | 52 | pytest (item 0.4) |
| `.env`, `.envrc` | 153,154 | **secrets — Lei Zero** |
| `.venv`, `venv/` | 155,157 | UV cria `.venv` (§3 do plano) |
| `.mypy_cache/` | 173 | MyPy (item 0.3) |
| `.ruff_cache/` | 209 | Ruff (item 0.2) |

**Adições específicas do fluksos-x (não presentes no template):**
- `.fluksos-x/sessions/` — histórico efêmero (§8 do plano; regra "Deliverables vs
  Intermediates" herdada do AGENTS-EXAMPLE.md)
- `.fluksos-x/reports/` — relatórios regeneráveis
- `.tmp/` — workbench intermediário
- `*.lance/`, `vectors.lance/` — LanceDB local (fase 3)
- `.specify/feature.json` — **já coberto** por `.specify/.gitignore` próprio; não duplicar

**Anti-entrada (não ignorar):** `uv.lock` (ver Q3).

## Q5 — Enforcement de Conventional Commits já é possível neste item?

```
$ command -v gitleaks  -> AUSENTE
$ command -v lefthook  -> AUSENTE
```

**Achado:** Lefthook é o item **0.5** (8º da fila); gitleaks entra com ele. Um
hook `commit-msg` nativo em `.git/hooks/` **não é versionável** e seria perdido
em clone — logo, não é determinístico.

**Decisão:** este item **define e documenta** a convenção (normativa, no
`CONTRIBUTING`/constitution) mas **não implementa enforcement**. O enforcement é
contrato entregue ao item 0.5 (Lefthook), que fará `commit-msg` versionado.
Registrado como dependência de saída na seção "Contratos" da spec.

## Estado do ambiente no momento desta pesquisa

| Ferramenta | Versão | Nota |
|---|---|---|
| git | 2.55.0 | ✅ |
| Python | 3.12.3 | ✅ dentro de `>=3.12,<3.14` |
| uv | 0.12.1 | ⚠️ plano pina 0.12.7 → tratado no item 003 (0.1) |
| specify | 1.0.1 | ✅ integration=claude |
| docker daemon | parado | manual por design — ver item 011 (0.8) |

## Contratos expostos para itens seguintes

| Consumidor | O que recebe deste item |
|---|---|
| **todos** | repo git em `main`, branch `develop`, convenção de commit normativa |
| 003 (0.1 UV) | `.gitignore` já ignorando `.venv/`; `uv.lock` explicitamente NÃO ignorado |
| 005/006/007 (Ruff/MyPy/pytest) | `.gitignore` já ignorando `.ruff_cache/`, `.mypy_cache/`, `.pytest_cache/`, `.coverage*` |
| 008 (0.5 Lefthook) | **dívida transferida:** implementar `commit-msg` versionado validando os 11 tipos |
| 012 (0.10 tree.md) | estratégia de branch a documentar |
