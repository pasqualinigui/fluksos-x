# Contract: Oráculo de Conformidade — CI completo (010)

**Feature**: `010-ci-completo` · **Data**: 2026-09-04
**Artefato**: `scripts/verify/f0-010-ci-completo.sh`
**Herda interface de**: `specs/001-git-branching-strategy/contracts/oracle-cli.md` (códigos 0/1/2, `--quiet`/`--list`, linha por REQ-ID, determinismo, somente leitura)

Este contrato especializa o oráculo `f0-010-ci-completo.sh` (13 asserções) e o **mapa FR↔asserção** (ADR-015b). Em 010 o mapa É identidade 1:1 — cada FR da spec tem uma asserção homônima; nenhuma fragmentação `a/b`.

## 1. Invocação e saída

Idênticas ao contrato herdado. Adicional 010: o oráculo **nunca usa token nem rede autenticada** (Lei Zero) — proteção de servidor é verificada via procedimento documentado + cenário humano (🧑), nunca por API.

## 2. Restrição de dependências

shell + git + Python 3.12 stdlib + `uv` + cadeia 005–009 (o oráculo pode invocar os verificadores locais para espelhar jobs). Sem `gh`, sem `docker` obrigatório (Trivy pleno só onde houver Docker — skip ⏭️ herdado).

## 3. Mapa FR spec ↔ FR oráculo (ADR-015b, identidade 1:1)

| FR spec | FR oráculo | Asserção |
|---|---|---|
| FR-001 | FR-001 | `ci.yml` estendido sem renomear job `verify` |
| FR-002 | FR-002 | `uses:` por SHA + comentário; runner `ubuntu-24.04` |
| FR-003 | FR-003 | `setup-uv` + `uv sync --frozen` + cache |
| FR-004 | FR-004 | matriz `["3.12","3.13"]` + `fail-fast: false` |
| FR-005 | FR-005 | 8 jobs nominais únicos (harness, lint, types, tests, audit, secrets, coverage, commitlint) |
| FR-006 | FR-006 | `pytest-cov` em dev + `--fail-under=90` |
| FR-007 | FR-007 | commitlint + preset 11 tipos; histórico 100% passa |
| FR-008 | FR-008 | procedimento de proteção versionado (checks + sem-bypass, sem reviews); **sem token em arquivo algum** |
| FR-009 | FR-009 | modo frouxo + sem-bypass documentados no procedimento |
| FR-010 | FR-010 | `timeout-minutes` por job; sem `continue-on-error`/retry |
| FR-011 | FR-011 | contrato de interface (este arquivo) + self-check próprio (list/exit2/2×/<5s) |
| FR-012 | FR-012 | manifest 10/10 + self-check `f0-001…f0-009` |
| FR-013 | FR-013 | README `010 ✅`+hash + tasks zero + vermelho-antes-do-verde |

*Sem fragmentação — mapa identidade. FR-008/009 cobrem o procedimento (lado versionável); o lado servidor é cenário 🧑 (precedente 003-T031).*

## 4. Contrato de extensão (para 011+)

011+ seguem este mesmo contrato. Regra de fronteira (ADR-017): item que tocar `.github/` declara impacto no PLAN + ADR prévia; renomear jobs com checks nominais = conflito.
