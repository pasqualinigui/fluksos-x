# Quickstart: Automação de release

## Validação completa

```bash
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done
sha256sum -c scripts/verify/manifest.sha256
```

## Cenário 1 — Versão derivada

```bash
uv run semantic-release version --print       # imprime X.Y.Z derivado
```

## Cenário 2 — Publicação sem credencial

```bash
grep -rni "sk-\|secret\|token\s*=" .github/workflows/release.yml  # zero ocorrências
```

## Cenário 3 — Metade servidora 🧑

Ver `checklists/server-side.md` para pending publishers + GitHub environment.
