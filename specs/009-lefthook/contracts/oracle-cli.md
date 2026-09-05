# Contract: Oráculo de Conformidade — Lefthook (009)

**Feature**: `009-lefthook` · **Data**: 2026-09-04
**Artefato**: `scripts/verify/f0-009-lefthook.sh`
**Herda interface de**: `specs/001-git-branching-strategy/contracts/oracle-cli.md` (códigos 0/1/2, `--quiet`/`--list`, linha por REQ-ID, determinismo, somente leitura)

Este contrato especializa o oráculo `f0-009-lefthook.sh` (16 asserções) e o **mapa FR↔asserção** (ADR-015b). Em 009 o mapa É identidade 1:1 — cada FR da spec tem uma asserção homônima; nenhuma fragmentação `a/b`.

## 1. Invocação e saída

Idênticas ao contrato herdado. Adicional 009: o oráculo **nunca executa jobs do hook** (observar via `lefthook validate`/`dump`/`check-install` + `grep` estrutural; executar job seria efeito sobre o estado medido).

## 2. Restrição de dependências

shell + git + Python 3.12 stdlib + `uv` + `pytest` + `ruff` + `mypy` + `pip-audit` (+ `trivy` quando Docker) + `lefthook` via `uv run`. É a última do harness de qualidade: pode assumir toda a cadeia (tabela `scripts/verify/README.md`, faixa 008+).

## 3. Mapa FR spec ↔ FR oráculo (ADR-015b, identidade 1:1)

| FR spec | FR oráculo | Asserção |
|---|---|---|
| FR-001 | FR-001 | pin `2.1.12`: `min_version` + dev + `uv.lock` concordam |
| FR-002 | FR-002 | `lefthook.yml` raiz YAML único; `remotes`/`self-update` ausentes |
| FR-003 | FR-003 | jobs `pre-commit` na ordem, via `uv run`, sem cor forçada |
| FR-004 | FR-004 | `trivy fs` só no `pre-push` + skip sem Docker |
| FR-005 | FR-005 | `pre-push` contém harness `f0-*.sh` |
| FR-006 | FR-006 | somente-leitura: nenhum `--fix`/`stage_fixed` no config |
| FR-007 | FR-007 | `validate` + `check-install` saem 0 |
| FR-008 | FR-008 | escape `LEFTHOOK=0` documentado |
| FR-009 | FR-009 | `.github/` intocado; glob do CI inclui `f0-009` |
| FR-010 | FR-010 | sem escrita fora do repo; nada global |
| FR-011 | FR-011 | **cadência (ADR-016)**: `f0-audit-005-008.md` presente + cabeçalhos inaugurais |
| FR-012 | FR-012 | **fronteira (ADR-017)**: PLAN declara tabela + ADR-018 existe antes do verde |
| FR-013 | FR-013 | contrato de interface (este arquivo): códigos, formato, `--list` |
| FR-014 | FR-014 | `sha256sum -c` 9/9 + self-check `f0-001…f0-008 --quiet` |
| FR-015 | FR-015 | `specs/README.md` `009 ✅` + hash (inquebrável) |
| FR-016 | FR-016 | CONVERGE: zero `^- \[ \]` em `tasks.md` + vermelho em commit separado (log) |

*Sem fragmentação — mapa identidade; FR-011/FR-012 são as primeiras asserções de governança processual do harness (auditoria + fronteira como FR testável).*

> **Guardas × comportamento (legibilidade do `red.txt`).** FR-008/009/010/011/012/013/014
> são guardas: invariantes já verdadeiras no vermelho por construção (FR-008 é
> documentação por natureza — nada a construir a viola). FR-001..007/015/016
> carregam o vermelho (9/16). O cabeçalho do oráculo repete esta distinção em
> comentário — padrão herdado, não defeito: guarda verde-desde-o-nascimento
> protege invariante, não prova TDD.

## 4. Contrato de extensão (para 010+)

010+ seguem este mesmo contrato. Regra de fronteira (ADR-017/018): item que adicionar ferramenta declara impacto no PLAN + ADR prévia; pós-fix silencioso proibido.
