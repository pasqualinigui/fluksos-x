# Quickstart: Atualização automática de dependências

## Validação completa

```bash
for f in scripts/verify/f0-*.sh; do "$f" --quiet || exit 1; done
sha256sum -c scripts/verify/manifest.sha256
```

## Cenário 1 — Config do bot íntegra

```bash
grep -A3 'package-ecosystem: "uv"' .github/dependabot.yml   # uv + schedule + grupos
grep -c 'package-ecosystem: "github-actions"' .github/dependabot.yml  # 1, separado
grep -rn "ignore-vuln\|\[tool.pip-audit\]" .github/ pyproject.toml lefthook.yml  # zero ocorrências
```

## Cenário 2 — Automerge condicionado

```bash
grep -n "dependabot\[bot\]" .github/workflows/dependabot-automerge.yml  # gate de ator
grep -n "merge --auto --merge" .github/workflows/dependabot-automerge.yml  # só --merge
grep -rn "squash\|rebase" .github/workflows/dependabot-automerge.yml  # zero ocorrências
```

## Cenário 3 — Hook operável

```bash
awk '/pre-commit:/,/pre-push:/' lefthook.yml | grep -c "pip-audit"  # 0
grep -n "pip-audit" lefthook.yml  # só no pre-push
```

## Cenário 4 — Primeiro PR real 🧑

Ver SC-007 da spec: agrupamento, prefixo `build(deps)`, forma SHA das actions e automerge no verde, com saídas verbatim via GitHub MCP. Divergência declarada é saída aceitável; silenciosa não é.
