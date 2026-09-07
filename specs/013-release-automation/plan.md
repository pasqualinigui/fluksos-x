# Implementation Plan: Automação de release

**Branch**: `feature/f0-013-release-automation` | **Date**: 2026-09-06 | **Spec**: `specs/013-release-automation/spec.md`

## Summary

Configurar versionamento semântico via `python-semantic-release==10.6.2`, com `CHANGELOG.md`, carimbo em lockstep, construção por `uv build`, publicação por `pypa/gh-action-pypi-publish@v1.14.2` (OIDC), inventário CycloneDX 1.5 via `uv export`, e oráculo `f0-013-release.sh` com 16 asserções.

## Constitution Check

| Princípio | Veredito | Fundamento |
|---|---|---|
| I Determinismo | ✅ PASS | versão derivada por regra, pins exatos |
| II Spec antes | ✅ PASS | spec 013 + clarify precedem |
| III Teste antes | ✅ PASS | oráculo vermelho→verde separado |
| IV Dados antes | ✅ PASS | data-model + contratos |
| V Lei Zero | ✅ PASS | OIDC, sem credencial em arquivo |
| VI Oráculo | ✅ PASS | 16 asserções novas, 001-012 intocados |
| VII Auto-reparo | ✅ PASS | lições 009-012 consumidas |
| VIII Elo verificado | ✅ PASS | PyPI + GitHub + executado Q1-Q10 |
| IX Agnosticismo | ✅ PASS | versiona este motor |
| X Observabilidade | ✅ PASS | FRs no oráculo |

## Decisões técnicas

D1 PSR 10.6.2 em dev · D2 build/SBOM por uv · D3 publicação por action oficial PyPA · D4 lockstep 3 pyproject.toml · D5 allow_zero_version + major_on_zero · D6 fluxo B (PSR calcula, humano aplica) · D7 artefatos efêmeros · D8 pending publishers + environment · D9 pin uv no workflow.

## Declaração de impacto de fronteira

013 **não toca** oráculo anterior: `pylock.toml` e SBOM são efêmeros (anexados ao release, não versionados).
