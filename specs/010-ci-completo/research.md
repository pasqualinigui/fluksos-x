# Research: CI completo + branch protection — portão servidor

**Fonte vinculante**: `docs/plan/research/f0-010-ci-completo.md` (Q1–Q10, fetch 2026-09-04) · **Consolidação**: decisões abaixo, sem NEEDS CLARIFICATION restante (limiar, modo e topologia resolvidos no CLARIFY 2026-09-04).

## Decision: checks frouxos + sem-bypass, proteção clássica, sem reviews

- **Decision**: required checks frouxos + "Do not allow bypassing" inclusive admin em `main`+`develop`; regra clássica (não rulesets); sem reviews obrigatórios.
- **Rationale**: frouxo economiza builds nesta escala; sem-bypass preserva o portão (é o que neutraliza `--no-verify`); rulesets sem benefício com 1 mantenedor; reviews com 1 humano = deadlock por desenho (docs GitHub).
- **Alternatives considered**: estritos (rejeitado: rebase+rebuild por merge sem ameaça); rulesets (rejeitado: complexidade sem ganho); reviews obrigatórios (rejeitado: trava o próprio mantenedor).

## Decision: pins SHA + runner fixo + matriz exata

- **Decision**: todo `uses:` por SHA + comentário (`checkout v7.0.1`, `setup-python v7.0.0`, `setup-uv v10.0.1`); `ubuntu-24.04`; matriz `["3.12","3.13"]`; `fail-fast: false`.
- **Rationale**: SHA é imutável (tag major sofre tamper silencioso); runner `latest` deriva; matriz = exatamente `requires-python`; sinal total por run (espelho da regra do harness).
- **Alternatives considered**: tags majors (rejeitado: mutáveis); `ubuntu-latest` (rejeitado); matriz com 3.11/3.14 (rejeitado: fora do intervalo declarado).

## Decision: jobs separados por verificador

- **Decision**: 8 jobs nominais únicos (`harness` preservado da 003 + lint, types, tests, audit, secrets, coverage, commitlint); cada job vira required check.
- **Rationale**: falha nomeia o culpado no PR (princípio X); granularidade para required checks; nomes únicos evitam ambiguidade que trava merge (docs).
- **Alternatives considered**: job único (rejeitado: sinal agregado esconde o culpado).

## Decision: cobertura como portão medido-primeiro

- **Decision**: `pytest-cov 7.1.0` em dev + `--fail-under=90` (medido 95% em 2026-09-04).
- **Rationale**: número com certidão (53 stmts); margem 5pp anti-fragilidade; elevação futura por spec/ADR.
- **Alternatives considered**: 80 convencional (rejeitado: sem fundamento = classe ADR-013); só-relatório (rejeitado: mantém lacuna 7 aberta).

## Decision: commitlint com os 11 tipos + quarentena sem máscara

- **Decision**: `commitlint v21.2.2`, preset aceitando os 11 tipos (CONTRIBUTING); `timeout-minutes` por job, sem `continue-on-error`, sem retry mascarador.
- **Rationale**: preset estrito quebraria histórico conforme (armadilha Q8); quarentena ADR-019: teto explícito + falha visível.
- **Alternatives considered**: preset conventional estrito (rejeitado: reprovaria `perf/build/style/revert`); retry automático (rejeitado: transforma vermelho real em verde eventual).
