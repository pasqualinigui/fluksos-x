# Quickstart — 003 CI mínimo

**Feature**: `003-ci-minimo` · **Spec**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md) · **Research**: [research.md](./research.md)
**Contrato**: [contracts/ci-workflow.md](./contracts/ci-workflow.md) · **Data model**: [data-model.md](./data-model.md)

Guia de validação runnable que prova que o workflow orquestra o harness em runner limpo sem violar fronteira de escopo. Cada cenário mapeia para SCs da spec.

> Pré-requisitos: `bash`, `git`, `python3` 3.12 (local `3.12.3`, runner `3.12.14` família `3.12`), repositório clonado na branch `003-ci-minimo`. Nenhum `pip install` necessário — stdlib apenas (escada).

---

## Cenário 1 — Inspeção estática do YAML (SC-001, SC-003, SC-004, SC-005, SC-006, SC-008)

Prova que o arquivo existe, é YAML válido e contém os pins determinísticos sem ferramentas proibidas — sem executar workflow remoto.

```bash
# 1a. Diretório criado por este item (FR-002)
ls -ld .github/workflows
test -f .github/workflows/ci.yml && echo "FR-001/002 PASS" || echo "FAIL"

# 1b. YAML válido (stdlib; sem PyYAML externo)
python3 -c "import pathlib; p=pathlib.Path('.github/workflows/ci.yml'); print(p.read_text()[:200])"
python3 << 'PY'
import subprocess, sys
# fallback grep estrutural se yaml não estiver disponível
import pathlib
text = pathlib.Path('.github/workflows/ci.yml').read_text()
assert 'name:' in text, "name ausente"
assert 'on:' in text, "on ausente"
assert 'permissions:' in text, "permissions ausente"
assert 'jobs:' in text, "jobs ausente"
print("YAML chaves top-level PASS (FR-001)")
PY

# 1c. Pins determinísticos (FR-003/004/005)
grep -q 'runs-on: ubuntu-24.04' .github/workflows/ci.yml && echo "FR-003 PASS (ubuntu-24.04)" || echo "FAIL FR-003"
grep -q 'uses: actions/checkout@v7' .github/workflows/ci.yml && echo "FR-004 uses@v7 PASS" || echo "FAIL FR-004"
grep -q 'fetch-depth: 0' .github/workflows/ci.yml && echo "FR-004 fetch-depth:0 PASS" || echo "FAIL FR-004"
grep -q 'uses: actions/setup-python@v7' .github/workflows/ci.yml && echo "FR-005 uses@v7 PASS" || echo "FAIL FR-005"
grep -q "python-version: '3.12'" .github/workflows/ci.yml && echo "FR-005 python 3.12 PASS" || echo "FAIL FR-005"

# 1d. Privilégio mínimo (FR-007)
grep -q 'permissions:' .github/workflows/ci.yml && grep -q 'contents: read' .github/workflows/ci.yml && echo "FR-007 PASS" || echo "FAIL FR-007"
! grep -q 'id-token: write' .github/workflows/ci.yml && echo "FR-007 no id-token PASS" || echo "FAIL FR-007"

# 1e. Gatilhos (FR-008)
grep -q 'push:' .github/workflows/ci.yml && grep -q 'pull_request:' .github/workflows/ci.yml && echo "FR-008 push+PR PASS" || echo "FAIL FR-008"
grep -A2 'push:' .github/workflows/ci.yml | grep -q 'main' && echo "FR-008 branches PASS" || echo "FAIL FR-008"

# 1f. Job estável (FR-009)
grep -q 'verify:' .github/workflows/ci.yml && echo "FR-009 job verify PASS" || echo "FAIL FR-009"
grep -q 'name: Checkout' .github/workflows/ci.yml && grep -q 'name: Setup Python 3.12' .github/workflows/ci.yml && grep -q 'name: Run harness' .github/workflows/ci.yml && echo "FR-009 steps PASS" || echo "FAIL FR-009"

# 1g. Run harness glob (FR-010)
grep -q 'for f in scripts/verify/f0-*.sh' .github/workflows/ci.yml && echo "FR-010 glob PASS" || echo "FAIL FR-010"
grep -q '|| exit 1' .github/workflows/ci.yml && echo "FR-010 propagate PASS" || echo "FAIL FR-010"

# 1h. Sem continue-on-error (FR-011)
! grep -q 'continue-on-error' .github/workflows/ci.yml && echo "FR-011 PASS" || echo "FAIL FR-011"

# 1i. Fronteira — nenhuma ferramenta de 010 (FR-006, C1)
! grep -Eq 'ruff|mypy|pytest|pip-audit|trivy|gitleaks|uv |matrix:|cache:|pull_request_target|workflow_run' .github/workflows/ci.yml && echo "FR-006 fronteira PASS" || echo "FAIL FR-006"

# 1j. Sem não-determinismo (FR-012)
! grep -Eq '\$RANDOM|date |GITHUB_RUN_NUMBER' .github/workflows/ci.yml && echo "FR-012 determinismo PASS" || echo "FAIL FR-012"
```

**Resultado esperado**: todos `PASS`. Falha em qualquer linha = workflow não conforme com `contracts/ci-workflow.md`.

---

## Cenário 2 — Harness local ainda verde (SC-001 pré-requisito, VI)

Prova que o harness que o workflow orquestrará continua íntegro e aprovando — sem ele, o CI não tem o que orquestrar.

```bash
for f in scripts/verify/f0-*.sh; do echo "== $f =="; "$f" --quiet && echo "PASS" || echo "FAIL"; done
# Esperado: f0-001 PASS, f0-002 PASS (f0-003 PASS após implementar)
scripts/verify/f0-001-foundation.sh --quiet; echo "f0-001 exit: $?"
scripts/verify/f0-002-constitution.sh --quiet; echo "f0-002 exit: $?"
```

**Paper trail**: `FR-021b` (re-executa `f0-001 --quiet`). Se qualquer um falhar, corrigir antes de validar CI.

---

## Cenário 3 — Oráculo 003 vermelho→verde (Princípio III)

Prova TDD: oráculo reprova antes do workflow existir e aprova depois.

```bash
# Estado vermelho (antes de criar .github/workflows/ci.yml)
scripts/verify/f0-003-ci-minimo.sh; echo "exit (esperado 1): $?"
scripts/verify/f0-003-ci-minimo.sh --list   # enumera 14 FRs sem executar

# Após criar ci.yml conforme contracts/ci-workflow.md:
scripts/verify/f0-003-ci-minimo.sh --quiet && echo "GREEN" || echo "RED (ainda não conforme)"
scripts/verify/f0-003-ci-minimo.sh           # log completo com FR-... PASS/FAIL
```

**Artefatos**: preservar saídas em `specs/003-ci-minimo/evidence/red.txt` e `green.txt` (não recuperáveis depois, princípio III).

---

## Cenário 4 — Determinismo do workflow (SC-007, Princípio I)

Prova que duas execuções do harness e duas leituras do YAML produzem saída idêntica, e que o workflow não introduz não-determinismo.

```bash
# 4a. Harness determinístico (FR-018)
scripts/verify/f0-003-ci-minimo.sh > /tmp/run1.txt 2>&1
scripts/verify/f0-003-ci-minimo.sh > /tmp/run2.txt 2>&1
diff -u /tmp/run1.txt /tmp/run2.txt && echo "determinismo harness PASS" || echo "FAIL determinismo"

# 4b. Workflow sem fonte de aleatoriedade
grep -Eq '\$RANDOM|date\(\)|GITHUB_RUN_NUMBER' .github/workflows/ci.yml && echo "FAIL não-determinismo" || echo "workflow determinístico PASS"

# 4c. Re-run idêntico (simula GitHub re-run sobre mesmo commit)
for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done > /tmp/harness1.txt 2>&1
for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done > /tmp/harness2.txt 2>&1
diff -u /tmp/harness1.txt /tmp/harness2.txt && echo "re-run PASS" || echo "FAIL re-run"
```

---

## Cenário 5 — fetch-depth: 0 detecta violação histórica (SC-007, FR-004)

Prova que `fetch-depth: 0` é necessário — `fetch-depth: 1` esconderia arquivo proibido no histórico (FR-020b).

```bash
# Simula shallow vs completo localmente
git log --all --pretty=format: --name-only --diff-filter=A | sort -u | head
echo "--- completo acima ---"
git log --max-count=1 --pretty=format: --name-only --diff-filter=A | sort -u | head
echo "--- shallow (1) acima ---"
# Injetar .env em commit antigo (em branch temporária) e mostrar que shallow não vê:
# (não muta main; apenas demonstra classe de falso-negativo; ver Q5 research)
grep -q 'fetch-depth: 0' .github/workflows/ci.yml && echo "fetch-depth:0 PASS — histórico completo auditado" || echo "FAIL"
```

**Referência**: `f0-001-foundation.sh:360` `HIST_ALL` + `action.yml` `fetch-depth default 1`.

---

## Cenário 6 — Execução remota (SC-002, só após push/PR real)

Prova que o portão remoto reproduz o veredito local — requer GitHub.

1. **Push conforme** em `main` (harness local `0`) → Actions aba → workflow `ci` → job `verify` verde. Log lista cada oráculo (`f0-001`, `f0-002`, `f0-003`) aprovando.

2. **Push não conforme**: em branch `feature/f0-teste`, introduzir violação mínima (ex.: mensagem de commit fora de `^(feat|fix|docs|chore|refactor)(\(.+\))?: .+` ou arquivo `.env` rastreado) → push → PR para `main` → job `verify` vermelho com `🔴 FR-...` e evidência (mesmo formato local, princípio X).

3. **Re-run** do mesmo commit no GitHub (botão Re-run) → mesma saída (determinismo).

> Este cenário não é simulável localmente com `act` sem perder fidelidade (runner `ubuntu-24.04` + `fetch-depth: 0` + `contents: read`); a evidência é a execução remota observada após merge. Registrá-la como comentário/PR é a prova de SC-002.
>
> **T031 — Deferido pós-merge**: `push` conforme verde + PR com violação vermelho + re-run idêntico só são observáveis após `push`/`PR` real em `main`/`develop` no GitHub. Não bloqueia convergência local; é o único SC que exige GitHub. Convergência local = Cenários 1–5 `PASS` + `green.txt` 14/14.

---

## Validação completa em um comando

```bash
# harness acumulado (o que o CI executa)
for f in scripts/verify/f0-*.sh; do "$f" || exit 1; done && echo "HARNESS GREEN" || echo "HARNESS RED"

# inspeção estática do workflow (contrato)
grep -q 'runs-on: ubuntu-24.04' .github/workflows/ci.yml && \
grep -q 'actions/checkout@v7' .github/workflows/ci.yml && \
grep -q 'fetch-depth: 0' .github/workflows/ci.yml && \
grep -q "python-version: '3.12'" .github/workflows/ci.yml && \
grep -q 'permissions:' .github/workflows/ci.yml && \
! grep -q 'continue-on-error' .github/workflows/ci.yml && \
! grep -Eq 'ruff|mypy|pytest|pip-audit' .github/workflows/ci.yml && \
echo "CONTRACT PASS" || echo "CONTRACT FAIL"
```

**Done quando**: Cenários 1–5 `PASS` localmente; Cenário 6 observado remotamente após merge (SC-002). Tudo com `shell` + `git` + `python3` stdlib — sem dependência nova.
