# Quickstart: Lefthook — orquestração pre-commit do harness

Validação fim-a-fim da 009. Cada cenário cita SC/FR; detalhes de formato no `contracts/oracle-cli.md`, entidades em `data-model.md`.

## Pré-requisitos

`uv sync` verde · harness 8/8 verde · `docs/plan/audit/f0-audit-005-008.md` presente · ADR-018 registrada.

## Cenário 1 — Pre-commit barra violação nomeada (SC-001, FR-003/006)

```bash
# isca com violação ruff em cópia descartável (nunca no repo real):
uv run lefthook run pre-commit
# esperado: saída ≠ 0, job ruff nomeado; nenhum job posterior executa
uv run lefthook validate   # esperado: 0
```

## Cenário 2 — Pre-push espelha o harness (SC-001, FR-005)

```bash
uv run lefthook run pre-push
# esperado: 0 com harness 9/9; LEFTHOOK=0 lefthook run pre-push → ganchos ignorados (FR-008)
```

## Cenário 3 — Setup em clone limpo (SC-002, FR-007)

```bash
uv sync && uv run lefthook install && uv run lefthook validate && uv run lefthook check-install
# esperado: todos 0; min_version divergente recusa com erro de versão
```

## Cenário 4 — Trivy condicional (FR-004, precedente 008-FR-009)

```bash
# sem Docker: job trivy = skip documentado, hook verde; com Docker: trivy fs executa
```

## Cenário 5 — Harness, manifest e inquebráveis (SC-003/005/006, FR-013/014/015/016)

```bash
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done  # 9/9
sha256sum -c scripts/verify/manifest.sha256                        # 9/9
grep -E "^- \[ \]" specs/009-lefthook/tasks.md | wc -l              # 0
git log --oneline | grep -E "test\(harness\).*009|feat\(harness\).*009|lefthook"
# esperado: vermelho em commit separado ANTES do verde
```

## Cenário 6 — CI e fronteira (FR-009/011/012)

```bash
git diff --name-only HEAD | grep -q "^\.github/" && echo "VIOLAÇÃO FR-009" || echo "CI intocado OK"
grep -q "f0-audit-005-008" scripts/verify/f0-009-lefthook.sh && echo "cadência OK"
grep -q "ADR-018" specs/009-lefthook/plan.md && echo "fronteira OK"
```

## Validação completa em um comando

```bash
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done && sha256sum -c scripts/verify/manifest.sha256 && uv run pytest -q | tail -1
```

## Troubleshooting

- Hook não executa: `check-install` + `LEFTHOOK_VERBOSE=1`; ausência de binário global não é falha (usa `uv run`).
- `lefthook.yml` rejeitado: `dump` mostra o merge efetivo; `validate` aponta a chave.
- Vermelho herdado 004–008 após o verde: só é legítimo o pré-autorizado na ADR-018; qualquer outro é conflito e sobe para ADR, nunca para fix direto.
