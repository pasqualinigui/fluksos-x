# Research: Automação de release

**Fonte vinculante**: `docs/plan/research/f0-013-release-automation.md` (Q1-Q10, fetch 2026-09-06)

## Decisões consolidadas

- **D1**: `python-semantic-release==10.6.2` em dev (Q1)
- **D2**: build/SBOM por uv, `cyclonedx-bom` descartado (Q5)
- **D3**: publicação por action oficial PyPA (única que produz atestado PEP 740 — Q6 corrigido)
- **D4**: lockstep 3 pyproject.toml via `version_toml` (Q4)
- **D5**: `allow_zero_version = true` + `major_on_zero = false` (Q3)
- **D6**: fluxo B — PSR calcula, humano aplica via PR (Q7)
- **D7**: artefatos efêmeros, não versionados (Q10)
- **D8**: dois pending publishers + GitHub environment (Q8)
- **D9**: pin `uv` no workflow (Q9)
