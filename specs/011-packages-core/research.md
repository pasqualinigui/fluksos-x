# Research: `packages/core` — kernel do motor

**Fonte vinculante**: `docs/plan/research/f0-011-packages-core.md` (Q1–Q10, fetch 2026-09-04) · **Consolidação**: decisões abaixo, sem NEEDS CLARIFICATION restante (runtime, superfície mínima e taxonomia resolvidos no CLARIFY 2026-09-04).

## Decision: pydantic(+settings) como runtime do pacote

- **Decision**: `pydantic==2.13.5` + `pydantic-settings==2.15.0` em `dependencies` de `packages/core`; `uv.lock` fonte única.
- **Rationale**: pacote publicado precisa ser funcional; adiar seria dívida à 013.
- **Alternatives considered**: só-dev do workspace (rejeitado: quebra quem instalar `fkx-core`).

## Decision: settings mínimas FKX_ + SecretStr

- **Decision**: ambiente, log, segredo; prefixo `FKX_`; segredos `SecretStr`; `.env.example` com exatamente as vars.
- **Rationale**: YAGNI/Escada; Fase 1+ estende com consumidor (regra escrita na spec).
- **Alternatives considered**: superfície operacional antecipada (rejeitado: especulação sem uso).

## Decision: TypedDict + reducers; Pydantic em models

- **Decision**: `state.py` com `status`, `etapa`, `erros` (acúmulo); sem canal de mensagens; Pydantic só em `models.py`.
- **Rationale**: forma canônica LangGraph (docs oficiais); Pydantic no estado é menos performático; mensagens puxariam `langchain-core` sem consumidor.
- **Alternatives considered**: dataclass (rejeitado: sem defaults a exigir); BaseModel como state (rejeitado: performance); canal messages já (rejeitado: dependência sem uso).

## Decision: FkxError + 3, sem Fase 1 antecipada

- **Decision**: `FkxError(Exception)` + `ConfigError`, `StateError`, `ModelError`; `except:` nu proibido; módulos §17 (4) e nada além.
- **Rationale**: um tipo por módulo; extensão futura por módulo novo (regra na spec).
- **Alternatives considered**: taxonomia genérica maior (rejeitado); `harness.py`/`bridge` já (rejeitado: sem consumidor — IV).
