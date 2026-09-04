# Contract: Oráculo de Conformidade — `packages/core` (011)

**Feature**: `011-packages-core` · **Data**: 2026-09-04
**Artefato**: `scripts/verify/f0-011-core.sh`
**Herda interface de**: `specs/001-git-branching-strategy/contracts/oracle-cli.md` (códigos 0/1/2, `--quiet`/`--list`, linha por REQ-ID, determinismo, somente leitura)

Este contrato especializa o oráculo `f0-011-core.sh` (12 asserções) e o **mapa FR↔asserção** (ADR-015b). Em 011 o mapa É identidade 1:1 — cada FR da spec tem uma asserção homônima; nenhuma fragmentação `a/b`.

## 1. Invocação e saída

Idênticas ao contrato herdado. Adicional 011: o oráculo pode importar o pacote (`python3 -c "import fkx_core"`) como asserção de importabilidade — sem efeitos colaterais (import sem I/O é requisito).

## 2. Restrição de dependências

shell + git + Python 3.12 stdlib + `uv` + cadeia 005–010. Sem rede além do já instalado; `uv sync` permitido no verde (materializa deps, como 008).

## 3. Mapa FR spec ↔ FR oráculo (ADR-015b, identidade 1:1)

| FR spec | FR oráculo | Asserção |
|---|---|---|
| FR-001 | FR-001 | `pydantic(+settings)` runtime em `packages/core` + hash `uv.lock` |
| FR-002 | FR-002 | membro UV + 4 módulos + `__init__`, nada além |
| FR-003 | FR-003 | settings `FKX_` + `SecretStr` + `ConfigError` em var ausente |
| FR-004 | FR-004 | `TypedDict` + canais/reducers; sem Pydantic como state |
| FR-005 | FR-005 | modelos Pydantic sem lógica |
| FR-006 | FR-006 | `FkxError` + 3; sem `except:` nu / `BaseException` |
| FR-007 | FR-007 | `ruff` + `mypy --strict` zeros sobre `src/fkx_core/` |
| FR-008 | FR-008 | testes em `tests/test_fkx_core_*.py` verdes (TDD preservado) |
| FR-009 | FR-009 | `.env.example` cobre vars; `.env` jamais versionado |
| FR-010 | FR-010 | contrato (este arquivo) + self-check próprio |
| FR-011 | FR-011 | manifest 11/11 + self-check `f0-001…f0-010` |
| FR-012 | FR-012 | README `011 ✅`+hash + tasks zero + vermelho-verde |

> **Guardas × comportamento (legibilidade do `red.txt`).** FR-010 (contrato
> auto-verificável) e FR-011 (manifest por acréscimo + self-check herdado, ambos
> verdadeiros pré-código) são guardas. FR-001..009/012 carregam o vermelho
> (10/12). Padrão herdado de 009/010, não defeito.

> **Guardas × comportamento (legibilidade do `red.txt`).** FR-010 é guarda
> (contrato auto-verificável, verde-desde-o-nascimento). FR-001..009/011/012
> carregam o vermelho (11/12). Padrão herdado de 009/010, não defeito.

## 4. Contrato de extensão (para 012+)

012+ seguem este mesmo contrato. Regra de fronteira (ADR-017): `packages/` agora existe (jurisdição 011/012); item que adicionar pacote declara impacto no PLAN + ADR prévia.
