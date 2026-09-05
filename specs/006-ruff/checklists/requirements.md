# Specification Quality Checklist: Ruff 0.16.5 — linter + formatter

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-08-31
**Feature**: [specs/006-ruff/spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs) — *spec mentions ruff/uv as required capability but Q1–Q10 pins justified; no code structure leaked beyond file paths*
- [x] Focused on user value and business needs — *US1 clone limpo, US2 regras sênior, US3 fronteira são jornadas de mantenedor/arquiteto*
- [x] Written for non-technical stakeholders — *Contexto e US em linguagem de jornada*
- [x] All mandatory sections completed — *Contexto, Clarifications, User Scenarios, Requirements, Key Entities, Success Criteria, Assumptions, Dependencies, Contratos, Out of Scope presentes*

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain — *Q clarifications fechadas 2026-08-31 (ruff.toml, ALL rules, --fix, mypy); spec 0 markers*
- [x] Requirements are testable and unambiguous — *FR-001..014 cada com MUST + mecanismo (tomllib, check-ignore, ruff check, sha256sum)*
- [x] Success criteria are measurable — *SC-001..008 com métricas 100%, idempotente, <5s*
- [x] Success criteria are technology-agnostic (no implementation details) — *SCs falam de clone limpo, format idempotente, sem mencionar framework interno*
- [x] All acceptance scenarios are defined — *US1 4 cenários, US2 4, US3 4, cada Given/When/Then*
- [x] Edge cases are identified — *8 casos (ruff.toml, E501, S101, S603, .ruff_cache, packages/, ruff 0.15.x, idempotente)*
- [x] Scope is clearly bounded — *Out of Scope lista mypy, lefthook, pip-audit, packages, ruff.toml, D/ANN*
- [x] Dependencies and assumptions identified — *6 assumptions + 4 dependencies + Contratos Recebido/Entregue/Transferido*

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria — *FR-001..014 mapeados a US1..3 e D1–D10*
- [x] User scenarios cover primary flows — *P1 lint+format, P2 regras sênior, P3 fronteira cobrem fluxo completo*
- [x] Feature meets measurable outcomes defined in Success Criteria — *SC-001..008 traçáveis a FR-001..014 e D1–D10*
- [x] No implementation details leak into specification — * Detalhe de ruff check restrito a FR-008/009 (comportamento verificável), sem vazar estrutura de classe*

## Notes

- Spec 006 entrega ruff 0.16.5 como linter+formatter único, com S sênior e compat mypy/py312. Verificado em docs/plan/research/f0-006-ruff.md 2026-08-31 com PyPI simple index + docs.astral.sh 129KB/737KB.
- Fronteira Escada verificada: não cria mypy/lefthook/packages; D sênior sem bloquear tests/.
- Próxima etapa: /speckit-clarify ou /speckit-plan

