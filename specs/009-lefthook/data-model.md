# Data Model: Lefthook — orquestração pre-commit do harness

## Entidades

### 1. Configuração do orquestrador (`lefthook.yml`)

| Campo | Tipo | Regra |
|---|---|---|
| `min_version` | string semver exata | MUST igualar o pin (`2.1.12`); a ferramenta recusa divergência |
| `pre-commit.commands[]` | lista ordenada | ordem fail-fast fixa (FR-003); cada job: `run` via `uv run`, `glob`/`tags` opcionais |
| `pre-push.commands[]` | lista | harness completo + `trivy fs` condicional (FR-004/005) |
| proibidos | — | `remotes`, `self-update`, qualquer escritor (`--fix`, `stage_fixed`) — presença reprova |

### 2. Dependência travada (dev + lock)

| Campo | Tipo | Regra |
|---|---|---|
| `[dependency-groups] dev` | entrada `lefthook==2.1.12` | pin exato, sem faixa |
| `uv.lock` | `name = "lefthook"` + hash | fonte de legitimidade das fronteiras (padrão ADR-018) |

### 3. Asserção de fronteira (herdada)

Declaração de oráculo anterior que proíbe artefato futuro; atributos: oráculo, FR, condição que dispara, ajuste pré-autorizado (tabela do PLAN). Ciclo de vida: proibição → declaração de impacto → ADR prévia → ajuste no verde → nova base congelada.

### 4. Dívida de cadência

Relatório `docs/plan/audit/f0-audit-NNN-MMM.md`; atributo: cabeçalhos do formato inaugural grepeáveis. Regra: a 5ª spec sem relatório não converge (ADR-016).

### 5. Linha de manifest + índice

9ª linha `sha256sum` de `f0-009` (acréscimo, nunca reescrita de valor alheio); `specs/README.md` `009 ✅` + hash do commit verde (inquebrável FR-015).

## Relações

- Configuração 1:1 Dependência travada (`min_version` = pin = lock).
- Oráculo observa Configuração via `validate`/`dump` (nunca executa jobs).
- Ajustes de fronteira N:1 ADR prévia (ADR-018 autoriza os 5 pontos).
- Índice aponta commit verde; verde aponta manifest; manifest aponta oráculo.

## Ciclo de vida

Ausente (vermelho 🔴) → presente + verde (🟢, Fase C) → convergido (índice + manifest). Reversão de versão = nova spec/ADR, nunca edição.

## Volume / escala

5 jobs `pre-commit` + harness `pre-push`; 16 FRs → 16 asserções; 1 arquivo de config; 0 pacotes.
