# Quickstart: CI completo + branch protection — portão servidor

Validação fim-a-fim da 010. Cenários locais executáveis + 1 cenário humano (🧑) no servidor. Detalhes em `contracts/oracle-cli.md`, entidades em `data-model.md`.

## Pré-requisitos

Harness 9/9 + manifest 9/9 · `docs/plan/audit/f0-audit-005-008.md` presente · ADR-018 vigente (fronteira `.github/` = uso previsto da 010, não conflito).

## Cenário 1 — Workflow estendido e íntegro (SC-004, FR-001/002/003/004/005/010)

```bash
scripts/verify/f0-010-ci-completo.sh
# esperado: 13/13 (pós-verde); job verify presente; nenhum uses: sem SHA; matriz 3.12+3.13; timeout-minutes em todo job
```

## Cenário 2 — Cobertura como portão (SC-002, FR-006)

```bash
uv run pytest -q --cov --cov-fail-under=90
# esperado: 0 (medido 95%); simulação: --cov-fail-under=99 → ≠0 nomeando déficit
```

## Cenário 3 — Commitlint nos 11 tipos (SC-003, FR-007)

```bash
git log --format=%s | npx --yes @commitlint/cli@21.2.2 --from HEAD~20 --to HEAD --verbose
# esperado: 0 no histórico; 'wip stuff' sintético → ≠0 com regra nomeada
```

## Cenário 4 — Bypass morre no servidor 🧑 (SC-001, FR-008/009)

Humano no GitHub (checklist versionado em `docs/plan/`): proteção clássica em `main`+`develop` (checks frouxos obrigatórios + sem-bypass + sem-force), PR de teste com defeito trava até verde, push direto recusado. Evidência registrada na convergência; se pendente, divergência declarada (SC-005 honesto).

## Cenário 5 — Harness, manifest e inquebráveis (SC-004/005/006, FR-011/012/013)

```bash
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done  # 10/10
sha256sum -c scripts/verify/manifest.sha256                        # 10/10
grep -E "^- \[ \]" specs/010-ci-completo/tasks.md | wc -l          # 0
git log --oneline | grep -E "test\(harness\).*010|feat\(ci\).*010"
# esperado: vermelho em commit separado ANTES do verde
```

## Cenário 6 — Quarentena e fronteira (FR-010/FR-001)

```bash
grep -rn "continue-on-error" .github/workflows/ && echo "VIOLAÇÃO" || echo "sem mascara OK"
grep -q "verify:" .github/workflows/ci.yml && echo "job verify preservado OK"
```

## Validação completa em um comando

```bash
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done && sha256sum -c scripts/verify/manifest.sha256 && uv run pytest -q | tail -1
```

## Troubleshooting

- Runner sem Docker: jobs Trivy skip ⏭️ (padrão 008); pleno validado onde houver Docker.
- Check ambíguo no PR: nomes de job duplicados entre workflows — renomear (docs Q1).
- Proteção ainda não aplicada: convergência parcial declarada; oráculo não finge cobrir servidor.
- Histórico com mensagem inválida: validar intervalo do push/PR, nunca reescrever passado.
