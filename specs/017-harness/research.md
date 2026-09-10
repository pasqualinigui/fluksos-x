# Research (consolidação Phase 0) — 017 harness

**Fonte vinculante**: `docs/plan/research/f1-017-harness.md` (Q1–Q8, D1–D7, hierarquia P0–P3 da ADR-025, pergunta-padrão de ambiente da ADR-027 §5). Abaixo, só decisões; o porquê mora no vinculante.

## Decisões

- **Decision: feedforward (portão pré-execução, saída `2`) + feedback (julgamento pós-execução, `0`/`1` + evidência).**
  Rationale: vocabulário de controle (P2) operacionalizado sobre precedentes do repo (P0: exit `0/1/2` do `oracle-cli.md`); indústria corrobora o termo "harness" como código determinístico ao redor do agente (P3: `langchain-ai/deepagents`).
  Alternatives considered: invocar oráculos shell via `subprocess` (rejeitado: duplica em vez de dar corpo; composição é por exit codes).
- **Decision: exit codes literais `0/1/2` puros, espelhando o oráculo.**
  Rationale: composição por construção com 16 oráculos; remap proibido (Regra 8). Triangulação: `EX_OK/EX_USAGE/EX_SOFTWARE` executados (P0) + uso real (P3: airflow).
  Alternatives considered: granularidade 64/70 (rejeitada no CLARIFY 2026-09-10).
- **Decision: julgamento com `check=False` + captura (caminho-1); `check=True` só em pré-condição.**
  Rationale: exceção não é evidência (X); `CalledProcessError` carrega `.returncode/.cmd/.output`, sinal vira negativo (`-9` medido), `TimeoutExpired` é fail-closed (P1 CPython + P0).
- **Decision: zero retry.**
  Rationale: governança antes do mérito (ADR-019 §3, `010` FR-010).
- **Decision: POSIX assumido com prova dupla; não-POSIX falha fechado com `HarnessError`.**
  Rationale: sem runner Windows não há prova (VIII); CLARIFY 2026-09-10 escolheu fail-closed sobre limite puro.
- **Decision: `HarnessError(FkxError)` (CLARIFY 2026-09-10).**
  Rationale: taxonomia por módulo da 011; falha nomeia o módulo (X).
- **Decision: fronteira com 1 ponto (`f0-011` FR-002) — PLAN declara, ADR prévia autoriza (10ª execução do molde ADR-017).**
  Rationale: levantamento mecânico (research Q7), não leitura; forma exata no PLAN.
- **Decision: stdlib puro, sem dependência nova.**
  Rationale: Escada; `uv.lock` intocado; Python 3.12.3 medido dentro de `>=3.12,<3.14`.
