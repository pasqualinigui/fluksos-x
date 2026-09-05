# Specification Quality Checklist: Pytest 9.1.1 — harness TDD

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-08-31
**Feature**: [specs/005-pytest/spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs) — *spec mentions pytest/uv as required capability (FR-001..004) but Q1–Q10 pins are justified via research; no code structure leaked beyond file paths required by harness contract*
- [x] Focused on user value and business needs — *US1 clone limpo, US2 promoção 1:1, US3 integridade são jornadas de mantenedor/arquiteto*
- [x] Written for non-technical stakeholders — *Contexto e US em linguagem de jornada, não de API*
- [x] All mandatory sections completed — *Contexto, Clarifications, User Scenarios, Requirements, Key Entities, Success Criteria, Assumptions, Dependencies, Contratos, Out of Scope presentes*

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain — *Q clarifications fechadas 2026-08-31 (tests/ raiz, xdist, cov portão, pytest.toml); spec 0 markers*
- [x] Requirements are testable and unambiguous — *FR-001..015 cada com MUST + mecanismo de verificação (check-ignore, sha256sum -c, uv lock --check, subprocess)*
- [x] Success criteria are measurable — *SC-001..008 com métricas <30s, <5s, 100%, 5 linhas, zero `[ ]`*
- [x] Success criteria are technology-agnostic (no implementation details) — *SCs falam de clone limpo, stdout idêntico, manifest 5 linhas, sem mencionar framework interno*
- [x] All acceptance scenarios are defined — *US1 4 cenários, US2 4, US3 4, cada Given/When/Then*
- [x] Edge cases are identified — *8 casos (uv 0.12.1, pytest.toml, async strict, marker typo, .pytest_cache, packages/, --frozen, .venv)*
- [x] Scope is clearly bounded — *Out of Scope lista ruff/mypy/packages/xdist/--cov-fail-under*
- [x] Dependencies and assumptions identified — *6 assumptions + 5 dependencies + Contratos Recebido/Entregue/Transferido*

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria — *FR-001..015 mapeados a US1..3 e a D1–D10 em research*
- [x] User scenarios cover primary flows — *P1 habilita TDD, P2 promoção, P3 integridade/CONVERGE cobrem fluxo completo*
- [x] Feature meets measurable outcomes defined in Success Criteria — *SC-001..008 traçáveis a FR-001..015 e a D1–D10*
- [x] No implementation details leak into specification — * Detalhe de `subprocess` restrito a FR-005/010 (comportamento verificável), sem vazar estrutura de classe*

## Notes

- Spec 005 paga dívidas ADR-007 (5 casos) + A1/A2/M4/B2 + ADR-015a–e (manifest, self-check total, CONVERGE). Verificado em `docs/plan/research/f0-005-pytest.md` 2026-08-31 com fetch PyPI/docs + disco.
- Fronteira Escada verificada: não cria ruff/mypy/packages; amplia `testpaths` só em 011/012 via contrato Transferido (determinístico, não oral).
- Próxima etapa: `/speckit-clarify` (max 5 perguntas) ou `/speckit-plan` (gera plan.md + data-model + contracts).

